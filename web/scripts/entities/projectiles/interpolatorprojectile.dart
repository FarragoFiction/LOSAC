import "package:CubeLib/CubeLib.dart" as B;

import "../../utility/extensions.dart";
import "../enemy.dart";
import "../tower.dart";
import "../towertype.dart";
import "projectile.dart";

class InterpolatorProjectile extends Projectile {

    InterpolatorWeaponType get type => projectileType;

    double travelFraction = 0;
    double travelSpeed = 1.0;

    InterpolatorProjectile(Tower parent, Enemy target, B.Vector2 targetPos) : super.impl(parent, target, targetPos) {
        this.position.setFrom(this.parent.position);
        this.previousPos.setFrom(this.parent.position);
        this.rot_angle = (targetPos - parent.position).angle;
        this.previousRot = rot_angle;

        this.travelSpeed = parent.towerType.weapon.projectileSpeed / (targetPos - this.position).length();
        this.maxAge = 2 / travelSpeed; // 2 because we're hedging bets here, it should never be more than 1/travelSpeed in practice;
    }

    @override
    void logicUpdate([num dt = 0]) {
        super.logicUpdate(dt);
        if (travelFraction >= 1) {
            this.kill();
            impact();
        }
    }

    @override
    void applyVelocity(num dt) {
        travelFraction += travelSpeed * dt;

        this.previousPos = this.position;

        this.position.setFrom(parent.position + (targetPos - parent.position) * travelFraction);

        this.previousRot = this.rot_angle;
        this.rot_angle = (position - previousPos).angle;
    }
}

class InterpolatorWeaponType extends WeaponType {

    InterpolatorWeaponType(TowerType towerType) : super(towerType);

    @override
    Projectile spawnProjectile(Tower parent, Enemy target, B.Vector2 targetPos) => new InterpolatorProjectile(parent, target, targetPos);
}