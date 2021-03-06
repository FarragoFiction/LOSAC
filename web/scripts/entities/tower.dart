import "dart:html";
import "dart:math" as Math;

import "package:collection/collection.dart";
import "package:CommonLib/Utility.dart";
import "package:CubeLib/CubeLib.dart" as B;

import "../engine/entity.dart";
import "../engine/game.dart";
import "../engine/spatialhash.dart";
import "../level/grid.dart";
import "../level/levelobject.dart";
import "../level/selectable.dart";
import "../renderer/2d/matrix.dart";
import "../resources/resourcetype.dart";
import "../ui/ui.dart";
import "../utility/extensions.dart";
import "../utility/towerutils.dart";
import "enemy.dart";
import "projectiles/projectile.dart";
import "towertype.dart";

enum TowerState {
    ready,
    building,
    upgrading,
    selling,
    busy
}

class Tower extends LevelObject with Entity, TerrainEntity, HasMatrix, SpatialHashable<Tower>, Selectable {
    final TowerType towerType;

    final Set<Enemy> targets = <Enemy>{};

    bool sleeping = false;
    int _sleep = 0;
    int _sleepCounter = 0;
    static const int _sleepFrames = 10;

    TowerState state = TowerState.ready;
    double buildTimer = 0;
    TowerType? upgradeTowerType;
    ResourceValue sellValue = new ResourceValue();

    double weaponCooldown = 0;
    int currentBurst = 0;
    num turretAngle = 0;
    num prevTurretAngle = 0;
    num targetAngle = 0;
    num turretDrawAngle = 0;

    late GridCell gridCell;
    @override
    double get slopeTestRadius => Grid.cellSize * 0.5;

    @override
    String get name => "tower.${towerType.name}";

    Tower(TowerType this.towerType) {
        this.sellValue.add(this.towerType.buildCost);
    }

    void updateTargetAngle() {
        if (targets.isEmpty) {
            // no targets, idle
            targetAngle = turretAngle;
        } else if (targets.length == 1) {
            // we have one target, the angle is simple
            final B.Vector2 offset = (getTargetLocation(targets.first) - this.position);
            targetAngle = Math.atan2(offset.y, offset.x);
        } else {
            // we have many targets... oh boy
            B.Vector2 offset = B.Vector2.Zero();
            for (final Enemy target in targets) {
                offset.addInPlace((getTargetLocation(target) - this.position).normalize());
            }
            offset = offset.normalize();
            targetAngle = Math.atan2(offset.y, offset.x);
        }
    }

    @override
    void logicUpdate([num dt = 0]) {
        if (state == TowerState.busy) {
            // busy blocks all action, including timers...
            // this state is for when we're waiting on another thread to complete
        } else if (state == TowerState.ready) {
            // we are built and operational!
            // evaluate weapon targets, sort out buffing, etc

            // only evaluate weapon related stuff if we actually have a weapon...
            if (towerType.weapon != null) {

                if (towerType.turreted) {
                    // we have a turret, and need to determine if we're angled right
                    updateTargetAngle();

                    // how far we are off pointing at the enemy
                    final double diff = angleDiff(this.turretAngle.toDouble(), targetAngle.toDouble()); // TODO: CommonLib angleDiff

                    this.prevTurretAngle = this.turretAngle;

                    this.turretAngle -= diff.sign * Math.min(diff.abs(), towerType.turnRate * dt);
                }

                if (weaponCooldown > 0) {
                    weaponCooldown = Math.max(0, weaponCooldown - dt);
                } else {
                    // if the tower is in a sleep cycle, skip targeting
                    if (sleeping) {
                        if (this._sleep >= 0) {
                            this._sleep--;
                            return;
                        }
                    }
                    evaluateTargets();
                    updateTargetAngle();
                    // line up and shoot at previously targeted enemies
                    if (!targets.isEmpty) {
                        // wakey wakey
                        sleeping = false;
                        _sleepCounter = 0;

                        if (towerType.turreted) {
                            // we have a turret and need to work out if we're pointing the right way to shoot
                            final double diff = angleDiff(this.turretAngle.toDouble(), targetAngle.toDouble()); // TODO: CommonLib angleDiff

                            if (diff.abs() <= TowerType.fireAngleFuzz || diff.abs() <= towerType.fireAngle) {
                                // if the angle is less than the fire angle limit, attack!
                                for (final Enemy target in targets) {
                                    attack(target);
                                }
                                _setCooldown();
                            } else {
                                // if the angle is greater, delay the attack
                                weaponCooldown = dt.toDouble();
                            }
                        } else {
                            // no turret, just fire
                            for (final Enemy target in targets) {
                                attack(target);
                            }
                            _setCooldown();
                        }
                    } else {
                        // count down to sleep cycle
                        _sleepCounter++;
                        if (_sleepCounter > _sleepFrames) {
                            sleeping = true; // ZZzzzz...
                        }
                    }
                    if (sleeping) {
                        // set sleep time for a new cycle
                        _sleep = _sleepFrames;
                    }
                }
            }
        } else {
            // we're in one of the other states, which means we're building, upgrading or selling

            if (buildTimer > 0) {
                // if the build timer is running, decrement it
                buildTimer = Math.max(0, buildTimer - dt);
            } else {
                // if the build timer is at zero, act based on our state

                if (state == TowerState.building) {
                    // a building tower simply completes and becomes ready
                    this.state = TowerState.ready;
                } else if (state == TowerState.selling) {
                    // a selling tower completes its sequence and deconstructs
                    _completeSell();
                } else if (state == TowerState.upgrading) {
                    // an upgrading tower completes its upgrade and is replaced
                    _completeUpgrade();
                }
            }
        }
    }

    void startBuilding() {
        if (state != TowerState.ready) {
            throw Exception("Invalid tower state, cannot start building: $state");
        }

        this.state = TowerState.building;
        this.buildTimer = this.towerType.buildTime;
    }

    void upgrade(TowerType upgradeTo, [bool instant = false]) {
        if (state != TowerState.ready) {
            throw Exception("Invalid tower state, cannot start upgrade: $state");
        }
        upgradeTowerType = upgradeTo;
        this.state = TowerState.upgrading;
        if (instant) {
            _completeUpgrade();
            return;
        }

        this.buildTimer = upgradeTowerType!.buildTime;
    }
    Future<void> _completeUpgrade() async {
        this.state = TowerState.busy;

        final Selectable? selected = engine.selected;
        engine.clearSelectionOnRemove = false;

        final Tower newTower = new Tower(upgradeTowerType!);
        await this.gridCell.replaceTower(newTower);
        newTower.sellValue.add(this.sellValue);

        if (selected == this) {
            engine.selectObject(newTower);
        }
        engine.clearSelectionOnRemove = true;
    }

    void sell([bool instant = false]) {
        if (state != TowerState.ready) {
            throw Exception("Invalid tower state, cannot start sell: $state");
        }
        this.state = TowerState.selling;

        if (instant) {
            _completeSell();
            return;
        }

        this.buildTimer = towerType.buildTime;
    }
    Future<void> _completeSell() async {
        this.state = TowerState.busy;

        await this.gridCell.removeTower();

        if (engine.selected == this) {
            engine.selectObject(this.gridCell);
        }

        if (engine is Game) {
            final Game game = engine as Game;
            game.resourceStockpile.add(sellValue, multiplier: game.rules.sellReturn);

            (sellValue * game.rules.sellReturn).popup(game, this.getWorldPosition(), this.getZPosition());
        }
    }

    Future<void> cancelBuilding() async {
        if (this.state == TowerState.selling || this.state == TowerState.upgrading) {
            // if we're selling or upgrading, we just need to set the status back to ready and it'll be ignored
            this.state = TowerState.ready;
            // refund cost if we were upgrading
            if (engine is Game && this.state == TowerState.upgrading && upgradeTowerType != null) {
                final Game game = engine as Game;
                game.resourceStockpile.add(upgradeTowerType!.buildCost);
                upgradeTowerType!.buildCost.popup(game, getWorldPosition(), getZPosition());
            }
            this.upgradeTowerType = null;
        } else if (this.state == TowerState.building) {
            // if we're building, we need to wait for the cell to sort out cleanup, and block in the meantime
            this.state = TowerState.busy;
            // refund build cost
            if (engine is Game) {
                final Game game = engine as Game;
                game.resourceStockpile.add(towerType.buildCost);
                towerType.buildCost.popup(game, getWorldPosition(), getZPosition());
            }
            await this.gridCell.removeTower();
        }
    }

    /// Build, upgrade or sell progress as a 0-1, for display purposes
    double getProgress() {
        if (state == TowerState.ready) { return 1; }

        if (state == TowerState.selling || state == TowerState.building) {
            return 1 - (buildTimer / towerType.buildTime);
        } else if (state == TowerState.upgrading) {
            return 1 - (buildTimer / upgradeTowerType!.buildTime);
        }

        return 0;
    }

    void _setCooldown() {
        final WeaponType? weapon = towerType.weapon;
        if (weapon == null) { return; }

        if (weapon.burst <= 1) {
            weaponCooldown = weapon.cooldown;
        } else {
            currentBurst++;
            if (currentBurst >= weapon.burst) {
                weaponCooldown = weapon.cooldown * (1-weapon.burstTime) * weapon.burst;
                currentBurst = 0;
            } else {
                weaponCooldown = weapon.cooldown * weapon.burstTime;
            }
        }
    }

    void attack(Enemy target) {
        final B.Vector2 targetPos = getTargetLocation(target);
        final double targetHeight = level!.levelHeightMap.getSmoothVal(targetPos.x, targetPos.y);
        final Projectile p = new Projectile(this, target, targetPos, targetHeight);
        this.engine.addEntity(p);
    }

    B.Vector2 getTargetLocation(Enemy enemy) {
        if (!this.towerType.leadTargets) {
            return enemy.position.clone();
        }

        //final Vector v = TowerUtils.intercept(this.posVector, enemy.posVector, Vector(0, -enemy.speed).applyMatrix(enemy.matrix), towerType.projectileSpeed);
        final B.Vector2? v = TowerUtils.interceptEnemy(this, enemy);
        if (v != null) {
            //print("lead");
            return v;
        } else {
            //print("cannot reach");
            return enemy.position.clone();
        }
    }

    void evaluateTargets() {
        final Game game = this.engine as Game;
        final WeaponType weapon = this.towerType.weapon!;
        final Set<Enemy> possibleTargets = game.enemySelector.queryRadius(position.x, position.y, towerType.leadTargets ? weapon.range * towerType.leadingRangeGraceFactor : weapon.range).where((Enemy e) => !e.dead).toSet();

        if (towerType.leadTargets) {
            final double checkRange = weapon.range * weapon.range;
            final double checkRangeLeading = checkRange * towerType.leadingRangeGraceFactor * towerType. leadingRangeGraceFactor;
            possibleTargets.retainWhere((Enemy target) {
                final B.Vector2 diff = target.position - this.position;
                final B.Vector2 diffLeading = getTargetLocation(target) - this.position;

                final num diffInLeading = diffLeading.x*diffLeading.x + diffLeading.y*diffLeading.y;
                final num diffIn = diff.x*diff.x + diff.y*diff.y;
                return (diffIn <= checkRange && diffInLeading <= checkRangeLeading) || (diffIn <= checkRangeLeading && diffInLeading <= checkRange);
            });
        }

        final Map<Enemy, double> evaluations = <Enemy, double>{};
        double getEval(Enemy enemy) {
            if (!evaluations.containsKey(enemy)) {
                evaluations[enemy] = weapon.targetingStrategy.evaluate(this, enemy);
            }
            return evaluations[enemy]!;
        }

        if (weapon.maxTargets >= possibleTargets.length) {
            // if we can target at least as many targets as possibles, just target them all!
            targets.clear();
            targets.addAll(possibleTargets);
        } else if (weapon.maxTargets == 1) {
            // if we only want a single target, then we work out the best
            Enemy? best;

            for (final Enemy enemy in possibleTargets) {
                if (best == null || getEval(enemy) > getEval(best)) {
                    best = enemy;
                }
            }

            targets.clear();

            if (best != null) {
                targets.add(best);
            }
        } else {
            // if we need many targets, it's time for a heap based queue

            // comparator sorts *lower* priorities first, this is deliberate
            final PriorityQueue<Enemy> best = new PriorityQueue<Enemy>((Enemy a, Enemy b) => getEval(a).compareTo(getEval(b)));

            for (final Enemy enemy in possibleTargets) {
                best.add(enemy);
                // here we remove the first element if the queue is longer than our max targets
                // because of the backwards sorting, this prunes the worst candidate
                if (best.length > weapon.maxTargets) {
                    best.removeFirst();
                }
            }

            targets.clear();

            // shove the list contents into the target set
            while (!best.isEmpty) {
                targets.add(best.removeFirst());
            }
        }
    }

    @override
    void renderUpdate([num interpolation = 0]) {
        this.turretDrawAngle = prevTurretAngle + angleDiff(turretAngle.toDouble(), prevTurretAngle.toDouble()) * interpolation; // TODO: CommonLib angleDiff
    }

    /*@override
    void drawToCanvas(CanvasRenderingContext2D ctx) {
        if (hidden || invisible) { return; }
        ctx.save();

        ctx.translate(pos_x, pos_y);

        if (towerType.turreted) {
            ctx.save();
        }

        ctx.rotate(rot_angle);
        ctx.scale(scale, scale);

        this.draw2D(ctx);

        if (towerType.turreted) {
            ctx.restore();

            ctx.rotate(turretDrawAngle);
            ctx.scale(scale, scale);

            towerType.drawTurret(ctx);
        }

        ctx.restore();
    }*/

    /*@override
    void drawUI2D(CanvasRenderingContext2D ctx, double scaleFactor) {
        ctx
            ..strokeStyle = "#30FF30"
            ..beginPath()
            ..arc(0, 0, towerType.weapon.range * scaleFactor, 0, Math.pi*2)
            ..closePath()
            ..stroke();

        if (this.targets != null && !this.targets.isEmpty) {

            for (final Enemy e in targets) {
                ctx
                    ..fillStyle = "#30FF30"
                    ..strokeStyle = "#30FF30";
                final double ex = (e.position.x - position.x) * scaleFactor;
                final double ey = (e.position.y - position.y) * scaleFactor;

                ctx.fillRect(ex - 2, ey - 2, 4, 4);
                ctx
                    ..beginPath()
                    ..moveTo(0, 0)
                    ..lineTo(ex, ey)
                    ..stroke();

                if (towerType.leadTargets) {
                    ctx
                        ..fillStyle = "#FF90FF"
                        ..strokeStyle = "#FF90FF";
                    final B.Vector2 lv = this.getTargetLocation(e);

                    final double lx = (lv.x - position.x) * scaleFactor;
                    final double ly = (lv.y - position.y) * scaleFactor;

                    ctx.fillRect(lx - 2, ly - 2, 4, 4);
                    ctx
                        ..beginPath()
                        ..moveTo(0, 0)
                        ..lineTo(lx, ly)
                        ..lineTo(ex, ey)
                        ..stroke();
                }
            }
        }

        if (sleeping) {
            ctx.fillStyle = "black";
            ctx.fillRect(-4, -4, 8, 8);
        }
    }*/

    @override
    double getZPosition() {
        return this.zPosition + this.gridCell.getZPosition();
    }

    @override
    SelectionDisplay<Tower> createSelectionUI(UIController controller) => new TowerSelectionDisplay(controller);

    @override
    void onSelect() {
        final B.AbstractMesh? mesh = this.mesh;
        final WeaponType? weapon = this.towerType.weapon;
        if (mesh == null || weapon == null) { return; }

        if (this.towerType.weapon != null) {
            this.renderer.standardAssets.rangeIndicator
                ..position.setFrom(mesh.position)
                ..scaling.set(weapon.range, 1, weapon.range)
                ..isVisible = true;
        }
    }

    @override
    void onDeselect() {
        this.renderer.standardAssets.rangeIndicator.isVisible = false;
    }
}