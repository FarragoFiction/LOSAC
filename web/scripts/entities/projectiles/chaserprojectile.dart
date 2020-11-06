import "dart:math" as Math;

import "package:CommonLib/Random.dart";
import "package:CommonLib/Utility.dart";
import "package:CubeLib/CubeLib.dart" as B;

import "../../utility/extensions.dart";
import "../../utility/towerutils.dart";
import "../enemy.dart";
import "../newtonianmover.dart";
import "../tower.dart";
import "../towertype.dart";
import "projectile.dart";

class ChaserProjectile extends Projectile with NewtonianMover {

    static final Random _random = new Random();

    ChaserWeaponType get type => projectileType;
    double hitArea;

    @override
    double get speed => this.velocity.length();

    // NewtonianMover getter overrides
    @override
    double get friction => type.friction;
    @override
    double get lateralFriction => type.lateralFriction;
    @override
    double get angularFriction => type.angularFriction;
    @override
    double get velocityAngleTransfer => type.velocityAngleTransfer;
    @override
    double get velocityAngleTransferLateral => type.velocityAngleTransferLateral;

    ChaserProjectile(Tower parent, Enemy target, B.Vector2 targetPos) : super.impl(parent, target, targetPos) {
        this.posVector.setFrom(this.parent.posVector);
        this.previousPos.setFrom(this.parent.posVector);
        if (parent.towerType.turreted) {
            this.rot_angle = parent.turretAngle;
        } else {
            this.rot_angle = (targetPos - parent.posVector).angle;
        }
        if (type.spread > 0) {
            this.rot_angle += (_random.nextDouble(type.spread) - type.spread * 0.5) * Math.pi * 2;
        }
        this.previousRot = rot_angle;
        this.hitArea = this.target.enemyType.size;
        this.thrust(type.initialThrust);
    }

    @override
    void logicUpdate([num dt = 0]) {
        super.logicUpdate(dt);

        if (type.lockOn && this.target != null && !target.dead) {
            final B.Vector2 tPos = TowerUtils.intercept(this.posVector, this.target.posVector, this.target.velocity, this.velocity.length());
            this.targetPos = tPos == null ? this.target.posVector : tPos;
        }

        final B.Vector2 toTarget = this.targetPos - this.posVector;
        final B.Vector2 angDir = new B.Vector2(1, 0)..applyMatrixInPlace(matrix);

        final double angDotTarget = angDir.dot(toTarget.normalized());
        final double angDiff = angleDiff(rot_angle, toTarget.angle);

        final double turnFactor = 0.15 + 0.85 * (1 - angDotTarget.clamp(0, 1));

        double turn = -angDiff.sign * type.turnRate * turnFactor * speed;
        if (angDiff == 0) {
            turn = -angularVelocity;
        } else if (this.angularVelocity.sign == angDiff.sign) {
            final double av = angularVelocity.abs();
            final double ad = angDiff.abs();
            if (av > ad) {
                this.torque(-angDiff.sign * (av-ad));
            }
        }

        this.torque(dt * turn);

        final double dx = targetPos.x - posVector.x;
        final double dy = targetPos.y - posVector.y;
        if (dx*dx + dy*dy <= hitArea*hitArea) {
            this.kill();
            this.impact();
        }

        this.thrust(type.thrustPower * dt);
    }
}

class ChaserWeaponType extends WeaponType {

    bool lockOn = true;

    double turnRate = 0.15;
    double thrustPower = 100;
    double initialThrust = 150;

    double friction = 0.95;
    double lateralFriction = 0.15;
    double angularFriction = 0.99;

    /// Random angle variance, 0 = none, 1 = full circle
    double spread = 1.0;

    /// Portion of velocity which is re-angled towards facing direction each step.
    double velocityAngleTransfer = 0.75;
    /// Multiplier for [velocityAngleTransfer] when (velocity dot facing) is 0, interpolates smoothly.
    double velocityAngleTransferLateral = 1.0;

    ChaserWeaponType(TowerType towerType) : super(towerType);

    @override
    Projectile spawnProjectile(Tower parent, Enemy target, B.Vector2 targetPos) => new ChaserProjectile(parent, target, targetPos);
}