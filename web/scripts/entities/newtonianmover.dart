import "dart:math" as Math;

import "../renderer/2d/vector.dart";
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

        final Vector velDir = this.velocity.norm();
        final Vector angDir = new Vector(1,0).applyMatrix(matrix);

        //print("velDir: $velDir, angDir: $angDir");
        final double angDotVel = angDir.dot(velDir);
        final double absdot = angDotVel.abs();

        //super.applyVelocity(dt);
        this.previousPos = this.posVector;
        this.posVector += this.velocity * (this._newtFrictionMult * absdot + this._newtLateralFrictionMult * (1-absdot));

        //print("v: dot: $angDotVel");
        //print(velocity);
        this.velocity *= this._newtFrictionStep * absdot + this._newtLateralFrictionStep * (1-absdot);
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

            final double magV = this.velocity.length;
            this.velocity *= (1-fraction);
            this.velocity += angDir * magV * fraction;
        }
    }

    void accelerate(double x, double y) {
        this.velocity = new Vector(velocity.x+x, velocity.y+y);
    }

    void thrust(double force) {
        this.velocity += new Vector(force,0).applyMatrix(this.matrix);
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