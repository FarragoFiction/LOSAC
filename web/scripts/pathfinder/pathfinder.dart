import "dart:async";

import "package:CommonLib/Workers.dart";

import "../level/level.dart";
import "../level/pathnode.dart";
import "commands.dart";

class Pathfinder {
    WorkerHandler worker;

    Pathfinder() {
        worker = createWebWorker("scripts/pathfinder/pathworker.worker.dart");
    }

    Future<void> transferNodeData(Level level) async {

        final List<Map<String, dynamic>> payload = level.pathNodes.map((PathNode node) => <String, dynamic>{
            "type": node is ExitNode ? "exit" : node is SpawnNode ? "spawn" : null,
            "x": node.pos_x,
            "y": node.pos_y,
            "shortcut": node.validShortcut,
            "blocked": node.blocked,
            "links": node.connections.keys.map((PathNode connection) => <String,dynamic>{
                "id": connection.id,
                "dist": node.connections[connection]
            }).toList()
        }).toList();

        final List<dynamic> nodeIdsToPrune = await worker.sendCommand(Commands.processNodeData, payload: payload);

        print("to prune: $nodeIdsToPrune");
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
}