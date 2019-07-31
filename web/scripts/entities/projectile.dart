import "dart:html";

import "../renderer/2d/vector.dart";
import "moverentity.dart";

class Projectile extends MoverEntity {

    Vector targetPos;

    @override
    void draw2D(CanvasRenderingContext2D ctx) {
        ctx
            ..fillStyle = "#201D00"
            ..fillRect(-3, -3, 6, 6)
            ..fillStyle = "#FFDD00"
            ..fillRect(-2, -2, 4, 4);
    }

    @override
    void logicUpdate([num dt = 0]) {
        super.logicUpdate(dt);
        if ((targetPos - this.posVector).length < 2) {
            this.dead = true;
        }
    }
}