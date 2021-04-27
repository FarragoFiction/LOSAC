
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
            } on Exception catch (e) {
                Engine.logger.warn("$typeDesc '$name' error parsing '$key' value '${yaml[key]}': $e");
                return false;
            // ignore: avoid_catching_errors
            } on TypeError {
                Engine.logger.warn("$typeDesc '$name' ignoring invalid '$key' value: ${yaml[key]}");
                return false;
            }
            return true;
        }
        return false;
    }

    static Lambda<dynamic> check<T>(Lambda<T> setter) {
        return (dynamic data) {
            if (data is T) {
                setter(data);
            } else {
                throw TypeError();
            }
        };
    }
}

class MessageOnlyException implements Exception {
    final String message;

    MessageOnlyException(String this.message);

    @override
    String toString() => message;
}