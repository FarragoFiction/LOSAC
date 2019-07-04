import "dart:math" as Math;

class RotationMatrix {
    final double sin;
    final double cos;

    RotationMatrix(num angle) : sin = Math.sin(angle), cos = Math.cos(angle);
}
