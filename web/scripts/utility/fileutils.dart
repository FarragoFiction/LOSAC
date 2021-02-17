
import "package:CommonLib/Utility.dart";
import 'package:yaml/yaml.dart';

import "../engine/engine.dart";

abstract class FileUtils {
    static final RegExp invalidFilePattern = new RegExp(r'^(con|prn|aux|nul|com[0-9]|lpt[0-9])$|([<>:"/\\|?*\s])|(\.|\s)$');

    static bool validateFilename(String filename) => !invalidFilePattern.hasMatch(filename);

    static bool setFromData(YamlMap yaml, String key, String typeDesc, String name, Lambda<dynamic> setter) {
        if (yaml.containsKey(key)) {
            try {
                setter(yaml[key]);
            // ignore: avoid_catching_errors
            } on TypeError {
                Engine.logger.warn("$typeDesc '$name' ignoring invalid '$key' value: ${yaml[key]}");
                return false;
            }
            return true;
        }
        return false;
    }
}