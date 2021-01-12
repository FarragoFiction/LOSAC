import "dart:html";

import "../engine/entity.dart";

class EnemyType {
    /// Localisation string identifier
    /// Will resolve patterns such as "enemy.(this value).name"
    String name = "default";

    SlopeMode slopeMode = SlopeMode.conform;

    double health = 100;
    double speed = 250;//25;
    double turnRate = 10;//1.0;
    double size = 10;

    double leakDamage = 1000;//5.0;

    void draw2D(CanvasRenderingContext2D ctx) {
        ctx.fillStyle="#FF0000";

        ctx
            ..beginPath()
            ..moveTo(-size, -size)
            ..lineTo(size, 0)
            ..lineTo(-size, size)
            ..closePath()
            ..fill();
    }
}