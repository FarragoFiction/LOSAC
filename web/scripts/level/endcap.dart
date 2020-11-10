import "dart:html";

import "package:CubeLib/CubeLib.dart" as B;

import "../renderer/2d/bounds.dart";
import "../renderer/2d/matrix.dart";
import "../utility/extensions.dart";
import "connectible.dart";
import "domainmap.dart";
import "grid.dart";
import "levelobject.dart";
import "pathnode.dart";

abstract class EndCap<TNode extends PathNode> extends LevelObject with HasMatrix, Connectible {

    TNode node;
    Connector connector;

    EndCap() {
        final Connector c = new ConnectorNeutral()..position.x = Grid.cellSize * 0.5..makeBoundsDirty();
        this.connector = c;
        this.addSubObject(c);
    }

    void drawSymbol(CanvasRenderingContext2D ctx, double size);

    @override
    Rectangle<num> calculateBounds() => rectBounds(this, Grid.cellSize, Grid.cellSize);

    @override
    void fillDomainMap(DomainMapRegion map) {
        B.Vector2 mWorld, local;
        const double size = Grid.cellSize * 0.5;
        for (int my = 0; my < map.height; my++) {
            for (int mx = 0; mx < map.width; mx++) {
                mWorld = map.getWorldCoords(mx, my);
                local = this.getLocalPositionFromWorld(mWorld);

                if (local.x >= -size && local.x < size && local.y >= -size && local.y < size) {
                    map.setVal(mx, my, this.node.id);
                }
            }
        }
    }
}

class SpawnerObject extends EndCap<SpawnNode> {

    @override
    Iterable<PathNode> generatePathNodes() {
        final SpawnNode n = new SpawnNode();

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