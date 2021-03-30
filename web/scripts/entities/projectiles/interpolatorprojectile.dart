import "dart:html";
import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "../../engine/game.dart";
import "../../renderer/3d/floateroverlay.dart";
import "../../utility/extensions.dart";
import "../../utility/styleconversion.dart";
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
    ballistic,
    /// As ballistic but takes the higher of the two angles. Falls back to simpleBallistic when no valid angle exists.
    ballisticHigh,
}

class InterpolatorProjectile extends Projectile {

    InterpolatorWeaponType get type => projectileType as InterpolatorWeaponType;
    Game get game => engine as Game;

    double travelFraction = 0;
    double travelSpeed = 1.0;

    // arc calculation stuff, since it doesn't need to be recalculated
    late double _distance;
    double? _totalTime;
    late double _v0;

    InterpolatorProjectile(Tower parent, Enemy target, B.Vector2 targetPos, double targetHeight) : super.impl(parent, target, targetPos, targetHeight) {
        this.position.setFrom(this.parent.position);
        this.previousPos.setFrom(this.parent.position);
        this.rot_angle = (targetPos - parent.position).angle;
        this.previousRot = rot_angle;

        // xy distance from origin to target
        _distance = (targetPos - this.position).length().toDouble();


        // stuff needed for ballistics, no point setting it up if we're not using gravity
        if (type.gravityMode == InterpolatorWeaponGravityMode.ballistic || type.gravityMode == InterpolatorWeaponGravityMode.ballisticHigh) {
            final B.Vector2? trajectory = TowerUtils.ballisticArc(_distance, targetHeight - originHeight, type.projectileSpeed, _gravity, type.gravityMode == InterpolatorWeaponGravityMode.ballisticHigh);

            if (trajectory != null) {
                // total expected travel time
                _totalTime = _distance / trajectory.x;
                _v0 = trajectory.y.toDouble();
            }
        }

        if (type.gravityMode == InterpolatorWeaponGravityMode.simpleBallistic || _totalTime == null) {
            // total expected travel time
            _totalTime = _distance / parent.towerType.weapon!.projectileSpeed;
            // initial z velocity for simple ballistic
            _v0 = ((targetHeight - originHeight) + (0.5 * _gravity * _totalTime! * _totalTime!)) / _totalTime!;
        }

        this.travelSpeed = 1.0 / _totalTime!;
        this.maxAge = 2 * _totalTime!; // 2 because we're hedging bets here, it should never be more than the total time in practice;
    }

    double get _gravity => game.level!.gravity ?? game.rules.gravity;

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
        case InterpolatorWeaponGravityMode.ballistic:
        case InterpolatorWeaponGravityMode.ballisticHigh:
            // simple ballistic, cheap and good enough for fast projectiles
            this.zPosition = TowerUtils.simpleBallisticArc(originHeight, _v0, _gravity, travelFraction * _totalTime!);
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

class InterpolatorTextProjectile extends InterpolatorProjectile with HasFloater {

    CanvasStyle? _styleDef;
    CanvasStyle get styleDef {
        _styleDef ??= renderer.floaterOverlay.getCanvasStyle(type.cssClass);
        return _styleDef!;
    }

    InterpolatorTextProjectile(Tower parent, Enemy target, B.Vector2 targetPos, double targetHeight) : super(parent, target, targetPos, targetHeight);

    @override
    void generateMesh() { /* no-op on purpose */ }

    @override
    bool shouldDrawFloater() => age > 0;

    @override
    bool drawFloater(B.Vector3 pos, CanvasRenderingContext2D ctx) {
        styleDef.applyTextStyle(ctx);

        ctx.fillText(type.textProjectile, pos.x, pos.y);

        return true;
    }
}

class InterpolatorWeaponType extends WeaponType {
    InterpolatorWeaponGravityMode gravityMode = InterpolatorWeaponGravityMode.simpleBallistic;

    // these bits are for the text projectiles... which aren't really intended for use but have fun if you work out how lol
    bool useTextProjectiles = false;
    String textProjectile = "🐎"; // HORNSE
    String cssClass = "floater";

    @override
    bool get useBallisticIntercept => (gravityMode == InterpolatorWeaponGravityMode.ballistic) || (gravityMode == InterpolatorWeaponGravityMode.ballisticHigh);
    @override
    bool get useBallisticHighArc => gravityMode == InterpolatorWeaponGravityMode.ballisticHigh;

    InterpolatorWeaponType(TowerType towerType) : super(towerType);

    @override
    Projectile spawnProjectile(Tower parent, Enemy target, B.Vector2 targetPos, double targetHeight) => useTextProjectiles ? new InterpolatorTextProjectile(parent, target, targetPos, targetHeight) : new InterpolatorProjectile(parent, target, targetPos, targetHeight);
}