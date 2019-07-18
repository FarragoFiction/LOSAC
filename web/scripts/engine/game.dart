import "dart:html";

import "../renderer/renderer.dart";
import "engine.dart";

class Game extends Engine {

    Game(Renderer renderer) : super(renderer);

    @override
    void logicUpdate([num dt = 0]) {
        super.logicUpdate(dt);


    }
}