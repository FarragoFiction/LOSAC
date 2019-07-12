import "dart:html";

import "package:collection/collection.dart";

import "../renderer/2d/bounds.dart";
import "../renderer/2d/matrix.dart";
import "../renderer/2d/renderable2d.dart";
import "../renderer/2d/vector.dart";

class SimpleLevelObject with Renderable2D {
    double pos_x = 0;
    double pos_y = 0;

    Vector get posVector => new Vector(pos_x, pos_y);
    set posVector(Vector pos) {
        this.pos_x = pos.x;
        this.pos_y = pos.y;
    }

    @override
    void drawToCanvas(CanvasRenderingContext2D ctx) {
        ctx.save();

        ctx.translate(pos_x, pos_y);

        ctx.fillStyle = "#FF0000";
        ctx.fillRect(-3, -3, 7, 7);

        ctx.restore();
    }

    @override
    void drawUIToCanvas(CanvasRenderingContext2D ctx, double ScaleFactor) {}
}

class LevelObject extends SimpleLevelObject {

    final Set<LevelObject> _subObjects = <LevelObject>{};
    Set<LevelObject> subObjects;

    LevelObject parentObject;

    double rot_angle = 0;
    double scale = 1;

    @override
    set pos_x(num val) {
        super.pos_x = val;
        makeBoundsDirty();
    }

    @override
    set pos_y(num val) {
        super.pos_y = val;
        makeBoundsDirty();
    }

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

    @override
    void drawToCanvas(CanvasRenderingContext2D ctx) {
        if (hidden) { return; }
        ctx.save();

        ctx.translate(pos_x, pos_y);
        ctx.rotate(rot_angle);
        ctx.scale(scale, scale);

        if (!invisible) {
            this.draw2D(ctx);
        }

        for (final LevelObject subObject in subObjects) {
            subObject.drawToCanvas(ctx);
        }

        ctx.restore();
    }

    void draw2D(CanvasRenderingContext2D ctx) {
        ctx.fillStyle = "#FF0000";

        ctx.fillRect(-5, -5, 10, 10);
    }

    @override
    void drawUIToCanvas(CanvasRenderingContext2D ctx, double scaleFactor) {
        if (hidden || !drawUI) { return; }
        ctx.save();

        ctx.translate(pos_x * scaleFactor, pos_y * scaleFactor);

        if (!invisible) {
            this.drawUI2D(ctx);
        }

        for (final LevelObject subObject in subObjects) {
            subObject.drawUIToCanvas(ctx, scaleFactor * this.scale);
        }

        ctx.restore();
    }

    void drawUI2D(CanvasRenderingContext2D ctx) {

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

    Point<num> getWorldPosition([Point<num> offset]) {
        Vector pos = this.posVector;

        if (offset != null) {
            pos += new Vector.fromPoint(offset).rotate(this.rot_angle);
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

            pos = pos.applyMatrix(rot);
            pos += o.posVector;
        }

        return pos;
    }

    Point<num> getLocalPositionFromWorld(Point<num> pos) {
        final Vector worldpos = this.getWorldPosition();
        final Vector parentpos = worldpos - this.posVector;

        //print("pos: $pos, worldpos: $worldpos, parentpos: $parentpos");
        return pos - parentpos;
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
        final num parentrot = getWorldRotation() - this.rot_angle;

        return angle - parentrot;
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