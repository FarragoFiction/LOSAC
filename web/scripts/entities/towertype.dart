import "dart:html";
import "dart:math" as Math;

class TowerType {

    int maxTargets = 1;
    double weaponCooldown = 1.0;

    double range = 200;

    void draw2D(CanvasRenderingContext2D ctx) {
        ctx.fillStyle="#A0A0A0";

        const int radius = 22;

        ctx
            ..beginPath()
            ..arc(0,0,radius, 0, Math.pi*2)
            ..closePath()
            ..fill();
    }
}