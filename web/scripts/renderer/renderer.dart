import "dart:html";

import "../engine/engine.dart";

abstract class Renderer {
    Engine engine;

    Element container;

    void draw([double interpolation]) {

    }

    void onMouseDown(MouseEvent e);
    void onMouseUp(MouseEvent e);
    void onMouseMove(MouseEvent e);
    void onMouseWheel(WheelEvent e);
    void drag(MouseEvent e, Point<num> offset);
    void click(MouseEvent e);
}