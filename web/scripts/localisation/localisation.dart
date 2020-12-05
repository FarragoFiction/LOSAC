import "package:LoaderLib/Loader.dart";
import 'package:yaml/yaml.dart';

import '../formats/yamlformat.dart';

class LocalisationEngine {
    static const String locPath = "assets/localisation";
    static const String masterFile = "languages.yaml";

    /// Matches sequences between paired $s (group 1), with optional extras after a | inside (group 3)
    static final RegExp _replacementPattern = new RegExp(r"\$([^$|]+)(\|([^$]+))?\$");

    static YAMLFormat yamlFormat = new YAMLFormat();

    Map<String,Language> languages = <String,Language>{};
    Language currentLanguage;

    String translate(String key) {
        if (currentLanguage == null) {
            return key;
        }
        return currentLanguage.translate(key);
    }

    Language get(String name) => languages[name];

    Future<void> initialise() async {
        final YamlDocument languagesFile = await Loader.getResource("$locPath/$masterFile", format: yamlFormat);

        final YamlMap languageDefs = languagesFile.contents.value["languages"];

        // parse languages
        for (final String key in languageDefs.keys) {
            final YamlMap languageDef = languageDefs[key];

            final String path = languageDef["file"];
            final String fallback = languageDef["fallback"];
            final String icon = languageDef["icon"];
            final YamlMap names = languageDef["names"];

            final Map<String,String> nameMap = names.map((dynamic key, dynamic value) => new MapEntry<String,String>(key.toString(), value.toString()));

            final Language language = new Language(path, nameMap, icon, fallbackName: fallback);

            this.languages[key] = language;
        }

        // link up fallback languages from their names
        for (final Language language in languages.values) {
            if (language.fallbackName == null) { continue; }
            if (languages.containsKey(language.fallbackName)) {
                language.fallback = languages[language.fallbackName];
            }
        }

        // if we have a language preference saved, use it
        final String savedLanguage = await getLanguagePreference();
        Language languageToUse;

        if (savedLanguage == null || !languages.containsKey(savedLanguage)) {
            languageToUse = this.languages[languages.keys.first];
        } else {
            languageToUse = this.languages[savedLanguage];
        }

        this.currentLanguage = languageToUse;

        // fire up the selected language
        await languageToUse.load();
    }

    Future<String> getLanguagePreference() async => null; //TODO: hook language up to the save data when that's in
}

class Language {
    final String path;
    Map<String,String> translationTable;
    final Map<String,String> languageNames;
    final String iconPath;
    final String fallbackName;
    Language fallback;

    Language(String this.path, Map<String,String> this.languageNames, String this.iconPath, {String this.fallbackName});

    String translate(String key) {
        if (translationTable.containsKey(key)) {
            return translationTable[key];
        }

        if (fallback != null) {
            return fallback.translate(key);
        }

        return key;
    }

    void unload() {
        this.translationTable = null;
    }

    Future<void> load() async {
        final YamlDocument languageFile = await Loader.getResource("${LocalisationEngine.locPath}/$path", format: LocalisationEngine.yamlFormat);
        final YamlList files = languageFile.contents.value["files"];

        String relativePath = (path.split("/")..removeLast()).join("/");
        if (!relativePath.isEmpty) {
            relativePath = "/$relativePath";
        }

        this.translationTable = <String,String>{};

        // load the contents of the listed files into the translation table
        for (final String fileName in files) {
            final YamlDocument file = await Loader.getResource("${LocalisationEngine.locPath}$relativePath/$fileName", format: LocalisationEngine.yamlFormat);
            final YamlMap entries = file.contents.value["translations"];

            for (final dynamic key in entries.keys) {
                translationTable[key.toString()] = entries[key].toString();
            }
        }

        // replace cross-references until there are none left which can be resolved
        final Set<String> keysToCheck = translationTable.keys.toSet();
        final Map<String,int> iterationCheck = <String,int>{};

        while(keysToCheck.isNotEmpty) {

            final String key = keysToCheck.first;
            keysToCheck.remove(key);

            String value = translationTable[key];

            bool replaced = false;

            value = value.replaceAllMapped(LocalisationEngine._replacementPattern, (Match match) {
                final String replaceKey = match.group(1);

                // skip if we have some kind of attached formatting information
                if (match.group(3) != null) {
                    return match.group(0);
                }

                if (translationTable.containsKey(replaceKey)) {
                    replaced = true;
                    return translationTable[replaceKey];
                }

                return match.group(0);
            });

            translationTable[key] = value;

            if (replaced) {
                keysToCheck.add(key);
            }

            if (iterationCheck.containsKey(key)) {
                iterationCheck[key] = iterationCheck[key] + 1;
                if (iterationCheck[key] > 20) {
                    throw Exception("Localisation resolution took too many attempts. Check key $key for circular references");
                }
            } else {
                iterationCheck[key] = 1;
            }
        }
    }
}