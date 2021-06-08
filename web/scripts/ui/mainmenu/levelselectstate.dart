import "dart:html";

import "package:ImageLib/Encoding.dart";
import "package:LoaderLib/Archive.dart";
import "package:LoaderLib/Loader.dart";
import "package:path/path.dart" as Path;
import "package:yaml/yaml.dart";

import "../../engine/engine.dart";
import "../../level/level.dart";
import "../../utility/extensions.dart";
import "../../utility/fileutils.dart";
import "mainmenu.dart";

class LevelSelectState extends MenuState {
    static final Element screen = querySelector("#levelselect")!;

    static final ButtonElement backButton = (querySelector("#levelselectback") as ButtonElement);
    static final ButtonElement startButton = (querySelector("#levelselectstart") as ButtonElement);
    static final ButtonElement uploadButton = (querySelector("#levelselectupload") as ButtonElement);
    static final ButtonElement clearUploadButton = (querySelector("#levelselectclear") as ButtonElement);

    static final Element listArea = querySelector("#levellist")!;
    static final Element listOverlay = querySelector("#levellistoverlay")!;
    static final Element infoArea = querySelector("#levelinfo")!;
    static final Element infoError = querySelector("#levelinfoerror")!;

    static final ImageElement uploadPreview = querySelector("#levellistuploadpreview") as ImageElement;

    Element? selectedElement;
    Archive? selectedArchive;

    @override
    String get name => "Level Select";

    LevelSelectState() {
        backButton.onClick.listen((Event e) {
            if(!active) { return; }
            MainMenu.changeState(MainMenu.mainMenu);
        });

        clearUploadButton.onClick.listen((Event e) {
            if (!active) { return; }
            clearUpload();
        });

        startButton.onClick.listen((Event e){
            if(!active) { return; }
            if (selectedArchive == null) { return; }

            MainMenu.game.archiveToLoad = selectedArchive;
            MainMenu.changeState(MainMenu.game);
        });

        uploadButton.replaceWith(FileFormat.loadButton(ArchivePng.format, (ArchivePng object, String filename) { loadFromFile(object); }, caption: "Load from file")..style.display="inline-block");
    }

    @override
    Future<void> enterState() async {
        deselect();
        screen.show();

        populateList(); // specifically NOT awaiting this one
    }

    @override
    Future<void> exitState() async {
        screen.hide();

        listArea.clear();

        deselect();
    }

    Future<void> populateList() async {
        final Map<String,dynamic> fileListFile = await Loader.getResource("levels/files.json", format: Formats.json);
        final List<String> fileList = (fileListFile["files"] as List<dynamic>).whereType<String>().toList()..sort();

        for (final String filename in fileList) {
            late Element box;
            box = new DivElement()
                ..className = "level"
                ..append(new ImageElement(src: "levels/$filename"))
                ..append(new SpanElement()..text = Path.basenameWithoutExtension(filename).replaceAll("_", " "))
                ..onClick.listen((Event e) {
                    if (box.classes.contains("selected")) { return; }

                    deselect();
                    box.classes.add("selected");
                    selectedElement = box;

                    selectListedLevel(filename);
                })
            ;

            listArea.append(box);
        }
    }

    Future<void> selectListedLevel(String filename) async {
        MainMenu.logger.debug("Selecting listed level '$filename'");

        try {
            final ArchivePng file = await Loader.getResource("levels/$filename", format: ArchivePng.format);

            if (file.archive == null) {
                infoError.show();
                MainMenu.logger.warn("'$filename' does not contain an archive");
                return;
            }

            await selectLevel(file.archive!);
        } on LoaderException catch(e) {
            infoError.show();
            MainMenu.logger.warn("Error loading level '$filename': $e");
            return;
        }
    }

    Future<void> loadFromFile(ArchivePng png) async {
        deselect();

        if (png.archive == null) {
            MainMenu.logger.warn("Uploaded file does not contain an archive, aborting");
            infoArea.text = "Uploaded image does not contain a level!";
            return;
        }

        uploadPreview.src = png.canvas.toDataUrl();

        listOverlay.show();
        selectLevel(png.archive!);
    }

    Future<void> selectLevel(Archive archive) async {
        try {
            final YamlMap data = await archive.getYamlFile(Engine.levelInfoFilePath);

            final LevelInfo info = new LevelInfo()
                ..load(data)
                ..hasModdedContent = archive.containsFile(Engine.dataPackFilePath)
            ;

            infoArea
                ..clear()
                ..append(new HeadingElement.h2()..text = info.name)
                ..append(new HeadingElement.h3()..text = "By ${info.author ?? "UNKNOWN"}");

            if (info.hasModdedContent) {
                infoArea.append(new HeadingElement.h3()..text = "Contains modded content");
            }

            if (info.description != null) {
                for (final String text in info.description!.split(r"\n")) {
                    infoArea.append(new ParagraphElement()..text = text);
                }
            } else {
                infoArea.append(new ParagraphElement()..text = "No description provided.");
            }

            selectedArchive = archive;
            startButton.disabled = false;
        } on Exception catch(e) {
            MainMenu.logger.warn("Error processing level archive: $e");

            deselect();
            infoArea.text = "Error loading level archive!";
        }
    }

    void deselect() {
        selectedElement?.classes.remove("selected");
        selectedElement = null;
        selectedArchive = null;

        infoError.hide();

        infoArea
            .clear()
            //..appendText("Select a level")
        ;

        startButton.disabled = true;
    }

    Future<void> clearUpload() async {
        listOverlay.hide();
        deselect();
    }
}