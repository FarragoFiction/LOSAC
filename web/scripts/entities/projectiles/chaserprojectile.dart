import "dart:math" as Math;

import "package:CommonLib/Random.dart";
import "package:CommonLib/Utility.dart";
import "package:CubeLib/CubeLib.dart" as B;
import "package:yaml/yaml.dart";

import "../../utility/extensions.dart";
import "../../utility/fileutils.dart";
import "../../utility/towerutils.dart";
import "../enemy.dart";
import "../newtonianmover.dart";
import "../tower.dart";
import "../towertype.dart";
import "projectile.dart";

class ChaserProjectile extends Projectile with NewtonianMover {

    static final Random _random = new Random();

    ChaserWeaponType get type => projectileType as ChaserWeaponType;
    late double hitArea;

    @override
    double get speed => this.velocity.length().toDouble();

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

    ChaserProjectile(Tower parent, Enemy target, B.Vector2 targetPos, double targetHeight) : super.impl(parent, target, targetPos, targetHeight) {
        this.position.setFrom(this.parent.position);
        this.previousPos.setFrom(this.parent.position);
        if (parent.towerType.turreted) {
            this.rot_angle = parent.turretAngle;
        } else {
            this.rot_angle = (targetPos - parent.position).angle;
        }
        if (type.spread > 0) {
            this.rot_angle += (_random.nextDouble(type.spread) - type.spread * 0.5) * Math.pi * 2;
        }
        this.previousRot = rot_angle;
        this.hitArea = this.target!.enemyType.size;
        this.thrust(type.initialThrust);
    }

    @override
    void logicUpdate([num dt = 0]) {
        super.logicUpdate(dt);

        final Enemy? target = this.target;

        if (type.lockOn && target != null && !target.dead) {
            final B.Vector2? tPos = TowerUtils.intercept(this.position, target.position, target.velocity, this.velocity.length());
            this.targetPos = tPos == null ? this.target!.position : tPos;
        }

        final B.Vector2 toTarget = this.targetPos - this.position;
        final B.Vector2 angDir = new B.Vector2(1, 0)..applyMatrixInPlace(matrix);

        final num angDotTarget = angDir.dot(toTarget.normalized());
        final num angDiff = angleDiff(rot_angle.toDouble(), toTarget.angle); // TODO: CommonLib angleDiff

        final double turnFactor = 0.15 + 0.85 * (1 - angDotTarget.clamp(0, 1));

        double turn = -angDiff.sign * type.turnRate * turnFactor * speed;
        if (angDiff == 0) {
            turn = -angularVelocity;
        } else if (this.angularVelocity.sign == angDiff.sign) {
            final double av = angularVelocity.abs();
            final num ad = angDiff.abs();
            if (av > ad) {
                this.torque(-angDiff.sign * (av-ad));
            }
        }

        this.torque(dt * turn);

        final num dx = targetPos.x - position.x;
        final num dy = targetPos.y - position.y;
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

    //ChaserWeaponType(TowerType towerType) : super(towerType);

    @override
    Projectile spawnProjectile(Tower parent, Enemy target, B.Vector2 targetPos, double targetHeight) => new ChaserProjectile(parent, target, targetPos, targetHeight);

    @override
    void loadData(DataSetter set) {
        super.loadData(set);

        set("lockOn", (bool b) => this.lockOn = b);

        set("turnRate", (num n) => this.turnRate = n.toDouble().max(0));
        set("thrustPower", (num n) => this.thrustPower = n.toDouble().max(0));
        set("initialThrust", (num n) => this.initialThrust.toDouble());

        set("friction", (num n) => this.friction = n.toDouble().clamp(0, 1));
        set("lateralFriction", (num n) => this.lateralFriction = n.toDouble().clamp(0, 1));
        set("angularFriction", (num n) => this.angularFriction = n.toDouble().clamp(0, 1));

        set("spread", (num n) => this.spread = n.toDouble().clamp(0, 1));

        set("velocityAngleTransfer", (num n) => this.velocityAngleTransfer = n.toDouble().clamp(0, 1));
        set("velocityAngleTransferLateral", (num n) => this.velocityAngleTransferLateral = n.toDouble());
    }
}