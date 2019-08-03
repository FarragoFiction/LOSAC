import "dart:math" as Math;

import "../entities/enemy.dart";
import "../entities/tower.dart";
import "../level/pathnode.dart";
import "../renderer/2d/vector.dart";

abstract class TowerUtils {

    static Vector intercept(Vector firePos, Vector targetPos, Vector targetVel, double projSpeed) {
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

    static double interceptTime(Vector firePos, Vector targetPos, Vector targetVel, double projSpeed) {
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

    static Vector interceptEnemy(Tower tower, Enemy enemy) {
        if (enemy.speed <= 0) { return enemy.posVector; }

        final Vector tPos = tower.posVector;

        Vector pos = enemy.posVector;
        PathNode nextNode = enemy.targetNode;
        Vector targetOffset = nextNode.posVector - pos;
        double targetDistance = targetOffset.length;
        Vector dir = targetOffset / targetDistance;
        double timeOffset = 0;

        int iter = 0;
        while(iter < 1000) {
            double time = interceptTime(tPos, pos - dir * enemy.speed * timeOffset, dir * enemy.speed, tower.towerType.projectileSpeed);
            if (time == -1) { return null; }
            time -= timeOffset;

            final double timeToNode = targetDistance / enemy.speed;

            if (time < timeToNode) {
                return pos + (dir * enemy.speed * time);
            }

            timeOffset += timeToNode;
            pos = nextNode.posVector;
            nextNode = nextNode.targetNode;
            targetOffset = nextNode.posVector - pos;
            targetDistance = targetOffset.length;
            dir = targetOffset / targetDistance;

            iter++;
        }
        print("ran out of iterations");
        return pos;
    }
}