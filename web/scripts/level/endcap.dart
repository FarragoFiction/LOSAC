import "dart:html";

import "package:CubeLib/CubeLib.dart" as B;
import "package:yaml/yaml.dart";

import "../renderer/2d/bounds.dart";
import "../renderer/2d/matrix.dart";
import "../utility/extensions.dart";
import "../utility/fileutils.dart";
import "connectible.dart";
import "domainmap.dart";
import "grid.dart";
import 'levelheightmap.dart';
import "levelobject.dart";
import "pathnode.dart";

abstract class EndCap<TNode extends PathNode> extends LevelObject with HasMatrix, Connectible {

    late TNode node;
    late Connector connector;

    EndCap() {
        final Connector c = new ConnectorNeutral()..position.x = Grid.cellSize * 0.5..makeBoundsDirty();
        this.connector = c;
        this.addSubObject(c);
    }

    void drawSymbol(CanvasRenderingContext2D ctx, double size);

    @override
    Connector? getConnector(String descriptor) => connector;

    @override
    Rectangle<num> calculateBounds() => rectBounds(this, Grid.cellSize, Grid.cellSize);

    @override
    void fillDataMaps(DomainMapRegion domainMap, LevelHeightMapRegion heightMap) {
        B.Vector2 mWorld, local;
        const double size = Grid.cellSize * 0.5;
        for (int my = 0; my < domainMap.height; my++) {
            for (int mx = 0; mx < domainMap.width; mx++) {
                mWorld = domainMap.getWorldCoords(mx, my)!;
                local = this.getLocalPositionFromWorld(mWorld);

                if (local.x >= -size && local.x < size && local.y >= -size && local.y < size) {
                    domainMap.setVal(mx, my, this.node.id);
                    if (this.generateLevelHeightData) {
                        heightMap.setVal(mx, my, this.zPosition);
                    }
                }
            }
        }
    }

    static void _load(EndCap<dynamic> cap, YamlMap yaml, String type, [String? name]) {
        name ??= yaml["name"];
        if (name == null) {
            throw MessageOnlyException("EndCap definition missing name");
        }
        final Set<String> fields = <String>{"name","model"};
        final DataSetter set = FileUtils.dataSetter(yaml, type, name, fields);

        set("x", (num n) => cap.position.x = n.toDouble());
        set("y", (num n) => cap.position.y = n.toDouble());
        set("z", (num n) => cap.zPosition = n.toDouble());
        set("rotation", (num n) => cap.rot_angle = n.toDouble());

        set("affectLevelHeight", (bool b) => cap.generateLevelHeightData = b);

        FileUtils.warnInvalidFields(yaml, type, name, fields);
    }
}

class SpawnerObject extends EndCap<SpawnNode> {
    late final String name;

    SpawnerObject();

    factory SpawnerObject.fromYaml(YamlMap yaml) {
        final SpawnerObject obj = new SpawnerObject();
        EndCap._load(obj, yaml, "Spawner");
        return obj;
    }

    @override
    Iterable<PathNode> generatePathNodes() {
        final SpawnNode n = new SpawnNode()..name = this.name;

        n.position.setFrom(this.getWorldPosition());

        this.node = n;
        n.pathObject = this;
        this.connector.node = n;

        return <PathNode>[n];
    }

    @override
    void drawSymbol(CanvasRenderingContext2D ctx, double size) {
        ctx.fillStyle = "#BBFFBB";

        ctx
            ..beginPath()
            ..moveTo(-size * 0.5, -size)
            ..lineTo(size * 0.75, 0)
            ..lineTo(-size * 0.5, size)
            ..closePath()
            ..fill();
    }
}

class ExitObject extends EndCap<ExitNode> {

    ExitObject();

    factory ExitObject.fromYaml(YamlMap yaml) {
        final ExitObject obj = new ExitObject();
        EndCap._load(obj, yaml, "Exit", "exit");
        return obj;
    }

    @override
    Iterable<PathNode> generatePathNodes() {
        final ExitNode n = new ExitNode();

        n.position.setFrom(this.getWorldPosition());

        this.node = n;
        n.pathObject = this;
        this.connector.node = n;

        return <PathNode>[n];
    }

    @override
    void drawSymbol(CanvasRenderingContext2D ctx, double size) {
        ctx.fillStyle = "#FFBBBB";

        ctx
            ..beginPath()
            ..moveTo(-size * 0.5, -size)
            ..lineTo(size * 0.75, 0)
            ..lineTo(-size * 0.5, size)
            ..closePath()
            ..fill();
    }
}