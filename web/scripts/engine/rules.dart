
import "package:yaml/yaml.dart";

import "../utility/fileutils.dart";

/// Various game rules, loaded from a file so that they can be altered per map
class RuleSet {
    static const String typeDesc = "Game Rules";

    /// Should enemies return to their entry point when they reach an exit?
    bool enemiesLoop = true;

    /// What fraction of purchase price should be refunded when a tower is sold?
    double sellReturn = 0.75;

    /// Default gravity to use for projectiles if the level doesn't override it
    double gravity = 300;

    /// Maximum life value to start a level with
    double maxLife = 100;


    void load(YamlMap yaml) {
        final Set<String> fields = <String>{};
        final DataSetter set = FileUtils.dataSetter(yaml, typeDesc, "rules", fields);

        set("enemiesLoop", (bool b) => enemiesLoop = b);
        set("sellReturn", (num n) => sellReturn = n.toDouble());
        set("gravity", (num n) => gravity = n.toDouble());
        set("maxLife", (num n) => maxLife = n.toDouble());

        FileUtils.warnInvalidFields(yaml, typeDesc, "rules", fields);
    }
}