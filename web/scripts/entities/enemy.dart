import "dart:html";

import "package:CubeLib/CubeLib.dart" as B;

import "../engine/game.dart";
import "../engine/spatialhash.dart";
import "../entities/targetmoverentity.dart";
import "../level/endcap.dart";
import "../level/pathnode.dart";
import "../utility/extensions.dart";
import "enemytype.dart";
import "terraincollider.dart";

class Enemy extends TargetMoverEntity with SpatialHashable<Enemy>, TerrainCollider {

    SpawnerObject originSpawner;

    double health;
    double get maxHealth => enemyType.health;

    PathNode currentNode;
    PathNode targetNode;

    double _progressToExit;
    bool _progressDirty = true;
    double get progressToExit {
        if (_progressDirty) {
            calculateProgressToExit();
        }
        return _progressToExit;
    }

    final EnemyType enemyType;

    Enemy(EnemyType this.enemyType) : health = enemyType.health, super() {
        this.baseSpeed = enemyType.speed;
        this.turnRate = enemyType.turnRate;
    }

    // drawing level progress for debug
    @override
    void drawUI2D(CanvasRenderingContext2D ctx, double scaleFactor) {
        //ctx.fillStyle = "#FF0000";
        //ctx.fillText(this.progressToExit.toStringAsFixed(3), (enemyType.size) * scaleFactor, - 5);

        if (health < maxHealth) {
            final double width = this.enemyType.size* 2 * scaleFactor;
            const double height = 3;
            ctx
                ..fillStyle = "black"
                ..fillRect(-width*0.5-1, -this.enemyType.size * scaleFactor - height-1, width+2, height+2)
                ..fillStyle = "#FF0000"
                ..fillRect(-width*0.5, -this.enemyType.size * scaleFactor - height, width, height)
                ..fillStyle = "#00FF00"
                ..fillRect(-width*0.5, -this.enemyType.size* scaleFactor - height, width * (health / maxHealth).clamp(0, 1), height);
        }
    }

    @override
    void logicUpdate([num dt = 0]) {
        if (this.health <= 0) {
            this.kill();

            if (this.engine is Game) {
                final Game game = engine;
                game.enemySelector.remove(this);
            }

            return;
        }

        this.updateTarget(dt);

        super.logicUpdate(dt);

        if (this.engine is Game) {
            final Game game = engine;
            game.enemySelector.insert(this);
        }
    }

    @override
    void applyVelocity(num dt) {
        super.applyVelocity(dt);
        _progressDirty = true;
    }

    @override
    void renderUpdate([num interpolation = 0]) {
        super.renderUpdate(interpolation);
    }

    /// used for resetting enemies when they leak, not normal movement
    void setPositionTo(B.Vector2 pos, double angle) {
        posVector.setFrom(pos);
        previousPos = null;
        rot_angle = angle;
        previousRot = null;
        targetPos = null;
        currentNode = null;
        targetNode = null;
        _progressDirty = true;
    }

    // might as well link these two together, not like it's going to be set anywhere
    @override
    double get boundsSize => enemyType.size;

    void updateTarget(num dt) {
        final int nodeId = this.engine.level.domainMap.getVal(this.posVector.x, this.posVector.y);
        if (nodeId == 0) {
            this.currentNode = null;
            this.targetNode = null;
            this.targetPos = null;
        } else {
            final PathNode node = this.engine.level.pathNodes[nodeId-1];
            this.currentNode = node;
            if (node.targetNode == null) {
                this.targetPos = node.posVector;
                this.targetNode = node;
            } else {
                this.targetPos = node.targetNode.posVector;
                this.targetNode = node.targetNode;
            }
            if (engine is Game && node is ExitNode) {
                if (closeToPos(node.posVector.x, node.posVector.y, this.stoppingThreshold + 1)) {
                    final Game game = engine;
                    game.leakEnemy(this);
                }
            }
        }
    }
    
    void calculateProgressToExit() {
        if (this.currentNode != null && this.targetNode != null) {
            // if we have a node and target, then work out how far we are from the exit
            if (this.currentNode == this.targetNode) {
                // if the current and target node are the same, we're basically at the exit unless something fucky is happening
                this._progressToExit = 1 - this.currentNode.distanceToExit;
            } else {
                // if the current and target differ, find the fraction of the path between the two and interpolate!

                final B.Vector2 currentToTarget = targetNode.posVector - currentNode.posVector;
                final B.Vector2 currentToPos = this.posVector - currentNode.posVector;

                final double dot = currentToPos.normalized().dot(currentToTarget.normalized());
                final double fraction = (dot * currentToPos.length()) / currentToTarget.length();

                this._progressToExit = 1 - (currentNode.distanceToExitFraction + (targetNode.distanceToExitFraction - currentNode.distanceToExitFraction) * fraction);
            }
        } else {
            // if we don't have a target or a current node, we're adrift, shouldn't happen except maybe just after spawning
            // in which case the value should end up as zero anyway
            this._progressToExit = 0;
        }
        _progressDirty = false;
    }

    void damage(double amount) {
        this.health -= amount;
        //print("$this, $amount");
    }
}