
import "package:CommonLib/Utility.dart";
import "package:CommonLib/Logging.dart";
import "package:LoaderLib/Archive.dart";
import "package:LoaderLib/Loader.dart";
import "package:yaml/yaml.dart" as YAML;

import "../entities/enemytype.dart";
import "../resources/resourcetype.dart";
import "../utility/fileutils.dart";
import "engine.dart";

abstract class DataLoading {
    static final Logger logger = Engine.logger;

    static Future<void> loadBaseDataFiles(Engine engine) async {
        // First are resource types, enemies and towers rely on these so we have to wait for it to be complete
        await loadDefinitionFile("resources", "Resource Type", ResourceType.load, engine.resourceTypeRegistry.register);

        // Now the path splits into two halves - waves rely upon enemies, but towers rely on neither of those
        // This means we can load towers alongside a function which loads enemies and waves sequentially
        await Future.wait(<Future<void>>[
            // load enemies, then waves
            () async {
                await loadDefinitionFile("enemies", "Enemy Type", EnemyType.load, engine.enemyTypeRegistry.register);
                // TODO: load waves here
            }(),
            // load towers at the same time as that's going on
            // TODO: load towers here
        ]);

        // anything which relies on those like... I guess cutscenes or something? go after those
    }

    static Future<void> loadDefinitionFile<T>(String subPath, String typeDesc, Mapping<YAML.YamlMap,T> generator, Lambda<T> consumer) async {
        YAML.YamlDocument files;
        try {
            files = await Loader.getResource("${Engine.dataPath}$subPath/files.yaml", format: Engine.yamlFormat);
        } on LoaderException {
            logger.warn("Could not load $typeDesc file list, skipping loading!");
            return;
        }

        if (!(files.contents.value is YAML.YamlList)) {
            logger.warn("$typeDesc file list is malformed, it should be a list of file names.");
            return;
        }

        final YAML.YamlList fileList = files.contents.value;

        // validate the filenames and fire off each file to be processed asynchronously
        final List<List<T>> allFiles = await Future.wait(
            fileList.where(
                    (dynamic file) {
                    if((!(file is String)) || (!FileUtils.validateFilename(file))) {
                        logger.warn("Skipping invalid resource type file name: $file");
                        return false;
                    }
                    return true;
                }
            ).whereType<String>().map((String file) => processDefinitionFile(file, subPath, typeDesc, generator))
        );

        // take the collated results and register them in the originally requested order
        for (final List<T> file in allFiles) {
            for (final T entry in file) {
                if (entry != null) {
                    consumer(entry);
                }
            }
        }
    }

    static Future<List<T>> processDefinitionFile<T>(String filename, String subPath, String typeDesc, Mapping<YAML.YamlMap,T> generator) async {
        final List<T> output = <T>[];

        YAML.YamlDocument file;
        try {
            file = await Loader.getResource("${Engine.dataPath}$subPath/$filename", format: Engine.yamlFormat);
        } on LoaderException {
            logger.warn("Skipping unloadable $typeDesc file: $filename");
            return null;
        }

        if (!(file.contents.value is YAML.YamlList)) {
            logger.warn("$typeDesc file $filename is malformed, should be a list of $typeDesc objects");
            return null;
        }

        final YAML.YamlList entries = file.contents.value;
        for (final dynamic entry in entries) {
            if (!(entry is YAML.YamlMap)) {
                logger.warn("Skipping malformed $typeDesc definition in $filename, should be a $typeDesc object.");
                continue;
            }

            final YAML.YamlMap definition = entry;
            final T item = generator(definition);

            if (item != null) {
                output.add(item);
            }
        }

        return output;
    }
}