import "package:build/build.dart";

import "levelbuilder.dart";

Builder levelBuilder(BuilderOptions options) {
    return new LevelBuilder();
}

PostProcessBuilder levelCleanupBuilder(BuilderOptions options) {
    return new FileDeletingBuilder(const <String>[""], isEnabled: (options.config["enabled"] as bool?) ?? false);
}


