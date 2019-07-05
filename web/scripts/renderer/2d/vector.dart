import "dart:math" as Math;

import "matrix.dart";

class Vector extends Math.Point<num> {

    double _length;

    double get length {
        _length ??= Math.sqrt(x*x + y*y);
        return _length;
    }

    Vector(num x, num y) : super(x,y);

    Vector applyMatrix(RotationMatrix matrix) {
        final num x = matrix.cos * this.x - matrix.sin * this.y;
        final num y = matrix.sin * this.x + matrix.cos * this.y;

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
}