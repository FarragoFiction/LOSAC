import "dart:html";

import "package:CubeLib/CubeLib.dart" as B;
import "package:collection/collection.dart";

import "../renderer/2d/bounds.dart";
import "../renderer/2d/matrix.dart";
import "../renderer/3d/renderable3d.dart";
import "../utility/extensions.dart";

class SimpleLevelObject with Renderable3D {
    B.Vector2 posVector = B.Vector2.Zero();

    @override
    void generateMesh() {
        this.mesh = B.MeshBuilder.CreateBox("Object ${this.hashCode}", new B.MeshBuilderCreateBoxOptions(size: 10));
        this.mesh.material = this.renderer.defaultMaterial;
        this.mesh.position.set(this.posVector.x, this.posVector.y, 0);
    }
}

class LevelObject extends SimpleLevelObject {

    final Set<LevelObject> _subObjects = <LevelObject>{};
    Set<LevelObject> subObjects;

    LevelObject parentObject;

    double rot_angle = 0;
    double scale = 1;

    Rectangle<num> _bounds;
    bool dirtyBounds = true;

    Rectangle<num> get bounds {
        if (dirtyBounds) {
            recalculateBounds();
        }
        return _bounds;
    }


    LevelObject() : rot_angle = 0 {
        subObjects = new UnmodifiableSetView<LevelObject>(_subObjects);
        initMixins();
    }

    void initMixins(){}

    /*@override
    void drawUIToCanvas(CanvasRenderingContext2D ctx, double scaleFactor) {
        if (hidden || !drawUI) { return; }
        ctx.save();

        ctx.translate(pos_x * scaleFactor, pos_y * scaleFactor);

        if (!invisible) {
            this.drawUI2D(ctx, scaleFactor);
        }

        for (final LevelObject subObject in subObjects) {
            subObject.drawUIToCanvas(ctx, scaleFactor * this.scale);
        }

        ctx.restore();
    }*/

    void drawUI2D(CanvasRenderingContext2D ctx, double scaleFactor) {

    }

    void addSubObject(LevelObject sub) {
        this._subObjects.add(sub);
        sub.parentObject = this;
    }

    void removeSubObject(LevelObject sub) {
        if (sub.parentObject != this) { return; }
        this._subObjects.remove(sub);
        sub.parentObject = null;
    }

    B.Vector2 getWorldPosition([B.Vector2 offset]) {
        final B.Vector2 pos = this.posVector.clone();

        if (offset != null) {
            pos.addInPlace(offset.rotate(this.rot_angle));
        }

        if (this.parentObject == null) { return pos; }

        RotationMatrix rot;
        LevelObject o = this;

        while( o.parentObject != null ) {
            o = o.parentObject;

            if (o is HasMatrix) {
                final HasMatrix h = o;
                rot = h.matrix;
            } else {
                rot = new RotationMatrix(o.rot_angle);
            }

            pos.applyMatrixInPlace(rot);
            pos.addInPlace(o.posVector);
        }

        return pos;
    }

    B.Vector2 getLocalPositionFromWorld(B.Vector2 pos) {
        final B.Vector2 worldPos = this.getWorldPosition();
        return worldPos.subtractInPlace(pos).scaleInPlace(-1).rotate(-rot_angle);
    }

    num getWorldRotation() {
        num rot = this.rot_angle;
        LevelObject o = this;

        while( o.parentObject != null) {
            o = o.parentObject;
            rot += o.rot_angle;
        }

        return rot;
    }

    num getLocalRotationFromWorld(num angle) {
        final num parentRot = getWorldRotation() - this.rot_angle;

        return angle - parentRot;
    }

    void makeBoundsDirty() {
        this.dirtyBounds = true;
        if (parentObject != null) {
            parentObject.makeBoundsDirty();
        }
    }

    void recalculateBounds() {
        if (dirtyBounds) {
            for (final LevelObject o in this.subObjects) {
                o.recalculateBounds();
            }
            _bounds = calculateBounds();
            dirtyBounds = false;
        }
    }

    Rectangle<num> calculateBounds() => rectBounds(this, 10,10);
}