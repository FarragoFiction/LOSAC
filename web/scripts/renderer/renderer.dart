import "dart:html";

import "../engine/engine.dart";
import "../level/selectable.dart";

typedef RenderLoopFunction = void Function(num frameTime);

abstract class Renderer {
    late Engine engine;

    late Element container;

    Future<void> initialise();

    void draw([double interpolation = 0]) {}
    void addRenderable(Object object) {}
    void addRenderables(Iterable<Object> objects) {
        for (final Object object in objects) {
            this.addRenderable(object);
        }
    }
    void removeRenderable(Object object) {}

    void initUiEventHandlers() {}
    void runRenderLoop(RenderLoopFunction loop);
    void stopRenderLoop();

    void onMouseDown(MouseEvent e);
    void onMouseUp(MouseEvent e);
    void onMouseMove(MouseEvent e);
    void onMouseWheel(WheelEvent e);
    void drag(int button, Point<num> offset, MouseEvent e);
    void click(int button, MouseEvent e);

    SelectionInfo? getSelectableAtScreenPos([int x, int y]);

    void moveTo(num x, num y);
    void centreOnObject(Object object);

    void destroy();
}

class SelectionInfo {
    final Selectable selectable;
    final Point<num> world;

    SelectionInfo(Selectable this.selectable, Point<num> this.world);
}