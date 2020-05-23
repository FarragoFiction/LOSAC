import "dart:async";
import "dart:html";
import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;
import "package:js/js.dart" as JS;
import "package:LoaderLib/Loader.dart";

Future<void> main() async {
    complexityTest();
}

class TestObject {
    B.Vector3 position;
    B.Vector3 velocity;
    double lifetime;
    bool dead = false;

    B.InstancedMesh mesh;
    B.BaseParticleSystem particles;
    B.TrailMesh trail;

    TestObject(B.Mesh sourceMesh, B.BaseParticleSystem this.particles, B.Vector3 this.position, B.Vector3 this.velocity, double this.lifetime) {
        this.mesh = sourceMesh.createInstance("TestObject ${this.hashCode}");
        this.trail = new B.TrailMesh("Train ${this.hashCode}", this.mesh, this.mesh.getScene(), 0.5, 60, false);

    }

    void update(double dt) {
        if (dead) { return; }
        lifetime -= dt;
        if (lifetime <= 0) {
            this.destroy();
            return;
        }

        this.position.addInPlace(velocity * dt);
        this.mesh.position.set(position.x, position.y, position.z);
    }

    void destroy() {
        this.dead = true;
        print("boom $hashCode");
        
        this.particles
            ..emitter = this.position
            ..manualEmitCount = 50
        ;

        this.mesh.dispose();
        this.trail.dispose();
    }
}

Future<void> complexityTest() async {
    final CanvasElement canvas = querySelector("#canvas");
    final B.Engine engine = new B.Engine(canvas, false);

    final B.Scene scene = new B.Scene(engine);

    final B.Camera camera = new B.FreeCamera("camera", B.Vector3(0,50,00), scene)
    ..attachControl(canvas);

    final B.Texture depth = scene.enableDepthRenderer(camera, false).getDepthMap();
    //final B.Light light = new B.HemisphericLight("light1", new B.Vector3(0,1,0), scene);
    final B.Light light = new B.DirectionalLight("light", B.Vector3(-.5,-1,0), scene);

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

    final Math.Random rand = new Math.Random(1);

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
        ), scene)
            //..convertToUnIndexedMesh()
            ..isVisible = false;

        final B.Material treeMat = new B.StandardMaterial("treeMat$i", scene)
            ..specularColor.set(0.1,0.1,0.1)
            ..diffuseColor.set(0.25 + rand.nextDouble() * 0.5, 0.25 + rand.nextDouble() * 0.5, 0.25 + rand.nextDouble() * 0.5)
            ..freeze()
        ;
        tree.material = treeMat;

        for (int j=0; j<treeCountPerType; j++) {
            final double x = terrainSize * (rand.nextDouble() - 0.5);
            final double z = terrainSize * (rand.nextDouble() - 0.5);
            final double y = terrain.getHeightAtCoordinates(x,z);
            final double scale = 0.85 + rand.nextDouble() * 0.3;
            //print("($x, $y, $z)");
            final B.InstancedMesh instance = tree.createInstance("tree${i}_$j")
                ..position.set(x, y + 2.5 * scale, z)
                ..scaling.set(scale, scale, scale)
                ..freezeWorldMatrix()
                ..alwaysSelectAsActiveMesh = true
                ..doNotSyncBoundingInfo = true;
        }
    }

    final B.Mesh projectileMesh = B.MeshBuilder.CreateBox("projectile", B.MeshBuilderCreateBoxOptions(size: 1))
        ..material = (new B.StandardMaterial("boxmat", scene)
            ..diffuseColor.set(1, 0, 0)
        )..isVisible = false;
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
    const double spawnInterval = 0.25;

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
                final TestObject obj = new TestObject(projectileMesh, explosions, new B.Vector3(0,30,0), new B.Vector3(vx,vy,vz), 2.0 + rand.nextDouble() * 5.0);
                obj.trail.start();
                objects.add(obj);
            }
        }

        scene.render();
    }));

    document.body.append(new DivElement()..append(new ButtonElement()..text="show inspector"..onClick.listen((MouseEvent e) { scene.debugLayer.show(); })));
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