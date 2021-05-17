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

    static EnemyType? load(YamlMap yaml, dynamic? extras) {
        final EnemyType object = new EnemyType();

        // reject if no name
        if (!FileUtils.setFromDataChecked(yaml, "name", typeDesc, "unknown", (String d) => object.name = d)) {
            Engine.logger.warn("$typeDesc missing name, skipping");
            return null;
        }
        final Set<String> fields = <String>{"name"};
        final DataSetter set = FileUtils.dataSetter(yaml, typeDesc, object.name, fields);

        set("health", (dynamic d) => object.health = d);
        set("speed", (dynamic d) => object.speed = d);
        set("turnRate", (dynamic d) => object.turnRate = d);
        set("size", (dynamic d) => object.size = d);

        set("leakDamage", (dynamic d) => object.leakDamage = d);

        FileUtils.warnInvalidFields(yaml, typeDesc, object.name, fields);

        return object;
    }
}