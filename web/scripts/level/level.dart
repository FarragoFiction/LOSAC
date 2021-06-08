import "dart:html";
import "dart:math" as Math;

import "package:LoaderLib/Archive.dart";
import "package:yaml/yaml.dart";

import "../engine/engine.dart";
import "../renderer/2d/bounds.dart";
import "../utility/fileutils.dart";
import "connectible.dart";
import "domainmap.dart";
import "levelheightmap.dart";
import "levelobject.dart";
import "pathnode.dart";
import "terrain.dart";

class Level {
    static const String typeDesc = "Level";
    late Engine engine;
    final LevelInfo levelInfo = new LevelInfo();

    Set<SimpleLevelObject> objects = <SimpleLevelObject>{};
    late Iterable<Connectible> connectibles;

    final List<PathNode> pathNodes = <PathNode>[];
    late Iterable<PathNode> connectedNodes;
    final Map<String, SpawnNode> spawners = <String, SpawnNode>{};
    ExitNode? exit;

    late DomainMap domainMap;
    late LevelHeightMap levelHeightMap;
    late LevelHeightMap cameraHeightMap;
    late Rectangle<num> bounds;

    Terrain? terrain;
    double? get gravity => levelInfo.gravityOverride;
    String get name => levelInfo.name;

    Level() {
        connectibles = objects.whereType();
        connectedNodes = pathNodes.where((PathNode node) => !node.isolated);
    }

    void addObject(SimpleLevelObject object) {
        this.objects.add(object);
        object.level = this;
    }

    void derivePathNodes() {
        this.pathNodes.clear();

        this.spawners.clear();
        this.exit = null;

        // starts at 1 because 0 is "no node"
        int id = 1;

        for (final Connectible object in connectibles) {
            object.clearPathNodes();
        }

        for (final Connectible object in connectibles) {
            final Iterable<PathNode> nodes = object.generatePathNodes();

            for(final PathNode node in nodes) {
                node.id = id;
                id++;
                if (id >= 65536) {
                    throw Exception("WHAT ARE YOU DOING?! THIS IS FAR TOO MANY NODES!");
                }
                pathNodes.add(node);

                if (node is SpawnNode) {
                    if (this.spawners.containsKey(node.name)) {
                        throw Exception("Spawner with duplicate name '${node.name}'!");
                    }
                    this.spawners[node.name] = node;
                } else if (node is ExitNode) {
                    if (this.exit != null) {
                        throw Exception("ONLY ONE EXIT, DUNKASS");
                    }
                    this.exit = node;
                }
            }
        }

        for (final Connectible object in connectibles) {
            object.connectPathNodes();
        }
    }

    void prunePathNodes(Iterable<PathNode> toPrune) {
        //LevelUtils.prunePathNodeList(this.pathNodes, toPrune.toList());
        for (final PathNode node in toPrune) {
            node.isolated = true;
        }
    }

    void buildDataMaps() {
        this.bounds = outerBounds(objects.whereType<LevelObject>().map((LevelObject o) => o.bounds));

        domainMap = new DomainMap(bounds.left, bounds.top, bounds.width, bounds.height);
        levelHeightMap = new LevelHeightMap(bounds.left, bounds.top, bounds.width, bounds.height);

        final double diameter = Math.sqrt(bounds.width * bounds.width + bounds.height * bounds.height);
        cameraHeightMap = new LevelHeightMap(bounds.left + (bounds.width * 0.5) - (diameter * 0.5), bounds.top + (bounds.height * 0.5) - (diameter * 0.5), diameter, diameter);

        if (this.terrain != null) {
            cameraHeightMap.processTerrain(terrain!);
        }

        for (final Connectible object in connectibles) {
            final Rectangle<num> bounds = object.bounds;

            final DomainMapRegion domainRegion = domainMap.subRegionForBounds(bounds);
            final LevelHeightMapRegion heightRegion = cameraHeightMap.subRegionForBounds(bounds);

            object.fillDataMaps(domainRegion, heightRegion);
        }

        levelHeightMap.copyDataFrom(cameraHeightMap);
        cameraHeightMap.smoothCameraHeights();
    }

    PathNode? getNodeFromPos(Point<num>? pos) {
        if (pos == null) { return null; }
        final int id = domainMap.getVal(pos.x, pos.y);
        if (id != 0) {
            return pathNodes[id-1];
        }
        return null;
    }


    Future<void> load(YamlMap yaml, String levelName) async {}
    Future<void> postLoad() async {}
}

class LevelInfo {
    static const String typeDesc = "Level Info";
    String name = "Unnamed Level";
    String? author;
    String? description;
    bool hasModdedContent = false;

    int? waveCount;
    double? gravityOverride;

    void load(YamlMap yaml) {
        if (!yaml.containsTypedEntry<String>("name")) {
            throw Exception("Level info is missing a 'name' field");
        }
        this.name = yaml["name"];

        final Set<String> fields = <String>{"name"};
        final DataSetter set = FileUtils.dataSetter(yaml, typeDesc, this.name, fields);

        set("author", (String s) => this.author = s);
        set("description", (String s) => this.description = s);
        set("waveCount", (num n) => this.waveCount = n.toInt());

        set("gravity", (num n) => this.gravityOverride = n.toDouble());

        FileUtils.warnInvalidFields(yaml, typeDesc, this.name, fields);
    }
}