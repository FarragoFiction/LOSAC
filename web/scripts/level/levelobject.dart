import "dart:html";

import "package:CubeLib/CubeLib.dart" as B;
import "package:collection/collection.dart";

import "../renderer/2d/bounds.dart";
import '../renderer/2d/extendedvectors.dart';
import "../renderer/2d/matrix.dart";
import "../renderer/3d/models/meshprovider.dart";
import "../renderer/3d/renderable3d.dart";
import "../utility/extensions.dart";
import "level.dart";

class SimpleLevelObject with Renderable3D {
    B.Vector2 position = B.Vector2.Zero();
    double zPosition = 0;

    MeshProvider<dynamic> meshProvider;
    
    B.ActionManager testManager;

    @override
    void generateMesh() {
        if (this.meshProvider != null) {
            this.mesh = this.meshProvider.provide(this);
        } else {
            this.mesh = this.renderer.defaultMeshProvider.provide(this);
        }

        this.updateMeshPosition();
    }

    Level get level => this.renderer?.engine?.level;

    B.Vector2 getModelPosition() => this.position;
    num getModelRotation() => 0;
    double getZPosition() => this.zPosition;

    @override
    void updateMeshPosition({B.Vector2 position, double height}) {
        position ??= this.position;
        height ??= this.getZPosition();
        this.mesh?.position?.setFromGameCoords(position, height);
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

    // ignore this complaint, we need this to be the subtype for bounds dirtying
    @override
    B.Vector2 position = new Vector2WithCallback(0, 0);

    Rectangle<num> get bounds {
        if (dirtyBounds) {
            recalculateBounds();
        }
        return _bounds;
    }

    LevelObject() : rot_angle = 0 {
        // set the callback on creation... if we don't do this immediately it'll die on first set
        final Vector2WithCallback v = this.position;
        v.callback = (B.Vector2 v) => this.makeBoundsDirty();

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
        print("honk: $this");

        final B.Vector2 pos = this.position.clone();

        print("pos1: ${pos.x},${pos.y}");

        if (offset != null) {
            pos.addInPlace(offset.rotate(this.rot_angle));
        }

        if (this.parentObject == null) { return pos; }

        print("pos2: ${pos.x},${pos.y}");

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
            print("pos3: ${pos.x},${pos.y}");
            print("o: $o");
            print("o.position: ${o.position.x},${o.position.y}");
            pos.addInPlace(o.position);
            print("pos4: ${pos.x},${pos.y}");
        }

        print("pos5: ${pos.x},${pos.y}");
        return pos;
    }
    @override
    B.Vector2 getModelPosition() => getWorldPosition();

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
    @override
    num getModelRotation() => getWorldRotation();

    num getLocalRotationFromWorld(num angle) {
        final num parentRot = getWorldRotation() - this.rot_angle;

        return angle - parentRot;
    }

    @override
    double getZPosition() {
        double z = this.zPosition;
        if (this.parentObject != null) {
            z += this.parentObject.getZPosition();
        }
        return z;
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

    @override
    void updateMeshPosition({B.Vector2 position, double height}) {
        super.updateMeshPosition(position: position, height: height);
        this.mesh?.rotation?.y = this.rot_angle;
    }
}