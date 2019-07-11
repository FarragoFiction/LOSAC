import "dart:html";

import "../renderer/2d/renderable2d.dart";
import "connectible.dart";
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

        ctx.fillStyle = "#60A0FF";
        ctx.strokeStyle = "#60A0FF";
        double size = 4;

        for (final PathNode node in pathNodes) {
            drawn.add(node);

            ctx.save();

            if (node is SpawnNode) {
                ctx.fillStyle = "#44EE44";
                size = 8;
            } else if (node is ExitNode) {
                ctx.fillStyle = "#FF3030";
                size = 8;
            }

            ctx.fillRect(node.pos_x * scaleFactor - size/2, node.pos_y * scaleFactor - size/2, size, size);

            ctx.restore();

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

        this.spawners.clear();
        this.exit = null;

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

        for (final PathNode node in pathNodes) {
            if (node is SpawnNode) {
                this.spawners.add(node);
            } else if (node is ExitNode) {
                if (this.exit != null) {
                    throw Exception("ONLY ONE EXIT, DUNKASS");
                }
                this.exit= node;
            }
        }
    }
}