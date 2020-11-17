import "dart:html";

import "../engine/engine.dart";
import "../engine/entity.dart";

typedef RenderLoopFunction = void Function(double frameTime);

abstract class Renderer {
    Engine engine;

    Element container;

    void draw([double interpolation]) {}
    void addRenderable(Object object) {}
    void addRenderables(Iterable<Object> objects) {
        for (final Object object in objects) {
            this.addRenderable(object);
        }
    }
    void removeRenderable(Object object) {}

    void runRenderLoop(RenderLoopFunction loop);

    void onMouseDown(MouseEvent e);
    void onMouseUp(MouseEvent e);
    void onMouseMove(MouseEvent e);
    void onMouseWheel(WheelEvent e);
    void drag(int button, Point<num> offset, MouseEvent e);
    void click(int button, MouseEvent e);

    void moveTo(num x, num y);
    void centreOnObject(Object object);

    void destroy();
}