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
import "../ui/ui.dart";
import "../utility/extensions.dart";
import "../utility/towerutils.dart";
import "enemy.dart";
import "projectiles/projectile.dart";
import "towertype.dart";

class Tower extends LevelObject with Entity, HasMatrix, SpatialHashable<Tower>, Selectable {
    final TowerType towerType;

    final Set<Enemy> targets = <Enemy>{};

    bool sleeping = false;
    int _sleep = 0;
    int _sleepCounter = 0;
    static const int _sleepFrames = 10;

    double weaponCooldown = 0;
    int currentBurst = 0;
    double turretAngle = 0;
    double prevTurretAngle = 0;
    double targetAngle = 0;
    double turretDrawAngle = 0;

    GridCell gridCell;

    @override
    String get name => "tower.${towerType.name}";

    Tower(TowerType this.towerType);

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
        if (towerType.turreted) {
            // we have a turret, and need to determine if we're angled right
            updateTargetAngle();

            // how far we are off pointing at the enemy
            final double diff = angleDiff(this.turretAngle, targetAngle);

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
                    final double diff = angleDiff(this.turretAngle, targetAngle);

                    if(diff.abs() <= TowerType.fireAngleFuzz || diff.abs() <= towerType.fireAngle) {
                        // if the angle is less than the fire angle limit, attack!
                        for (final Enemy target in targets) {
                            attack(target);
                        }
                        _setCooldown();
                    } else {
                        // if the angle is greater, delay the attack
                        weaponCooldown = dt;
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
            if(sleeping) {
                // set sleep time for a new cycle
                _sleep = _sleepFrames;
            }
        }
    }

    void _setCooldown() {
        if (towerType.weapon.burst <= 1) {
            weaponCooldown = towerType.weapon.cooldown;
        } else {
            currentBurst++;
            if (currentBurst >= towerType.weapon.burst) {
                weaponCooldown = towerType.weapon.cooldown * (1-towerType.weapon.burstTime) * towerType.weapon.burst;
                currentBurst = 0;
            } else {
                weaponCooldown = towerType.weapon.cooldown * towerType.weapon.burstTime;
            }
        }
    }

    void attack(Enemy target) {
        final B.Vector2 targetPos = getTargetLocation(target);
        final Projectile p = new Projectile(this, target, targetPos);
        this.engine.addEntity(p);
    }

    B.Vector2 getTargetLocation(Enemy enemy) {
        if (!this.towerType.leadTargets) {
            return enemy.position.clone();
        }

        //final Vector v = TowerUtils.intercept(this.posVector, enemy.posVector, Vector(0, -enemy.speed).applyMatrix(enemy.matrix), towerType.projectileSpeed);
        final B.Vector2 v = TowerUtils.interceptEnemy(this, enemy);
        if (v != null) {
            //print("lead");
            return v;
        } else {
            //print("cannot reach");
            return enemy.position.clone();
        }
    }

    void evaluateTargets() {
        final Game game = this.engine;
        final Set<Enemy> possibleTargets = game.enemySelector.queryRadius(position.x, position.y, towerType.leadTargets ? towerType.weapon.range * towerType.leadingRangeGraceFactor : towerType.weapon.range).where((Enemy e) => !e.dead).toSet();

        if (towerType.leadTargets) {
            final double checkRange = towerType.weapon.range * towerType.weapon.range;
            final double checkRangeLeading = checkRange * towerType.leadingRangeGraceFactor * towerType. leadingRangeGraceFactor;
            possibleTargets.retainWhere((Enemy target) {
                final B.Vector2 diff = target.position - this.position;
                final B.Vector2 diffLeading = getTargetLocation(target) - this.position;

                final double diffInLeading = diffLeading.x*diffLeading.x + diffLeading.y*diffLeading.y;
                final double diffIn = diff.x*diff.x + diff.y*diff.y;
                return (diffIn <= checkRange && diffInLeading <= checkRangeLeading) || (diffIn <= checkRangeLeading && diffInLeading <= checkRange);
            });
        }

        final Map<Enemy, double> evaluations = <Enemy, double>{};
        double getEval(Enemy enemy) {
            if (!evaluations.containsKey(enemy)) {
                evaluations[enemy] = towerType.weapon.targetingStrategy.evaluate(this, enemy);
            }
            return evaluations[enemy];
        }

        if (towerType.weapon.maxTargets >= possibleTargets.length) {
            // if we can target at least as many targets as possibles, just target them all!
            targets.clear();
            targets.addAll(possibleTargets);
        } else if (towerType.weapon.maxTargets == 1) {
            // if we only want a single target, then we work out the best
            Enemy best;

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
                if (best.length > towerType.weapon.maxTargets) {
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
        this.turretDrawAngle = prevTurretAngle + angleDiff(turretAngle, prevTurretAngle) * interpolation;
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

    @override
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
    }

    @override
    double getZPosition() {
        double z = this.zPosition;
        if (this.gridCell != null) {
            z += this.gridCell.getZPosition();
        }
        return z;
    }

    /*@override
    SelectionDisplay<Tower> createSelectionUI(UIController controller) => null;*/

    @override
    void onSelect() {
        if (this.towerType.weapon != null) {
            this.renderer.rangeIndicator
                ..position.setFrom(this.mesh.position)
                ..scaling.set(this.towerType.weapon.range, 1, this.towerType.weapon.range)
                ..isVisible = true;
        }
    }

    @override
    void onDeselect() {
        this.renderer.rangeIndicator.isVisible = false;
    }
}