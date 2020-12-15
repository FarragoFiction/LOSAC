import "dart:collection";
import "dart:html";

import "../engine/game.dart";
import "../localisation/localisation.dart";
import "resourcetype.dart";

// ignore: prefer_mixin
class ResourceValue with MapMixin<ResourceType, double> {
    final Map<ResourceType,double> _map = <ResourceType,double>{};

    void add(ResourceValue other, {double multiplier = 1.0}) {
        for (final ResourceType type in other.keys) {
            addResource(type, other[type] * multiplier);
        }
    }

    void subtract(ResourceValue other, {double multiplier = 1.0}) {
        for (final ResourceType type in other.keys) {
            addResource(type, -other[type] * multiplier);
        }
    }

    void addResource(ResourceType type, double value) {
        if (this.containsKey(type)) {
            this[type] = this[type] + value;
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
                final double value = _map[type];
                final Element span = new SpanElement();
                String locKey = "tooltip.cost";
                if (showInsufficient && localisationEngine.engine is Game) {
                    final Game game = localisationEngine.engine;
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
    double operator [](Object key) => _map[key];
    @override
    void operator []=(ResourceType key, double value) => _map[key] = value;
    @override
    void clear() => _map.clear();
    @override
    Iterable<ResourceType> get keys => _map.keys;
    @override
    double remove(Object key) => _map.remove(key);
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
    double operator [](Object key) => _map[key] ?? 0;

    double capped(ResourceType type, double value) => value.clamp(type.minimum, type.maximum);

    bool canAfford(ResourceValue value) {
        for(final ResourceType type in value.keys) {
            if (!canAffordResource(type, value[type])) { return false; }
        }
        return true;
    }

    bool canAffordResource(ResourceType type, double amount) {
        if (!containsKey(type)) { return false; }

        if (this[type] < amount) { return false; }

        return true;
    }
}