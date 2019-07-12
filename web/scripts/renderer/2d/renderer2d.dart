import "dart:html";
import "dart:math" as Math;

import "../../level/level.dart";

/// Debug and stand-in development renderer!
/// Render chain involving classes implementing [Renderable2D]
/// Slow compared to 3d but as long as individual objects are simple drawing should be cheap enough to be workable
class Renderer2D {
    final CanvasElement canvas;
    final CanvasRenderingContext2D ctx;
    Level level;

    bool dragging = false;
    int zoomLevel = 0;
    double zoomFactor = 1.0;

    Point<num> offset = const Point<num>(0,0);

    Renderer2D(CanvasElement this.canvas, Level this.level) : ctx = canvas.context2D {
        this.canvas.onMouseDown.listen(mouseDown);
        window.onMouseUp.listen(mouseUp);
        window.onMouseMove.listen(mouseMove);
        this.canvas.onMouseWheel.listen(mouseWheel);

        redraw();
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

            redraw();
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

        redraw();
        //print(zoomLevel);
    }

    void clear() => ctx.clearRect(0, 0, canvas.width, canvas.height);

    void redraw() {
        this.clear();
        ctx.save();
        ctx.translate(offset.x, offset.y);
        ctx.scale(zoomFactor, zoomFactor);

        level.drawToCanvas(ctx);

        if (level.domainMap != null && level.domainMap.debugCanvas != null) {
            ctx.drawImage(level.domainMap.debugCanvas, level.domainMap.pos_x, level.domainMap.pos_y);
        }

        ctx.restore();

        ctx.save();
        ctx.translate(offset.x, offset.y);

        level.drawUIToCanvas(ctx, zoomFactor);

        ctx.restore();
    }

    void recalculateZoomFactor() {
        double n = 1.0;

        /*if (zoomLevel > 0) {
            n = zoomLevel.toDouble() + 1;
        } else if (zoomLevel < 0) {
            n = 1 / (-zoomLevel + 1);
        }*/

        n = Math.pow(1.2, zoomLevel);

        zoomFactor = n;
    }
}