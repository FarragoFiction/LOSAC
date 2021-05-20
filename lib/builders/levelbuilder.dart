import "package:build/build.dart";
import "package:glob/glob.dart";
import "package:path/path.dart" as p;

class LevelBuilder extends Builder {
    @override
    Map<String, List<String>> get buildExtensions {
        return const <String,List<String>>{
            ".level": <String>[".txt"]
        };
    }

    @override
    Future<void> build(BuildStep buildStep) async {
        final AssetId input = buildStep.inputId;

        // extensionless filename
        final String name = p.basenameWithoutExtension(input.path);
        // directory path without file with forward slashes
        final String directory = p.split(p.dirname(input.path)).join("/");

        // the source directory path for the level
        final String dataDir = "$directory/level_$name";

        // glob for finding all files in the data directory
        final Glob assetPath = new Glob("$dataDir/**");

        // map for all the files
        final Map<String,AssetId> files = <String,AssetId>{};

        // populate map with files, keyed by path relative to dataDir
        await for (final AssetId input in buildStep.findAssets(assetPath)) {
            final String rel = p.split(p.relative(input.path, from: dataDir)).join("/");

            files[rel] = input;
        }

        // TODO: make checks here, do stuff with the files, warn and skip if there's stuff missing and the process aborts

        // output file
        final AssetId output = input.changeExtension(".txt");

        await buildStep.writeAsString(output, files.keys.join("\n"));
    }
}