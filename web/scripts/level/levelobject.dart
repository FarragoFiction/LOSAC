import "dart:html";

import "../renderer/2d/renderable2d.dart";
import "../renderer/2d/vector.dart";

class SimpleLevelObject implements Renderable2D {
    double pos_x = 0;
    double pos_y = 0;

    Vector get posVector => new Vector(pos_x, pos_y);

    @override
    void drawToCanvas(CanvasRenderingContext2D ctx) {
        ctx.save();

        ctx.translate(pos_x, pos_y);

        ctx.fillStyle = "#FF0000";
        ctx.fillRect(-3, -3, 7, 7);

        ctx.restore();
    }
}

class LevelObject extends SimpleLevelObject {

    Set<LevelObject> subObjects = <LevelObject>{};

    double rot_angle = 0;
    double scale = 1;

    LevelObject() : rot_angle = 0 {
        initMixins();
    }

    void initMixins(){}

    @override
    void drawToCanvas(CanvasRenderingContext2D ctx) {
        ctx.save();

        ctx.translate(pos_x, pos_y);
        ctx.rotate(rot_angle);
        ctx.scale(scale, scale);

        this.draw2D(ctx);

        for (final LevelObject subObject in subObjects) {
            subObject.drawToCanvas(ctx);
        }

        ctx.restore();
    }

    void draw2D(CanvasRenderingContext2D ctx) {
        ctx.fillStyle = "#FF0000";

        ctx.fillRect(-5, -5, 11, 11);
    }
}