import "dart:math" as Math;

import "../renderer/2d/vector.dart";
import "moverentity.dart";

mixin NewtonianMover on MoverEntity {

    double _friction = 0.5;
    double angularVelocity = 0;
    double _angularFriction = 0.2;

    double get friction => _friction;
    set friction(double val) {
        _friction = val;
        _newtLastDt = null;
    }

    double get angularFriction => _angularFriction;
    set angularFriction(double val) {
        _angularFriction = val;
        _newtLastDt = null;
    }

    num _newtLastDt;
    double _newtFrictionStep;
    double _newtAngularFrictionStep;

    @override
    void applyVelocity(num dt) {
        this._updateFrictionValues(dt);

        this.rot_angle += this.angularVelocity * dt;
        this.angularVelocity *= this._newtAngularFrictionStep;

        super.applyVelocity(dt);
        this.velocity *= this._newtFrictionStep;
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
        _newtAngularFrictionStep = Math.pow(angularFriction, dt);
    }
}