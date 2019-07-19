import "dart:html";

import "../engine/game.dart";
import "../engine/spatialhash.dart";
import "../entities/targetmoverentity.dart";
import "../level/endcap.dart";
import "../level/pathnode.dart";
import "enemytype.dart";

class Enemy extends TargetMoverEntity with SpatialHashable {

    SpawnerObject originSpawner;

    double health;
    double get maxHealth => enemyType.health;

    final EnemyType enemyType;

    Enemy(EnemyType this.enemyType) : health = enemyType.health, super() {
        this.baseSpeed = enemyType.speed;
        this.turnRate = enemyType.turnRate;
    }

    @override
    void draw2D(CanvasRenderingContext2D ctx) {
        //super.draw2D(ctx);
        enemyType.draw2D(ctx);
    }

    @override
    void logicUpdate([num dt = 0]) {
        if (this.health <= 0) {
            this.dead = true;

            if (this.engine is Game) {
                final Game game = engine;
                game.enemySelector.remove(this);
            }

            return;
        }

        this.updateTarget();

        super.logicUpdate(dt);

        if (this.engine is Game) {
            final Game game = engine;
            game.enemySelector.insert(this);
        }
    }

    @override
    void renderUpdate([num interpolation = 0]) {
        super.renderUpdate(interpolation);
    }

    void updateTarget() {
        final int nodeId = this.engine.level.domainMap.getVal(this.pos_x, this.pos_y);
        if (nodeId == 0) {
            this.targetPos = null;
        } else {
            final PathNode node = this.engine.level.pathNodes[nodeId-1];
            if (node.targetNode == null) {
                this.targetPos = node.posVector;
            } else {
                this.targetPos = node.targetNode.posVector;
            }
            if (engine is Game && node is ExitNode) {
                if (closeToPos(node.pos_x, node.pos_y, this.stoppingThreshold + 1)) {
                    final Game game = engine;
                    game.leakEnemy(this);
                }
            }
        }
    }
}