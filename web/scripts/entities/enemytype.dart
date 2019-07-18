import "dart:html";

class EnemyType {

    double health = 100;
    double speed = 25;
    double turnRate = 1.0;
    double size = 10;

    void draw2D(CanvasRenderingContext2D ctx) {
        ctx.fillStyle="#FF0000";

        ctx
            ..beginPath()
            ..moveTo(-size, size)
            ..lineTo(0, -size)
            ..lineTo(size, size)
            ..closePath()
            ..fill();
    }
}