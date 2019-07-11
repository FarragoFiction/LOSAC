import "dart:html";
import "dart:math" as Math;

import "../renderer/2d/matrix.dart";
import "../renderer/2d/vector.dart";
import "connectible.dart";
import "grid.dart";
import "levelobject.dart";
import "pathnode.dart";

abstract class EndCap<TNode extends PathNode> extends LevelObject with HasMatrix, Connectible {

    TNode node;
    Connector connector;

    EndCap() {
        final Connector c = new ConnectorNeutral()..pos_y = -Grid.cellSize * 0.5;
        this.connector = c;
        this.addSubObject(c);
    }

    @override
    void draw2D(CanvasRenderingContext2D ctx) {
        ctx
            ..strokeStyle="#404040"
            ..strokeRect(-Grid.cellSize/2, -Grid.cellSize/2, Grid.cellSize, Grid.cellSize);

        this.drawSymbol(ctx, Grid.cellSize * 0.4);
    }

    void drawSymbol(CanvasRenderingContext2D ctx, double size);
}

class SpawnerObject extends EndCap<SpawnNode> {

    @override
    Iterable<PathNode> generatePathNodes() {
        final SpawnNode n = new SpawnNode();

        n.posVector = this.getWorldPosition();

        this.node = n;
        this.connector.node = n;

        return <PathNode>[n];
    }

    @override
    void drawSymbol(CanvasRenderingContext2D ctx, double size) {
        ctx.fillStyle = "#BBFFBB";

        ctx
            ..beginPath()
            ..moveTo(-size, size * 0.5)
            ..lineTo(0, -size * 0.75)
            ..lineTo(size, size * 0.5)
            ..closePath()
            ..fill();
    }
}

class ExitObject extends EndCap<ExitNode> {

    @override
    Iterable<PathNode> generatePathNodes() {
        final ExitNode n = new ExitNode();

        n.posVector = this.getWorldPosition();

        this.node = n;
        this.connector.node = n;

        return <PathNode>[n];
    }

    @override
    void drawSymbol(CanvasRenderingContext2D ctx, double size) {
        ctx.fillStyle = "#FFBBBB";

        ctx
            ..beginPath()
            ..moveTo(-size, -size * 0.5)
            ..lineTo(0, size * 0.75)
            ..lineTo(size, -size * 0.5)
            ..closePath()
            ..fill();
    }
}