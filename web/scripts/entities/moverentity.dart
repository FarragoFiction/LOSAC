import "dart:html";

import "package:CommonLib/Utility.dart";
import "package:CubeLib/CubeLib.dart" as B;

import "../engine/entity.dart";
import "../level/levelobject.dart";
import "../renderer/2d/matrix.dart";
import "../utility/extensions.dart";

class MoverEntity extends LevelObject with Entity, HasMatrix {
    double speedMultiplier = 1.0;
    double baseSpeed = 10.0;
    double speed;
    double get derivedSpeed => baseSpeed * speedMultiplier;

    B.Vector2 velocity = B.Vector2.Zero();
    B.Vector2 previousPos = B.Vector2.Zero();
    double previousRot;
    B.Vector2 drawPos;
    double drawRot;

    /// Used in calculateBounds to override the main [LevelObject] rotated bounds code
    double boundsSize = 10;

    MoverEntity() {
        speed = baseSpeed;
    }

    @override
    void logicUpdate([num dt = 0]) {
        this.applyVelocity(dt);
    }

    void applyVelocity(num dt) {
        if (this.velocity.length() == 0) { return; }
        this.previousPos.setFrom(this.position);
        this.position.addInPlace(this.velocity * dt);
    }

    @override
    void renderUpdate([num interpolation = 0]) {
        previousPos ??= position.clone();
        previousRot ??= rot_angle;
        drawPos ??= position.clone();

        final double dx = this.position.x - previousPos.x;
        final double dy = this.position.y - previousPos.y;
        drawPos.set(previousPos.x + dx * interpolation, previousPos.y + dy * interpolation);

        final double da = angleDiff(rot_angle, previousRot);
        drawRot = previousRot + da * interpolation;

        if (this.mesh != null) {
            this.mesh
                ..position.setFromGameCoords(drawPos, this.getModelZPosition())
                ..rotation.y = drawRot;
        }
    }

    @override
    double getModelZPosition() {
        drawPos ??= position.clone();
        double z = this.getWorldZPosition();
        if (this.level != null) {
            z += this.level.levelHeightMap.getSmoothVal(this.drawPos.x, this.drawPos.y);
        }
        return z;
    }

    /*@override
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
    }*/

    /*@override
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
    }*/

    // this greatly simplifies the bounding boxes for moving objects, which is probably a good thing...
    @override
    Rectangle<num> calculateBounds() => new Rectangle<num>(this.position.x-boundsSize/2, this.position.y-boundsSize/2, boundsSize, boundsSize);
}