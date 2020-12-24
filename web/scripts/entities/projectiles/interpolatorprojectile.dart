import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "../../engine/game.dart";
import "../../utility/extensions.dart";
import "../../utility/towerutils.dart";
import "../enemy.dart";
import "../tower.dart";
import "../towertype.dart";
import "projectile.dart";

enum InterpolatorWeaponGravityMode {
    /// No gravity, just linear interpolation of position
    none,
    /// Simple ballistic trajectory where muzzle velocity changes instead of elevation.
    /// Less realistic but way cheaper to calculate... and good enough for fast weapons.
    simpleBallistic,
    /// True ballistic trajectory where muzzle velocity remains constant but elevation changes.
    /// Takes the lower of the two angles available, falls back to simpleBallistic when no valid angle exists.
    ballistic, // TODO: implement ballistic and ballisticHigh
    /// As ballistic but takes the higher of the two angles. Falls back to simpleBallistic when no valid angle exists.
    ballisticHigh,
}

class InterpolatorProjectile extends Projectile {

    InterpolatorWeaponType get type => projectileType;
    Game get game => engine;

    double travelFraction = 0;
    double travelSpeed = 1.0;

    // arc calculation stuff, since it doesn't need to be recalculated
    double _distance;
    double _totalTime;
    double _v0;

    InterpolatorProjectile(Tower parent, Enemy target, B.Vector2 targetPos, double targetHeight) : super.impl(parent, target, targetPos, targetHeight) {
        this.position.setFrom(this.parent.position);
        this.previousPos.setFrom(this.parent.position);
        this.rot_angle = (targetPos - parent.position).angle;
        this.previousRot = rot_angle;

        // xy distance from origin to target
        _distance = (targetPos - this.position).length();
        // total expected travel time
        _totalTime = _distance / parent.towerType.weapon.projectileSpeed;

        // stuff needed for ballistics, no point setting it up if we're not using gravity
        if (type.gravityMode != InterpolatorWeaponGravityMode.none) {
            // initial z velocity for simple ballistic
            _v0 = ((targetHeight - originHeight) + (0.5 * _gravity * _totalTime * _totalTime)) / _totalTime;
        }

        this.travelSpeed = 1.0 / _totalTime;
        this.maxAge = 2 * _totalTime; // 2 because we're hedging bets here, it should never be more than the total time in practice;
    }

    double get _gravity => game.level.gravity ?? game.rules.gravity;

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

        this.previousPos.setFrom(this.position);
        this.previousZPosition = this.zPosition;
        this.previousElevation = this.elevation;

        this.position.setFrom(originPos + (targetPos - originPos) * travelFraction);

        switch(type.gravityMode) {
        case InterpolatorWeaponGravityMode.simpleBallistic:
            // simple ballistic, cheap and good enough for fast projectiles
            this.zPosition = TowerUtils.simpleBallisticArc(originHeight, _v0, _gravity, travelFraction * _totalTime);
            break;
        default:
            // none, the remainder
            this.zPosition = originHeight + (targetHeight - originHeight) * travelFraction;
        }

        this.previousRot = this.rot_angle;
        this.rot_angle = (position - previousPos).angle;

        this.updateElevation();
    }
}

class InterpolatorWeaponType extends WeaponType {
    final InterpolatorWeaponGravityMode gravityMode;

    InterpolatorWeaponType(TowerType towerType, {InterpolatorWeaponGravityMode this.gravityMode = InterpolatorWeaponGravityMode.simpleBallistic}) : super(towerType);

    @override
    Projectile spawnProjectile(Tower parent, Enemy target, B.Vector2 targetPos, double targetHeight) => new InterpolatorProjectile(parent, target, targetPos, targetHeight);
}