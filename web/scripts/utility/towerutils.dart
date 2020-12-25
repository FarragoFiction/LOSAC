import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "../entities/enemy.dart";
import "../entities/tower.dart";
import "../level/pathnode.dart";
import "extensions.dart";

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
        final Math.Point<double> ts = quadratic(a, b, c);

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

    static Math.Point<double> quadratic(double a, double b, double c) {
        const double epsilon = 1e-6;
        if (a.abs() < epsilon) {
            if (b.abs() < epsilon) {
                return c.abs() < epsilon ? const Math.Point<double>(0,0) : null;
            } else {
                return new Math.Point<double>(-c/b, -c/b);
            }
        } else {
            double disc = b*b - 4*a*c;
            if (disc >= 0) {
                disc = Math.sqrt(disc);
                a *= 2;
                return new Math.Point<double>((-b-disc)/a, (-b+disc)/a);
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
        final Math.Point<double> ts = quadratic(a, b, c);

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