import "dart:math" as Math;

import "../../level/levelobject.dart";

class RotationMatrix {
    final double sin;
    final double cos;

    RotationMatrix(num angle) : sin = Math.sin(angle), cos = Math.cos(angle);
}

mixin HasMatrix on LevelObject {
    RotationMatrix matrix;

    @override
    void initMixins() {
        super.initMixins();
        updateMatrix();
    }

    @override
    set rot_angle(double value) {
        super.rot_angle = value;
        updateMatrix();
    }

    void updateMatrix() {
        this.matrix = new RotationMatrix(this.rot_angle);
    }
}
