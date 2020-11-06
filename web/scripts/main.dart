import "dart:async";
import 'dart:html';
import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "engine/game.dart";
import "engine/inputhandler.dart";
import "entities/enemytype.dart";
import "entities/tower.dart";
import "entities/towertype.dart";
import "level/curve.dart";
import "level/endcap.dart";
import "level/grid.dart";
import "level/level.dart";
import "level/level3d.dart";
import "pathfinder/pathfinder.dart";
import "renderer/3d/renderer3d.dart";
import "renderer/renderer.dart";
import "utility/extensions.dart";

Future<void> main() async {
    print("LOSAC yo");

    final CanvasElement testCanvas = new CanvasElement(width: 800, height: 600)..style.border="1px solid black";
    //final CanvasRenderingContext2D ctx = testCanvas.context2D;

    document.body.append(testCanvas);

    final DivElement fpsElement = new DivElement();
    document.body.append(fpsElement);

    final Pathfinder pathfinder = new Pathfinder();
    final Level testLevel = new Level3D();

    // basic object test

    /*final LevelObject testObject = new LevelObject()..pos_x = 250..pos_y = 250..rot_angle = 0.5..scale=8.0;

    testObject.addSubObject(new LevelObject()..pos_x = -10..rot_angle=-0.6..scale=0.5);
    testObject.addSubObject(new LevelObject()..pos_x = 10..rot_angle=0.6..scale=0.5);

    testLevel.objects.add(testObject);*/

    // grid

    final Grid testGrid = new Grid(6, 10)..posVector.x = 500..posVector.y = 400..rot_angle = 0.1;

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

    final Grid sideGrid = new Grid(4,1)..posVector.x = 200..posVector.y = 160..rot_angle = 0.75;
    sideGrid.updateConnectors();
    testLevel.objects.add(sideGrid);

    // curve

    final Curve testPath = new Curve()
        //..renderVertices=true
        //..renderSegments = true
    ;

    testPath.addVertex(new CurveVertex()..posVector.x = 50..posVector.y=30..rot_angle = -0.3..handle2 = 60);
    testPath.addVertex(new CurveVertex()..posVector.x = 220..posVector.y=40..rot_angle = 0.9..handle1 = 60..handle2 = 60);
    testPath.addVertex(new CurveVertex()..posVector.x = 280..posVector.y=180..rot_angle = 0.5..handle1 = 50);

    testPath.updateConnectors();
    testPath.endConnector.connectAndOrient(testGrid.getCell(0, 0).left);

    testPath.rebuildSegments();

    testPath.recentreOrigin();

    testLevel.objects.add(testPath);

    // entrances and exit

    final ExitObject testExit = new ExitObject();//..pos_x=500..pos_y=500;

    testExit.connector.connectAndOrient(testPath.startConnector);
    //testPath.startConnector.connectAndOrient(testExit.connector);

    testPath.rebuildSegments();

    testPath.recentreOrigin();

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
    final TowerType testTowerType = new TowerType();

    /*final Tower testTower = new Tower(testTowerType);
    //final Point<num> towerCoord = sideGrid.getCell(2, 0).getWorldPosition();
    final Point<num> towerCoord = testGrid.getCell(0, 8).getWorldPosition();
    testTower..pos_x = towerCoord.x..pos_y = towerCoord.y;*/
    
    final Renderer renderer = new Renderer3D(testCanvas);

    final Game game = new Game(renderer)
        ..pathfinder = pathfinder
        ..setLevel(testLevel)
        ..fpsElement = fpsElement
        ..start();

    //game.addEntity(testTower);

    /*const int towers = 5;
    for (int i=0; i<towers; i++) {
        final Tower tower = new Tower(testTowerType);
        testGrid.placeTower(i, 8, tower);
        game.addEntity(tower);
    }*/

    {
        final Tower tower = new Tower(testTowerType);
        sideGrid.placeTower(3, 0, tower);
        game.addEntity(tower);
    }

    {
        final Tower tower = new Tower(testTowerType);
        testGrid.placeTower(3, 8, tower);
        game.addEntity(tower);
    }

    final Rectangle<num> lb = testLevel.bounds;
    renderer.moveTo((lb.left + lb.right)*0.5, (lb.top + lb.bottom)*0.5);

    //game.spawnEnemy(testEnemyType, testSpawner1);
    int n = 0;
    new Timer.periodic(const Duration(milliseconds: 1500), (Timer t) {
        game.spawnEnemy(testEnemyType, testSpawner1);
        n++;
        if (n >= 10) {
            t.cancel();
        }
    });

    //game.input.listen("A", testCallback, allowRepeats: false);

    B.Vector2 v = new B.Vector2(1,0);
    print("(1,0): ${v.angle}");
    v = new B.Vector2(1,1);
    print("(1,1): ${v.angle}");
    v = new B.Vector2(0,1);
    print("(0,1): ${v.angle}");

    v = new B.Vector2(1,0).rotate(Math.pi * 0.5);
    print(v);
}

/*bool testCallback(String key, KeyEventType type, bool shift, bool control, bool alt) {
    print("key: $key, shift: $shift, type: $type");
    return false;
}*/
