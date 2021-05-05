import "dart:html";
import "dart:math" as Math;

import "package:CommonLib/Utility.dart";
import "package:CubeLib/CubeLib.dart" as B;
import "package:yaml/yaml.dart";

import "../../engine/game.dart";
import '../../localisation/localisation.dart';
import "../../targeting/targetingstrategy.dart";
import '../../ui/ui.dart';
import "../../utility/extensions.dart";
import '../../utility/fileutils.dart';
import "../enemy.dart";
import "../moverentity.dart";
import "../tower.dart";
import "../towertype.dart";
import 'beamprojectile.dart';
import 'chaserprojectile.dart';
import 'interpolatorprojectile.dart';

export "beamprojectile.dart";
export "chaserprojectile.dart";
export "interpolatorprojectile.dart";

abstract class Projectile extends MoverEntity {

    final WeaponType projectileType;

    late Tower parent;
    Enemy? target;

    double age = 0;
    double maxAge = 10; // might need changing elsewhere for very slow and long range projectiles, but why would you go that slow?

    double previousZPosition = 0;
    double elevation = 0;
    double previousElevation = 0;

    late B.Vector2 originPos;
    late double originHeight;

    /// Not used by all types of projectile
    late B.Vector2 targetPos;
    late double targetHeight;

    double? drawZ;
    double? drawElevation;

    factory Projectile(Tower parent, Enemy target, B.Vector2 targetPos, double targetHeight) => parent.towerType.weapon!.spawnProjectile(parent, target, targetPos, targetHeight);

    Projectile.impl(Tower this.parent, Enemy this.target, B.Vector2 this.targetPos, double this.targetHeight) : projectileType = parent.towerType.weapon! {
        this.originPos = new B.Vector2()..setFrom(parent.position);
        this.originHeight = parent.getZPosition() + parent.towerType.weaponHeight;
        this.zPosition = originHeight;
        this.previousZPosition = originHeight;
        this.engine = parent.engine; // this is a cheat but it helps
    }

    void impact() {
        applyDamage();
    }

    void applyDamage() {
        final bool hasTarget = this.target != null && !this.target!.dead;
        final double damage = parent.towerType.weapon!.damage;
        if (projectileType.hasAreaOfEffect) {
            // AOE
            final double radius = projectileType.areaOfEffectRadius; // damage radius
            final double hotspot = projectileType.areaOfEffectHotspot; // full damage fraction of radius
            final double splash = projectileType.areaOfEffectNonTargetMultiplier; // non-main-target damage multiplier
            final Game game = this.engine as Game;
            final Set<Enemy> targets = game.enemySelector.queryRadius(position.x, position.y, radius);

            if (hotspot < 1) {
                // if there is falloff to consider
                for (final Enemy enemy in targets) {
                    final num dx = enemy.position.x - this.position.x;
                    final num dy = enemy.position.y - this.position.y;
                    final num dSquared = dx*dx + dy*dy;

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
                target!.damage(damage);
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

    @override
    void renderUpdate([num interpolation = 0]) {
        if (firstDraw) {
            previousPos.setFrom(position);
            previousRot = rot_angle;
            previousZPosition = zPosition;
            drawPos.setFrom(position);
            previousElevation = elevation;
            firstDraw = false;
        }

        final num dx = this.position.x - previousPos.x;
        final num dy = this.position.y - previousPos.y;
        drawPos.set(previousPos.x + dx * interpolation, previousPos.y + dy * interpolation);
        this.drawZ = previousZPosition + (zPosition - previousZPosition) * interpolation;
        this.drawElevation = previousElevation + (elevation - previousElevation) * interpolation;

        final num da = angleDiff(rot_angle.toDouble(), previousRot.toDouble()); // TODO: CommonLib angleDiff
        drawRot = previousRot + da * interpolation;

        this.updateMeshPosition(position: drawPos, height:drawZ, rotation:drawRot);
    }

    @override
    void updateMeshPosition({B.Vector2? position, num? height, num? rotation}) {
        super.updateMeshPosition(position: position, height: height, rotation: rotation);
        this.mesh?.rotation.z = this.drawElevation ?? 0;
    }

    @override
    double getZPosition() => drawZ ?? zPosition;

    void updateElevation() {
        final num movedHorizontal = (position - previousPos).length().abs();
        final double movedVertical = zPosition - previousZPosition;

        elevation = Math.atan2(-movedVertical, movedHorizontal);
    }
}

abstract class WeaponType {
    static const String typeDesc = "Tower Weapon Type";

    late final TowerType towerType;

    final WeaponInfo tooltipData;

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

    bool get useBallisticIntercept => false;
    bool get useBallisticHighArc => false;

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

    //WeaponType(TowerType this.towerType) : tooltipData = new WeaponInfo() {
    WeaponType() : tooltipData = new WeaponInfo() {
        tooltipData.owner = this;
    }

    Projectile spawnProjectile(Tower parent, Enemy target, B.Vector2 targetPos, double targetHeight);

    void populateTooltip(Element tooltip, LocalisationEngine localisationEngine) {
        tooltip.appendFormattedLocalisation("tooltip.weaponstats", localisationEngine, data: this.tooltipData);
    }

    static final Map<String, WeaponType Function()> _loadingTypeMap = <String, WeaponType Function()>{
        //"beam" : () => new BeamWeaponType(),
        "chaser" : () => new ChaserWeaponType(),
        "default" : () => new InterpolatorWeaponType(),
    };

    factory WeaponType.fromYaml(YamlMap yaml, TowerType towerType) {
        String type = "default";
        if (yaml.containsKey("type")) {
            type = yaml["type"].toString();
        }

        if (_loadingTypeMap.containsKey(type)) {
            final WeaponType weapon = _loadingTypeMap[type]!()..towerType = towerType;

            final Set<String> fields = <String>{};
            final DataSetter setter = FileUtils.dataSetter(yaml, typeDesc, towerType.name, fields);

            weapon.loadData(setter);

            FileUtils.warnInvalidFields(yaml, typeDesc, towerType.name, fields);

            return weapon;
        } else {
            throw MessageOnlyException("Invalid weapon type: '$type'. Possible values: [${_loadingTypeMap.keys.join(", ")}]");
        }
    }

    void loadData(DataSetter set) {

        set("maxTargets", (int n) => this.maxTargets = n.toInt());
        set("cooldown", (num n) => this.cooldown = n.toDouble());
        set("damage", (num n) => this.damage = n.toDouble());

        // targeting strategy

        set("range", (num n) => this.range = n.toDouble());
        //projectileSpeed num
        //useBallisticIntercept bool
        //useBallisticHighArc bool
        
        //burst int
        //burstTime num

        //aoe bool
        //aoeRadius num
        //aoeHotspot num
        //TODO: implement a field which sets what the damage should be at the EDGE of aoe
        //aoeSecondaryMult num

    }
}

class WeaponInfo extends DataSurrogate<WeaponType> {
    static const Set<String> _keys = <String>{"dps", "damage", "targets", "cooldown", "rof", "range",
        "projSpeed", "burstTime", "burst", "burstRof", "hasAoe", "aoe", "aoeHotspot", "aoeSecondary"};

    @override
    Iterable<String> get keys => _keys;

    @override
    String? operator [](Object? key) {
        switch(key) {
            case "dps":
                return (owner.damage / owner.cooldown).toStringAsFixed(2);
            case "damage":
                return owner.damage.toStringAsFixed(2);
            case "targets":
                return owner.maxTargets.toString();
            case "cooldown":
                return owner.cooldown.toStringAsFixed(2);
            case "rof":
                return (1/owner.cooldown).toStringAsFixed(2);
            case "range":
                return owner.range.toStringAsFixed(2);
            case "projSpeed":
                return owner.projectileSpeed.toStringAsFixed(2);
            case "burstTime":
                return owner.burstTime.toStringAsFixed(2);
            case "burstRof":
                return (owner.burstTime/owner.cooldown).toStringAsFixed(2);
            case "burst":
                return owner.burst.toString();
            case "hasAoe":
                return owner.hasAreaOfEffect ? "\$yes" : "\$no";
            case "aoe":
                return owner.areaOfEffectRadius.toStringAsFixed(2);
            case "aoeHotspot":
                return owner.areaOfEffectHotspot.toStringAsFixed(2);
            case "aoeSecondary":
                return owner.areaOfEffectNonTargetMultiplier.toStringAsFixed(2);
        }

        return null;
    }
}