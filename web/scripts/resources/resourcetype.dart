import "package:yaml/yaml.dart";

import "../engine/engine.dart";
import "../engine/registry.dart";

export "stockpile.dart";

class ResourceType with Registerable {
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

    factory ResourceType.load(YamlMap yaml) {
        final ResourceType resource = new ResourceType();

        // reject if no name
        if (yaml.containsKey("name")) {
            resource.name = yaml["name"];
        } else {
            Engine.logger.warn("Resource type missing name, skipping");
            return null;
        }

        if (yaml.containsKey("maximum")) {
            try {
                resource.maximum = yaml["maximum"];
            // ignore: avoid_catching_errors
            } on TypeError {
                Engine.logger.warn("Resource type '${resource.name}' ignoring invalid maximum value: ${yaml["maximum"]}");
            }
        }

        if (yaml.containsKey("minimum")) {
            try {
                resource.minimum = yaml["minimum"];
            } catch(e) {
                print(e);
                Engine.logger.warn("Resource type '${resource.name}' ignoring invalid minimum value: ${yaml["minimum"]}");
            }
        }

        return resource;
    }
}