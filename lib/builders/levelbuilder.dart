
import 'dart:typed_data';

import "package:archive/archive.dart";
import "package:build/build.dart";
import "package:glob/glob.dart";
import "package:path/path.dart" as p;

// ignore: implementation_imports
import "package:ImageLib/src/encoding/pngcontainer.dart";



class LevelBuilder extends Builder {
    static final ZipEncoder _encoder = new ZipEncoder();
    static const String thumbnailFile = "preview.png";
    static const String blockName = "ffDb";
    static const String subFolderName = "losac";

    @override
    Map<String, List<String>> get buildExtensions {
        return const <String,List<String>>{
            ".level": <String>[".png"]
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

        if (!files.containsKey(thumbnailFile)) {
            log.warning("Level '$name' is missing $thumbnailFile, skipping");
            return;
        }

        // preview image
        final AssetId preview = files[thumbnailFile]!;
        final Uint8List previewBytes = (await buildStep.readAsBytes(preview)) as Uint8List;

        // get the image
        final List<PngBlock> blocks = await PngContainer.fromBytes(previewBytes.buffer);

        // put all the files into an archive
        final Archive archive = new Archive();

        for (final String path in files.keys) {
            final AssetId asset = files[path]!;

            // don't include our thumbnail in the final thing, we don't need that twice...
            if (asset == preview) { continue; }

            final Uint8List file = (await buildStep.readAsBytes(asset)) as Uint8List;

            archive.addFile(new ArchiveFile("$subFolderName/$path", file.lengthInBytes, file));
        }

        // add the archive as a zip in our block
        blocks.insert(blocks.length-1, new PngBlock(blockName, (_encoder.encode(archive) as Uint8List)));

        // output file
        final AssetId output = input.changeExtension(".png");

        // output the png with archive embedded
        await buildStep.writeAsBytes(output, (await PngContainer.toBytes(blocks)).asUint8List());
    }
}