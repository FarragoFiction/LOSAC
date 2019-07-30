import "dart:html";
import "dart:math" as Math;

import "../engine/entity.dart";
import "../engine/game.dart";
import "../engine/spatialhash.dart";
import "../level/levelobject.dart";
import "../renderer/2d/matrix.dart";
import "enemy.dart";
import "towertype.dart";

class Tower extends LevelObject with Entity, HasMatrix, SpatialHashable<Tower> {
    final TowerType towerType;

    final Set<Enemy> targets = <Enemy>{};

    double weaponCooldown = 0;

    Tower(TowerType this.towerType);

    @override
    void logicUpdate([num dt = 0]) {
        final Game game = this.engine;

        if (weaponCooldown > 0) {
            weaponCooldown = Math.max(0, weaponCooldown - dt);
        }

        //_targetPool = game.enemySelector.queryRadius(pos_x, pos_y, towerType.range);
        //print(_targetPool);
    }

    void evaluateTargets() {

    }

    @override
    void renderUpdate([num interpolation = 0]) {

    }

    @override
    void draw2D(CanvasRenderingContext2D ctx) {
        //super.draw2D(ctx);
        towerType.draw2D(ctx);
    }

    @override
    void drawUI2D(CanvasRenderingContext2D ctx, double scaleFactor) {
        ctx
            ..strokeStyle = "#30FF30"
            ..beginPath()
            ..arc(0, 0, towerType.range * scaleFactor, 0, Math.pi*2)
            ..closePath()
            ..stroke();

        if (this.targets != null && !this.targets.isEmpty) {
            ctx.fillStyle = "#30FF30";
            for (final Enemy e in targets) {
                ctx.fillRect(e.pos_x * scaleFactor - 2 - pos_x, e.pos_y * scaleFactor - 2 - pos_y, 4, 4);
            }
        }
    }
}