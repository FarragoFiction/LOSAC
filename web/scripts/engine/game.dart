import "dart:html";

import "../entities/enemy.dart";
import "../entities/enemytype.dart";
import "../entities/tower.dart";
import "../level/endcap.dart";
import "../level/level.dart";
import '../level/selectable.dart';
import "../renderer/3d/renderer3d.dart";
import "../resources/resourcetype.dart";
import '../ui/ui.dart';
import "../utility/extensions.dart";
import "engine.dart";
import "rules.dart";
import "spatialhash.dart";
import 'wavemanager.dart';

class Game extends Engine {

    late SpatialHash<Tower> towerSelector;
    late SpatialHash<Enemy> enemySelector;

    late UIComponent selectionWindow;
    late UIComponent resourceList;
    late UIComponent lifeDisplay;

    ResourceStockpile resourceStockpile = new ResourceStockpile();
    RuleSet rules = new RuleSet();
    late WaveManager waveManager;

    late double maxLife;
    late double currentLife;


    Game(Renderer3D renderer, Element uiContainer) : super(renderer, uiContainer) {
        this.selectionWindow = uiController.addComponent(new SelectionWindow(uiController));
        uiController.addComponent(new WaveTracker(uiController));
        this.waveManager = new WaveManager(this);
    }

    @override
    Future<void> initialise() async {
        await super.initialise();

        this.maxLife = rules.maxLife;
        this.currentLife = rules.maxLife.toDouble();

        this.resourceList = uiController.addComponent(new ResourceList(uiController));
        this.lifeDisplay = uiController.addComponent(new LifeDisplay(uiController));
    }

    @override
    void logicUpdate([num dt = 0]) {
        super.logicUpdate(dt);

        final double updateTime = dt / 1000;

        waveManager.update(updateTime);
    }

    Enemy spawnEnemy(EnemyType enemyType, SpawnerObject spawner) {
        final Enemy enemy = new Enemy(enemyType);
        enemy
            ..originSpawner = spawner
            ..rot_angle = spawner.rot_angle
            ..position.setFrom(spawner.node.position);
        this.addEntity(enemy);
        return enemy;
    }

    void leakEnemy(Enemy enemy) {
        this.addLife(-enemy.leakDamage);

        if (runState == EngineRunState.stopped) { return; } // don't reset position if this is the deathblow
        enemy.setPositionTo(enemy.originSpawner.position, enemy.originSpawner.rot_angle);
    }

    void addLife(double amount) {
        currentLife = (currentLife + amount).clamp(0.0, maxLife);
        if (currentLife <= 0) {
            this.lose();
        }
    }

    void lose() {
        print("defeat!");

        _endGame();
        uiController.addComponent(new GameOverBox(uiController, false));
    }

    void win() {
        print("victory!");

        _endGame();
        uiController.addComponent(new GameOverBox(uiController, true));
    }

    void _endGame() {
        runState = EngineRunState.stopped;
        selectObject(null);
    }

    @override
    void setLevel(Level level) {
        super.setLevel(level);
        final Rectangle<num> levelBounds = level.bounds;

        const int buffer = 20;

        enemySelector = new SpatialHash<Enemy>(50, levelBounds.left - buffer, levelBounds.top - buffer, levelBounds.width + buffer*2, levelBounds.height + buffer*2);
        towerSelector = new SpatialHash<Tower>(100, levelBounds.left - buffer, levelBounds.top - buffer, levelBounds.width + buffer*2, levelBounds.height + buffer*2);
    }

    @override
    Future<void> click(int button, Point<num>? worldPos, Selectable? clickedObject) async {
        if (button == MouseButtons.left) {
            this.selectObject(clickedObject);
        } else if (button == MouseButtons.right) {
            this.selectObject(null);
        }

        /*final PathNode node = level.getNodeFromPos(worldPos);

        print("click! $worldPos $node $clickedObject");

        if (node != null) {
            final PathNodeObject pathObj = node.pathObject;
            print(pathObj);

            if (pathObj is Grid) {
                final Grid grid = pathObj;
                final bool valid = await placementCheck(node);

                if (valid) {
                    print("YEP");
                    await pathfinder.flipNodeState(<PathNode>[node]);
                    final GridCell cell = grid.getCellFromPathNode(node);
                    cell.toggleBlocked();
                    await pathfinder.recalculatePathData(level);
                } else {
                    print("NOPE");
                }
            }
        }*/
    }



    @override
    void selectObject(Selectable? selectable) {
        super.selectObject(selectable);
        selectionWindow.updateAndPropagate();
    }

    @override
    void destroy() {
        super.destroy();
        //selectionWindow = null;
        //resourceList = null;
        //lifeDisplay = null;
    }
}