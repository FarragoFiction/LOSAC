import "dart:html";

import "../renderer/2d/renderable2d.dart";
import "levelobject.dart";

class Level implements Renderable2D {

    Set<LevelObject> objects = <LevelObject>{};

    @override
    void drawToCanvas(CanvasRenderingContext2D ctx) {
        for (final LevelObject o in objects) {
            o.drawToCanvas(ctx);
        }
    }
}