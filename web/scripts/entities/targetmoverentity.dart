import "dart:math" as Math;

import "package:CommonLib/Utility.dart";
import "package:CubeLib/CubeLib.dart" as B;

import "../utility/extensions.dart";
import "moverentity.dart";

class TargetMoverEntity extends MoverEntity {

    B.Vector2 targetPos;
    double stoppingThreshold = 5.0;
    double turnRate = 1.0;
    double turnThreshold = Math.pi *0.51;
    bool turningAround = false;

    double debugTargetAngle = 0;

    @override
    void logicUpdate([num dt = 0]) {
        this.moveTowardsTarget(dt);
        this.updateVelocityFromHeading(dt);
        super.logicUpdate(dt);
    }

    void moveTowardsTarget(num dt) {
        if (this.targetPos == null || dt == 0) {
            this.speed = 0;
            return;
        }

        if (closeToPos(targetPos.x, targetPos.y, stoppingThreshold)) {
            this.targetPos = null;
            return;
        }

        final B.Vector2 targetOffset = targetPos - this.position;
        final double targetAngle = targetOffset.angle;

        debugTargetAngle = targetAngle;

        final double angDiff = angleDiff(this.rot_angle, targetAngle);

        double turn = turnRate * dt;

        if (this.turningAround) {
            turn *= 2.5;
        }

        final double turnAmount = Math.min(angDiff.abs(), turn);

        this.previousRot = this.rot_angle;
        this.rot_angle += -turnAmount * angDiff.sign;

        if (angDiff.abs() < turnThreshold) {
            //final double targetDist = targetOffset.length;
            //final double newSpeed = Math.min(targetDist, this.baseSpeed);
            //this.speed = newSpeed;
            this.speed = this.baseSpeed;

            if (angDiff.abs() < turnThreshold * 0.25) {
                this.turningAround = false;
            }
        } else {
            this.speed = 0;
            this.turningAround = true;
        }
    }

    void updateVelocityFromHeading(num dt) {
        this.velocity..set(1,0)..applyMatrixInPlace(this.matrix)..scaleInPlace(this.speed);
    }

    bool closeToPos(double x, double y, double distance) {
        final double dx = x - this.position.x;
        final double dy = y - this.position.y;
        return dx*dx + dy*dy <= distance*distance;
    }

    /*@override
    void drawUIToCanvas(CanvasRenderingContext2D ctx, double scaleFactor) {
        ctx.strokeStyle = "#00FF00";

        final Vector o = new Vector(0,-1).rotate(debugTargetAngle);

        ctx
            ..beginPath()
            ..moveTo(this.pos_x * scaleFactor, this.pos_y * scaleFactor)
            ..lineTo((this.pos_x + o.x * 30) * scaleFactor, (this.pos_y + o.y * 30) * scaleFactor)
            ..stroke();


        if(this.targetPos != null) {
            ctx.strokeStyle = "#FF8000";
            ctx
                ..beginPath()
                ..moveTo(this.pos_x * scaleFactor, this.pos_y * scaleFactor)
                ..lineTo(targetPos.x * scaleFactor, targetPos.y * scaleFactor)
                ..stroke();
        }
    }*/
}