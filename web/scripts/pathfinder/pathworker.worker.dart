import "dart:collection";

import "package:collection/collection.dart";
import "package:CommonLib/Logging.dart";
import "package:CommonLib/Workers.dart";

import "../level/domainmap.dart";
import "../level/pathnode.dart";
import "../renderer/2d/vector.dart";
import "../utility/levelutils.dart";
import "commands.dart";

class PathWorker extends WorkerBase {
    static final Logger logger = new Logger("Path Worker", true);

    DomainMap domainMap;
    List<PathNode> pathNodes;
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
        }

        return null;
    }

    Future<List<int>> processNodeData(dynamic nodeDataPayload) async {
        logger.debug("Node data payload: $nodeDataPayload");

        final List<dynamic> data = nodeDataPayload;

        pathNodes = <PathNode>[];
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
                ..pos_x = nodeData["x"]
                ..pos_y = nodeData["y"]
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

        LevelUtils.prunePathNodeList(pathNodes, unconnected);

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

    Future<List<int>> rebuildPathData() async {

        final Map<PathNode, double> distance = <PathNode, double>{
            exitNode : 0
        };
        final Map<PathNode, PathNode> previous = <PathNode, PathNode>{};

        final Map<PathNode, double> priorities = <PathNode,double>{
            exitNode: 0
        };
        final PriorityQueue<PathNode> open = new PriorityQueue<PathNode>((PathNode a, PathNode b) => priorities[a].compareTo(priorities[b]));
        open.add(exitNode);

        // init values
        for (final PathNode node in pathNodes) {
            node.targetNode = null;
            if (node != exitNode) {
                distance[node] = double.infinity;
            }
        }

        while(!open.isEmpty) {
            final PathNode u = open.removeFirst();

            for (final PathNode neighbour in u.connections.keys) {
                if (neighbour.blocked) { continue; }
                final double alt = distance[u] + u.connections[neighbour];
                if (alt < distance[neighbour]) {
                    distance[neighbour] = alt;
                    previous[neighbour] = u;
                    priorities[neighbour] = alt;
                    open.add(neighbour);
                }
            }
        }

        for (final PathNode node in pathNodes) {
            if (previous.containsKey(node)) {
                node.targetNode = previous[node];
            }
        }

        calculateShortcuts();

        return pathNodes.map((PathNode node) => node.targetNode == null ? -1 : node.targetNode.id).toList();
    }

    void calculateShortcuts() {
        final Set<PathNode> shortcuttable = new Set<PathNode>.from(pathNodes.where((PathNode n) => n.validShortcut));

        final Map<PathNode,PathNode> newTargets = <PathNode,PathNode>{};
        final Map<PathNode, List<PathNode>> shortcutPassSteps = <PathNode, List<PathNode>>{};

        final Map<PathNode,Map<PathNode,double>> distances = <PathNode,Map<PathNode,double>>{};
        double getDist(PathNode from, PathNode to) {
            if(distances.containsKey(from)) {
                final Map<PathNode, double> subdists = distances[from];
                if (subdists.containsKey(to)) {
                    return subdists[to];
                }
            } else {
                distances[from] = <PathNode, double>{};
            }
            if (!distances.containsKey(to)) {
                distances[to] = <PathNode, double>{};
            }
            final double dist = (to.posVector - from.posVector).length;
            distances[from][to] = dist;
            distances[to][from] = dist;
            return dist;
        }

        for (final PathNode node in shortcuttable) {
            if (node.targetNode == null) { continue; }

            PathNode iNode = node.targetNode;
            while (iNode.validShortcut) {
                final bool clear = LevelUtils.isLineClear(domainMap, pathNodes, node, iNode);

                if (clear) {
                    newTargets[node] = iNode;
                    if (iNode.targetNode != null) {
                        iNode = iNode.targetNode;
                    } else {
                        break;
                    }
                } else {
                    break;
                }
            }

        }

        for (final PathNode node in newTargets.keys) {
            //node.targetNode = newTargets[node];
            final PathNode sNode = newTargets[node];

            final List<PathNode> steps = domainMap
                .valuesAlongLine(node.pos_x, node.pos_y, sNode.pos_x, sNode.pos_y, 10)
                .map((int id) => pathNodes[id-1])
                .where((PathNode n) => node != n)
                .toList();

            final Map<PathNode, double> distances = <PathNode, double>{};

            for (final PathNode step in steps) {
                distances[step] = getDist(node, step);
                if (newTargets.containsKey(step)) {
                    distances[step] += getDist(step, newTargets[step]);
                }
            }

            steps.sort((PathNode a, PathNode b) => distances[a].compareTo(distances[b]));

            shortcutPassSteps[node] = steps;
        }

        for (final PathNode node in shortcuttable) {
            if (node.targetNode == null) { continue; }

            PathNode iNode = node;
            while(iNode.validShortcut) {
                if (shortcutPassSteps.containsKey(iNode)) {
                    final PathNode shortcut = refineShortcut(iNode, newTargets, shortcutPassSteps[iNode]);
                    iNode.targetNode = shortcut;
                    iNode = shortcut;
                } else {
                    if (newTargets.containsKey(iNode)) {
                        iNode.targetNode = newTargets[iNode];
                    }
                    break;
                }
            }
        }
    }

    PathNode refineShortcut(PathNode node, Map<PathNode,PathNode> newTargets, List<PathNode> steps) {
        for (final PathNode testNode in steps) {
            if (newTargets[testNode] != newTargets[node]) {
                return testNode;
            }
        }
        return newTargets[node];
    }
}

void main() {
    new PathWorker();
}

