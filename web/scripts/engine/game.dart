import "dart:html";

import "../entities/enemy.dart";
import "../entities/enemytype.dart";
import "../entities/tower.dart";
import "../level/endcap.dart";
import "../level/grid.dart";
import "../level/level.dart";
import '../level/levelobject.dart';
import "../level/pathnode.dart";
import "../renderer/renderer.dart";
import "../utility/extensions.dart";
import "engine.dart";
import "spatialhash.dart";

class Game extends Engine {

    SpatialHash<Tower> towerSelector;
    SpatialHash<Enemy> enemySelector;

    Game(Renderer renderer) : super(renderer);

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
    Future<void> click(Point<num> worldPos, SimpleLevelObject clickedObject) async {
        final PathNode node = level.getNodeFromPos(worldPos);

        print("click! $worldPos $node $clickedObject");

        /*if (node != null) {
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

    Future<bool> placementCheck(PathNode node) async {
        final Set<PathNode> unreachables = new Set<PathNode>.from(await pathfinder.connectivityCheck(level, flipTests: <PathNode>[node]));

        for (final PathNode p in level.spawners) {
            if (unreachables.contains(p)) {
                return false;
            }
        }

        for (final Enemy enemy in this.entities.whereType()) {
            final Set<PathNode> enemyNodes = enemy.getNodesAtPos();
            for (final PathNode node in enemyNodes) {
                if (unreachables.contains(node)) {
                    return false;
                }
            }
        }

        return true;
    }
}