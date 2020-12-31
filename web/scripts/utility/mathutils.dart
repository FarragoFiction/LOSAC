import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

abstract class MathUtils {
    static const double epsilon = 1e-6;

    static B.Vector3 tempVector1 = B.Vector3.Zero();
    static B.Vector3 tempVector2 = B.Vector3.Zero();
    static B.Vector3 tempVector3 = B.Vector3.Zero();
    static B.Vector3 tempVector4 = B.Vector3.Zero();
    static B.Vector3 tempVector5 = B.Vector3.Zero();

    static Math.Point<double> quadratic(double a, double b, double c) {
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

    static List<double> _quadratic(double a, double b, double c) {
        final List<double> solutions = <double>[];

        if (a.abs() < epsilon) {
            if (b.abs() < epsilon) {
                if (c.abs() < epsilon) {
                    solutions.add(0);
                }
            } else {
                solutions.add(-c/b);
            }
        } else {
            double disc = b*b - 4*a*c;
            if (disc >= 0) {
                disc = Math.sqrt(disc);
                a *= 2;

                solutions.add((-b-disc)/a);
                solutions.add((-b+disc)/a);
            }
        }
        return solutions;
    }

    static List<double> cubic(double a, double b, double c, double d) {
        double A,B,C;
        double sq_A,p,q;
        double cb_p,D;

        final List<double> solutions = <double>[];

        A = b/a;
        B = c/a;
        C = d/a;

        sq_A = A*A;
        p = 1/3 * (-1/3 * sq_A + B);
        q = 1/2 * (2/27 * A * sq_A - 1/3 * A * B + C);

        cb_p = p*p*p;
        D = q*q*cb_p;

        if (D.abs() < epsilon) {
            if (q.abs() < epsilon) {
                // one triple solution
                solutions.add(0);
            } else {
                // one single and one double solution
                final double u = Math.pow(-q, 1/3);
                solutions.add(2 * u);
                solutions.add(-u);
            }
        } else if (D < 0) {
            // three real solutions
            final double phi = 1/3 * Math.acos(-q / Math.sqrt(-cb_p));
            final double t = 2 * Math.sqrt(-p);

            solutions.add(t * Math.cos(phi));
            solutions.add(t * Math.cos(phi + Math.pi / 3));
            solutions.add(t * Math.cos(phi - Math.pi / 3));
        } else {
            // one real solution
            final double sqrt_D = Math.sqrt(D);
            final double u = Math.pow(sqrt_D - q, 1/3);
            final double v = -Math.pow(sqrt_D + q, 1/3);

            solutions.add(u + v);
        }

        if (!solutions.isEmpty) {
            final double sub = 1/3 * A;

            for (int i=0; i<solutions.length; i++) {
                solutions[i] = solutions[i] - sub;
            }
        }

        return solutions;
    }

    static List<double> quartic(double a, double b, double c, double d, double e) {
        double z,u,v;
        double A,B,C,D;
        double sq_A,p,q,r;

        final List<double> solutions = <double>[];

        A = b/a;
        B = c/a;
        C = d/a;
        D = e/a;

        sq_A = A*A;
        p = -3/8 * sq_A + B;
        q = 1/8 * sq_A * A - 1/2 * A * B + C;
        r = -3/256 * sq_A * sq_A + 1/16 * sq_A * B - 1/4 * A *C + D;

        if (r.abs() < epsilon) {
            // no absolute term: y(y^3 + py + q) = 0

            solutions.addAll(cubic(1, 0, p, q));
        } else {
            // solve the resolvent cubic

            final List<double> cubicResult = cubic(1, -1/2 * p, -r, 1/2 * r * p - 1/8 * q * q);

            // and take the real solution
            z = cubicResult[0];

            // to build two quadratic equations
            u = z*z-r;
            v = 2*z-p;

            if (u.abs() < epsilon) {
                u = 0;
            } else if (u > 0) {
                u = Math.sqrt(u);
            } else {
                // no solution, array is empty
                return solutions;
            }

            if (v.abs() < epsilon) {
                v = 0;
            } else if (v > 0) {
                v = Math.sqrt(v);
            } else {
                // no solution, array is empty
                return solutions;
            }

            solutions.addAll(_quadratic(1, q < 0 ? -v : v, z - u));
            solutions.addAll(_quadratic(1, q < 0 ? v : -v, z + u));
        }

        if (!solutions.isEmpty) {
            final double sub = 1/4 * A;

            for (int i=0; i<solutions.length; i++) {
                solutions[i] = solutions[i] - sub;
            }
        }

        return solutions;
    }
}