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
import "level/terrain.dart";
import "pathfinder/pathfinder.dart";
import 'renderer/3d/models/curvemeshprovider.dart';
import 'renderer/3d/models/gridmeshprovider.dart';
import "renderer/3d/renderer3d.dart";
import "renderer/renderer.dart";
import "utility/extensions.dart";
import "utility/levelutils.dart";

Future<void> main() async {
    print("LOSAC yo");

    final CanvasElement testCanvas = new CanvasElement(width: 800, height: 600)..style.border="1px solid black";
    //final CanvasRenderingContext2D ctx = testCanvas.context2D;

    document.body.append(testCanvas);

    final DivElement fpsElement = new DivElement();
    document.body.append(fpsElement);

    final Renderer renderer = new Renderer3D(testCanvas);

    final Pathfinder pathfinder = new Pathfinder();
    final Level testLevel = new Level3D();

    final Terrain terrain = new Terrain();
    renderer.addRenderable(terrain);
    testLevel.terrain = terrain;

    // basic object test

    /*final LevelObject testObject = new LevelObject()..pos_x = 250..pos_y = 250..rot_angle = 0.5..scale=8.0;

    testObject.addSubObject(new LevelObject()..pos_x = -10..rot_angle=-0.6..scale=0.5);
    testObject.addSubObject(new LevelObject()..pos_x = 10..rot_angle=0.6..scale=0.5);

    testLevel.objects.add(testObject);*/

    // grid

    final GridMeshProvider gridMeshProvider = new DebugGridMeshProvider(renderer);
    final CurveMeshProvider curveMeshProvider = new DebugCurveMeshProvider(renderer);
    final EndCapMeshProvider endCapMeshProvider = new DebugEndCapMeshProvider(renderer);

    final Grid testGrid = new Grid(6, 10)
        ..position.set(500,400)
        ..zPosition = 50
        ..rot_angle = 0.1
        ..generateLevelHeightData = false
        ..meshProvider = gridMeshProvider;

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

    final Grid sideGrid = new Grid(4,1)
        ..position.set(200, 160)
        ..rot_angle = 0.75
        ..meshProvider = gridMeshProvider;
    sideGrid.updateConnectors();
    testLevel.objects.add(sideGrid);

    // curve

    final Curve testPath = new Curve()
        ..meshProvider = curveMeshProvider
        //..renderVertices=true
        //..renderSegments = true
    ;

    testPath.addVertex(new CurveVertex()..position.set(50, 30)..rot_angle = -0.3..handle2 = 60);
    testPath.addVertex(new CurveVertex()..position.set(220, 40)
        ..zPosition = 100
        ..rot_angle = 0.9..handle1 = 60..handle2 = 60);
    testPath.addVertex(new CurveVertex()..position.set(280, 180)..rot_angle = 0.5..handle1 = 50);

    testPath.updateConnectors();
    testPath.endConnector.connectAndOrient(testGrid.getCell(0, 0).left);

    testPath.rebuildSegments();

    testPath.recentreOrigin();

    testLevel.objects.add(testPath);

    // entrances and exit

    final ExitObject testExit = new ExitObject()
        ..meshProvider = endCapMeshProvider;//..pos_x=500..pos_y=500;

    testExit.connector.connectAndOrient(testPath.startConnector);
    //testPath.startConnector.connectAndOrient(testExit.connector);

    testPath.rebuildSegments();

    testPath.recentreOrigin();

    testLevel.objects.add(testExit);

    final SpawnerObject testSpawner1 = new SpawnerObject()
        ..meshProvider = endCapMeshProvider;
    testSpawner1.connector.connectAndOrient(testGrid.getCell(0, 9).down);
    testLevel.objects.add(testSpawner1);

    // build path nodes

    testLevel.derivePathNodes();

    // send node data, evaluate connectivity
    await pathfinder.transferNodeData(testLevel);

    final Renderer3D r3d = renderer;

    testLevel.buildDataMaps();

    //testLevel.domainMap.updateDebugCanvas();
    //document.body.append(testLevel.domainMap.debugCanvas);
    //r3d.createDataMapDebugModel(testLevel.domainMap);

    //testLevel.levelHeightMap.updateDebugCanvas();
    //document.body.append(testLevel.levelHeightMap.debugCanvas);
    //r3d.createDataMapDebugModel(testLevel.levelHeightMap);

    testLevel.cameraHeightMap.updateDebugCanvas();
    document.body.append(testLevel.cameraHeightMap.debugCanvas);
    //r3d.createDataMapDebugModel(testLevel.cameraHeightMap);


    await pathfinder.transferDomainMap(testLevel);
    await pathfinder.recalculatePathData(testLevel);

    final EnemyType testEnemyType = new EnemyType();
    final TowerType testTowerType = new TowerType();

    /*final Tower testTower = new Tower(testTowerType);
    //final Point<num> towerCoord = sideGrid.getCell(2, 0).getWorldPosition();
    final Point<num> towerCoord = testGrid.getCell(0, 8).getWorldPosition();
    testTower..pos_x = towerCoord.x..pos_y = towerCoord.y;*/
    


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

    renderer.centreOnObject(testLevel);
    r3d.initCameraBounds(testLevel);

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
}

/*bool testCallback(String key, KeyEventType type, bool shift, bool control, bool alt) {
    print("key: $key, shift: $shift, type: $type");
    return false;
}*/

void testInverseBilinear() {
    const int w = 80;
    const int h = 80;

    final CanvasElement testCanvas = new CanvasElement(width:w, height:h);
    final CanvasRenderingContext2D ctx = testCanvas.context2D;

    /*final B.Vector2 a = new B.Vector2(20,30);
    final B.Vector2 b = new B.Vector2(350,90);
    final B.Vector2 c = new B.Vector2(300,260);
    final B.Vector2 d = new B.Vector2(60,380);*/


    final B.Vector2 a = new B.Vector2(20,20);
    final B.Vector2 b = new B.Vector2(40,20);
    final B.Vector2 c = new B.Vector2(40,40);
    final B.Vector2 d = new B.Vector2(20,40);

    final ImageData idata = ctx.getImageData(0, 0, w, h);
    int i;
    B.Vector2 uv;
    final B.Vector2 coord = B.Vector2.Zero();
    for (int y=0; y<h;y++) {
        for (int x=0;x<w;x++) {
            i = (y * w + x) * 4;

            coord.set(x, y);
            uv = LevelUtils.inverseBilinear(coord,a,b,c,d);

            int red = 0;
            int green = 0;
            int blue = 0;
            int alpha = 0;

            if (uv.x >= 0) {
                red = (uv.x * 255).round();
                green = (uv.y * 255).round();
                alpha = 255;
            }

            idata.data[i] = red;
            idata.data[i+1] = green;
            idata.data[i+2] = blue;
            idata.data[i+3] = alpha;
        }
    }
    ctx.putImageData(idata, 0, 0);

    document.body.append(testCanvas);
}
