import "dart:html";
import "dart:math" as Math;

import "../../engine/engine.dart";
import "../../engine/game.dart";
import "../../engine/spatialhash.dart";
import "../../level/level2d.dart";
import "../renderer.dart";
import "renderable2d.dart";
import "vector.dart";

/// Debug and stand-in development renderer!
/// Render chain involving classes implementing [Renderable2D]
/// Slow compared to 3d but as long as individual objects are simple drawing should be cheap enough to be workable
class Renderer2D extends Renderer{
    final CanvasElement canvas;
    final CanvasRenderingContext2D ctx;

    int zoomLevel = 0;
    double zoomFactor = 1.0;

    Point<num> rawOffset = const Point<num>(0,0);
    num get offsetX => rawOffset.x + this.canvas.width*0.5;
    num get offsetY => rawOffset.y + this.canvas.height*0.5;

    Iterable<Renderable2D> renderableEntities;

    @override
    set engine(Engine e) {
        super.engine = e;
        this.renderableEntities = e.entities.whereType();
    }

    Renderer2D(CanvasElement this.canvas) : ctx = canvas.getContext("2d", <dynamic,dynamic>{ "alpha": false }) {
        this.container = this.canvas;
    }

    @override
    void moveTo(num x, num y) {
        this.rawOffset = new Math.Point<num>(-x, -y);
    }

    @override
    void onMouseDown(MouseEvent e) {
        _updateCursor();
    }

    @override
    void onMouseUp(MouseEvent e) {
        _updateCursor();
    }

    @override
    void onMouseMove(MouseEvent e) {
        _updateCursor();
    }

    @override
    void onMouseWheel(WheelEvent e) {
        e.preventDefault();
        zoomLevel -= e.deltaY.sign;

        final Point<num> diff = new Point<num>(e.offset.x - offsetX, e.offset.y - offsetY);
        //print("diff $diff");
        final Point<num> mouse = Point<num>(diff.x / zoomFactor, diff.y / zoomFactor);

        recalculateZoomFactor();

        final Point<num> mouse2 = Point<num>(mouse.x * zoomFactor, mouse.y * zoomFactor);
        //print("mouse2 $mouse2");

        final Point<num> delta = mouse2 - diff;
        //print("delta: $delta");

        rawOffset -= delta;

        //draw();
        //print(zoomLevel);
    }

    @override
    void click(MouseEvent e) {
        final Vector worldPos = new Vector((e.offset.x - offsetX) / zoomFactor, (e.offset.y - offsetY) / zoomFactor);
        this.engine.click(worldPos);
    }

    @override
    void drag(MouseEvent e, Point<num> offset) {
        this.rawOffset += offset;
        _updateCursor();
    }

    void _updateCursor() {
        if (this.engine.input.dragging) {
            canvas.classes.add("dragging");
        } else {
            canvas.classes.remove("dragging");
        }
    }

    void clear() => ctx.clearRect(0, 0, canvas.width, canvas.height);

    @override
    void draw([double dt = 0]) {

        this.clear();
        ctx.save();
        ctx.translate(offsetX, offsetY);
        ctx.scale(zoomFactor, zoomFactor);

        final Level2D level = engine.level;

        level.drawToCanvas(ctx);

        for (final Renderable2D o in renderableEntities) {
            o.drawToCanvas(ctx);
        }

        ctx.restore();

        ctx.save();
        ctx.translate(offsetX, offsetY);

        level.drawUIToCanvas(ctx, zoomFactor);

        for (final Renderable2D o in renderableEntities) {
            o.drawUIToCanvas(ctx, zoomFactor);
        }

        /*if (engine is Game) {
            final Game g = engine;
            drawSpatialHash(g.enemySelector);
        }*/

        ctx.restore();
    }

    void recalculateZoomFactor() {
        double n = 1.0;

        n = Math.pow(1.2, zoomLevel);

        zoomFactor = n;
    }


    // ignore: always_specify_types
    void drawSpatialHash(SpatialHash hash) {
        //print("aaa");
        ctx.strokeStyle = "#FFCC00";
        for (final SpatialHashKey bucket in hash.buckets.keys) {
            final num x = hash.xPos + bucket.x * hash.bucketSize;
            final num y = hash.yPos + bucket.y * hash.bucketSize;
            //print("bucket ${bucket.x},${bucket.y}: $x,$y");
            ctx.strokeRect(x * zoomFactor, y * zoomFactor, hash.bucketSize * zoomFactor, hash.bucketSize * zoomFactor);
        }
    }
}