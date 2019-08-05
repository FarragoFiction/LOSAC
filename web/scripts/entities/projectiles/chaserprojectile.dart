
import "../../renderer/2d/vector.dart";
import "../enemy.dart";
import "../newtonianmover.dart";
import "../tower.dart";
import "projectile.dart";

class ChaserProjectile extends Projectile with NewtonianMover {

    ChaserProjectile(Tower parent, Enemy target, Vector targetPos) : super(parent, target, targetPos) {
        this.posVector = this.parent.posVector;
        this.previousPos = this.parent.posVector;
        if (parent.towerType.turreted) {
            this.rot_angle = parent.turretAngle;
        } else {
            this.rot_angle = (targetPos - parent.posVector).angle;
        }
        this.previousRot = rot_angle;
    }

    @override
    void logicUpdate([num dt = 0]) {
        super.logicUpdate(dt);


    }
}