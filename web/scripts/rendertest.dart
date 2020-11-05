import "dart:async";
import "dart:html";
import 'dart:js';
import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;
import "package:js/js.dart" as JS;
import "package:js/js_util.dart" as JSu;
import "package:LoaderLib/Loader.dart";

Future<void> main() async {
    complexityTest();

    testTrailId();
}

class TestObject {
    B.Vector3 position;
    B.Vector3 prevPosition;
    B.Vector3 velocity;
    double spin;
    double lifetime;
    bool dead = false;

    B.InstancedMesh mesh;
    B.BaseParticleSystem particles;
    B.TrailMesh trail;

    TestObject(B.Mesh sourceMesh, B.BaseParticleSystem this.particles, B.Vector3 this.position, B.Vector3 this.velocity, double this.spin, double this.lifetime) {
        this.mesh = sourceMesh.createInstance("TestObject ${this.hashCode}");
        //this.trail = new B.TrailMesh("Trail ${this.hashCode}", this.mesh, this.mesh.getScene(), 0.5, 60, false);
        this.prevPosition = position.clone();
        final dynamic iBuffers = this.mesh.instancedBuffers;
        const int trail = 5;
        for (int i=0; i<trail; i++) {
            JSu.setProperty(iBuffers, "trail$i", position.clone());
        }
    }

    void update(double dt) {
        if (dead) {
            return;
        }
        lifetime -= dt;
        if (lifetime <= 0) {
            this.destroy();
            return;
        }
        this.prevPosition.copyFrom(this.position);

        this.velocity.rotateByQuaternionAroundPointToRef(B.Quaternion.FromEulerAngles(0, this.spin * dt, 0), this.position, this.velocity);

        this.position.addInPlace(velocity * dt);

        if (this.position.x.abs() > 150 || this.position.z.abs() > 150) {
            this.destroy();
        }
    }
    void renderUpdate(double dt, double frameProgress) {
        final B.Vector3 diff = position - prevPosition;

        this.mesh.position.set(
            prevPosition.x + frameProgress * diff.x,
            prevPosition.y + frameProgress * diff.y,
            prevPosition.z + frameProgress * diff.z,
        );
    }

    void destroy() {
        this.dead = true;
        //print("boom $hashCode");
        
        this.particles
            ..emitter = this.position
            ..manualEmitCount = 50
        ;

        this.mesh.dispose();
        //this.trail.dispose();
    }
}

Future<void> complexityTest() async {
    final CanvasElement canvas = querySelector("#canvas");
    final B.Engine engine = new B.Engine(canvas, false);

    final B.Scene scene = new B.Scene(engine);

    final B.Camera camera = new B.FreeCamera("camera", B.Vector3(0,50,00), scene)
    ..maxZ = 500
    ..attachControl(canvas);

    final B.Texture depth = scene.enableDepthRenderer(camera, false).getDepthMap();
    //final B.Light light = new B.HemisphericLight("light1", new B.Vector3(0,1,0), scene);
    final B.Light light = new B.DirectionalLight("light", B.Vector3(-.5,-1,0), scene)
        ..position.y = 50
        //..shadowMaxZ = 500
        //..autoUpdateExtends = false
        ..autoCalcShadowZBounds = true
    ;
    final B.ShadowGenerator shadows = new B.ShadowGenerator(4096, light)
        ..useCloseExponentialShadowMap = true
        //..bias = 0.1
        ..usePoissonSampling = true
        //..autoCalcDepthBounds = true
        //..forceBackFacesOnly = true
    ;

    const double terrainSize = 300;

    final Completer<void> terrainCompleter = new Completer<void>();
    void callback(B.GroundMesh ground) {
        terrainCompleter.complete();
    }
    final B.GroundMesh terrain = B.Mesh.CreateGroundFromHeightMap("ground", "assets/textures/heightTest.png", terrainSize, terrainSize, 256, 0, 50, scene, false, JS.allowInterop(callback))
        ..material = (new B.StandardMaterial("terrainMat", scene)
            ..diffuseColor.set(.5, .5, .5)
            ..specularColor.set(0.1, 0.1, 0.1)
            ..freeze()
        )..freezeWorldMatrix()
        ..alwaysSelectAsActiveMesh = true
        ..doNotSyncBoundingInfo = true;
    await terrainCompleter.future;
    //shadows.addShadowCaster(terrain);
    terrain.receiveShadows = true;

    final Math.Random rand = new Math.Random(1);
    final B.Observable<double> tickObservable = new B.Observable<double>();

    const int treeTypes = 10;
    const int treeCount = 5000;
    const int treeCountPerType = treeCount ~/ treeTypes;
    for (int i=0; i<treeTypes; i++) {
        final B.Mesh tree = B.MeshBuilder.CreateCylinder("tree$i", B.MeshBuilderCreateCylinderOptions(
            height: 5.0,
            diameterTop: 0,
            diameterBottom: 2,
            tessellation: 5,
            cap: B.Mesh.NO_CAP
        ), scene);

        final B.Material treeMat = new B.StandardMaterial("treeMat$i", scene)
            ..specularColor.set(0.1,0.1,0.1)
            ..diffuseColor.set(0.25 + rand.nextDouble() * 0.5, 0.25 + rand.nextDouble() * 0.5, 0.25 + rand.nextDouble() * 0.5)
            ..freeze()
        ;
        tree.material = treeMat;

        final List<B.Mesh> trees = <B.Mesh>[];
        for (int j=0; j<treeCountPerType; j++) {
            final double x = terrainSize * (rand.nextDouble() - 0.5);
            final double z = terrainSize * (rand.nextDouble() - 0.5);
            final double y = terrain.getHeightAtCoordinates(x,z);
            final double scale = 0.85 + rand.nextDouble() * 0.3;
            if (j == 0) {
                trees.add(tree
                    ..position.set(x, y + 2.5 * scale, z)
                    ..scaling.set(scale, scale, scale)
                );
            } else {
                trees.add(tree.clone("tree${i}_$j")
                    ..position.set(x, y + 2.5 * scale, z)
                    ..scaling.set(scale, scale, scale));
            }
        }
        final B.Mesh merged = B.Mesh.MergeMeshes(trees)
            ..alwaysSelectAsActiveMesh = true
            ..doNotSyncBoundingInfo = true
            ..freezeWorldMatrix();
        shadows.addShadowCaster(merged);
    }

    final String boxMatVert = await Loader.getResource("assets/shaders/basic_with_trail.vert");
    final String boxMatFrag = await Loader.getResource("assets/shaders/basic.frag");
    final B.ShaderMaterial boxMat = new B.ShaderMaterial("boxmat", scene, B.ShaderMaterialShaderPath(
        vertexSource: boxMatVert,
        fragmentSource: boxMatFrag
    ), B.IShaderMaterialOptions(
        attributes: <String>["position", "normal", "uv", "color", "world0","world1","world2","world3", "trail0","trail1","trail2","trail3","trail4"],
        uniforms: <String>["world", "viewProjection", "worldViewProjection", "trailStep", "trailLength"],
        defines: <String>["#define INSTANCES"]
    ));

    final B.Mesh projectileMesh = B.MeshBuilder.CreateBox("projectile", B.MeshBuilderCreateBoxOptions(size: 1))
        ..material = boxMat /*(new B.StandardMaterial("boxmat", scene)
            ..diffuseColor.set(1, 1, 1)
        )*/..isVisible = false;
    shadows.addShadowCaster(projectileMesh);
    tickObservable.add(addTrailToMesh(projectileMesh, 5));
    final B.Texture particleTexture = new B.Texture("assets/textures/alphaTest.png", scene);
    final B.BaseParticleSystem explosions = new B.ParticleSystem("boom", 5000, scene)
        //..targetStopDuration = 0.2
        ..emitRate = 0
        ..createSphereEmitter(0.1)

        ..particleTexture = particleTexture

        ..minEmitPower = 5
        ..maxEmitPower = 50
        ..addVelocityGradient(0, 1.0)
        ..addVelocityGradient(1, 0.1)

        ..minLifeTime = 0.1
        ..maxLifeTime = 0.75

        ..minSize = 2.0
        ..maxSize = 2.5
        ..addSizeGradient(0, 1.0)
        ..addSizeGradient(0.75, 1.5)
        ..addSizeGradient(1, 5.0)

        ..addColorGradient(0, new B.Color4(1,1,0,1))
        ..addColorGradient(0.5, new B.Color4(1,0,0,1))
        ..addColorGradient(0.75, new B.Color4(0.5,0.5,0.5,0.5))
        ..addColorGradient(1, new B.Color4(0.5,0.5,0.5,0.0))

        ..blendMode = B.BaseParticleSystem.BLENDMODE_STANDARD

        //..disposeOnStop = true
        ..start()
    ;

    double dt;
    double worldTime = 0.0;
    double tickCounter = 0.0;
    const int ticksPerSecond = 20;
    const double tickInterval = 1000 / ticksPerSecond;

    double spawnTimer = 0.0;
    const double spawnInterval = 0.01;

    final Set<TestObject> objects = <TestObject>{};
    final Set<TestObject> dispose = <TestObject>{};

    engine.runRenderLoop(JS.allowInterop((){
        dt = engine.getDeltaTime();
        worldTime += dt;
        tickCounter += dt;

        int iter = 0;
        while(tickCounter >= tickInterval) {
            tickCounter -= tickInterval;

            iter++;
            if (iter > 4) { continue; }
            dispose.clear();
            const double seconds = tickInterval * 0.001;

            for (final TestObject o in objects) {
                o.update(seconds);
                if (o.dead) {
                    dispose.add(o);
                }
            }

            tickObservable.notifyObservers(seconds);

            for (final TestObject o in dispose) {
                objects.remove(o);
            }

            spawnTimer += seconds;
            while(spawnTimer > spawnInterval) {
                spawnTimer -= spawnInterval;

                final double speed = 20 + rand.nextDouble() * 60;
                final double angle = rand.nextDouble() * Math.pi * 2;
                final double vx = Math.sin(angle) * speed;
                final double vz = Math.cos(angle) * speed;
                final double vy = (rand.nextDouble() - 0.5) * 10;
                final TestObject obj = new TestObject(projectileMesh, explosions, new B.Vector3(0,30,0), new B.Vector3(vx,vy,vz), (rand.nextDouble() - 0.5) * 15, 2.0 + rand.nextDouble() * 5.0);
                //obj.trail.start();
                objects.add(obj);
                shadows.addShadowCaster(obj.mesh);
            }
        }

        final double fraction = (tickCounter / tickInterval).clamp(0, 1);
        for (final TestObject o in objects) {
            boxMat.setFloat("tickFraction", fraction);
            boxMat.setVector3("cameraPos", camera.position);
            o.renderUpdate(tickInterval * 0.001, fraction);
        }

        scene.render();
    }));

    document.body.append(new DivElement()..append(new ButtonElement()..text="show inspector"..onClick.listen((MouseEvent e) { scene.debugLayer.show(); })));
}

void Function(double dt, B.EventState state) addTrailToMesh(B.Mesh mesh, int length) {
    final List<dynamic> positions = mesh.getVerticesData(B.VertexBuffer.PositionKind);
    final List<dynamic> normals = mesh.getVerticesData(B.VertexBuffer.NormalKind);
    final List<dynamic> uvs = mesh.getVerticesData(B.VertexBuffer.UVKind);
    final List<dynamic> indices = mesh.getIndices();

    /*print("before");
    print(positions);
    print(normals);
    print(uvs);
    print(indices);*/

    final List<double> colours = <double>[];

    const List<double> blankColour = <double>[1,1,1,1];
    for (int i=0; i<positions.length ~/ 3; i++) {
        colours.addAll(blankColour);
    }

    final int offset = positions.length ~/3;
    for (int i=0; i<length; i++) {
        final double lengthFraction = i / (length-1);
        positions.addAll(<double>[1.0,0.0,i * 5.0, -1.0,0.0,i * 5.0]);
        normals.addAll(<double>[0.0,1.0,0.0, 0.0,1.0,0.0]);
        colours.addAll(<double>[0.0, lengthFraction, 0.0, 1.0, 0.0, lengthFraction, 1.0, 1.0]);
        uvs.addAll(<double>[0.0,lengthFraction, 1.0,lengthFraction]);

        if (i<length-1) {
            final int n = offset + i*2;
            indices.addAll(<int>[n,n+2,n+1, n+1,n+2,n+3]);
        }
    }

    new B.VertexData()
        ..positions = positions
        ..normals = normals
        ..uvs = uvs
        ..indices = indices
        ..colors = colours
        ..applyToMesh(mesh);


    for (int i = 0; i<length; i++) {
        mesh.registerInstancedBuffer("trail$i", 3);
        //JSu.setProperty(mesh.instancedBuffers, "trail$i", new B.Vector3(0,0,0));
    }

    int step = 0;
    return (JS.allowInterop((double dt, B.EventState state) {
        for (final B.InstancedMesh instance in mesh.instances) {
            final dynamic iBuffers = instance.instancedBuffers;

            if (JSu.getProperty(iBuffers, "trail0") == null) {
                //print("set");
                for (int i=0; i<length; i++) {
                    JSu.setProperty(iBuffers, "trail$i", new B.Vector3(0, 0, 0));
                }
            }

            final B.Vector3 data = JSu.getProperty(iBuffers, "trail$step");
            data.set(instance.position.x, instance.position.y, instance.position.z);
            //print("$step $data");
            //print(context["console"]);

        }

        final B.ShaderMaterial material = mesh.material;
        material.setInt("trailStep", step);
        material.setInt("trailLength", length);

        step--;
        if (step < 0) {
            step += length;
        }
    }));

    /*final List<dynamic> positions2 = mesh.getVerticesData(B.VertexBuffer.PositionKind);
    final List<dynamic> normals2 = mesh.getVerticesData(B.VertexBuffer.NormalKind);
    final List<dynamic> uvs2 = mesh.getVerticesData(B.VertexBuffer.UVKind);
    final List<dynamic> indices2 = mesh.getIndices();

    print("after");
    print(positions2);
    print(normals2);
    print(uvs2);
    print(indices2);*/
}

Future<void> portalTest() async {
    final CanvasElement canvas = querySelector("#canvas");
    final B.Engine engine = new B.Engine(canvas, false);

    final B.Scene scene = new B.Scene(engine);

    final B.Camera camera = new B.ArcRotateCamera("camera", 0, 0, 5, B.Vector3.Zero(), scene)
        ..attachControl(canvas, false)
        ..allowUpsideDown = false
    //..upperBetaLimit = Math.pi * 0.5
        ..lowerRadiusLimit = 2.5 //5.0
        ..upperRadiusLimit = 100.0
    ;

    final B.Texture depth = scene.enableDepthRenderer(camera, false).getDepthMap();

    final B.Light light = new B.HemisphericLight("light1", new B.Vector3(0,1,0), scene);

    final B.Mesh plane = B.MeshBuilder.CreatePlane("plane", B.MeshBuilderCreatePlaneOptions( size: 2 ) , scene);

    final String vert = await Loader.getResource("assets/shaders/basic.vert");
    final String frag = await Loader.getResource("assets/shaders/timehole.frag");

    final B.Texture alphaTestTexture = new B.Texture("assets/textures/alphaTest.png", engine);

    final B.ShaderMaterial material = new B.ShaderMaterialWithAlphaTestTexture("material", scene, B.ShaderMaterialShaderPath(
        vertexSource: vert,
        fragmentSource: frag,
    ), B.IShaderMaterialOptions(
        needAlphaTesting: true
    ), alphaTestTexture)
        ..backFaceCulling = false
    ;

    plane.material = material;

    double time = 0.0;
    scene.registerBeforeRender(JS.allowInterop(([dynamic a, dynamic b]) {
        time += engine.getDeltaTime();
        material.setFloat("time", time * 0.001);
        material.setVector3("cameraPosition", camera.position);
    }));

    final B.PostProcess postTest = new B.PostProcess("post test", "./assets/shaders/rough_edges", <String>["screenSize", "invProjView", "nearZ", "farZ"], <String>["depthSampler"], 1.0, camera);

    final B.Matrix invTransform = new B.Matrix();

    postTest.onApply = JS.allowInterop((B.Effect effect, [dynamic a]) {
        effect.setTexture("depthSampler", depth);
        effect.setFloat2("screenSize", postTest.width, postTest.height);

        scene.getTransformMatrix().invertToRef(invTransform);
        effect.setMatrix("invProjView", invTransform);

        effect.setFloat("nearZ", camera.minZ);
        effect.setFloat("farZ", camera.maxZ);
    });

    engine.runRenderLoop(JS.allowInterop((){
        scene.render();
    }));
}

void testTrailId() {
    const int length = 5;
    const List<double> points = <double>[0.0,0.25,0.5,0.75,1.0];

    int getIndex(double fraction) {
        return ((fraction) * (length-1) + 0.2).floor();
    }

    int getPointIndex(int index, int step) {
        int id = index + step;
        if (id >= length) {
            id -= length;
        }
        return id;
    }

    void printTestRange(int step) {
        final List<int> list = <int>[];
        for (int i=0; i<length; i++) {
            list.add(getPointIndex(getIndex(points[i]), step));
        }
        print(list);
    }

    /*for (int i=0; i<length; i++) {
        printTestRange(i);
    }*/

    final B.Vector3 pos = new B.Vector3();
    final List<B.Vector3> trailPositions = new List<B.Vector3>.generate(length, (int i) => new B.Vector3());

    int step = 0;
    for (int iter = 0; iter < 10; iter++) {
        pos.x += 1.0;

        trailPositions[step].set(pos.x, pos.y, pos.z);

        final List<B.Vector3> positions = <B.Vector3>[];
        for (int i=0; i<length; i++) {
            final int id = getIndex(points[i]);
            final int pointId = getPointIndex(id, step);
            positions.add(trailPositions[pointId]);
        }
        print(positions);

        step --;
        if(step < 0) {
            step += length;
        }
    }
}