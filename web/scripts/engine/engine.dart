import "dart:html";

import "../level/level.dart";
import "../renderer/renderer.dart";
import "entity.dart";

abstract class Engine {
    Renderer renderer;
    Level level;
    Set<Entity> entities = <Entity>{};

    bool started = false;
    int currentFrame = 0;
    num lastFrameTime = 0;
    double delta = 0;

    double logicStep = 1000 / 20;

    double fps = 60;
    int framesThisSecond = 0;
    num lastFpsUpdate = 0;
    Element fpsElement;

    Engine(Renderer this.renderer) {
        renderer.engine = this;
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

        while (delta >= logicStep) {
            this.logicUpdate(logicStep);
            delta -= logicStep;
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
        final Set<Entity> toRemove = <Entity>{};

        for (final Entity o in entities) {
            if (o.active) {
                o.logicUpdate(updateTime);
            }
            if (o.dead) {
                toRemove.add(o);
            }
        }

        entities.removeAll(toRemove);
    }

    void graphicsUpdate([num interpolation = 0]) {
        for (final Entity o in entities) {
            o.renderUpdate(interpolation);
        }
        renderer.draw(interpolation);
    }

    void addObject(Entity entity) {
        entity.engine = this;
        this.entities.add(entity);
    }
}