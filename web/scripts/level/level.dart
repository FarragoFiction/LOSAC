import "dart:html";

import "../renderer/2d/renderable2d.dart";
import "connectable.dart";
import "levelobject.dart";
import "pathnode.dart";

class Level with Renderable2D {

    Set<LevelObject> objects = <LevelObject>{};

    final List<PathNode> pathNodes = <PathNode>[];
    final List<SpawnNode> spawners = <SpawnNode>[];
    ExitNode exit;

    @override
    void drawToCanvas(CanvasRenderingContext2D ctx) {
        for (final LevelObject o in objects) {
            o.drawToCanvas(ctx);
        }
    }

    @override
    void drawUIToCanvas(CanvasRenderingContext2D ctx, double scaleFactor) {
        for (final LevelObject o in objects) {
            o.drawUIToCanvas(ctx, scaleFactor);
        }

        drawPathNodes(ctx, scaleFactor);
    }

    void drawPathNodes(CanvasRenderingContext2D ctx, double scaleFactor) {
        final Set<PathNode> drawn = <PathNode>{};

        ctx.fillStyle = "#44EE44";
        ctx.strokeStyle = "#44EE44";

        for (final PathNode node in pathNodes) {
            drawn.add(node);

            ctx.fillRect(node.pos_x * scaleFactor - 2, node.pos_y * scaleFactor - 2, 4, 4);

            for (final PathNode other in node.connections.keys) {
                if (drawn.contains(other)) { continue; }

                ctx
                    ..beginPath()
                    ..lineTo(node.pos_x * scaleFactor, node.pos_y * scaleFactor)
                    ..lineTo(other.pos_x * scaleFactor, other.pos_y * scaleFactor)
                    ..stroke();
            }
        }
    }

    void derivePathNodes() {
        this.pathNodes.clear();

        final Iterable<Connectible> connectibles = objects.whereType();

        for (final Connectible object in connectibles) {
            object.clearPathNodes();
        }

        for (final Connectible object in connectibles) {
            pathNodes.addAll(object.generatePathNodes());
        }

        for (final Connectible object in connectibles) {
            object.connectPathNodes();
        }
    }
}