import "dart:html";
import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;
import "package:yaml/yaml.dart";

import "../engine/engine.dart";
import "../engine/game.dart";
import "../entities/tower.dart";
import "../renderer/2d/bounds.dart";
import "../renderer/2d/matrix.dart";
import "../ui/ui.dart";
import "../utility/extensions.dart";
import "../utility/fileutils.dart";
import "connectible.dart";
import "domainmap.dart";
import "level.dart";
import 'levelheightmap.dart';
import "levelobject.dart";
import "pathnode.dart";
import "selectable.dart";

enum GridCellState {
    hole,
    clear,
    blocked
}

class Grid extends LevelObject with HasMatrix, Connectible, Selectable {
    static final RegExp _coordPattern = new RegExp(r"(\d+)\s*,\s*(\d+)(?:\s+(\d+)\s*,\s*(\d+))?");
    static final RegExp _connectPattern = new RegExp(r"(\d+)\s*,\s*(\d+)\s*(up|down|left|right)");
    static const String typeDesc = "Grid";
    static const num cellSize = 50;

    final int xSize;
    final int ySize;
    late final List<GridCell> cells;

    final Map<PathNode, GridCell> _cellsFromNodes = <PathNode, GridCell>{};

    @override
    String get name => "grid";

    Grid(int this.xSize, int this.ySize) { // : cells = new List<GridCell>(xSize*ySize) {
        cells = new List<GridCell>.from(_generateCells());
        this.updateConnectors();
    }

    factory Grid.fromYaml(YamlMap yaml) {
        int width = 1;
        int height = 1;
        final String name = yaml["name"];
        final Set<String> fields = <String>{"name","model"};

        final DataSetter set = FileUtils.dataSetter(yaml, typeDesc, name, fields);

        set("width", (num n) => width = n.toInt());
        set("height", (num n) => height = n.toInt());

        final Grid grid = new Grid(width, height);

        set("x", (num n) => grid.position.x = n.toDouble());
        set("y", (num n) => grid.position.y = n.toDouble());
        set("z", (num n) => grid.zPosition = n.toDouble());

        set("rotation", (num n) => grid.rot_angle = n.toDouble());

        set("affectLevelHeight", (bool b) => grid.generateLevelHeightData = b);

        bool inverted = false;
        set("invertHoles", (bool b) => inverted = b);
        if (inverted) {
            for (final GridCell cell in grid.cells) {
                cell.state = GridCellState.hole;
            }
        }

        set("holes", (YamlList list) => FileUtils.typedList("holes", list, (String item, int index) {
            final Match? match = _coordPattern.matchAsPrefix(item);
            if (match == null) {
                Engine.logger.warn("Grid '$name' has an invalid hole entry: '$item', skipping");
                return;
            }

            if (match.group(3) == null) {
                // single coordinate
                grid.getCell(int.parse(match.group(1)!), int.parse(match.group(2)!))?.state = inverted ? GridCellState.clear : GridCellState.hole;
            } else {
                // coordinate range
                final int x1 = int.parse(match.group(1)!);
                final int y1 = int.parse(match.group(2)!);
                final int x2 = int.parse(match.group(3)!);
                final int y2 = int.parse(match.group(4)!);

                final List<GridCell> cells = grid.getCells(x1, y1, x2, y2);
                for (final GridCell cell in cells) {
                    cell.state = inverted ? GridCellState.clear : GridCellState.hole;
                }
            }
        }));

        FileUtils.warnInvalidFields(yaml, typeDesc, name, fields);

        grid.updateConnectors();

        return grid;
    }

    Iterable<GridCell> _generateCells() sync* {
        final double ox = (xSize - 1) * cellSize * 0.5;
        final double oy = (ySize - 1) * cellSize * 0.5;
        for (int y = 0; y<ySize; y++) {
            for (int x = 0; x < xSize; x++) {
                //final int id = y * xSize + x;

                final GridCell cell = new GridCell(this)
                    ..position.set(x * cellSize - ox, y * cellSize - oy)
                    ..makeBoundsDirty();

                //this.cells[id] = cell;
                yield cell;
            }
        }
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
                        ..position.set(cell.position.x, cell.position.y - cellSize*0.5)
                        ..rot_angle = -Math.pi * 0.5;
                    cell.up = c;
                    addSubObject(c);
                }

                // down
                if (y == ySize-1 || cells[id + xSize].state == GridCellState.hole) {
                    final Connector c = new ConnectorPositive()
                        ..position.set(cell.position.x, cell.position.y + cellSize*0.5)
                        ..rot_angle = Math.pi * 0.5;
                    cell.down = c;
                    addSubObject(c);
                }

                // left
                if (x == 0 || cells[id - 1].state == GridCellState.hole) {
                    final Connector c = new ConnectorPositive()
                        ..position.set(cell.position.x - cellSize*0.5, cell.position.y)
                        ..rot_angle = Math.pi;
                    cell.left = c;
                    addSubObject(c);
                }

                // right
                if (x == xSize-1 || cells[id + 1].state == GridCellState.hole) {
                    final Connector c = new ConnectorPositive()
                        ..position.set(cell.position.x + cellSize*0.5, cell.position.y)
                        ..rot_angle = 0;
                    cell.right = c;
                    addSubObject(c);
                }
            }
        }
    }

    B.Vector2? cellCoords(int x, int y) {
        if (x < 0 || y < 0 || x >= xSize || y >= ySize) {
            return null;
        }
        return new B.Vector2((x + 0.5 - (xSize * 0.5)) * cellSize, (y + 0.5 - (ySize * 0.5)) * cellSize)..applyMatrixInPlace(matrix);
    }

    B.Vector2? cellCoordsById(int id) {
        final Math.Point<int> coord = id2Coords(id);
        return cellCoords(coord.x, coord.y);
    }

    Math.Point<int> id2Coords(int id) => Math.Point<int>(id % xSize, id ~/ xSize);

    @override
    Iterable<PathNode> generatePathNodes() {
        final List<PathNode> nodes = <PathNode>[];

        for(int y = 0; y<ySize; y++) {
            for(int x = 0; x<xSize; x++) {
                final GridCell cell = getCell(x, y)!;
                if (cell.state == GridCellState.hole) { continue; }

                final PathNode node = new PathNode()
                    ..pathObject = this
                    ..validShortcut = true
                    ..position.setFrom(cell.getWorldPosition())
                    ..zPosition = this.zPosition
                    ..blocked = cell.state == GridCellState.blocked;

                _cellsFromNodes[node] = cell;
                cell.setNode(node);

                if (x > 0) {
                    final GridCell left = getCell(x-1, y)!;
                    if (left.node != null) {
                        cell.node!.connectTo(left.node!);
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
                    final GridCell up = getCell(x, y-1)!;
                    if (up.node != null) {
                        cell.node!.connectTo(up.node!);
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

    GridCell? getCell(int x, int y) {
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
                final GridCell? cell = getCell(x,y);
                if (cell != null) {
                    c.add(cell);
                }
            }
        }

        return c;
    }

    GridCell? getCellFromCoords(num x, num y) {
        final double ox = this.xSize * 0.5 * cellSize;
        final double oy = this.ySize * 0.5 * cellSize;

        final int cx = ((x + ox) / cellSize).floor();
        final int cy = ((y + oy) / cellSize).floor();

        return getCell(cx, cy);
    }

    GridCell? getCellFromPathNode(PathNode node) {
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
    void fillDataMaps(DomainMapRegion domainMap, LevelHeightMapRegion heightMap) {
        B.Vector2? mWorld;
        B.Vector2 local;
        for (int my = 0; my < domainMap.height; my++) {
            for (int mx = 0; mx < domainMap.width; mx++) {
                mWorld = domainMap.getWorldCoords(mx, my);
                if (mWorld == null) { continue; }
                local = this.getLocalPositionFromWorld(mWorld);
                final GridCell? cell = getCellFromCoords(local.x, local.y);
                if (cell != null && cell.node != null) {
                    domainMap.setVal(mx, my, cell.node!.id);
                    if (this.generateLevelHeightData) {
                        heightMap.setVal(mx, my, this.zPosition);
                    }
                }
            }
        }
    }

    @override
    Selectable? getSelectable(B.Vector2 loc) {
        if (!(this.renderer.engine is Game)) {
            return this;
        }
        final B.Vector2 local = this.getLocalPositionFromWorld(loc);
        final GridCell? cell = getCellFromCoords(local.x, local.y);
        if (cell == null || cell.state == GridCellState.hole) {
            return null;
        }
        return cell.getSelectable(loc);
    }

    Future<void> placeTower(int x, int y, Tower tower) async {
        final GridCell? cell = getCell(x, y);
        if (cell == null) { throw Exception("invalid cell $x,$y"); }
        return cell.placeTower(tower);
    }

    @override
    SelectionDisplay<Grid>? createSelectionUI(UIController controller) => null;

    @override
    Connector? getConnector(String descriptor) {
        final Match? match = _connectPattern.matchAsPrefix(descriptor);

        if (match != null) {
            final int x = int.parse(match.group(1)!);
            final int y = int.parse(match.group(2)!);
            final String side = match.group(3)!;

            final GridCell? cell = this.getCell(x, y);
            if (cell == null) { return null; }

            switch(side) {
                case "up":
                    return cell.up;
                case "down":
                    return cell.down;
                case "left":
                    return cell.left;
                case "right":
                    return cell.right;
            }
        }
        return null;
    }
}

class GridCell extends LevelObject with Selectable {
    final Grid grid;
    GridCellState state = GridCellState.clear;

    PathNode? node;
    Tower? tower;

    Connector? up;
    Connector? down;
    Connector? left;
    Connector? right;

    @override
    String get name => "gridcell";

    @override
    Level? get level => grid.level;

    GridCell(Grid this.grid) {
        this.parentObject = grid;
    }

    void setNode(PathNode n) {
        this.node = n;
        if (this.up != null) { up!.node = n; }
        if (this.down != null) { down!.node = n; }
        if (this.left != null) { left!.node = n; }
        if (this.right != null) { right!.node = n; }

    }

    void setBlocked() {
        this.state = GridCellState.blocked;
        if (this.node != null) {
            node!.blocked = true;
        }
    }

    void setClear() {
        this.state = GridCellState.clear;
        if (this.node != null) {
            node!.blocked = false;
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
    Selectable? getSelectable(B.Vector2 loc) {
        if (this.tower != null) { return tower!.getSelectable(loc); }
        return this;
    }

    @override
    SelectionDisplay<GridCell> createSelectionUI(UIController controller) => new GridCellSelectionDisplay(controller);

    Future<void> placeTower(Tower tower) async {

        if (tower.towerType.blocksPath) {
            await level!.engine.pathfinder.flipNodeState(<PathNode>[node!]);
            toggleBlocked();
            await level!.engine.pathfinder.recalculatePathData(level!);
        }

        final B.Vector2 worldCoords = this.getWorldPosition();
        final num rot = this.getWorldRotation();
        tower
            ..gridCell = this
            ..position.setFrom(worldCoords)
            ..rot_angle = rot
            ..turretAngle = rot
            ..prevTurretAngle = rot;
        this.tower = tower;
        this.level!.engine.addEntity(tower);
    }

    Future<void> removeTower() async {
        if (this.tower == null) { return; }

        if (tower!.towerType.blocksPath) {
            await level!.engine.pathfinder.flipNodeState(<PathNode>[node!]);
            toggleBlocked();
            await level!.engine.pathfinder.recalculatePathData(level!);
        }

        this.tower!.kill();
        this.tower = null;
    }

    Future<void> replaceTower(Tower replacement) async {
        final bool currentBlocks = tower!.towerType.blocksPath;
        final bool replacementBlocks = replacement.towerType.blocksPath;

        if (currentBlocks ^ replacementBlocks) {
            await level!.engine.pathfinder.flipNodeState(<PathNode>[node!]);
            toggleBlocked();
            await level!.engine.pathfinder.recalculatePathData(level!);
        }

        tower!.kill();

        tower = replacement;

        final B.Vector2 worldCoords = this.getWorldPosition();
        final num rot = this.getWorldRotation();
        tower!
            ..gridCell = this
            ..position.setFrom(worldCoords)
            ..rot_angle = rot
            ..turretAngle = rot
            ..prevTurretAngle = rot;
        this.tower = tower;
        this.level!.engine.addEntity(tower!);
    }
}