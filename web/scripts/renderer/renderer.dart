import "dart:html";

import "../engine/engine.dart";
import "../engine/entity.dart";

typedef RenderLoopFunction = void Function(double frameTime);

abstract class Renderer {
    Engine engine;

    Element container;

    void draw([double interpolation]) {}
    void addRenderable(Object entity) {}
    void removeRenderable(Object entity) {}

    void runRenderLoop(RenderLoopFunction loop);

    void onMouseDown(MouseEvent e);
    void onMouseUp(MouseEvent e);
    void onMouseMove(MouseEvent e);
    void onMouseWheel(WheelEvent e);
    void drag(MouseEvent e, Point<num> offset);
    void click(MouseEvent e);

    void moveTo(num x, num y);

    void destroy();
}