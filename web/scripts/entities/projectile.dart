import "dart:html";
import "dart:math" as Math;

import "../renderer/2d/vector.dart";
import "enemy.dart";
import "moverentity.dart";
import "tower.dart";

class Projectile extends MoverEntity {

    Tower parent;
    Enemy target;

    Vector targetPos;

    double travelFraction = 0;
    double travelSpeed = 1.0;

    Projectile(Tower this.parent, Enemy this.target, Vector this.targetPos) {
        this.posVector = this.parent.posVector;
        this.previousPos = this.parent.posVector;
        this.rot_angle = (targetPos - parent.posVector).angle;
        this.previousRot = rot_angle;
    }

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
        if (travelFraction >= 1) {
            this.dead = true;
            impact();
        }
    }

    @override
    void applyVelocity(num dt) {
        travelFraction += travelSpeed * dt;

        this.previousPos = this.posVector;

        this.posVector = parent.posVector + (targetPos - parent.posVector) * travelFraction;

        this.previousRot = this.rot_angle;
        this.rot_angle = (posVector - previousPos).angle;
    }

    void impact() {
        target.health -= parent.towerType.weaponDamage;
    }
}