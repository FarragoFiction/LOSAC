import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "../utility/extensions.dart";
import "moverentity.dart";

mixin NewtonianMover on MoverEntity {

    double _friction = 0.95;
    double _lateralFriction = 0.15;
    double angularVelocity = 0;
    double _angularFriction = 0.5;

    /// Portion of velocity which is re-angled towards facing direction each step.
    double velocityAngleTransfer = 0.5;
    /// Multiplier for [velocityAngleTransfer] when (velocity dot facing) is 0, interpolates smoothly.
    double velocityAngleTransferLateral = 1.0;

    double get friction => _friction;
    set friction(double val) {
        _friction = val;
        _newtLastDt = null;
    }

    double get lateralFriction => _lateralFriction;
    set lateralFriction(double val) {
        _lateralFriction = val;
        _newtLastDt = null;
    }

    double get angularFriction => _angularFriction;
    set angularFriction(double val) {
        _angularFriction = val;
        _newtLastDt = null;
    }

    num _newtLastDt;
    double _newtFrictionStep;
    double _newtFrictionMult;
    double _newtLateralFrictionStep;
    double _newtLateralFrictionMult;
    double _newtAngularFrictionStep;
    double _newtAngularFrictionMult;

    @override
    void applyVelocity(num dt) {
        this._updateFrictionValues(dt);

        this.previousRot = this.rot_angle;
        this.rot_angle += this.angularVelocity * _newtAngularFrictionMult;
        this.angularVelocity *= this._newtAngularFrictionStep;

        final B.Vector2 velDir = this.velocity.normalized();
        final B.Vector2 angDir = new B.Vector2(1,0)..applyMatrixInPlace(matrix);

        //print("velDir: $velDir, angDir: $angDir");
        final double angDotVel = angDir.dot(velDir);
        final double absdot = angDotVel.abs();

        //super.applyVelocity(dt);
        this.previousPos.setFrom(this.position);
        this.position.addInPlace(this.velocity.scale(this._newtFrictionMult * absdot + this._newtLateralFrictionMult * (1-absdot)));

        //print("v: dot: $angDotVel");
        //print(velocity);
        this.velocity.scaleInPlace(this._newtFrictionStep * absdot + this._newtLateralFrictionStep * (1-absdot));
        //print(velocity);

        if (velocityAngleTransfer > 0) {
            double fraction;
            if (velocityAngleTransferLateral == 0) {
                fraction = velocityAngleTransfer * absdot;
            } else if (velocityAngleTransferLateral == 1) {
                fraction = velocityAngleTransfer;
            } else {
                fraction = velocityAngleTransfer * absdot + velocityAngleTransfer * velocityAngleTransferLateral * (1-absdot);
            }

            final double magV = this.velocity.length();
            this.velocity.scaleInPlace(1-fraction);
            this.velocity.addInPlace(angDir * magV * fraction);
        }
    }

    void accelerate(double x, double y) {
        this.velocity.set(this.velocity.x + x, this.velocity.y + y);
    }

    void thrust(double force) {
        this.velocity.addInPlace(new B.Vector2(force,0)..applyMatrixInPlace(this.matrix));
    }

    void torque(double force) => this.angularVelocity += force;

    void _updateFrictionValues(num dt) {
        if (_newtLastDt == dt) { return; }
        _newtLastDt = dt;

        _newtFrictionStep = Math.pow(friction, dt);
        _newtFrictionMult = (Math.pow(friction, dt*dt)-1) / (dt * Math.log(friction));
        _newtLateralFrictionStep = Math.pow(lateralFriction, dt);
        _newtLateralFrictionMult = (Math.pow(lateralFriction, dt*dt)-1) / (dt * Math.log(lateralFriction));
        _newtAngularFrictionStep = Math.pow(angularFriction, dt);
        _newtAngularFrictionMult = (Math.pow(angularFriction, dt*dt)-1) / (dt * Math.log(angularFriction));
    }
}