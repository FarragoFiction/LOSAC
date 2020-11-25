import "dart:collection";
import 'dart:html';

import "package:collection/collection.dart";
import "package:CommonLib/Logging.dart";
import "package:CommonLib/Workers.dart";
import "package:CubeLib/CubeLib.dart" as B;

import "../level/domainmap.dart";
import "../level/pathnode.dart";
import "../utility/levelutils.dart";
import "commands.dart";

class PathWorker extends WorkerBase {
    static final Logger logger = new Logger("Path Worker");//, true); // debug print flag

    DomainMap domainMap;
    List<PathNode> pathNodes;
    Iterable<PathNode> connectedNodes;
    List<SpawnNode> spawners;
    ExitNode exitNode;

    PathWorker() {
        logger.info("Worker Loaded");
    }

    @override
    Future<dynamic> handleCommand(String command, dynamic payload) async {

        switch(command) {
            case Commands.processNodeData:
                return processNodeData(payload);
            case Commands.sendDomainMap:
                return processDomainMap(payload);
            case Commands.recalculatePaths:
                return rebuildPathData();
            case Commands.connectivityCheck:
                return connectivityCheck(payload);
            case Commands.flipNodeState:
                return flipNodeState(payload);
        }

        return null;
    }

    Future<List<int>> processNodeData(dynamic nodeDataPayload) async {
        logger.debug("Node data payload: $nodeDataPayload");

        final List<dynamic> data = nodeDataPayload;

        pathNodes = <PathNode>[];
        connectedNodes = pathNodes.where((PathNode node) => !node.isolated);
        spawners = <SpawnNode>[];
        exitNode = null;

        for(int i=0; i<data.length; i++) {
            final Map<dynamic, dynamic> nodeData = data[i];

            PathNode node;

            if (nodeData["type"] == null) {
                node = new PathNode();
            } else if (nodeData["type"] == "spawn") {
                node = new SpawnNode();
                spawners.add(node);
            } else if (nodeData["type"] == "exit") {
                if (exitNode != null) {
                    throw Exception("ONLY ONE EXIT NODE, DUNKASS: Worker Edition");
                }
                node = new ExitNode();
                exitNode = node;
            }

            node
                ..id = i + 1
                ..position.x = nodeData["x"]
                ..position.y = nodeData["y"]
                ..blocked = nodeData["blocked"]
                ..validShortcut = nodeData["shortcut"];

            pathNodes.add(node);
        }

        for(final PathNode node in pathNodes) {
            final List<dynamic> connections = data[node.id-1]["links"];

            for (final Map<dynamic,dynamic> connection in connections) {
                node.connections[pathNodes[connection["id"]-1]] = connection["dist"];
            }
        }

        // ignore blocked, because we care about disconnected cells, not blocked ones here
        final List<PathNode> unconnected = await connectivityTest(ignoreBlockedStatus: true);

        final List<int> returnIds = unconnected.map((PathNode node) => node.id).toList();

        //LevelUtils.prunePathNodeList(pathNodes, unconnected);
        for (final PathNode node in unconnected) {
            node.isolated = true;
        }

        return returnIds;
    }

    Future<void> processDomainMap(dynamic domainMapPayload) async {
        logger.debug("Domain map payload: $domainMapPayload");

        final Map<dynamic, dynamic> data = domainMapPayload;

        domainMap = new DomainMap.fromData(data["x"], data["y"], data["width"], data["height"], data["array"]);
    }

    /// Walks the node graph from the exit node in a simple manner.
    /// Returns a list of blocked or disconnected nodes
    ///
    /// If IgnoreBlockedStatus is true, blocked cells are treated as clear, and the list is only unconnected nodes
    Future<List<PathNode>> connectivityTest({bool ignoreBlockedStatus = false, List<int> flipTests}) async {

        final Queue<PathNode> open = new Queue<PathNode>()..add(exitNode);
        final Set<PathNode> closed = <PathNode>{};

        while (!open.isEmpty) {
            final PathNode current = open.removeFirst();
            open.remove(current);
            closed.add(current);

            for (final PathNode connected in current.connections.keys) {
                if (!ignoreBlockedStatus) {
                    bool blocked = connected.blocked;
                    if (flipTests.contains(connected.id)) {
                        blocked = !blocked;
                    }
                    if (blocked) { continue; }
                }

                if (!closed.contains(connected)) {
                    open.add(connected);
                }
            }
        }

        final List<PathNode> unconnected = pathNodes.where((PathNode node) => !closed.contains(node)).toList();

        return unconnected;
    }

    /// Modified Theta* without heuristic, so basically Dijkstra's with corner cutting.
    /// Respects the pathNode validShortcut property
    Future<Map<String, List<num>>> rebuildPathData() async {
        final Map<PathNode, double> distance = <PathNode, double>{
            exitNode : 0
        };
        final Map<PathNode, PathNode> previous = <PathNode, PathNode>{
            exitNode : exitNode
        };

        final Map<PathNode, double> priorities = <PathNode,double>{
            exitNode: 0
        };
        final PriorityQueue<PathNode> open = new PriorityQueue<PathNode>((PathNode a, PathNode b) {
            final int c = priorities[a].compareTo(priorities[b]);
            if (c == 0 && a != b) { return 1; }
            return c;
        });
        open.add(exitNode);
        // openSet tracks the same objects as open, but is cheaper to query contains
        final Set<PathNode> openSet = <PathNode>{exitNode};

        final Set<PathNode> closed = <PathNode>{};

        // init values
        for (final PathNode node in pathNodes) {
            node.targetNode = null;
            if (node != exitNode) {
                distance[node] = double.infinity;
            }
        }

        //update function
        void update_vertex(PathNode s, PathNode neighbour) {
            if( neighbour.validShortcut && previous[s].validShortcut && LevelUtils.isLineClear(domainMap, pathNodes, previous[s], neighbour)) {
                final double dist = (previous[s].position - neighbour.position).length();

                if (distance[previous[s]] + dist < distance[neighbour]) {
                    distance[neighbour] = distance[previous[s]] + dist;
                    previous[neighbour] = previous[s];
                    if (openSet.contains(neighbour)) {
                        open.remove(neighbour);
                        openSet.remove(neighbour);
                    }
                    priorities[neighbour] = distance[neighbour];
                    open.add(neighbour);
                    openSet.add(neighbour);
                }
            } else {
                if (distance[s] + s.connections[neighbour] < distance[neighbour]) {
                    distance[neighbour] = distance[s] + s.connections[neighbour];
                    previous[neighbour] = s;
                    if (openSet.contains(neighbour)) {
                        open.remove(neighbour);
                        openSet.remove(neighbour);
                    }
                    priorities[neighbour] = distance[neighbour];
                    open.add(neighbour);
                    openSet.add(neighbour);
                }
            }
        }

        while(!openSet.isEmpty) {
            final PathNode u = open.removeFirst();
            openSet.remove(u);
            closed.add(u);

            for (final PathNode neighbour in u.connections.keys) {
                if (neighbour.blocked) { continue; }

                if (!closed.contains(neighbour)) {
                    if(!openSet.contains(neighbour)) {
                        distance[neighbour] = double.infinity;
                        previous[neighbour] = null;
                    }
                    update_vertex(u, neighbour);
                }
            }
        }

        for (final PathNode node in pathNodes) {
            if (previous.containsKey(node)) {
                node.targetNode = previous[node];
            }
        }

        return <String,List<num>> {
            "id": pathNodes.map((PathNode node) => node.targetNode == null ? -1 : node.targetNode.id).toList(),
            "dist": pathNodes.map((PathNode node) => distance[node]).toList()
        };
    }

    bool compareOpenToOpenSet(PriorityQueue<PathNode> open, Set<PathNode> openSet ) {
        if (open.length != openSet.length) { return true; }

        final Set<PathNode> checked = <PathNode>{};
        final List<PathNode> openList = open.toList();
        for (final PathNode n in openList) {
            checked.add(n);
            if (!openSet.contains(n)) {
                return true;
            }
        }
        if (checked.length != openSet.length) { return true; }
        return false;
    }

    Future<List<int>> connectivityCheck(dynamic payload) async {
        final Map<dynamic,dynamic> data = payload;

        final bool ignore = data.containsKey("ignore") ? data["ignore"] : false;
        final List<int> flips = data.containsKey("flip") ? new List<int>.from(data["flip"]) : null;

        final List<PathNode> nodes = await connectivityTest(ignoreBlockedStatus: ignore, flipTests: flips);

        return nodes.map((PathNode node) => node.id).toList();
    }

    Future<void> flipNodeState(dynamic payload) async {
        final List<dynamic> ids = payload;

        for (int i=0; i<ids.length; i++) {
            final int id = ids[i];
            final PathNode n = pathNodes[id-1];
            n.blocked = !n.blocked;
        }
    }
}

void main() {
    new PathWorker();
    
    WorkerGlobalScope.instance.importScripts("../../packages/CubeLib/js/babylon.js");
    WorkerGlobalScope.instance.importScripts("../../packages/CubeLib/js/babylon_extensions.js");

    final B.Vector3 a = new B.Vector3(1,0,0);
    final B.Vector3 b = new B.Vector3(0.5,1,0);

    print(a+b);
}

