import "dart:html";

import 'package:CommonLib/Logging.dart';
import "package:LoaderLib/Archive.dart";
import "package:LoaderLib/Loader.dart";
import 'package:yaml/yaml.dart' as YAML;

import "../entities/enemy.dart";
import '../entities/enemytype.dart';
import "../entities/towertype.dart";
import "../formats/yamlformat.dart";
import "../level/level.dart";
import "../level/pathnode.dart";
import '../level/selectable.dart';
import '../localisation/localisation.dart';
import "../pathfinder/pathfinder.dart";
import "../renderer/3d/renderer3d.dart";
import "../resources/resourcetype.dart";
import '../ui/ui.dart';
import "../utility/fileutils.dart";
import "dataloading.dart";
import "entity.dart";
import "inputhandler.dart";
import "registry.dart";

enum EngineRunState {
    stopped,
    running,
    paused,
}

abstract class Engine {
    static const String archivePath = "losac/";
    static const String dataPath = "assets/data/";

    static final YAMLFormat yamlFormat = new YAMLFormat();
    static final Logger logger = new Logger("Engine", false);

    DataPack? overrideDataPack;
    late Renderer3D renderer;
    Level? level;
    Set<Entity> entities = <Entity>{};
    final Set<Entity> _entityQueue = <Entity>{};

    final Registry<EnemyType> enemyTypeRegistry = new Registry<EnemyType>();
    final Registry<TowerType> towerTypeRegistry = new Registry<TowerType>();
    final Registry<ResourceType> resourceTypeRegistry = new Registry<ResourceType>();

    late InputHandler input;
    late UIController uiController;
    bool clearSelectionOnRemove = true;

    EngineRunState runState = EngineRunState.stopped;
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
    late Element fpsElement;

    Selectable? selected;
    Selectable? hovering;

    late Pathfinder pathfinder;
    late LocalisationEngine localisation;

    Element get container => renderer.container;

    Engine(Renderer3D this.renderer, Element uiContainer) {
        renderer.engine = this;
        this.input = new InputHandler3D(this);
        this.uiController = new UIController(this, uiContainer);
        this.uiController.tooltip = this.uiController.addComponent(new TooltipComponent(uiController));
        this.renderer.initUiEventHandlers();
        this.localisation = new LocalisationEngine()..engine = this;
    }

    Future<void> initialise() async {
        await localisation.initialise();

        /*for (final ResourceType type in resourceTypeRegistry.mapping.values) {
            final String name = type.getRegistrationKey();
            localisation.formatting.registerIcon("resource.$name", "assets/icons/resources/$name.png");
        }*/

        await Future.wait(resourceTypeRegistry.mapping.values.map((ResourceType type) async {
            final String name = type.getRegistrationKey();
            await localisation.formatting.registerIcon("resource.$name", "assets/icons/resources/$name.png");
        }));
    }

    void start() {
        if (runState != EngineRunState.stopped) { return; }
        runState = EngineRunState.running;

        renderer.runRenderLoop(mainLoop);
    }

    void stop() {
        if (runState == EngineRunState.stopped) { return; }
        runState = EngineRunState.stopped;

        //renderer.stopRenderLoop();
    }

    bool userCanAct() => runState != EngineRunState.stopped;

    void mainLoop(num frameTime) {
        if (runState == EngineRunState.running) {
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

        this.uiController.update();
    }

    void graphicsUpdate([double interpolation = 0]) {
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
        entity.level = this.level;
        this._entityQueue.add(entity);
        this.renderer.addRenderable(entity);
    }

    void removeEntity(Entity entity) {
        this.renderer.removeRenderable(entity);
        if (clearSelectionOnRemove && entity == selected) {
            this.selectObject(null);
        }
        entity.dispose();
    }

    void setLevel(Level level) {
        this.level = level;
        level.engine = this;
        this.renderer.addRenderables(this.level!.objects);
    }

    //input

    Future<void> click(int button, Point<num>? worldPos, Selectable? clickedObject);

    void selectObject(Selectable? selectable) {
        if (selected == null) {
            if (runState == EngineRunState.stopped) { return; }
            if (selectable != null) {
                // select object
                this.selected = selectable;
                this.selected!.onSelect();
            }
        } else {
            if (selectable == null) {
                // deselect
                this.selected?.onDeselect();
                this.selected = null;

            } else if (selectable != selected) {
                // select other object
                this.selected?.onDeselect();
                this.selected = selectable;
                this.selected!.onSelect();
            }
        }
        renderer.clearTowerPreview();
    }

    Future<bool> placementCheck(PathNode node) async {
        final Level? level = this.level;
        if (level == null) { return false; }

        final Set<PathNode> unreachables = new Set<PathNode>.from(await pathfinder.connectivityCheck(level, flipTests: <PathNode>[node]));

        for (final PathNode p in level.spawners) {
            if (unreachables.contains(p)) {
                return false;
            }
        }

        for (final Enemy enemy in this.entities.whereType()) {
            final Set<PathNode>? enemyNodes = enemy.getNodesAtPos();
            if (enemyNodes == null) { continue; }
            for (final PathNode node in enemyNodes) {
                if (unreachables.contains(node)) {
                    return false;
                }
            }
        }

        return true;
    }

    void destroy() {
        for (final Entity entity in this.entities) {
            entity.dispose();
        }
        entities.clear();
        //entities = null;
        renderer.destroy();
        //renderer = null;
        input.destroy();
        //input = null;
        uiController.destroy();
        //uiController = null;
        pathfinder.destroy();
        //pathfinder = null;

        if (overrideDataPack != null) {
            Loader.unmountDataPack(overrideDataPack!);
        }
    }

    //##############################################################################################################################################
    //##############################################################################################################################################
    // Level and Data Loading
    //##############################################################################################################################################
    //##############################################################################################################################################

    Future<void> loadBaseDataFiles() => DataLoading.loadBaseDataFiles(this);

    Future<void> loadLevelArchive(Archive levelArchive) async {
        // Ok, loading a level is a pretty complex process which goes through several stages.
        // Because levels can hold overridden data, we need to check first for a data pack embedded in the level
        // and then load the resources, enemies, towers and level *after* that, since they could be replaced in the data pack.
        // Notably this function *does not* start the simulation running, because we will need to do more stuff for the editor and game.

        // first things first, check for and mount any override datapack included in the level
        // if present, this gets unmounted when the engine is destroyed
        final Archive? dataPackArchive = await levelArchive.getFile("${archivePath}datapack.zip");
        if (dataPackArchive != null) {
            overrideDataPack = Loader.mountDataPack(dataPackArchive.rawArchive);
        }

        // Now we load the default data files, including resources, enemies and towers.
        // These will be overridden if the datapack above contains replacements
        await loadBaseDataFiles();

        final YAML.YamlMap? levelFile = await levelArchive.getFile("${archivePath}level.yaml");
        if (levelFile == null) {
            throw Exception("Level file missing");
        }
    }

}

abstract class MouseButtons {
    static const int left = 0;
    static const int middle = 1;
    static const int right = 2;
}