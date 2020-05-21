
import "dart:html";

import "package:CubeLib/CubeLib.dart" as B;
import "package:js/js.dart" as JS;
import "package:LoaderLib/Loader.dart";

import "jstest.dart";

Future<void> main() async {
    final CanvasElement canvas = querySelector("#canvas");
    final B.Engine engine = new B.Engine(canvas, false);

    final B.Scene scene = new B.Scene(engine);

    final B.Camera camera = new B.ArcRotateCamera("camera", 0, 0, 5, B.Vector3.Zero(), scene)
        ..attachControl(canvas, false);

    final B.Texture depth = scene.enableDepthRenderer(camera, false).getDepthMap();

    final B.Light light = new B.HemisphericLight("light1", new B.Vector3(0,1,0), scene);

    final B.Mesh plane = B.MeshBuilder.CreatePlane("plane", B.MeshBuilderCreatePlaneOptions( size: 2 ) , scene);

    final String vert = await Loader.getResource("assets/shaders/basic.vert");
    final String frag = await Loader.getResource("assets/shaders/timehole.frag");

    final B.Texture alphaTestTexture = new B.Texture("assets/textures/alphaTest.png", engine);

    final B.ShaderMaterial material = new ShaderMaterialWithAlphaTestTexture("material", scene, B.IShaderMaterialOptions(
        vertexSource: vert,
        fragmentSource: frag,
    ), B.IShaderMaterialOptions(
        needAlphaTesting: true
    ), alphaTestTexture)
        ..backFaceCulling = false
    ;

    plane.material = material;

    final DateTime startTime = new DateTime.now();
    scene.registerBeforeRender(JS.allowInterop(([dynamic a, dynamic b]) {
        material.setFloat("time", (DateTime.now().difference(startTime)).inMilliseconds * 0.001);
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