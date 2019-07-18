
import "../engine/entity.dart";
import "../level/levelobject.dart";
import "../renderer/2d/matrix.dart";
import "../renderer/2d/vector.dart";

class MoverEntity extends LevelObject with Entity, HasMatrix {
    double speedMultiplier = 1.0;
    double baseSpeed = 10.0;
    double speed;
    double get derivedSpeed => baseSpeed * speedMultiplier;

    Vector velocity = new Vector.zero();
    Vector previousPos;

    MoverEntity() {
        speed = baseSpeed;
    }

    @override
    void logicUpdate([num dt = 0]) {
        this.applyVelocity(dt);
    }

    void applyVelocity(num dt) {
        if (this.velocity.length == 0) { return; }
        this.previousPos = this.posVector;
        this.posVector += this.velocity * dt;
    }

    @override
    void renderUpdate([num interpolation = 0]) {
        previousPos ??= posVector;
    }
}