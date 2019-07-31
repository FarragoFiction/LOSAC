import "dart:html";
import "dart:math" as Math;

import "../entities/tower.dart";
import "../renderer/2d/bounds.dart";
import "../renderer/2d/matrix.dart";
import "../renderer/2d/vector.dart";

import "connectible.dart";
import "domainmap.dart";
import "levelobject.dart";
import "pathnode.dart";

enum GridCellState {
    hole,
    clear,
    blocked
}

class Grid extends LevelObject with HasMatrix, Connectible {
    static const num cellSize = 50;

    final int xSize;
    final int ySize;
    final List<GridCell> cells;

    final Map<PathNode, GridCell> _cellsFromNodes = <PathNode, GridCell>{};

    Grid(int this.xSize, int this.ySize) : cells = new List<GridCell>(xSize*ySize) {
        final double ox = (xSize - 1) * cellSize * 0.5;
        final double oy = (ySize - 1) * cellSize * 0.5;
        for (int y = 0; y<ySize; y++) {
            for (int x = 0; x < xSize; x++) {
                final int id = y * xSize + x;

                final GridCell cell = new GridCell(this)
                    ..pos_x = x * cellSize - ox
                    ..pos_y = y * cellSize - oy;

                this.cells[id] = cell;
            }
        }

        this.updateConnectors();
    }

    void updateConnectors() {
        clearConnectors();
        int id;
        GridCell cell;
        for (int y = 0; y<ySize; y++) {
            for (int x = 0; x<xSize; x++) {
                id = y * xSize + x;
                cell = cells[id];

                if (cell.state == GridCellState.hole) { continue; }

                // up
                if (y == 0 || cells[id - xSize].state == GridCellState.hole) {
                    final Connector c = new ConnectorPositive()
                        ..pos_x = cell.pos_x
                        ..pos_y = cell.pos_y - cellSize*0.5
                        ..rot_angle = 0;
                    cell.up = c;
                    addSubObject(c);
                }

                // down
                if (y == ySize-1 || cells[id + xSize].state == GridCellState.hole) {
                    final Connector c = new ConnectorPositive()
                        ..pos_x = cell.pos_x
                        ..pos_y = cell.pos_y + cellSize*0.5
                        ..rot_angle = Math.pi;
                    cell.down = c;
                    addSubObject(c);
                }

                // left
                if (x == 0 || cells[id - 1].state == GridCellState.hole) {
                    final Connector c = new ConnectorPositive()
                        ..pos_x = cell.pos_x - cellSize*0.5
                        ..pos_y = cell.pos_y
                        ..rot_angle = -Math.pi * 0.5;
                    cell.left = c;
                    addSubObject(c);
                }

                // right
                if (x == xSize-1 || cells[id + 1].state == GridCellState.hole) {
                    final Connector c = new ConnectorPositive()
                        ..pos_x = cell.pos_x + cellSize*0.5
                        ..pos_y = cell.pos_y
                        ..rot_angle = Math.pi * 0.5;
                    cell.right = c;
                    addSubObject(c);
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
            ..strokeStyle = "#EEEEEE";

        for (int x = 0; x<=xSize; x++) {
            ctx..beginPath()..moveTo(x * cellSize - ox, - oy)..lineTo(x * cellSize - ox, oy)..stroke();
        }
        for (int y = 0; y<=ySize; y++) {
            ctx..beginPath()..moveTo(- ox, y * cellSize - oy)..lineTo(ox, y * cellSize - oy)..stroke();
        }

        for (final GridCell cell in cells) {
            cell.drawToCanvas(ctx);
        }
    }

    @override
    Iterable<PathNode> generatePathNodes() {
        final List<PathNode> nodes = <PathNode>[];

        for(int y = 0; y<ySize; y++) {
            for(int x = 0; x<xSize; x++) {
                final GridCell cell = getCell(x, y);
                if (cell.state == GridCellState.hole) { continue; }

                final PathNode node = new PathNode()
                    ..pathObject = this
                    ..validShortcut = true
                    ..posVector = cell.getWorldPosition()
                    ..blocked = cell.state == GridCellState.blocked;

                _cellsFromNodes[node] = cell;
                cell.setNode(node);

                if (x > 0) {
                    final GridCell left = getCell(x-1, y);
                    if (left.node != null) {
                        cell.node.connectTo(left.node);
                        /*if (y < ySize - 1) {
                            final GridCell down = getCell(x, y+1);
                            final GridCell downLeft = getCell(x-1,y+1);
                            if (down.node != null && downLeft.node != null) {
                                cell.node.connectTo(downLeft.node);
                            }
                        }
                        if (y > 0) {
                            final GridCell up = getCell(x, y-1);
                            final GridCell upLeft = getCell(x-1, y-1);
                            if (up.node != null && upLeft.node != null) {
                                cell.node.connectTo(upLeft.node);
                            }
                        }*/
                    }
                }
                if (y > 0) {
                    final GridCell up = getCell(x, y-1);
                    if (up.node != null) {
                        cell.node.connectTo(up.node);
                    }
                }

                nodes.add(node);
            }
        }

        return nodes;
    }

    @override
    void clearPathNodes() {
        for (final GridCell cell in cells) {
            cell.node = null;
        }

        _cellsFromNodes.clear();

        super.clearPathNodes();
    }

    GridCell getCell(int x, int y) {
        if (x < 0 || x >= xSize || y < 0 || y >= ySize) { return null; }
        return cells[y * xSize + x];
    }

    List<GridCell> getCells(int x1, int y1, int x2, int y2) {
        if (x2 < x1) {
            final int x = x1;
            x1 = x2;
            x2 = x;
        }
        if (y2 < y1) {
            final int y = y1;
            y1 = y2;
            y2 = y;
        }

        final List<GridCell> c = <GridCell>[];

        for (int x=x1; x <= x2; x++) {
            for (int y=y1; y <= y2; y++) {
                c.add(getCell(x, y));
            }
        }

        return c;
    }

    GridCell getCellFromCoords(num x, num y) {
        final double ox = this.xSize * 0.5 * cellSize;
        final double oy = this.ySize * 0.5 * cellSize;

        final int cx = ((x + ox) / cellSize).floor();
        final int cy = ((y + oy) / cellSize).floor();

        return getCell(cx, cy);
    }

    GridCell getCellFromPathNode(PathNode node) {
        if (_cellsFromNodes.containsKey(node)) {
            return _cellsFromNodes[node];
        }
        return null;
    }

    @override
    Rectangle<num> calculateBounds() {
        return rectBounds(this, xSize * cellSize, ySize * cellSize);
    }

    @override
    void fillDomainMap(DomainMapRegion map) {
        Vector mWorld, local;
        for (int my = 0; my < map.height; my++) {
            for (int mx = 0; mx < map.width; mx++) {
                mWorld = map.getWorldCoords(mx, my);
                local = this.getLocalPositionFromWorld(mWorld);
                final GridCell cell = getCellFromCoords(local.x, local.y);
                if (cell != null && cell.node != null) {
                    map.setVal(mx, my, cell.node.id);
                }
            }
        }
    }

    void placeTower(int x, int y, Tower tower) {
        final GridCell cell = getCell(x, y);
        if (cell == null) { throw Exception("invalid cell $x,$y"); }
        final Math.Point<num> worldCoords = cell.getWorldPosition();
        final double rot = cell.getWorldRotation();
        tower
            ..pos_x = worldCoords.x
            ..pos_y = worldCoords.y
            ..rot_angle = rot
            ..turretAngle = rot
            ..prevTurretAngle = rot;
    }
}

class GridCell extends LevelObject {
    final Grid grid;
    GridCellState state = GridCellState.clear;

    PathNode node;

    Connector up;
    Connector down;
    Connector left;
    Connector right;

    GridCell(Grid this.grid) {
        this.parentObject = grid;
    }

    void setNode(PathNode n) {
        this.node = n;
        if (this.up != null) { up.node = n; }
        if (this.down != null) { down.node = n; }
        if (this.left != null) { left.node = n; }
        if (this.right != null) { right.node = n; }

    }

    void setBlocked() {
        this.state = GridCellState.blocked;
        if (this.node != null) {
            node.blocked = true;
        }
    }

    void setClear() {
        this.state = GridCellState.clear;
        if (this.node != null) {
            node.blocked = false;
        }
    }

    void toggleBlocked() {
        if (this.state == GridCellState.clear) {
            setBlocked();
        } else if (this.state == GridCellState.blocked) {
            setClear();
        }
    }

    @override
    void draw2D(CanvasRenderingContext2D ctx) {
        if (this.state == GridCellState.hole) { return; }

        ctx.strokeStyle = "#606060";

        switch(this.state) {
            case GridCellState.clear:
                ctx.fillStyle = "#EEEEEE";
                break;
            case GridCellState.blocked:
                ctx.fillStyle = "#808080";
                break;
            default:
                ctx.fillStyle = "#EEEEEE";
        }

        const double o = -Grid.cellSize * 0.5;
        ctx.fillRect(o, o, Grid.cellSize, Grid.cellSize);
        ctx.strokeRect(o, o, Grid.cellSize, Grid.cellSize);
    }
}