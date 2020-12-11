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
}