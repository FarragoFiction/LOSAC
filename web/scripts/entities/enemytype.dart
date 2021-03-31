import "dart:html";

import "package:yaml/yaml.dart";

import "../engine/engine.dart";
import "../engine/entity.dart";
import "../engine/registry.dart";
import "../utility/fileutils.dart";

class EnemyType with Registerable {
    static const String typeDesc = "Enemy Type";

    /// Localisation string identifier
    /// Will resolve patterns such as "enemy.(this value).name"
    String name = "default";

    SlopeMode slopeMode = SlopeMode.conform;

    double health = 100;
    double speed = 25;
    double turnRate = 1.0;
    double size = 10;

    double leakDamage = 5.0; // 5.0

    @override
    String getRegistrationKey() => name;

    void draw2D(CanvasRenderingContext2D ctx) {
        ctx.fillStyle="#FF0000";

        ctx
            ..beginPath()
            ..moveTo(-size, -size)
            ..lineTo(size, 0)
            ..lineTo(-size, size)
            ..closePath()
            ..fill();
    }

    // This needs to be a method rather than a constructor because it's passed as an argument in the data loader
    // ignore: prefer_constructors_over_static_methods
    static EnemyType? load(YamlMap yaml) {
        final EnemyType object = new EnemyType();

        // reject if no name
        if (!FileUtils.setFromData(yaml, "name", typeDesc, "unknown", (dynamic d) => object.name = d)) {
            Engine.logger.warn("$typeDesc missing name, skipping");
            return null;
        }

        FileUtils.setFromData(yaml, "health", typeDesc, object.name, (dynamic d) => object.health = d);
        FileUtils.setFromData(yaml, "speed", typeDesc, object.name, (dynamic d) => object.speed = d);
        FileUtils.setFromData(yaml, "turnRate", typeDesc, object.name, (dynamic d) => object.turnRate = d);
        FileUtils.setFromData(yaml, "size", typeDesc, object.name, (dynamic d) => object.size = d);

        FileUtils.setFromData(yaml, "leakDamage", typeDesc, object.name, (dynamic d) => object.leakDamage = d);

        return object;
    }
}