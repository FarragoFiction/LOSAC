import "dart:html";

import "../renderer/2d/renderable2d.dart";
import "../renderer/2d/vector.dart";
import "level.dart";
import "levelobject.dart";
import "pathnode.dart";

class Level2D extends Level with Renderable2D {

    @override
    void drawToCanvas(CanvasRenderingContext2D ctx) {
        for (final LevelObject o in objects) {
            o.drawToCanvas(ctx);
        }

        ctx.save();
        ctx.globalAlpha = 0.3;
        if (domainMap != null && domainMap.debugCanvas != null) {
            ctx.drawImage(domainMap.debugCanvas, domainMap.pos_x, domainMap.pos_y);
        }
        ctx.restore();
    }

    @override
    void drawUIToCanvas(CanvasRenderingContext2D ctx, double scaleFactor) {
        for (final LevelObject o in objects) {
            o.drawUIToCanvas(ctx, scaleFactor);
        }

        //drawPathNodes(ctx, scaleFactor);

        //drawBoundingBoxes(ctx, scaleFactor);

        drawRoutes(ctx, scaleFactor);
    }

    void drawBoundingBoxes(CanvasRenderingContext2D ctx, double scaleFactor) {
        const double cross = 10;
        ctx.strokeStyle = "rgba(255,200,20)";
        for (final LevelObject o in objects) {
            final Rectangle<num> bounds = o.bounds;
            ctx.strokeRect(bounds.left * scaleFactor, bounds.top * scaleFactor, bounds.width * scaleFactor, bounds.height * scaleFactor);

            final Vector v = o.getWorldPosition() * scaleFactor;

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

            ctx.fillRect(node.pos_x * scaleFactor - size/2, node.pos_y * scaleFactor - size/2, size, size);

            ctx.restore();

            for (final PathNode other in node.connections.keys) {
                if (other.isolated || drawn.contains(other)) { continue; }

                ctx
                    ..beginPath()
                    ..lineTo(node.pos_x * scaleFactor, node.pos_y * scaleFactor)
                    ..lineTo(other.pos_x * scaleFactor, other.pos_y * scaleFactor)
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

            final Vector pos = node.posVector;
            final Vector tpos = node.targetNode.posVector;

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