import "dart:html";

import "renderer3d.dart";

class FloaterOverlay {
    final Renderer3D renderer;
    final CanvasElement canvas;

    bool _drewSomethingLastFrame = false;

    FloaterOverlay(Renderer3D this.renderer, CanvasElement this.canvas);

    void updateCanvasSize() {
        canvas.width = renderer.canvas.width;
        canvas.height = renderer.canvas.height;
        draw();
    }

    void draw() {
        final CanvasRenderingContext2D ctx = canvas.context2D;
        final int w = canvas.width;
        final int h = canvas.height;

        if (_drewSomethingLastFrame) {
            ctx.clearRect(0, 0, w, h);
        }
    }
}