import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "../level/levelobject.dart";
import "../utility/extensions.dart";
import "engine.dart";

mixin Entity on LevelObject {
    Engine engine;

    bool active = true;
    bool dead = false;

    void logicUpdate([num dt = 0]);

    void renderUpdate([num interpolation = 0]);

    void kill() {
        this.dead = true;
    }
}

enum SlopeMode {
    upright,
    conform
}

mixin TerrainEntity on Entity {
    SlopeMode slopeMode = SlopeMode.upright;

    double get slopeTestRadius;

    @override
    double getZPosition() {
        final B.Vector2 pos = this.getModelPosition();
        double z = super.getZPosition();
        if (this.level != null) {
            z += this.level.levelHeightMap.getSmoothVal(pos.x, pos.y);
        }
        return z;
    }

    @override
    void updateMeshPosition({B.Vector2 position, double height, double rotation}) {
        super.updateMeshPosition(position: position, height: height);

        if (this.mesh == null || this.level == null) { return; }

        if (this.slopeMode == SlopeMode.conform) {
            position ??= this.position;
            final B.Vector2 offset = new B.Vector2(0,slopeTestRadius)..rotateInPlace(this.rot_angle);

            final double right = this.level.levelHeightMap.getSmoothVal(position.x + offset.x, position.y + offset.y);
            final double left = this.level.levelHeightMap.getSmoothVal(position.x - offset.x, position.y - offset.y);

            final double roll = Math.atan2(left-right, slopeTestRadius * 2);

            final double front = this.level.levelHeightMap.getSmoothVal(position.x - offset.y, position.y + offset.x);
            final double back = this.level.levelHeightMap.getSmoothVal(position.x + offset.y, position.y - offset.x);

            final double pitch = Math.atan2(front-back, slopeTestRadius * 2);

            rotation ??= rot_angle;

            this.mesh.rotation..x = roll..y = rotation..z = pitch;
        }
    }
}