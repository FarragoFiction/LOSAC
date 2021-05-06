
import "package:CommonLib/Utility.dart";
import 'package:yaml/yaml.dart';

import "../engine/engine.dart";

typedef DataSetter = bool Function<T>(String, void Function(T), [String?]);

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

    static bool setFromDataChecked<T>(YamlMap yaml, String key, String typeDesc, String name, Lambda<T> setter) {
        return setFromData(yaml, key, typeDesc, name, check(setter));
    }

    static bool Function<T>(String, Lambda<T>, [String? nameOverride]) dataSetter(YamlMap data, String typeDesc, String name, [Set<String>? fieldList]) {

        bool subFunc<T>(String key, Lambda<T> setter, [String? nameOverride]) {
            // if a field list is provided, add in the key so it can be considered valid later
            fieldList?.add(key);

            return setFromDataChecked(data, key, typeDesc, nameOverride ?? name, setter);
        }

        return subFunc;
    }

    static void warnInvalidFields(YamlMap yaml, String typeDesc, String name, Set<String> fields) {
        for(final String key in yaml.keys) {
            if (!fields.contains(key)) {
                Engine.logger.warn("$typeDesc '$name' has invalid field: $key");
            }
        }
    }

    static T option<T>(String key, Map<String,T> map) {
        if (map.containsKey(key)) {
            return map[key]!;
        }
        throw MessageOnlyException("Invalid option, valid options are [${map.keys.join(", ")}]");
    }
}

class MessageOnlyException implements Exception {
    final String message;

    MessageOnlyException(String this.message);

    @override
    String toString() => message;
}