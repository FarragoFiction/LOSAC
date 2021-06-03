import "package:yaml/yaml.dart";

import "../engine/engine.dart";
import "../engine/registry.dart";
import "../utility/fileutils.dart";

export "stockpile.dart";

class ResourceType with Registerable {
    static const String typeDesc = "Resource Type";

    /// Localisation string
    /// Will resolve patterns such as "resource.(this value).name"
    String name = "default";

    /// Base stockpile cap for this resource.
    double maximum = double.infinity;

    /// Base stockpile minimum value for this resource.
    /// I can't really think of a reason to change this but might as well have it
    double minimum = 0;

    @override
    String getRegistrationKey() => name;

    ResourceType();

    static ResourceType? load(YamlMap yaml, dynamic extras) {
        final ResourceType object = new ResourceType();

        // reject if no name
        if (!FileUtils.setFromDataChecked(yaml, "name", typeDesc, "unknown", (String d) => object.name = d)) {
            Engine.logger.warn("$typeDesc missing name, skipping");
            return null;
        }
        final Set<String> fields = <String>{"name"};
        final DataSetter set = FileUtils.dataSetter(yaml, typeDesc, object.name, fields);

        set("maximum", (dynamic d) => object.maximum = d);
        set("minimum", (dynamic d) => object.minimum = d);

        FileUtils.warnInvalidFields(yaml, typeDesc, object.name, fields);

        return object;
    }

    @override
    String toString() => name;
}