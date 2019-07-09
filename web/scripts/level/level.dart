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
    }

    void derivePathNodes() {
        this.pathNodes.clear();

        final Iterable<Connectable> connectables = objects.whereType();

        for (final Connectable object in connectables) {
            pathNodes.addAll(object.getPathNodes());
        }

        for (final Connectable object in connectables) {
            object.connectPathNodes();
        }
    }
}