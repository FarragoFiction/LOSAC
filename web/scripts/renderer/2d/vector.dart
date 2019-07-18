import "dart:math" as Math;

import "matrix.dart";

class Vector extends Math.Point<num> {

    double _length;

    double get length {
        _length ??= Math.sqrt(x*x + y*y);
        return _length;
    }

    Vector(num x, num y) : super(x,y);

    factory Vector.fromPoint(Math.Point<num> point) {
        if (point is Vector) {
            return point;
        }
        return new Vector(point.x, point.y);
    }

    factory Vector.zero() => new Vector(0,0);

    Vector applyMatrix(RotationMatrix matrix) {
        final num x = matrix.cos * this.x - matrix.sin * this.y;
        final num y = matrix.sin * this.x + matrix.cos * this.y;

        return new Vector(x,y);
    }

    Vector applyMatrixInverse(RotationMatrix matrix) {
        final num x = matrix.cos * this.y - matrix.sin * this.x;
        final num y = matrix.sin * this.y + matrix.cos * this.x;

        return new Vector(x,y);
    }

    Vector rotate(num angle) => applyMatrix(new RotationMatrix(angle));

    @override
    Vector operator +(Object other) {
        if (other is Math.Point<num>) {
            return Vector(x + other.x, y + other.y);
        } else if (other is num) {
            return Vector(x + other, y + other);
        }
        throw ArgumentError("Invalid vector addition: $this + $other");
    }

    @override
    Vector operator -(Object other) {
        if (other is Math.Point<num>) {
            return Vector(x - other.x, y - other.y);
        } else if (other is num) {
            return Vector(x - other, y - other);
        }
        throw ArgumentError("Invalid vector subtraction: $this - $other");
    }

    @override
    Vector operator *(Object other) {
        if (other is Math.Point<num>) {
            return Vector(x * other.x, y * other.y);
        } else if (other is num) {
            return Vector(x * other, y * other);
        }
        throw ArgumentError("Invalid vector multiplication: $this * $other");
    }

    Vector operator /(Object other) {
        if (other is Math.Point<num>) {
            return Vector(x / other.x, y / other.y);
        } else if (other is num) {
            return Vector(x / other, y / other);
        }
        throw ArgumentError("Invalid vector division: $this / $other");
    }

    Vector norm() => this / this.length;
    double dot(Vector other) => x * other.x + y * other.y;
}