import "../../renderer/2d/vector.dart";
import "../enemy.dart";
import "../tower.dart";
import "projectile.dart";

class InterpolatorProjectile extends Projectile {

    double travelFraction = 0;
    double travelSpeed = 1.0;

    InterpolatorProjectile(Tower parent, Enemy target, Vector targetPos) : super(parent, target, targetPos) {
        this.posVector = this.parent.posVector;
        this.previousPos = this.parent.posVector;
        this.rot_angle = (targetPos - parent.posVector).angle;
        this.previousRot = rot_angle;

        this.travelSpeed = parent.towerType.projectileSpeed / (targetPos - this.posVector).length;
        this.maxAge = 2 / travelSpeed; // 2 because we're hedging bets here, it should never be more than 1/travelSpeed in practice;
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
}