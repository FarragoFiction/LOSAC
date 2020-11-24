import "dart:html";

import "../level/level.dart";
import '../level/levelobject.dart';
import '../level/selectable.dart';
import "../pathfinder/pathfinder.dart";
import "../renderer/renderer.dart";
import '../ui/ui.dart';
import "entity.dart";
import "inputhandler.dart";

abstract class Engine {
    Renderer renderer;
    Level level;
    Set<Entity> entities = <Entity>{};
    final Set<Entity> _entityQueue = <Entity>{};

    InputHandler input;
    UIController uiController;

    bool started = false;
    int currentFrame = 0;
    num lastFrameTime = 0;
    double delta = 0;

    double logicStep = 1000 / 20;
    static const int maxLogicStepsPerFrame = 250;
    int selectionUpdateSteps = 0;
    int stepsPerSelectionUpdate = 4;

    double fps = 60;
    int framesThisSecond = 0;
    num lastFpsUpdate = 0;
    Element fpsElement;

    Selectable selected;
    Selectable hovering;

    Pathfinder pathfinder;

    Element get container => renderer.container;

    Engine(Renderer this.renderer, Element uiContainer) {
        renderer.engine = this;
        this.input = new InputHandler3D(this);
        this.uiController = new UIController(this, uiContainer);
        this.renderer.initUiEventHandlers();
    }

    void start() {
        if (started) { return; }
        started = true;

        renderer.runRenderLoop(mainLoop);
    }

    void stop() {
        if (!started) { return; }
        started = false;
        window.cancelAnimationFrame(currentFrame);
    }

    void mainLoop(double frameTime) {
        delta += frameTime;

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

        /*if (timestamp >= lastFpsUpdate + 1000) {
            fps = 0.5 * framesThisSecond + 0.5 * fps;
            lastFpsUpdate = timestamp;
            framesThisSecond = 0;
            if (fpsElement != null) {
                fpsElement.text = fps.round().toString();
            }
        }
        framesThisSecond++;*/

        //currentFrame = window.requestAnimationFrame(mainLoop);

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
        entities.removeWhere((Entity e) {
            if (e.dead) {
                this.removeEntity(e);
                return true;
            }
            return false;
        });
        /*selectionUpdateSteps++;
        if (selectionUpdateSteps >= stepsPerSelectionUpdate) {
            this.input.updateMouseOver();
            selectionUpdateSteps = 0;
        }*/
    }

    void graphicsUpdate([num interpolation = 0]) {
        for (final Entity o in entities) {
            o.renderUpdate(interpolation);
        }
        renderer.draw(interpolation);
        selectionUpdateSteps++;
        if (selectionUpdateSteps >= stepsPerSelectionUpdate) {
            this.hovering = renderer.getSelectableAtScreenPos()?.selectable;
            selectionUpdateSteps = 0;
        }
    }

    void addEntity(Entity entity) {
        entity.engine = this;
        this._entityQueue.add(entity);
        this.renderer.addRenderable(entity);
    }

    void removeEntity(Entity entity) {
        this.renderer.removeRenderable(entity);
        if (entity == selected) {
            this.selectObject(null);
        }
    }

    void setLevel(Level level) {
        this.level = level;
        this.renderer.addRenderables(this.level.objects);
    }

    //input

    Future<void> click(int button, Point<num> worldPos, Selectable clickedObject);

    void selectObject(Selectable selectable) {
        if (selected == null) {
            if (selectable != null) {
                // select object
                this.selected = selectable;
                //print("selected: $selectable");
            }
        } else {
            if (selectable == null) {
                // deselect
                this.selected = null;
                //print("deselect");
            } else if (selectable != selected) {
                // select other object
                this.selected = selectable;
                //print("selection changed: $selectable");
            }
        }
    }
}

abstract class MouseButtons {
    static const int left = 0;
    static const int middle = 1;
    static const int right = 2;
}