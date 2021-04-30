import "dart:html";
import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;
import "package:yaml/yaml.dart";

import "../engine/engine.dart";
import "../engine/game.dart";
import "../engine/registry.dart";
import "../localisation/localisation.dart";
import "../resources/resourcetype.dart";
import "../targeting/strategies.dart";
import "../ui/ui.dart";
import "../utility/extensions.dart";
import "../utility/fileutils.dart";
import "enemy.dart";
import "projectiles/projectile.dart";

class TowerType with Registerable {
    static const String typeDesc = "Tower Type";

    /// "close enough" angle delta for turrets - within this, we are considered to be pointing at the target
    static const double fireAngleFuzz = 0.01;
    static final TargetingStrategy<Enemy> defaultTargetingStrategy = new ProgressTargetingStrategy() + new StickyTargetingStrategy() * 0.1;

    /// Localisation string
    /// Will resolve patterns such as "tower.(this value).name"
    String name = "default";
    /// Does this tower block the path of enemies?
    bool blocksPath = true;
    /// How long in seconds does this tower take to construct or upgrade to?
    double buildTime = 5.0;
    /// Can this tower be built directly onto a blank cell?
    /// False would suggest it's only an upgrade
    bool buildable = true;
    /// How much does this tower cost to construct, or upgrade to?
    ResourceValue buildCost = new ResourceValue();
    /// Which types of tower can this one be upgraded into?
    Set<TowerType> upgradeList = <TowerType>{};

    /// Does this tower have a turret?
    bool turreted = false;
    /// Does this tower lead targets with its turret?
    bool leadTargets = false;
    /// When leading targets, allow leading points which are within this many times [range].
    double leadingRangeGraceFactor = 1.1;
    /// Turret turn rate per second in radians.
    double turnRate = Math.pi * 0.5;
    /// How close the turret angle needs to be to fire, in radians.
    /// This might be greater than 0 for something like a missile launcher which doesn't require precise aim
    double fireAngle = 1.5;
    /// Added to the z position of the tower to get the spawn height of projectiles
    double weaponHeight = 0.0;

    WeaponType? weapon;

    B.Mesh? mesh;

    void draw2D(CanvasRenderingContext2D ctx) {
        ctx.fillStyle="#A0A0A0";

        const int radius = 22;

        ctx
            ..beginPath()
            ..arc(0,0,radius, 0, Math.pi*2)
            ..closePath()
            ..fill();
    }

    void drawTurret(CanvasRenderingContext2D ctx) {
        ctx.fillStyle="#C0C0C0";

        const int radius = 13;
        const int w = 10;

        ctx
            ..beginPath()
            ..arc(0,0,radius, 0, Math.pi*2)
            ..closePath()
            ..fill()
            ..fillRect(0, -w*0.5, 25, w);
    }

    bool isAffordable(Engine engine) {
        if (engine is Game) {
            final Game game = engine;
            if (!game.resourceStockpile.canAfford(buildCost)) {
                return false;
            }
        }
        return true;
    }

    @override
    String getRegistrationKey() => name;

    String getDisplayName() => "tower.$name.name";

    void populateTooltip(Element tooltip, LocalisationEngine localisationEngine) {
        tooltip.append(new HeadingElement.h1()..appendFormattedLocalisation(this.getDisplayName(), localisationEngine));

        this.buildCost.populateTooltip(tooltip, localisationEngine);
        tooltip..append(new BRElement())..append(new BRElement());

        if (this.weapon != null) {
            this.weapon!.populateTooltip(tooltip, localisationEngine);
            tooltip..append(new BRElement())..append(new BRElement());
        }

        tooltip.appendFormattedLocalisation("tower.${getRegistrationKey()}.description", localisationEngine);
    }

    bool get useBallisticIntercept => (weapon != null) && (weapon!.useBallisticIntercept);

    // Loading stuff ------------------------------------------------------

    // This needs to be a method rather than a constructor because it's passed as an argument in the data loader
    // ignore: prefer_constructors_over_static_methods
    static TowerType? load(YamlMap yaml, Registry<ResourceType>? resourceRegistry) {
        if (resourceRegistry == null) { throw Exception("Resource registry is null somehow"); }

        final _LoadedTowerType object = new _LoadedTowerType();

        // reject if no name
        if (!FileUtils.setFromDataChecked(yaml, "name", typeDesc, "unknown", (String d) => object.name = d)) {
            Engine.logger.warn("$typeDesc missing name, skipping");
            return null;
        }
        final Set<String> fields = <String>{"name"};
        final DataSetter set = FileUtils.dataSetter(yaml, typeDesc, object.name, fields);

        set("blocksPath", (bool b) => object.blocksPath = b);

        set("buildTIme", (num n) => object.buildTime = n.toDouble());
        set("buildable", (bool b) => object.buildable = b);
        set("buildCost", (YamlMap d) => object.buildCost = new ResourceValue.fromYaml(d, resourceRegistry));

        set("upgradeList", (YamlList list) { object.loadingUpgradeList?.addAll(list.map((dynamic element) => element?.toString()).notNull());});

        set("turreted", (bool b) => object.turreted = b);
        set("leadTargets", (bool b) => object.leadTargets = b);
        set("leadingRangeGraceFactor", (num n) => object.leadingRangeGraceFactor = n.toDouble());
        set("turnRate", (num n) => object.turnRate = n.toDouble());
        set("fireAngle", (num n) => object.fireAngle = n.toDouble());
        set("weaponHeight", (num n) => object.weaponHeight = n.toDouble());

        FileUtils.warnInvalidFields(yaml, typeDesc, object.name, fields);

        return object;
    }

    /// Process the tower registry to convert the strings from loading into actual references
    static void processAllLoadedData(Registry<TowerType> registry) {
        for (final TowerType type in registry.mapping.values) {
            if (type is _LoadedTowerType) {
                type.processLoadedData(registry);
            }
        }
    }

}

/// subclass for keeping the loading stuff out of the way
class _LoadedTowerType extends TowerType {
    Set<String>? loadingUpgradeList = <String>{};

    void processLoadedData(Registry<TowerType> registry) {
        if (loadingUpgradeList == null) { return; }

        for (final String key in loadingUpgradeList!) {
            final TowerType? type = registry.get(key);
            if (type != null) {
                upgradeList.add(type);
            } else {
                Engine.logger.warn("Missing ${TowerType.typeDesc} upgrade for '$name': $key");
            }
        }

        // discard the list now that we're done with it
        loadingUpgradeList = null;
    }
}