import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "../renderer/2d/matrix.dart";

extension Vector2Extras on B.Vector2 {
    void setFrom(B.Vector2 other) => this.set(other.x, other.y);

    double get angle => Math.atan2(y, x);
    double dot(B.Vector2 other) => B.Vector2.Dot(this, other);
    B.Vector2 normalized() => this.clone().normalize();

    B.Vector2 rotate(double angle) {
        final RotationMatrix matrix = new RotationMatrix(angle);
        return this.applyMatrix(matrix);
    }

    void rotateInPlace(double angle) {
        final RotationMatrix matrix = new RotationMatrix(angle);
        this.applyMatrixInPlace(matrix);
    }

    B.Vector2 applyMatrix(RotationMatrix matrix) {
        final num x = matrix.cos * this.x - matrix.sin * this.y;
        final num y = matrix.sin * this.x + matrix.cos * this.y;

        return new B.Vector2(x,y);
    }

    B.Vector2 applyMatrixInverse(RotationMatrix matrix) {
        final num x = matrix.cos * this.y - matrix.sin * this.x;
        final num y = matrix.sin * this.y + matrix.cos * this.x;

        return new B.Vector2(x,y);
    }

    void applyMatrixInPlace(RotationMatrix matrix) {
        final num x = matrix.cos * this.x - matrix.sin * this.y;
        final num y = matrix.sin * this.x + matrix.cos * this.y;

        this.set(x, y);
    }

    void applyMatrixInverseInPlace(RotationMatrix matrix) {
        final num x = matrix.cos * this.y - matrix.sin * this.x;
        final num y = matrix.sin * this.y + matrix.cos * this.x;

        this.set(x, y);
    }

    double cross(B.Vector2 other) {
        return (this.x * other.y) - (this.y * other.x);
    }
}

extension Vector3Extras on B.Vector3 {
    void setFromGameCoords(B.Vector2 loc, double height) {
        this.set(-loc.x, height, loc.y);
    }

    B.Vector2 toGameCoords() {
        return new B.Vector2(-x,z);
    }
}