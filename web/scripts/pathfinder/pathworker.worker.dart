import "package:CommonLib/Logging.dart";
import "package:CommonLib/Workers.dart";

import "../level/domainmap.dart";
import "../level/pathnode.dart";
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

        return unconnected.map((PathNode node) => node.id).toList();
    }

    Future<void> processDomainMap(dynamic domainMapPayload) async {
        logger.debug("Domain map payload: $domainMapPayload");
    }

    /// Walks the node graph from the exit node in a simple manner.
    /// Returns a list of blocked or disconnected nodes
    ///
    /// If IgnoreBlockedStatus is true, blocked cells are treated as clear, and the list is only unconnected nodes
    Future<List<PathNode>> connectivityTest({bool ignoreBlockedStatus = false, List<int> flipTests}) async {

        final Set<PathNode> open = <PathNode>{exitNode};
        final Set<PathNode> closed = <PathNode>{};

        while (!open.isEmpty) {
            final PathNode current = open.first;
            open.remove(current);
            closed.add(current);

            for (final PathNode connected in current.connections.keys) {
                if (!closed.contains(connected)) {
                    open.add(connected);
                }
            }
        }

        final List<PathNode> unconnected = pathNodes.where((PathNode node) => !closed.contains(node)).toList();

        return unconnected;
    }
}

void main() {
    new PathWorker();
}

