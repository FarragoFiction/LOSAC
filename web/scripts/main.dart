import "dart:async";
import 'dart:html';
import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;
import "package:ImageLib/Encoding.dart";
import "package:LoaderLib/Loader.dart";

import "engine/engine.dart";
import "engine/game.dart";
import "engine/wavemanager.dart";
import "entities/enemytype.dart";
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
import "utility/levelutils.dart";
import "utility/mathutils.dart";

import "targeting/targetingparser.dart";

Future<void> main() async {
    Formats.addMapping(Engine.yamlFormat, "yaml");
    //testProjectileArc();
    //losac();

    //print(TowerUtils.ballisticArc(300, 0, 350, 300, false));
    //print(TowerUtils.ballisticArc(300, 0, 350, 300, true));

    //print(MathUtils.quartic(2, -7, 5, 31, -30).toList());
    //print(MathUtils.cubic(1.5, 3, 1.5, 1.5).toList()); // this gives 3 NaNs
    //print(MathUtils.cubic(2, 3, 1.5, 1.5).toList());
    //testMathSolvers();

    //TargetingParser.test();

    MainMenu.connectStartButton();
}

abstract class MainMenu {

    static void connectStartButton() {
        querySelector("#startgame")!.onClick.first.then((MouseEvent e) async {
            querySelector("#loadscreen")!.classes.remove("hidden");
            querySelector("#menu")!.classes.add("hidden");

            await losac();

            querySelector("#loadscreen")!.classes.add("hidden");
        });
    }

    static Future<void> exitToMenu(Future<void> Function() cleanup) async {
        querySelector("#loadscreen")!.classes.remove("hidden");

        await cleanup();
        
        final Element container = querySelector("#container")!;
        final Element newContainer = container.clone(true) as Element;
        container.replaceWith(newContainer);

        querySelector("#menu")!.classes.remove("hidden");
        connectStartButton();
        querySelector("#loadscreen")!.classes.add("hidden");
    }

    static Future<void> losac() async {
        print("LOSAC yo");

        final CanvasElement testCanvas = new CanvasElement(width: 800, height: 600);
        final CanvasElement floaterCanvas = new CanvasElement(width: 800, height: 600);

        querySelector("#canvascontainer")!.append(testCanvas);
        querySelector("#floatercontainer")!.append(floaterCanvas);

        /*final DivElement fpsElement = new DivElement();
        document.body.append(fpsElement);*/

        final Renderer3D renderer = new Renderer3D(testCanvas, floaterCanvas);
        await renderer.initialise();
        final Game game = new Game(renderer, querySelector("#uicontainer")!);

        final Pathfinder pathfinder = new Pathfinder();
        final Level testLevel = new Level3D();

        game.pathfinder = pathfinder;
        testLevel.engine = game;

        // LOADING TEST ####################################
        final ArchivePng levelImage = await Loader.getResource("levels/testlevel.png", format: ArchivePng.format);
        await game.loadLevelArchive(levelImage.archive!, testLevel);
        // LOADING TEST ####################################

        final Terrain terrain = new Terrain();
        renderer.addRenderable(terrain);
        testLevel.terrain = terrain;

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

        // init
        game.setLevel(testLevel);
        await game.initialise();
        game.start();

        renderer.centreOnObject(testLevel);
        r3d.initCameraBounds(testLevel);
    }


}

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

    document.body!.append(testCanvas);
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

    document.body!.append(canvas);
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