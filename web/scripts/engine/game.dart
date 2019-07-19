import "dart:html";

import "../entities/enemy.dart";
import "../entities/enemytype.dart";
import "../level/endcap.dart";
import "../level/level.dart";
import "../renderer/renderer.dart";
import "engine.dart";
import "spatialhash.dart";

class Game extends Engine {

    SpatialHash towerSelector;
    SpatialHash enemySelector;

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
            ..posVector = spawner.node.posVector;
        this.addObject(enemy);
    }

    void leakEnemy(Enemy enemy) {
        enemy.posVector = enemy.originSpawner.posVector;
        enemy.previousPos = null;
        enemy.rot_angle = enemy.originSpawner.rot_angle;
        enemy.previousRot = null;
        enemy.targetPos = null;
    }

    @override
    void setLevel(Level level) {
        super.setLevel(level);
        final Rectangle<num> levelBounds = level.bounds;

        const int buffer = 20;

        enemySelector = new SpatialHash(20, levelBounds.left - buffer, levelBounds.top - buffer, levelBounds.width + buffer*2, levelBounds.height + buffer*2);
        towerSelector = new SpatialHash(60, levelBounds.left - buffer, levelBounds.top - buffer, levelBounds.width + buffer*2, levelBounds.height + buffer*2);
    }
}