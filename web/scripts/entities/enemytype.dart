import "dart:html";

class EnemyType {
    /// Localisation string identifier
    /// Will resolve patterns such as "enemy.(this value).name"
    String name = "default";

    double health = 100;
    double speed = 25;
    double turnRate = 1.0;
    double size = 10;

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