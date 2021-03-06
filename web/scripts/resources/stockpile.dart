import "dart:collection";
import "dart:html";

import "package:CubeLib/CubeLib.dart" as B;
import "package:yaml/yaml.dart";

import "../engine/game.dart";
import "../engine/registry.dart";
import "../entities/floaterentity.dart";
import "../localisation/localisation.dart";
import "../utility/extensions.dart";
import "../utility/fileutils.dart";
import "resourcetype.dart";

// ignore: prefer_mixin
class ResourceValue with MapMixin<ResourceType, double> {
    final Map<ResourceType,double> _map = <ResourceType,double>{};

    ResourceValue();

    factory ResourceValue.fromYaml(YamlMap yaml, Registry<ResourceType> registry) {
        final ResourceValue val = new ResourceValue();

        for (final String key in yaml.keys) {
            final ResourceType? res = registry.get(key);
            if (res == null) {
                //print("missing resource: $key");
                throw MessageOnlyException("Missing ResourceType: $key");
            } else {
                final dynamic count = yaml[key];
                if (count is num) {
                    val.addResource(res, count.toDouble());
                } else {
                    throw MessageOnlyException("Invalid resource number for '$key': $count");
                }
            }
        }

        return val;
    }

    void add(ResourceValue other, {double multiplier = 1.0}) {
        for (final ResourceType type in other.keys) {
            addResource(type, other[type]! * multiplier);
        }
    }

    void subtract(ResourceValue other, {double multiplier = 1.0}) {
        for (final ResourceType type in other.keys) {
            addResource(type, -other[type]! * multiplier);
        }
    }

    void addResource(ResourceType type, double value) {
        if (this.containsKey(type)) {
            this[type] = this[type]! + value;
        } else {
            this[type] = value;
        }
    }

    bool isZero() {
        for (final double val in _map.values) {
            if (val != 0) { return false; }
        }
        return true;
    }

    void populateTooltip(Element tooltip, LocalisationEngine localisationEngine, {bool showInsufficient = true, bool plus = false, double displayMultiplier = 1.0}) {
        if (isZero()) {
            tooltip.appendFormattedLocalisation("tooltip.cost.nocost", localisationEngine);
        } else {
            final Element resources = new SpanElement()..className="ResourceList";

            for (final ResourceType type in _map.keys) {
                final double value = _map[type]!;
                final Element span = new SpanElement();
                String locKey = "tooltip.cost";
                if (showInsufficient && localisationEngine.engine is Game) {
                    final Game game = localisationEngine.engine as Game;
                    if (!game.resourceStockpile.canAffordResource(type, value)) {
                        locKey = "tooltip.cost.insufficient";
                    }
                }
                span.appendFormattedLocalisation(locKey, localisationEngine, data: <String,String>{
                    "resource" : "resource.${type.getRegistrationKey()}",
                    "amount": "${plus ? "+" : ""}${(value * displayMultiplier).floor().toString()}"
                });
                resources.append(span);
            }

            tooltip.append(resources);
        }
    }

    // map functionality
    @override
    double? operator [](Object? key) => _map[key];
    @override
    void operator []=(ResourceType key, double value) => _map[key] = value;
    @override
    void clear() => _map.clear();
    @override
    Iterable<ResourceType> get keys => _map.keys;
    @override
    double? remove(Object? key) => _map.remove(key);

    ResourceValue operator *(Object other) {
        if (!(other is num)) { throw ArgumentError("Must multiply ResourceValue by a number"); }

        final ResourceValue newVal = new ResourceValue();
        for (final ResourceType type in this.keys) {
            newVal[type] = this[type]! * other;
        }
        return newVal;
    }

    void popup(Game engine, B.Vector2 location, double height, [bool positive = true]) {
        final ResourcePopup floater = new ResourcePopup(this, positive);
        floater..position.setFrom(location)..zPosition = height;
        engine.renderer.addRenderable(floater);
        engine.addEntity(floater);
    }
}

class ResourceStockpile extends ResourceValue {

    @override
    void addResource(ResourceType type, double value) {
        if (this.containsKey(type)) {
            this[type] = capped(type, this[type] + value);
        } else {
            this[type] = capped(type, value);
        }
    }

    @override
    double operator [](Object? key) => _map[key] ?? 0;

    double capped(ResourceType type, double value) => value.clamp(type.minimum, type.maximum);

    bool canAfford(ResourceValue value) {
        for(final ResourceType type in value.keys) {
            if (!canAffordResource(type, value[type]!)) { return false; }
        }
        return true;
    }

    bool canAffordResource(ResourceType type, double amount) {
        if (!containsKey(type)) { return false; }

        if (this[type] < amount) { return false; }

        return true;
    }
}