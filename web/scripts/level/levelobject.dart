import "dart:html";

import "../renderer/2d/renderable2d.dart";


class LevelObject implements Renderable2D {

    Set<LevelObject> subObjects = <LevelObject>{};

    double pos_x = 0;
    double pos_y = 0;
    double rot_angle = 0;
    double scale = 1;

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

        ctx.fillRect(-5, -5, 10, 10);
    }
}