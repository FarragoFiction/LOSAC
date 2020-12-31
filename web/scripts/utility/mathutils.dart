import "dart:math" as Math;

import 'package:CommonLib/Logging.dart';
import "package:CubeLib/CubeLib.dart" as B;

abstract class MathUtils {
    static final Logger _logger = new Logger("MathUtils");//, true);//
    static const double epsilon = 1e-9;

    static B.Vector3 tempVector1 = B.Vector3.Zero();
    static B.Vector3 tempVector2 = B.Vector3.Zero();
    static B.Vector3 tempVector3 = B.Vector3.Zero();
    static B.Vector3 tempVector4 = B.Vector3.Zero();
    static B.Vector3 tempVector5 = B.Vector3.Zero();

    static double cubeRoot(double x) => x.sign * Math.pow(x.abs(), 1/3);

    static Math.Point<double> quadraticBasic(double a, double b, double c) {
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

    static Iterable<double> quadratic(double a, double b, double c) sync* {
        double p,q,D;

        p = b / (2*a);
        q = c / a;

        D = p*p - q;

        if (D.abs() < epsilon) {
            yield -p;
        } else if (D < 0) {
            // no-op
        } else {
            final double sqrt_D = Math.sqrt(D);

            yield sqrt_D - p;
            yield -sqrt_D - p;
        }
    }

    static Iterable<double> cubic(double a, double b, double c, double d) sync* {
        double A,B,C,sub;
        double sq_A,p,q;
        double cb_p,D;

        A = b/a;
        B = c/a;
        C = d/a;

        sub = 1/3 * A;

        sq_A = A*A;
        p = 1/3 * (-1/3 * sq_A + B);
        q = 1/2 * (2/27 * A * sq_A - 1/3 * A * B + C);

        cb_p = p*p*p;
        D = q*q + cb_p;

        if (D.abs() < epsilon) {
            if (q.abs() < epsilon) {
                // one triple solution
                yield -sub;
            } else {
                // one single and one double solution
                final double u = cubeRoot(-q);

                yield (2 * u) - sub;
                yield (-u) -sub;
            }
        } else if (D < 0) {
            // three real solutions
            final double phi = 1/3 * Math.acos(-q / Math.sqrt(-cb_p));
            final double t = 2 * Math.sqrt(-p);

            yield (t * Math.cos(phi)) - sub;
            yield (- t * Math.cos(phi + (Math.pi / 3))) - sub;
            yield (- t * Math.cos(phi - (Math.pi / 3))) - sub;
        } else {
            // one real solution
            final double sqrt_D = Math.sqrt(D);
            final double u = cubeRoot(sqrt_D - q);
            final double v = -cubeRoot(sqrt_D + q);

            yield (u + v) - sub;
        }
    }

    static Iterable<double> quartic(double a, double b, double c, double d, double e) sync* {
        double z,u,v,sub;
        double A,B,C,D;
        double sq_A,p,q,r;

        A = b/a;
        B = c/a;
        C = d/a;
        D = e/a;

        sub = 1/4 * A;

        sq_A = A*A;
        p = -3/8 * sq_A + B;
        q = 1/8 * sq_A * A - 1/2 * A * B + C;
        r = -3/256 * sq_A * sq_A + 1/16 * sq_A * B - 1/4 * A * C + D;

        if (r.abs() < epsilon) {
            // no absolute term: y(y^3 + py + q) = 0

            yield* cubic(1, 0, p, q).map((double e) => e-sub);
        } else {
            // solve the resolvent cubic

            final Iterable<double> cubicResult = cubic(1, -1/2 * p, -r, 1/2 * r * p - 1/8 * q * q);

            // and take the real solution
            z = cubicResult.first;

            // to build two quadratic equations
            u = z*z-r;
            v = 2*z-p;

            if (u.abs() < epsilon) {
                u = 0;
            } else if (u > 0) {
                u = Math.sqrt(u);
            } else {
                // no solution, array is empty
                return;
            }

            if (v.abs() < epsilon) {
                v = 0;
            } else if (v > 0) {
                v = Math.sqrt(v);
            } else {
                // no solution, array is empty
                return;
            }

            yield* quadratic(1, q < 0 ? -v : v, z - u).map((double e) => e-sub);
            yield* quadratic(1, q < 0 ? v : -v, z + u).map((double e) => e-sub);
        }
    }
}