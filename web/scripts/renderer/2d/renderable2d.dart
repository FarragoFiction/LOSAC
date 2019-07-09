import "dart:html";

mixin Renderable2D {
    bool hidden = false;
    bool invisible = false;
    bool drawUI = true;

    void drawToCanvas(CanvasRenderingContext2D ctx);

    void drawUIToCanvas(CanvasRenderingContext2D ctx, double scaleFactor);
}