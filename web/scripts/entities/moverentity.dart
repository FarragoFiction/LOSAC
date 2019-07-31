import "dart:html";

import "package:CommonLib/Utility.dart";

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
    double previousRot;
    Vector drawPos;
    double drawRot;

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
        previousRot ??= rot_angle;

        final double dx = this.pos_x - previousPos.x;
        final double dy = this.pos_y - previousPos.y;
        drawPos = new Vector(previousPos.x + dx * interpolation, previousPos.y + dy * interpolation);

        final double da = angleDiff(rot_angle, previousRot);
        drawRot = previousRot + da * interpolation;
    }

    @override
    void drawToCanvas(CanvasRenderingContext2D ctx) {
        if (hidden) { return; }
        ctx.save();

        ctx.translate(drawPos.x, drawPos.y);
        ctx.rotate(drawRot);
        ctx.scale(scale, scale);

        if (!invisible) {
            this.draw2D(ctx);
        }

        for (final LevelObject subObject in subObjects) {
            subObject.drawToCanvas(ctx);
        }

        ctx.restore();
    }

    @override
    void drawUIToCanvas(CanvasRenderingContext2D ctx, double scaleFactor) {
        if (hidden || !drawUI) { return; }
        ctx.save();

        ctx.translate(drawPos.x * scaleFactor, drawPos.y * scaleFactor);

        if (!invisible) {
            this.drawUI2D(ctx, scaleFactor);
        }

        for (final LevelObject subObject in subObjects) {
            subObject.drawUIToCanvas(ctx, scaleFactor * this.scale);
        }

        ctx.restore();
    }
}