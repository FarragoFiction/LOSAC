import "dart:html";

import "../renderer/2d/bounds.dart";
import "../renderer/2d/renderable2d.dart";
import "../renderer/2d/vector.dart";
import "../utility/levelutils.dart";
import "connectible.dart";
import "domainmap.dart";
import "levelobject.dart";
import "pathnode.dart";

class Level with Renderable2D {

    Set<LevelObject> objects = <LevelObject>{};
    Iterable<Connectible> connectibles;

    final List<PathNode> pathNodes = <PathNode>[];
    final List<SpawnNode> spawners = <SpawnNode>[];
    ExitNode exit;

    DomainMap domainMap;
    Rectangle<num> bounds;

    Level() {
        connectibles = objects.whereType();
    }

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

    void derivePathNodes() {
        this.pathNodes.clear();

        this.spawners.clear();
        this.exit = null;

        // starts at 1 because 0 is "no node"
        int id = 1;

        for (final Connectible object in connectibles) {
            object.clearPathNodes();
        }

        for (final Connectible object in connectibles) {
            final Iterable<PathNode> nodes = object.generatePathNodes();

            for(final PathNode node in nodes) {
                node.id = id;
                id++;
                if (id >= 65536) {
                    throw Exception("WHAT ARE YOU DOING?! THIS IS FAR TOO MANY NODES!");
                }
                pathNodes.add(node);

                if (node is SpawnNode) {
                    this.spawners.add(node);
                } else if (node is ExitNode) {
                    if (this.exit != null) {
                        throw Exception("ONLY ONE EXIT, DUNKASS");
                    }
                    this.exit = node;
                }
            }
        }

        for (final Connectible object in connectibles) {
            object.connectPathNodes();
        }
    }

    void prunePathNodes(Iterable<PathNode> toPrune) {
        LevelUtils.prunePathNodeList(this.pathNodes, toPrune.toList());
    }

    void buildDomainMap() {
        this.bounds = outerBounds(objects.map((LevelObject o) => o.bounds));

        domainMap = new DomainMap(bounds.left, bounds.top, bounds.width, bounds.height);

        for (final Connectible object in connectibles) {
            final Rectangle<num> bounds = object.bounds;

            final DomainMapRegion boundsRegion = domainMap.subRegionForBounds(bounds);

            object.fillDomainMap(boundsRegion);
        }
    }
}