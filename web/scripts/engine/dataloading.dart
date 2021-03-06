
import "package:CommonLib/Utility.dart";
import "package:CommonLib/Logging.dart";
import "package:LoaderLib/Loader.dart";
import "package:yaml/yaml.dart" as YAML;

import "../entities/enemytype.dart";
import "../entities/towertype.dart";
import "../resources/resourcetype.dart";
import "../utility/fileutils.dart";
import "engine.dart";

typedef LoaderFunction<T,U> = T? Function(YAML.YamlMap map, U? extras);

abstract class DataLoading {
    static final Logger logger = Engine.logger;

    static Future<void> loadBaseDataFiles(Engine engine) async {
        // First are resource types, enemies and towers rely on these so we have to wait for it to be complete
        await loadDefinitionFile("resources", "Resource Type", ResourceType.load, engine.resourceTypeRegistry.register);

        // Now the path splits into two halves - enemies and towers
        // Neither relies on the other which means we can load them at the same time with some Future funkiness
        // This doesn't really do a whole lot for us because it's still one thread but hey, the http requests can happen concurrently at least
        await Future.wait(<Future<void>>[
            loadDefinitionFile("enemies", "Enemy Type", EnemyType.load, engine.enemyTypeRegistry.register),
            // Here we pass in the resource registry as an extra so that the towers can parse their construction and upgrade costs
            loadDefinitionFile("towers", "Tower Type", TowerType.load, engine.towerTypeRegistry.register, extras: engine.resourceTypeRegistry),
        ]);

        // Process tower types so that their upgrade lists are properly cross-referenced, since the full list isn't available during loading
        TowerType.processAllLoadedData(engine.towerTypeRegistry);
    }

    static Future<void> loadDefinitionFile<T,U>(String subPath, String typeDesc, LoaderFunction<T,U> generator, Lambda<T> consumer, {U? extras}) async {
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
        final List<List<T>?> allFiles = await Future.wait(
            fileList.where(
                (dynamic file) {
                    if((!(file is String)) || (!FileUtils.validateFilename(file))) {
                        logger.warn("Skipping invalid resource type file name: $file");
                        return false;
                    }
                    return true;
                }
            ).whereType<String>().map((String file) => processDefinitionFile(file, subPath, typeDesc, generator, extras))
        );

        // take the collated results and register them in the originally requested order
        for (final List<T>? file in allFiles) {
            if (file == null) { continue; }
            for (final T entry in file) {
                if (entry != null) {
                    consumer(entry);
                }
            }
        }
    }

    static Future<List<T>?> processDefinitionFile<T,U>(String filename, String subPath, String typeDesc, LoaderFunction<T,U> generator, [U? extras]) async {
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
            final T? item = generator(definition, extras);

            if (item != null) {
                output.add(item);
            }
        }

        return output;
    }
}