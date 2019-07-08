import "dart:html";
import "dart:math" as Math;

import "../renderer/2d/matrix.dart";
import "../renderer/2d/vector.dart";
import "connectable.dart";
import "levelobject.dart";
import "pathnode.dart";

enum GridCellState {
    hole,
    clear,
    blocked
}

class Grid extends LevelObject with HasMatrix, Connectable {
    static const num cellSize = 50;

    final int xSize;
    final int ySize;
    final List<GridCell> cells;

    Grid(int this.xSize, int this.ySize) : cells = new List<GridCell>(xSize*ySize) {
        for (int y = 0; y<ySize; y++) {
            for (int x = 0; x < xSize; x++) {
                final int id = y * xSize + x;

                final GridCell cell = new GridCell(this);

                this.cells[id] = cell;
            }
        }
    }

    void updateConnectors() {
        int id;
        GridCell cell;
        for (int y = 0; y<ySize; y++) {
            for (int x = 0; x<xSize; x++) {
                id = y * xSize + x;
                cell = cells[id];

                if (cell.state == GridCellState.hole) { continue; }

                // up
                if (y == 0 || cells[id - xSize].state == GridCellState.hole) {

                }

                // down
                if (y == ySize-1 || cells[id + xSize].state == GridCellState.hole) {

                }

                // left
                if (x == 0 || cells[id - 1].state == GridCellState.hole) {

                }

                // right
                if (x == xSize-1 || cells[id + 1].state == GridCellState.hole) {

                }
            }
        }
    }

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

    @override
    Iterable<PathNode> getPathNodes() => null;
}

class GridCell extends LevelObject {
    final Grid grid;
    GridCellState state = GridCellState.clear;

    PathNode node;

    Connector up;
    Connector down;
    Connector left;
    Connector right;

    GridCell(Grid this.grid);
}