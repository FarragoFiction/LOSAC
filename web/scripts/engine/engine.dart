import "dart:html";

import "../level/level.dart";
import "../pathfinder/pathfinder.dart";
import "../renderer/renderer.dart";
import "entity.dart";
import "inputhandler.dart";

abstract class Engine {
    Renderer renderer;
    Level level;
    Set<Entity> entities = <Entity>{};
    final Set<Entity> _entityQueue = <Entity>{};

    InputHandler input;

    bool started = false;
    int currentFrame = 0;
    num lastFrameTime = 0;
    double delta = 0;

    double logicStep = 1000 / 20;
    static const int maxLogicStepsPerFrame = 250;

    double fps = 60;
    int framesThisSecond = 0;
    num lastFpsUpdate = 0;
    Element fpsElement;

    Pathfinder pathfinder;

    Element get container => renderer.container;

    Engine(Renderer this.renderer) {
        renderer.engine = this;
        this.input = new InputHandler(this);
    }

    void start() {
        if (started) { return; }
        started = true;

        currentFrame = window.requestAnimationFrame((num timestamp) {
            this.graphicsUpdate();
            lastFrameTime = timestamp;
            lastFpsUpdate = timestamp;
            framesThisSecond = 0;
            currentFrame = window.requestAnimationFrame(mainLoop);
        });
    }

    void stop() {
        if (!started) { return; }
        started = false;
        window.cancelAnimationFrame(currentFrame);
    }

    void mainLoop([num timestamp = 0]) {
        final double frameTime = timestamp - lastFrameTime;

        delta += frameTime;
        lastFrameTime = timestamp;

        /*if (frameTime > timeStep) {

        }*/

        int stepsThisFrame = 0;
        while (delta >= logicStep) {
            stepsThisFrame++;
            if (stepsThisFrame > maxLogicStepsPerFrame) {
                final int skipped = (delta / logicStep).floor();
                delta -= skipped * logicStep;
                print("Skipping $skipped logic steps");
            } else {
                this.logicUpdate(logicStep);
                delta -= logicStep;
            }
        }

        this.graphicsUpdate(delta / logicStep);

        if (timestamp >= lastFpsUpdate + 1000) {
            fps = 0.5 * framesThisSecond + 0.5 * fps;
            lastFpsUpdate = timestamp;
            framesThisSecond = 0;
            if (fpsElement != null) {
                fpsElement.text = fps.round().toString();
            }
        }
        framesThisSecond++;

        currentFrame = window.requestAnimationFrame(mainLoop);
    }

    void logicUpdate([num dt = 0]) {
        final double updateTime = dt / 1000;

        entities.addAll(_entityQueue);
        _entityQueue.clear();

        for (final Entity o in entities) {
            if (o.active) {
                o.logicUpdate(updateTime);
            }
        }
        entities.removeWhere((Entity e) => e.dead);
    }

    void graphicsUpdate([num interpolation = 0]) {
        for (final Entity o in entities) {
            o.renderUpdate(interpolation);
        }
        renderer.draw(interpolation);
    }

    void addEntity(Entity entity) {
        entity.engine = this;
        this._entityQueue.add(entity);
    }

    void setLevel(Level level) {
        this.level = level;
    }

    //input

    Future<void> click(Point<num> worldPos);

}