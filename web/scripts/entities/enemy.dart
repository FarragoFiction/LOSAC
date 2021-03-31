import "dart:html";

import "package:CubeLib/CubeLib.dart" as B;

import "../engine/entity.dart";
import "../engine/game.dart";
import "../engine/spatialhash.dart";
import "../entities/targetmoverentity.dart";
import "../level/endcap.dart";
import "../level/level.dart";
import "../level/pathnode.dart";
import "../level/selectable.dart";
import "../renderer/3d/floateroverlay.dart";
import "../resources/resourcetype.dart";
import "../utility/extensions.dart";
import "../utility/mathutils.dart";
import "enemytype.dart";
import "terraincollider.dart";

class Enemy extends TargetMoverEntity with TerrainEntity, SpatialHashable<Enemy>, TerrainCollider, Selectable, HasFloater {
    @override
    // ignore: overridden_fields
    covariant late Game engine;

    Game get game => engine;

    late SpawnerObject originSpawner;
    ResourceValue? bounty;

    double health;
    double get maxHealth => enemyType.health;

    late double leakDamage;

    PathNode? currentNode;
    PathNode? targetNode;

    late double _progressToExit;
    bool _progressDirty = true;
    double get progressToExit {
        if (_progressDirty) {
            calculateProgressToExit();
        }
        return _progressToExit;
    }

    @override
    String get name => "enemy.${enemyType.name}";

    final EnemyType enemyType;

    Enemy(EnemyType this.enemyType) : health = enemyType.health {
        this.baseSpeed = enemyType.speed;
        this.turnRate = enemyType.turnRate;
        this.slopeMode = enemyType.slopeMode;
        this.leakDamage = enemyType.leakDamage;
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

            final ResourceValue? bounty = this.bounty;
            if (bounty != null) {
                game.resourceStockpile.add(bounty);
                bounty.popup(engine, this.getWorldPosition(), this.getZPosition());
            }

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
    void setPositionTo(B.Vector2 pos, num angle) {
        position.setFrom(pos);
        previousPos.setFrom(pos);
        rot_angle = angle;
        //previousRot = null;
        //targetPos = null;
        currentNode = null;
        targetNode = null;
        _progressDirty = true;
    }

    // might as well link these two together, not like it's going to be set anywhere
    @override
    double get boundsSize => enemyType.size;

    void updateTarget(num dt) {
        final Level? level = this.engine.level;
        if (level == null) { return; }

        final int nodeId = level.domainMap.getVal(this.position.x, this.position.y);
        if (nodeId == 0) {
            this.currentNode = null;
            this.targetNode = null;
            this.targetPos = null;
        } else {
            final PathNode node = level.pathNodes[nodeId-1];
            this.currentNode = node;
            if (node.targetNode == null) {
                this.targetPos = node.position;
                this.targetNode = node;
            } else {
                this.targetPos = node.targetNode!.position;
                this.targetNode = node.targetNode;
            }
            if (engine is Game && node is ExitNode) {
                if (closeToPos(node.position.x, node.position.y, this.stoppingThreshold + 1)) {
                    final Game game = engine;
                    game.leakEnemy(this);
                }
            }
        }
    }
    
    void calculateProgressToExit() {
        final PathNode? currentNode = this.currentNode;
        final PathNode? targetNode = this.targetNode;
        if (currentNode != null && targetNode != null) {
            // if we have a node and target, then work out how far we are from the exit
            if (currentNode == targetNode) {
                // if the current and target node are the same, we're basically at the exit unless something fucky is happening
                this._progressToExit = 1 - currentNode.distanceToExit;
            } else {
                // if the current and target differ, find the fraction of the path between the two and interpolate!

                final B.Vector2 currentToTarget = targetNode.position - currentNode.position;
                final B.Vector2 currentToPos = this.position - currentNode.position;

                final num dot = currentToPos.normalized().dot(currentToTarget.normalized());
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

    /*@override
    SelectionDisplay<Enemy> createSelectionUI(UIController controller) => null;*/

    @override
    bool shouldDrawFloater() => true;//this.health < this.maxHealth;
    @override
    bool drawFloater(B.Vector3 pos, CanvasRenderingContext2D ctx) {
        final num dist = (MathUtils.tempVector1..setFrom(renderer.camera.position)..subtractInPlace(this.getFloaterPos())).length();
        final double size = (this.boundsSize * window.innerHeight! * 2) / dist;
        const double thickness = 4;
        final double healthFraction = (this.health / this.maxHealth);

        final double redness = 1-healthFraction*healthFraction;
        final double greenness = 1 - (1-healthFraction) * (1-healthFraction);

        ctx.shadowColor = "transparent";
        ctx.fillStyle = "rgba(0,0,0,0.5)";
        ctx.fillRect(pos.x - size*0.5, pos.y - size*0.5 - thickness * 0.5, size, thickness);
        ctx.fillStyle = "rgb(${(255*redness).round()},${(255*greenness).round()},0)";
        ctx.fillRect(pos.x - size*0.5, pos.y - size*0.5 - thickness * 0.5, size * healthFraction, thickness);

        return true;
    }

    @override
    double get slopeTestRadius => boundsSize * 0.5;
}