import "dart:html";
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

    Math.Point<num> toPoint() => new Math.Point<num>(x,y);
}

extension Vector3Extras on B.Vector3 {
    void setFrom(B.Vector3 other) => this.set(other.x, other.y, other.z);

    void setFromGameCoords(B.Vector2 loc, double height) {
        this.set(-loc.x, height, loc.y);
    }

    B.Vector2 toGameCoords() {
        return new B.Vector2(-x,z);
    }
}

extension ElementExtras on Element {
    int get totalWidth {
        final CssStyleDeclaration computed = this.getComputedStyle();

        int handler(String s) => 0;

        final String cLeft = computed.marginLeft;
        final String cRight = computed.marginRight;

        int left = 0, right = 0;

        if (!cLeft.isEmpty) {
            left = int.parse(cLeft.substring(0, cLeft.length - 2), onError: handler);
        }
        if (!cRight.isEmpty) {
            right = int.parse(cRight.substring(0, cRight.length - 2), onError: handler);
        }

        return this.offsetWidth + left + right;
    }

    int get totalHeight {
        final CssStyleDeclaration computed = this.getComputedStyle();

        int handler(String s) => 0;

        final String cTop = computed.marginTop;
        final String cBottom = computed.marginBottom;

        int top = 0, bottom = 0;

        if (!cTop.isEmpty) {
            top = int.parse(cTop.substring(0, cTop.length - 2), onError: handler);
        }
        if (!cBottom.isEmpty) {
            bottom = int.parse(cBottom.substring(0, cBottom.length - 2), onError: handler);
        }

        return this.offsetHeight + top + bottom;
    }
}