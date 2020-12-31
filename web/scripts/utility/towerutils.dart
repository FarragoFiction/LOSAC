import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "../entities/enemy.dart";
import "../entities/tower.dart";
import "../level/pathnode.dart";
import "extensions.dart";
import "mathutils.dart";

abstract class TowerUtils {

    static B.Vector2 intercept(B.Vector2 firePos, B.Vector2 targetPos, B.Vector2 targetVel, double projSpeed) {
        if (projSpeed <= 0) { return null; }

        final double tx = targetPos.x - firePos.x;
        final double ty = targetPos.y - firePos.y;
        final double tvx = targetVel.x;
        final double tvy = targetVel.y;

        // work out quadratic terms
        final double a = tvx*tvx + tvy*tvy - projSpeed*projSpeed;
        final double b = 2 * (tvx * tx + tvy * ty);
        final double c = tx*tx + ty*ty;

        // solve quadratic equation for those terms
        final Math.Point<double> ts = MathUtils.quadraticBasic(a, b, c);

        // find smallest positive solution
        if (ts != null) {
            final double t0 = ts.x;
            final double t1 = ts.y;
            double t = Math.min(t0, t1);
            if (t < 0) {
                t = Math.max(t0, t1);
            }
            if (t > 0) {
                return targetPos + targetVel * t;
            }
        }

        return null;
    }

    static double interceptTime(B.Vector2 firePos, B.Vector2 targetPos, B.Vector2 targetVel, double projSpeed) {
        final double tx = targetPos.x - firePos.x;
        final double ty = targetPos.y - firePos.y;
        final double tvx = targetVel.x;
        final double tvy = targetVel.y;

        // work out quadratic terms
        final double a = tvx*tvx + tvy*tvy - projSpeed*projSpeed;
        final double b = 2 * (tvx * tx + tvy * ty);
        final double c = tx*tx + ty*ty;

        // solve quadratic equation for those terms
        final Math.Point<double> ts = MathUtils.quadraticBasic(a, b, c);

        // find smallest positive solution
        if (ts != null) {
            final double t0 = ts.x;
            final double t1 = ts.y;
            double t = Math.min(t0, t1);
            if (t < 0) {
                t = Math.max(t0, t1);
            }
            if (t > 0) {
                return t;
            }
        }

        // no solution
        return -1;
    }

    static double ballisticInterceptTime(B.Vector2 firePos, double fireHeight, B.Vector2 targetPos, double targetHeight, B.Vector2 targetVel, double projSpeed, double gravity) {
        if (gravity == 0) {
            // special case for no gravity, since the quartic would shit itself with a divide by zero
            return interceptTime(firePos, targetPos, targetVel, projSpeed);
        }

        final double tx = targetPos.x - firePos.x;
        final double ty = targetPos.y - firePos.y;
        final double tz = targetHeight - fireHeight;
        final double tvx = targetVel.x;
        final double tvy = targetVel.y;
        const double tvz = 0; // ehhhhhh

        final double g = -0.5 * gravity;

        // work out quartic terms
        final double a = g*g;
        final double b = 2*tvz*g; // this comes out as 0 when tvz is 0... whatever, the compiler will get it
        final double c = tvz*tvz + 2*tz*g - projSpeed*projSpeed + tvx*tvx + tvy*tvy;
        final double d = 2*tz*tvz + 2*tx*tvx + 2*ty*tvy;
        final double e = tvz*tvz + tx*tx + ty*ty;


        // no solution
        return -1;
    }

    static B.Vector2 interceptEnemy(Tower tower, Enemy enemy) {
        if (enemy.speed <= 0) { return enemy.position; }

        final B.Vector2 tPos = tower.position;

        B.Vector2 pos = enemy.position;
        PathNode nextNode = enemy.targetNode;
        B.Vector2 targetOffset = nextNode.position - pos;
        num targetDistance = targetOffset.length();
        B.Vector2 dir = targetOffset / targetDistance;
        double timeOffset = 0;

        int iter = 0;
        while(iter < 1000) {
            double time = interceptTime(tPos, pos - dir * enemy.speed * timeOffset, dir * enemy.speed, tower.towerType.weapon.projectileSpeed);
            if (time == -1) { return null; }
            time -= timeOffset;

            final double timeToNode = targetDistance / enemy.speed;

            if (time < timeToNode) {
                return pos + (dir * enemy.speed * time);
            }

            timeOffset += timeToNode;
            pos = nextNode.position;
            nextNode = nextNode.targetNode;
            targetOffset = nextNode.position - pos;
            targetDistance = targetOffset.length();
            dir = targetOffset / targetDistance;

            iter++;
        }
        print("ran out of iterations");
        return pos;
    }

    static double simpleBallisticArc(double z0, double v0, double g, double t) {
        return z0 + v0 * t - 0.5 * g * t * t;
    }

    static B.Vector2 ballisticArc(double distance, double height, double muzzleVel, double gravity, bool highArc) {
        final double v = muzzleVel;
        final double y = height;
        final double x = distance;
        final double g = gravity;

        final double term1 = v*v*v*v - (g * ( (g * x * x) + (2 * y * v * v) ));

        if (term1 >= 0) {
            final double term2 = Math.sqrt(term1);
            final double divisor = g * x;

            if (divisor != 0.0) {
                double root;
                if (highArc) {
                    root = (v * v + term2) / divisor;
                } else {
                    root = (v * v - term2) / divisor;
                }

                root = Math.atan(root);

                return new B.Vector2(muzzleVel, 0)..rotateInPlace(root);
            }
        }

        return null;
    }
}