import "dart:async";
import 'dart:html';

import "engine/game.dart";
import "engine/inputhandler.dart";
import "entities/enemy.dart";
import "entities/enemytype.dart";
import "level/curve.dart";
import "level/endcap.dart";
import "level/grid.dart";
import "level/level.dart";
import "level/pathnode.dart";
import "pathfinder/pathfinder.dart";
import "renderer/2d/renderer2d.dart";
import "renderer/2d/vector.dart";
import "utility/levelutils.dart";

Future<void> main() async {
    print("LOSAC yo");

    final CanvasElement testCanvas = new CanvasElement(width: 800, height: 600)..style.border="1px solid black";
    final CanvasRenderingContext2D ctx = testCanvas.context2D;

    document.body.append(testCanvas);

    final DivElement fpsElement = new DivElement();
    document.body.append(fpsElement);

    final Pathfinder pathfinder = new Pathfinder();
    final Level testLevel = new Level();

    // basic object test

    /*final LevelObject testObject = new LevelObject()..pos_x = 250..pos_y = 250..rot_angle = 0.5..scale=8.0;

    testObject.addSubObject(new LevelObject()..pos_x = -10..rot_angle=-0.6..scale=0.5);
    testObject.addSubObject(new LevelObject()..pos_x = 10..rot_angle=0.6..scale=0.5);

    testLevel.objects.add(testObject);*/

    // grid

    final Grid testGrid = new Grid(6, 10)..pos_x = 500..pos_y = 400..rot_angle = 0.1;

    List<GridCell> cells = testGrid.getCells(0, 4, 1, 5);
    for (final GridCell c in cells) {
        c.state = GridCellState.hole;
    }

    cells = testGrid.getCells(4, 4, 5, 5);
    for (final GridCell c in cells) {
        c.state = GridCellState.hole;
    }

    cells = testGrid.getCells(0, 8, 4, 8);
    for (final GridCell c in cells) {
        c.state = GridCellState.blocked;
    }

    testGrid.updateConnectors();
    testLevel.objects.add(testGrid);

    // side grid

    final Grid sideGrid = new Grid(4,1)..pos_x = 200..pos_y = 160..rot_angle = 0.75;
    sideGrid.updateConnectors();
    testLevel.objects.add(sideGrid);

    // curve

    final Curve testPath = new Curve()
        //..renderVertices=true
        //..renderSegments = true
    ;

    testPath.addVertex(new CurveVertex()..pos_x = 50..pos_y=30..rot_angle = 1.2..handle2 = 60);
    testPath.addVertex(new CurveVertex()..pos_x = 220..pos_y=40..rot_angle = 2.4..handle1 = 60..handle2 = 60);
    testPath.addVertex(new CurveVertex()..pos_x = 280..pos_y=180..rot_angle = 2.0..handle1 = 50);

    testPath.updateConnectors();
    testPath.endConnector.connectAndOrient(testGrid.getCell(0, 0).left);

    testPath.rebuildSegments();

    testPath.recentreOrigin();

    testLevel.objects.add(testPath);

    // entrances and exit

    final ExitObject testExit = new ExitObject();//..pos_x=500..pos_y=500;

    testExit.connector.connectAndOrient(testPath.startConnector);

    testLevel.objects.add(testExit);

    final SpawnerObject testSpawner1 = new SpawnerObject();
    testSpawner1.connector.connectAndOrient(testGrid.getCell(0, 9).down);
    testLevel.objects.add(testSpawner1);

    // build path nodes

    testLevel.derivePathNodes();

    // send node data, evaluate connectivity
    await pathfinder.transferNodeData(testLevel);

    testLevel.buildDomainMap();
    //testLevel.domainMap.updateDebugCanvas();

    await pathfinder.transferDomainMap(testLevel);
    await pathfinder.recalculatePathData(testLevel);

    final EnemyType testEnemyType = new EnemyType();
    
    final Renderer2D renderer = new Renderer2D(testCanvas);

    final Game game = new Game(renderer)
        ..pathfinder = pathfinder
        ..setLevel(testLevel)
        ..fpsElement = fpsElement
        ..start();

    int n = 0;
    new Timer.periodic(Duration(milliseconds: 1500), (Timer t) {
        game.spawnEnemy(testEnemyType, testSpawner1);
        n++;
        if (n >= 30) {
            t.cancel();
        }
    });

    game.input.listen("A", testCallback, allowRepeats: false);
}

bool testCallback(String key, KeyEventType type, bool shift, bool control, bool alt) {
    print("key: $key, shift: $shift, type: $type");
    return false;
}
