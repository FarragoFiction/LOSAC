import "dart:html";
import "dart:math" as Math;

import "package:collection/collection.dart";
import "package:CommonLib/Utility.dart";

import "../engine/entity.dart";
import "../engine/game.dart";
import "../engine/spatialhash.dart";
import "../level/levelobject.dart";
import "../renderer/2d/matrix.dart";
import "../renderer/2d/vector.dart";
import "../utility/towerutils.dart";
import "enemy.dart";
import "projectile.dart";
import "towertype.dart";

class Tower extends LevelObject with Entity, HasMatrix, SpatialHashable<Tower> {
    final TowerType towerType;

    final Set<Enemy> targets = <Enemy>{};

    bool sleeping = false;
    int _sleep = 0;
    int _sleepCounter = 0;
    static const int _sleepFrames = 10;

    double weaponCooldown = 0;
    double turretAngle = 0;
    double prevTurretAngle = 0;
    double targetAngle = 0;
    double turretDrawAngle = 0;

    Tower(TowerType this.towerType);

    void updateTargetAngle() {
        if (targets.isEmpty) {
            // no targets, idle
            targetAngle = turretAngle;
        } else if (targets.length == 1) {
            // we have one target, the angle is simple
            final Vector offset = (getTargetLocation(targets.first) - this.posVector);
            targetAngle = Math.atan2(offset.y, offset.x);
        } else {
            // we have many targets... oh boy
            Vector offset = new Vector.zero();
            for (final Enemy target in targets) {
                offset += (getTargetLocation(target) - this.posVector).norm();
            }
            offset = offset.norm();
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
                        weaponCooldown = towerType.weaponCooldown;
                    } else {
                        // if the angle is greater, delay the attack
                        weaponCooldown = dt;
                    }
                } else {
                    // no turret, just fire
                    for (final Enemy target in targets) {
                        attack(target);
                    }
                    weaponCooldown = towerType.weaponCooldown;
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

    void attack(Enemy target) {
        final Vector targetPos = getTargetLocation(target);
        final Projectile p = new Projectile(this, target, targetPos)
            ..travelSpeed = towerType.projectileSpeed / (targetPos - this.posVector).length;
            //..posVector = this.posVector
            //..velocity = (targetPos - this.posVector).norm() * towerType.projectileSpeed
            //..targetPos = targetPos;
        this.engine.addEntity(p);
    }

    Vector getTargetLocation(Enemy enemy) {
        if (!this.towerType.leadTargets) {
            return enemy.posVector;
        }

        //final Vector v = TowerUtils.intercept(this.posVector, enemy.posVector, Vector(0, -enemy.speed).applyMatrix(enemy.matrix), towerType.projectileSpeed);
        final Vector v = TowerUtils.interceptEnemy(this, enemy);
        if (v != null) {
            //print("lead");
            return v;
        } else {
            //print("cannot reach");
            return enemy.posVector;
        }
    }

    void evaluateTargets() {
        final Game game = this.engine;
        final Set<Enemy> possibleTargets = game.enemySelector.queryRadius(pos_x, pos_y, towerType.leadTargets ? towerType.range * towerType.leadingRangeGraceFactor : towerType.range);

        if (towerType.leadTargets) {
            final double checkRange = towerType.range * towerType.range;
            final double checkRangeLeading = checkRange * towerType.leadingRangeGraceFactor * towerType. leadingRangeGraceFactor;
            possibleTargets.retainWhere((Enemy target) {
                final Vector diff = target.posVector - this.posVector;
                final Vector diffLeading = getTargetLocation(target) - this.posVector;

                final double diffInLeading = diffLeading.x*diffLeading.x + diffLeading.y*diffLeading.y;
                final double diffIn = diff.x*diff.x + diff.y*diff.y;
                return (diffIn <= checkRange && diffInLeading <= checkRangeLeading) || (diffIn <= checkRangeLeading && diffInLeading <= checkRange);
            });
        }

        final Map<Enemy, double> evaluations = <Enemy, double>{};
        double getEval(Enemy enemy) {
            if (!evaluations.containsKey(enemy)) {
                evaluations[enemy] = towerType.targetingStrategy.evaluate(this, enemy);
            }
            return evaluations[enemy];
        }

        if (towerType.maxTargets >= possibleTargets.length) {
            // if we can target at least as many targets as possibles, just target them all!
            targets.clear();
            targets.addAll(possibleTargets);
        } else if (towerType.maxTargets == 1) {
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
                if (best.length > towerType.maxTargets) {
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

    @override
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

            for (final Enemy e in targets) {
                ctx
                    ..fillStyle = "#30FF30"
                    ..strokeStyle = "#30FF30";
                final double ex = (e.pos_x - pos_x) * scaleFactor;
                final double ey = (e.pos_y - pos_y) * scaleFactor;

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
                    final Vector lv = this.getTargetLocation(e);

                    final double lx = (lv.x - pos_x) * scaleFactor;
                    final double ly = (lv.y - pos_y) * scaleFactor;

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
}