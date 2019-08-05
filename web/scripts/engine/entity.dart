
import "../level/levelobject.dart";
import "engine.dart";

mixin Entity on LevelObject {
    Engine engine;

    bool active = true;
    bool dead = false;

    void logicUpdate([num dt = 0]);

    void renderUpdate([num interpolation = 0]);

    void kill() {
        this.dead = true;
    }
}