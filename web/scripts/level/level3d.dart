import "dart:html";

import "package:CubeLib/CubeLib.dart" as B;

import "../engine/engine.dart";
import "../renderer/3d/renderable3d.dart";
import "level.dart";
import "levelobject.dart";
import "pathnode.dart";

class Level3D extends Level with Renderable3D {

    /*@override
    void drawUIToCanvas(CanvasRenderingContext2D ctx, double scaleFactor) {
        for (final LevelObject o in objects) {
            o.drawUIToCanvas(ctx, scaleFactor);
        }

        //drawPathNodes(ctx, scaleFactor);

        //drawBoundingBoxes(ctx, scaleFactor);

        drawRoutes(ctx, scaleFactor);
    }*/

    void drawBoundingBoxes(CanvasRenderingContext2D ctx, double scaleFactor) {
        const double cross = 10;
        ctx.strokeStyle = "rgba(255,200,20)";
        for (final LevelObject o in objects) {
            final Rectangle<num> bounds = o.bounds;
            ctx.strokeRect(bounds.left * scaleFactor, bounds.top * scaleFactor, bounds.width * scaleFactor, bounds.height * scaleFactor);

            final B.Vector2 v = o.getWorldPosition() * scaleFactor;

            ctx
                ..beginPath()
                ..moveTo(v.x - cross, v.y)
                ..lineTo(v.x + cross, v.y)
                ..stroke()
                ..beginPath()
                ..moveTo(v.x, v.y - cross)
                ..lineTo(v.x, v.y + cross)
                ..stroke();
        }
    }

    void drawPathNodes(CanvasRenderingContext2D ctx, double scaleFactor) {
        final Set<PathNode> drawn = <PathNode>{};

        ctx.fillStyle = "#60A0FF";
        ctx.strokeStyle = "#60A0FF";
        double size = 4;

        for (final PathNode node in connectedNodes) {
            drawn.add(node);

            ctx.save();

            if (node is SpawnNode) {
                ctx.fillStyle = "#44EE44";
                size = 8;
            } else if (node is ExitNode) {
                ctx.fillStyle = "#FF3030";
                size = 8;
            }

            ctx.fillRect(node.position.x * scaleFactor - size/2, node.position.y * scaleFactor - size/2, size, size);

            ctx.fillText(node.distanceToExitFraction.toStringAsFixed(3), node.position.x * scaleFactor + size, node.position.y * scaleFactor - 5);

            ctx.restore();

            for (final PathNode other in node.connections.keys) {
                if (other.isolated || drawn.contains(other)) { continue; }

                ctx
                    ..beginPath()
                    ..lineTo(node.position.x * scaleFactor, node.position.y * scaleFactor)
                    ..lineTo(other.position.x * scaleFactor, other.position.y * scaleFactor)
                    ..stroke();
            }
        }
    }

    void drawRoutes(CanvasRenderingContext2D ctx, double scaleFactor) {
        ctx.save();
        final Set<PathNode> routeNodes = <PathNode>{};
        routeNodes.addAll(spawners);

        for (final SpawnNode spawn in spawners) {
            PathNode node = spawn;
            while (node.targetNode != null) {
                if (routeNodes.contains(node.targetNode)) {
                    break;
                }
                routeNodes.add(node.targetNode);
                node = node.targetNode;
            }
        }

        ctx.strokeStyle = "rgba(30,50,255, 0.3)";

        for (final PathNode node in pathNodes) {
            if (node.targetNode == null) { continue; }
            ctx.save();
            if (routeNodes.contains(node)) {
                ctx.strokeStyle = "rgba(30,50,255, 1.0)";
                ctx.lineWidth = 2;
            }

            final B.Vector2 pos = node.position;
            final B.Vector2 tpos = node.targetNode.position;

            ctx
                ..beginPath()
                ..moveTo(pos.x * scaleFactor, pos.y * scaleFactor)
                ..lineTo(tpos.x * scaleFactor, tpos.y * scaleFactor)
                ..stroke();

            ctx.restore();
        }

        ctx.restore();
    }
}