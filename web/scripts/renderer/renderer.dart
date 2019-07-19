import "dart:html";

import "../engine/engine.dart";

abstract class Renderer {
    Engine engine;

    Element container;

    void draw([double interpolation]) {

    }
}