import "dart:html";
import "dart:math" as Math;

import "../../engine/engine.dart";
import "../renderer.dart";
import "renderable2d.dart";

/// Debug and stand-in development renderer!
/// Render chain involving classes implementing [Renderable2D]
/// Slow compared to 3d but as long as individual objects are simple drawing should be cheap enough to be workable
class Renderer2D extends Renderer{
    final CanvasElement canvas;
    final CanvasRenderingContext2D ctx;

    bool dragging = false;
    int zoomLevel = 0;
    double zoomFactor = 1.0;

    Point<num> offset = const Point<num>(0,0);

    Iterable<Renderable2D> renderableEntities;

    @override
    set engine(Engine e) {
        super.engine = e;
        this.renderableEntities = e.entities.whereType();
    }

    Renderer2D(CanvasElement this.canvas) : ctx = canvas.context2D {
        this.canvas.onMouseDown.listen(mouseDown);
        window.onMouseUp.listen(mouseUp);
        window.onMouseMove.listen(mouseMove);
        this.canvas.onMouseWheel.listen(mouseWheel);
        this.container = this.canvas;
    }

    void mouseDown(MouseEvent e) {
        if (e.button == 0) {
            dragging = true;
            canvas.classes.add("dragging");
        }
    }

    void mouseUp(MouseEvent e) {
        if (e.button == 0) {
            dragging = false;
            canvas.classes.remove("dragging");
        }
    }

    void mouseMove(MouseEvent e) {
        if (dragging) {
            offset += e.movement;
            //print("offset: $offset");

            //draw();
        }
    }

    void mouseWheel(WheelEvent e) {
        e.preventDefault();
        zoomLevel -= e.deltaY.sign;

        final Point<num> diff = (e.offset - offset);
        //print("diff $diff");
        final Point<num> mouse = Point<num>(diff.x / zoomFactor, diff.y / zoomFactor);

        recalculateZoomFactor();

        final Point<num> mouse2 = Point<num>(mouse.x * zoomFactor, mouse.y * zoomFactor);
        //print("mouse2 $mouse2");

        final Point<num> delta = mouse2 - diff;
        //print("delta: $delta");

        offset -= delta;

        //draw();
        //print(zoomLevel);
    }

    void clear() => ctx.clearRect(0, 0, canvas.width, canvas.height);

    @override
    void draw([double dt = 0]) {
        this.clear();
        ctx.save();
        ctx.translate(offset.x, offset.y);
        ctx.scale(zoomFactor, zoomFactor);

        engine.level.drawToCanvas(ctx);

        for (final Renderable2D o in renderableEntities) {
            o.drawToCanvas(ctx);
        }

        ctx.restore();

        ctx.save();
        ctx.translate(offset.x, offset.y);

        engine.level.drawUIToCanvas(ctx, zoomFactor);

        for (final Renderable2D o in renderableEntities) {
            o.drawUIToCanvas(ctx, zoomFactor);
        }

        ctx.restore();
    }

    void recalculateZoomFactor() {
        double n = 1.0;

        n = Math.pow(1.2, zoomLevel);

        zoomFactor = n;
    }
}