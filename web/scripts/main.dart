import "dart:async";
import 'dart:html';
import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "engine/game.dart";
import "engine/inputhandler.dart";
import "engine/wavemanager.dart";
import "entities/enemytype.dart";
import 'entities/floaterentity.dart';
import 'entities/projectiles/chaserprojectile.dart';
import 'entities/projectiles/interpolatorprojectile.dart';
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
import "resources/resourcetype.dart";
import "utility/extensions.dart";
import "utility/levelutils.dart";
import "utility/mathutils.dart";
import "utility/towerutils.dart";

Future<void> main() async {
    //testProjectileArc();
    //losac();

    //print(TowerUtils.ballisticArc(300, 0, 350, 300, false));
    //print(TowerUtils.ballisticArc(300, 0, 350, 300, true));

    //print(MathUtils.quartic(2, -7, 5, 31, -30).toList());
    //print(MathUtils.cubic(1.5, 3, 1.5, 1.5).toList()); // this gives 3 NaNs
    //print(MathUtils.cubic(2, 3, 1.5, 1.5).toList());
    //testMathSolvers();

    MainMenu.connectStartButton();
}

abstract class MainMenu {

    static void connectStartButton() {
        querySelector("#startgame").onClick.first.then((MouseEvent e) async {
            querySelector("#loadscreen").classes.remove("hidden");
            querySelector("#menu").classes.add("hidden");

            await losac();

            querySelector("#loadscreen").classes.add("hidden");
        });
    }

    static Future<void> exitToMenu(Future<void> Function() cleanup) async {
        querySelector("#loadscreen").classes.remove("hidden");

        await cleanup();
        
        final Element container = querySelector("#container");
        final Element newContainer = container.clone(true);
        container.replaceWith(newContainer);

        querySelector("#menu").classes.remove("hidden");
        connectStartButton();
        querySelector("#loadscreen").classes.add("hidden");
    }

    static Future<void> losac() async {
        print("LOSAC yo");

        final CanvasElement testCanvas = new CanvasElement(width: 800, height: 600);
        final CanvasElement floaterCanvas = new CanvasElement(width: 800, height: 600);

        querySelector("#canvascontainer").append(testCanvas);
        querySelector("#floatercontainer").append(floaterCanvas);

        /*final DivElement fpsElement = new DivElement();
    document.body.append(fpsElement);*/

        final Renderer renderer = new Renderer3D(testCanvas, floaterCanvas);
        await renderer.initialise();
        final Game game = new Game(renderer, querySelector("#uicontainer"));

        final Pathfinder pathfinder = new Pathfinder();
        final Level testLevel = new Level3D();

        final Terrain terrain = new Terrain();
        renderer.addRenderable(terrain);
        testLevel.terrain = terrain;

        /*final FloaterEntity testFloater = new RisingText("ratratratratrat 🐀🐀🐀🐀🐀", "Floater")..zPosition = 20;
    testLevel.addObject(testFloater);
    game.addEntity(testFloater);*/

        // grid

        final GridMeshProvider gridMeshProvider = new DebugGridMeshProvider(renderer);
        final CurveMeshProvider curveMeshProvider = new DebugCurveMeshProvider(renderer);
        final EndCapMeshProvider endCapMeshProvider = new DebugEndCapMeshProvider(renderer);

        final Grid testGrid = new Grid(6, 10)
            ..position.set(500, 400)
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

        testGrid.updateConnectors();
        testLevel.addObject(testGrid);

        // side grid

        final Grid sideGrid = new Grid(4, 1)
            ..position.set(200, 160)
            ..zPosition = 50
            ..rot_angle = 0.75
            ..meshProvider = gridMeshProvider;
        sideGrid.updateConnectors();
        testLevel.addObject(sideGrid);

        // curve

        final Curve testPath = new Curve()
            ..meshProvider = curveMeshProvider
        //..renderVertices=true
        //..renderSegments = true
            ;

        testPath.addVertex(new CurveVertex()
            ..position.set(50, 30)
            ..zPosition = 50
            ..rot_angle = -0.3
            ..handle2 = 60)
        ;
        testPath.addVertex(new CurveVertex()
            ..position.set(220, 40)
            ..zPosition = 100
            ..rot_angle = 0.9
            ..handle1 = 60
            ..handle2 = 60);
        testPath.addVertex(new CurveVertex()
            ..position.set(280, 180)
            ..rot_angle = 0.5
            ..handle1 = 50);

        testPath.updateConnectors();
        testPath.endConnector.connectAndOrient(testGrid
            .getCell(0, 0)
            .left);

        testPath.rebuildSegments();

        testPath.recentreOrigin();

        testLevel.addObject(testPath);

        // entrances and exit

        final ExitObject testExit = new ExitObject()
            ..meshProvider = endCapMeshProvider; //..pos_x=500..pos_y=500;

        testExit.connector.connectAndOrient(testPath.startConnector);

        testPath.rebuildSegments();

        testPath.recentreOrigin();

        testLevel.addObject(testExit);

        final SpawnerObject testSpawner1 = new SpawnerObject()
            ..meshProvider = endCapMeshProvider;
        testSpawner1.connector.connectAndOrient(testGrid
            .getCell(0, 9)
            .down);
        testLevel.addObject(testSpawner1);

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

        //testLevel.cameraHeightMap.updateDebugCanvas();
        //document.body.append(testLevel.cameraHeightMap.debugCanvas);
        //r3d.createDataMapDebugModel(testLevel.cameraHeightMap);


        await pathfinder.transferDomainMap(testLevel);
        await pathfinder.recalculatePathData(testLevel);

        final ResourceType testResource = new ResourceType();
        game.resourceTypeRegistry.register(testResource);
        final ResourceType testResource2 = new ResourceType()
            ..name = "second";
        game.resourceTypeRegistry.register(testResource2);

        game.resourceStockpile.addResource(testResource, 20);

        final EnemyType testEnemyType = new EnemyType();
        final TowerType testTowerType = new TowerType()
            ..buildCost.addResource(testResource, 10)
            ..leadTargets = true
        ;
        //testTowerType.weapon = new ChaserWeaponType(testTowerType);
        testTowerType.weapon = new InterpolatorWeaponType(testTowerType)
            ..projectileSpeed = 350
        ;
        game.towerTypeRegistry.register(testTowerType);

        final TowerType upgradeTestTowerType = new TowerType()
            ..name = "upgradetest"
            ..buildable = false
            ..buildCost.addResource(testResource, 25)
            ..buildCost.addResource(testResource2, 1)
        ;
        upgradeTestTowerType.weapon = new ChaserWeaponType(upgradeTestTowerType)
            ..damage = 3;
        game.towerTypeRegistry.register(upgradeTestTowerType);
        testTowerType.upgradeList.add(upgradeTestTowerType);

        // spawn waves

        for (int i = 0; i < 5; i++) {
            final Wave testWave = new Wave();
            for (int j = 0; j < 5; j++) {
                testWave.entries.add(<WaveEntry>{new WaveEntry(testEnemyType, 0, new ResourceValue()..addResource(testResource, 1))});
            }
            game.waveManager.waves.add(testWave);
        }

        // init
        await game.initialise();
        game
            ..pathfinder = pathfinder
            ..setLevel(testLevel)
        //..fpsElement = fpsElement
            ..start();

        {
            final Tower tower = new Tower(testTowerType);
            await sideGrid.placeTower(3, 0, tower);
        }

        {
            final Tower tower = new Tower(testTowerType);
            await testGrid.placeTower(3, 8, tower);
        }

        renderer.centreOnObject(testLevel);
        r3d.initCameraBounds(testLevel);

        /*int n = 0;
    new Timer.periodic(const Duration(milliseconds: 1500), (Timer t) {
        game.spawnEnemy(testEnemyType, testSpawner1);
        n++;
        if (n >= 10) {
            t.cancel();
        }
    });*/

        //game.input.listen("A", testCallback, allowRepeats: false);
    }


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

void testProjectileArc() {
    const int w = 400;
    const int h = 300;
    const int padding = 20;

    const double distance = 600;
    const double speed = 100;
    const double gravity = 50;

    const double y0 = 0;
    const double y1 = 50;
    const double dy = y1 - y0;

    final CanvasElement canvas = new CanvasElement(width: padding * 2 + w, height: padding * 2 + h);
    final CanvasRenderingContext2D ctx = canvas.context2D;

    const double totalTime = distance / speed;
    const double vy = (dy - (0.5 * -gravity * totalTime * totalTime)) / totalTime;

    for (int ix = 0; ix<w; ix++) {
        final double fraction = ix / w;
        final double t = fraction * totalTime;

        final double py = y0 + vy * t - 0.5 * gravity * t * t;
        final double y = y0 + (y1-y0) * fraction;

        ctx.fillStyle = "blue";
        ctx.fillRect(padding + ix, (padding + h) - y, 1, 1);
        ctx.fillStyle = "red";
        ctx.fillRect(padding + ix, (padding + h) - py, 1, 1);

        print("t,y,py: $t,$y,$py");
        print("blue, red: ${padding + h - y},${padding + h - py}");
    }

    document.body.append(canvas);
}

void testMathSolvers() {
    {
        print("QUADRATICS:");
        const int steps = 10;
        const double offset = 1;
        const double stepSize = 0.5;
        double a,b,c;

        for (int ci = 0; ci<steps; ci++) {
            for (int bi = 0; bi<steps; bi++) {
                for (int ai = 0; ai<steps; ai++) {
                    a = ai * stepSize + offset;
                    b = bi * stepSize + offset;
                    c = ci * stepSize + offset;

                    print("a: $a, b: $b, c: $c -> ${MathUtils.quadratic(a, b, c).toList()}");
                }
            }
        }
    }

    {
        print("CUBICS:");
        const int steps = 5;
        const double offset = 1.5;
        const double stepSize = 0.5;
        double a,b,c,d;

        for (int di = 0; di<steps; di++) {
            for (int ci = 0; ci < steps; ci++) {
                for (int bi = 0; bi < steps; bi++) {
                    for (int ai = 0; ai < steps; ai++) {
                        a = ai * stepSize + offset;
                        b = bi * stepSize + offset;
                        c = ci * stepSize + offset;
                        d = di * stepSize + offset;

                        print("a: $a, b: $b, c: $c, d: $d -> ${MathUtils.cubic(a, b, c, d).toList()}");
                    }
                }
            }
        }
    }

    {
        print("QUARTICS:");
        const int steps = 5;
        const double offset = 1.5;
        const double stepSize = 0.5;
        double a,b,c,d,e;

        for (int ei = 0; ei<steps; ei++) {
            for (int di = 0; di < steps; di++) {
                for (int ci = 0; ci < steps; ci++) {
                    for (int bi = 0; bi < steps; bi++) {
                        for (int ai = 0; ai < steps; ai++) {
                            a = ai * stepSize + offset;
                            b = bi * stepSize + offset;
                            c = ci * stepSize + offset;
                            d = di * stepSize + offset;
                            e = ei * stepSize + offset;

                            print("a: $a, b: $b, c: $c, d: $d, e: $e -> ${MathUtils.quartic(a, b, c, d, e).toList()}");
                        }
                    }
                }
            }
        }
    }
}