import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "../../engine/game.dart";
import "../../targeting/targetingstrategy.dart";
import "../enemy.dart";
import "../moverentity.dart";
import "../tower.dart";
import "../towertype.dart";

export "beamprojectile.dart";
export "chaserprojectile.dart";
export "interpolatorprojectile.dart";

abstract class Projectile extends MoverEntity {

    final WeaponType projectileType;

    Tower parent;
    Enemy target;

    double age = 0;
    double maxAge = 10; // might need changing elsewhere for very slow and long range projectiles, but why would you go that slow?

    /// Not used by all types of projectile
    B.Vector2 targetPos;

    factory Projectile(Tower parent, Enemy target, B.Vector2 targetPos) => parent.towerType.weapon.spawnProjectile(parent, target, targetPos);

    Projectile.impl(Tower this.parent, Enemy this.target, B.Vector2 this.targetPos) : projectileType = parent.towerType.weapon;

    void impact() {
        applyDamage();
    }

    void applyDamage() {
        final bool hasTarget = this.target != null && !this.target.dead;
        final double damage = parent.towerType.weapon.damage;
        if (projectileType.hasAreaOfEffect) {
            // AOE
            final double radius = projectileType.areaOfEffectRadius; // damage radius
            final double hotspot = projectileType.areaOfEffectHotspot; // full damage fraction of radius
            final double splash = projectileType.areaOfEffectNonTargetMultiplier; // non-main-target damage multiplier
            final Game game = this.engine;
            final Set<Enemy> targets = game.enemySelector.queryRadius(posVector.x, posVector.y, radius);

            if (hotspot < 1) {
                // if there is falloff to consider
                for (final Enemy enemy in targets) {
                    final double dx = enemy.posVector.x - this.posVector.x;
                    final double dy = enemy.posVector.y - this.posVector.y;
                    final double dSquared = dx*dx + dy*dy;

                    if (dSquared <= radius * radius * hotspot * hotspot) {
                        // if the target is inside the hotspot
                        if( hasTarget && enemy == target) {
                            enemy.damage(damage);
                        } else {
                            enemy.damage(damage * splash);
                        }
                    } else {
                        // if the target is in falloff range
                        final double dist = Math.sqrt(dSquared);
                        final double fraction = 1 - (((dist / radius).clamp(0, 1) - hotspot) / (1-hotspot));

                        if( hasTarget && enemy == target) {
                            enemy.damage(damage * fraction);
                        } else {
                            enemy.damage(damage * splash * fraction);
                        }
                    }
                }
            } else {
                // if it's just full damage for all targets
                for (final Enemy enemy in targets) {
                    if( hasTarget && enemy == target) {
                        enemy.damage(damage);
                    } else {
                        enemy.damage(damage * projectileType.areaOfEffectNonTargetMultiplier);
                    }
                }
            }
        } else {
            // single target
            if (hasTarget) {
                target.damage(damage);
            }
        }
    }

    @override
    void logicUpdate([num dt = 0]) {
        super.logicUpdate(dt);
        this.age += dt;
        if (this.age >= this.maxAge) {
            this.kill();
        }
    }
}

abstract class WeaponType {

    final TowerType towerType;

    /// Maximum target count
    /// This isn't the amount of targets which can be hit (since AoE is a thing),
    /// but how many enemies may be independently targeted at once.
    int maxTargets = 1;
    /// Minimum time between shots.
    /// Turreted towers may need more time to line up the shot
    double cooldown = 0.2;
    /// Damage per hit inflicted upon target.
    double damage = 1.0;
    /// Targeting strategies evaluate each enemy in range when targets are being selected.
    /// The enemy/enemies rated highest will be targeted.
    TargetingStrategy<Enemy> targetingStrategy = TowerType.defaultTargetingStrategy;
    /// Weapon range, in pixels at 100% zoom.
    double range = 200;
    /// Weapon projectile speed, in pixels per second at 100% zoom.
    double projectileSpeed = 100;

    /// Number of projectiles in a single burst.
    /// The burst is made of this many projectiles with burstTime times the normal delay between,
    /// followed by this many times 1-burstTime delay before the next burst
    int burst = 5;
    double burstTime = 0.2;

    bool hasAreaOfEffect = false;
    double areaOfEffectRadius = 60;
    /// Fraction of [areaOfEffectRadius] in which targets take full damage
    double areaOfEffectHotspot = 0.2;
    /// Multiplier for damage to secondary targets
    double areaOfEffectNonTargetMultiplier = 1.0;

    WeaponType(TowerType this.towerType) {
        load(null);
    }

    Projectile spawnProjectile(Tower parent, Enemy target, B.Vector2 targetPos);

    void load(Map<dynamic,dynamic> json) {}
}