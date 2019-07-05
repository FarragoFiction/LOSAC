import "dart:html";
import "dart:math" as Math;

import "../renderer/2d/matrix.dart";
import "../renderer/2d/vector.dart";
import "levelobject.dart";

enum GridCellState {
    empty
}

class Grid extends LevelObject with HasMatrix {
    static const num cellSize = 50;

    final int xSize;
    final int ySize;
    final List<GridCellState> states;

    Grid(int this.xSize, int this.ySize) : states = new List<GridCellState>.filled(xSize*ySize, GridCellState.empty);

    Vector cellCoords(int x, int y) {
        if (x < 0 || y < 0 || x >= xSize || y >= ySize) {
            return null;
        }
        return new Vector((x + 0.5 - (xSize * 0.5)) * cellSize, (y + 0.5 - (ySize * 0.5)) * cellSize).applyMatrix(matrix);
    }

    Vector cellCoordsById(int id) {
        final Math.Point<int> coord = id2Coords(id);
        return cellCoords(coord.x, coord.y);
    }

    Math.Point<int> id2Coords(int id) => Math.Point<int>(id % xSize, id ~/ xSize);

    @override
    void draw2D(CanvasRenderingContext2D ctx) {
        final double ox = xSize * cellSize * 0.5;
        final double oy = ySize * cellSize * 0.5;

        ctx
            ..lineCap = "round"
            ..strokeStyle = "black";

        for (int x = 0; x<=xSize; x++) {
            ctx..beginPath()..moveTo(x * cellSize - ox, - oy)..lineTo(x * cellSize - ox, oy)..stroke();
        }
        for (int y = 0; y<=ySize; y++) {
            ctx..beginPath()..moveTo(- ox, y * cellSize - oy)..lineTo(ox, y * cellSize - oy)..stroke();
        }
    }
}