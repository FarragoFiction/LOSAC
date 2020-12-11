import "dart:html";

import "../entities/enemy.dart";
import "../entities/enemytype.dart";
import "../entities/tower.dart";
import "../level/endcap.dart";
import "../level/level.dart";
import '../level/selectable.dart';
import "../renderer/renderer.dart";
import "../resources/resourcetype.dart";
import '../ui/ui.dart';
import "../utility/extensions.dart";
import "engine.dart";
import "spatialhash.dart";

class Game extends Engine {

    SpatialHash<Tower> towerSelector;
    SpatialHash<Enemy> enemySelector;

    UIComponent selectionWindow;
    UIComponent resourceList;

    ResourceStockpile resourceStockpile = new ResourceStockpile();

    Game(Renderer renderer, Element uiContainer) : super(renderer, uiContainer) {
        this.selectionWindow = uiController.addComponent(new SelectionWindow(uiController));
    }

    @override
    Future<void> initialise() async {
        await super.initialise();

        this.resourceList = uiController.addComponent(new ResourceList(uiController));
    }

    @override
    void logicUpdate([num dt = 0]) {
        super.logicUpdate(dt);


    }

    void spawnEnemy(EnemyType enemyType, SpawnerObject spawner) {
        final Enemy enemy = new Enemy(enemyType);
        enemy
            ..originSpawner = spawner
            ..rot_angle = spawner.rot_angle
            ..position.setFrom(spawner.node.position);
        this.addEntity(enemy);
    }

    void leakEnemy(Enemy enemy) {
        enemy.setPositionTo(enemy.originSpawner.position, enemy.originSpawner.rot_angle);
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
    Future<void> click(int button, Point<num> worldPos, Selectable clickedObject) async {
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
    void selectObject(Selectable selectable) {
        super.selectObject(selectable);
        selectionWindow.updateAndPropagate();
    }
}