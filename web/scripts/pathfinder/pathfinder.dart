import "dart:async";
import "dart:math" as Math;

import "package:CommonLib/Workers.dart";

import "../level/level.dart";
import "../level/pathnode.dart";
import "commands.dart";

class Pathfinder {
    late WorkerHandler worker;

    Pathfinder() {
        worker = createWebWorker("scripts/pathfinder/pathworker.worker.dart");
    }

    Future<void> transferNodeData(Level level) async {

        final List<Map<String, dynamic>> payload = level.pathNodes.map((PathNode node) => <String, dynamic>{
            "type": node is ExitNode ? "exit" : node is SpawnNode ? "spawn" : null,
            "x": node.position.x,
            "y": node.position.y,
            "shortcut": node.validShortcut,
            "blocked": node.blocked,
            "links": node.connections.keys.map((PathNode connection) => <String,dynamic>{
                "id": connection.id,
                "dist": node.connections[connection]
            }).toList()
        }).toList();

        final List<dynamic> nodeIdsToPrune = await worker.sendCommand(Commands.processNodeData, payload: payload);

        level.prunePathNodes(nodeIdsToPrune.map<PathNode>((dynamic id) => level.pathNodes[id-1]));
    }

    Future<void> transferDomainMap(Level level) async {
        final Map<String, dynamic> payload = <String,dynamic>{
            "x": level.domainMap.pos_x,
            "y": level.domainMap.pos_y,
            "width": level.domainMap.width,
            "height": level.domainMap.height,
            "array": level.domainMap.array
        };

        await worker.sendCommand(Commands.sendDomainMap, payload: payload);
    }

    Future<void> recalculatePathData(Level level) async {
        final Map<dynamic, dynamic> payload = await worker.sendCommand(Commands.recalculatePaths);
        final List<dynamic> ids = payload["id"];
        final List<dynamic> distances = payload["dist"];

        for (final PathNode node in level.pathNodes) {
            node.targetNode = null;
        }

        double maxDist = 0;

        for (int i=0; i<ids.length; i++) {
            // set node next targets
            final int targetId = ids[i];
            if (targetId > 0) {
                level.pathNodes[i].targetNode = level.pathNodes[targetId-1];
            }
            // set distances from exit and calculate largest distance for fractional
            final double dist = distances[i];
            level.pathNodes[i].distanceToExit = dist;
            if (dist < double.infinity) {
                maxDist = Math.max(maxDist, dist);
            }
        }

        //divide distance for each node by maxDist to get the fraction, if not infinite
        for (final PathNode node in level.pathNodes) {
            if (maxDist > 0 && node.distanceToExit < double.infinity) {
                node.distanceToExitFraction = node.distanceToExit / maxDist;
            } else {
                node.distanceToExitFraction = double.infinity;
            }
        }
    }

    Future<List<PathNode>> connectivityCheck(Level level, {Iterable<PathNode>? flipTests, bool ignoreBlockedStatus = false}) async {

        final Map<String,dynamic> payload = <String,dynamic> {
            "ignore": ignoreBlockedStatus
        };

        if (flipTests != null) {
            payload["flip"] = flipTests.map((PathNode node) => node.id).toList();
        }

        final List<dynamic> unreachableIds = await worker.sendCommand(Commands.connectivityCheck, payload: payload);

        return unreachableIds.map((dynamic id) => level.pathNodes[id-1]).toList();
    }

    Future<void> flipNodeState(Iterable<PathNode> nodes) async {
        return worker.sendCommand(Commands.flipNodeState, payload: nodes.map((PathNode node) => node.id).toList());
    }

    void destroy() {
        worker.destroyWorker();
    }
}