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

    // This needs to be a method rather than a constructor because it's passed as an argument in the data loader
    // ignore: prefer_constructors_over_static_methods
    static ResourceType? load(YamlMap yaml) {
        final ResourceType object = new ResourceType();

        // reject if no name
        if (!FileUtils.setFromData(yaml, "name", typeDesc, "unknown", (dynamic d) => object.name = d)) {
            Engine.logger.warn("$typeDesc missing name, skipping");
            return null;
        }

        FileUtils.setFromData(yaml, "maximum", typeDesc, object.name, (dynamic d) => object.maximum = d);
        FileUtils.setFromData(yaml, "minimum", typeDesc, object.name, (dynamic d) => object.minimum = d);

        return object;
    }
}