import "dart:math" as Math;
import "dart:typed_data";

import "package:CubeLib/CubeLib.dart" as B;
import "package:js/js.dart" as JS;
import "package:LoaderLib/Loader.dart";

import "../../../level/levelobject.dart";
import '../renderer3d.dart';
import 'curvemeshprovider.dart';
import 'gridmeshprovider.dart';
import "meshprovider.dart";

class Renderer3DStandardAssets {
    final Renderer3D renderer;

    late B.Material defaultMaterial;
    late MeshProvider<SimpleLevelObject> defaultMeshProvider;

    late GridMeshProvider debugGridMeshProvider;
    late CurveMeshProvider debugCurveMeshProvider;
    late EndCapMeshProvider debugEndcapMeshProvider;

    late B.Texture emptyTexture;

    late B.Material towerPreviewMaterial;

    late B.ShaderMaterial rangeMaterial;
    late B.AbstractMesh rangeIndicator;
    late B.AbstractMesh rangePreview;

    late B.AbstractMesh hoverIndicator;
    late B.AbstractMesh selectionIndicator;
    late PickerPredicate pickerPredicateInterop;
    late PickerPredicate gridPickerPredicateInterop;

    Renderer3DStandardAssets(Renderer3D this.renderer);

    Future<void> initialise() async {
        // ########## Shader file loading ##########

        final String basicVert = await Loader.getResource("assets/shaders/basic.vert");
        final String basicDepthVert = await Loader.getResource("assets/shaders/basic_with_depth.vert");
        final String rangeFrag = await Loader.getResource("assets/shaders/range.frag");

        // ########## Textures ##########

        this.emptyTexture = new B.RawTexture(new Uint8ClampedList.fromList(<int>[
            0,0,0,0
        ]), 1,1, B.Engine.TEXTUREFORMAT_RGBA, renderer.scene, false, false, B.Texture.NEAREST_SAMPLINGMODE, B.Engine.TEXTURETYPE_UNSIGNED_BYTE)
            ..wrapU = B.Texture.WRAP_ADDRESSMODE
            ..wrapV = B.Texture.WRAP_ADDRESSMODE
        ;

        // ########## Materials ##########

        this.defaultMaterial = new B.StandardMaterial("defaultMaterial", renderer.scene);

        this.towerPreviewMaterial = new B.StandardMaterial("towerPreviewMaterial", renderer.scene)
            ..diffuseColor.set(0.25, 0.5, 0.25)
            ..emissiveColor.set(0.0, 0.5, 0.0)
            ..specularColor.set(0, 0, 0)
            ..alpha = 0.5
        ;

        this.rangeMaterial = new B.ShaderMaterialWithAlphaTestTexture("rangeIndicatorMaterial", renderer.scene, B.ShaderMaterialShaderPath(
            vertexSource: basicDepthVert,
            fragmentSource: rangeFrag
        ), B.IShaderMaterialOptions(
            needAlphaTesting: true,
            needAlphaBlending: true,
            attributes: <String>["position", "normal", "uv", "color"],
            uniforms: <String>["world", "viewProjection", "worldViewProjection", "depthValues", "colour"],
            samplers: <String>["depth"],
            //defines: <String>["#define INSTANCES"]
        ),emptyTexture)
            ..setTexture("depth", renderer.depthTexture!)
            ..setVector2("depthValues", B.Vector2(renderer.camera.minZ, renderer.camera.minZ + renderer.camera.maxZ))
            //..setColor4("colour", B.Color4(0.9,0.2,0.2,0.65))
            ..backFaceCulling = false
        ;

        // ########## Meshes ##########

        this.defaultMeshProvider = new MeshProvider<SimpleLevelObject>(renderer);

        this.debugGridMeshProvider = new DebugGridMeshProvider(renderer);
        this.debugCurveMeshProvider = new DebugCurveMeshProvider(renderer);
        this.debugEndcapMeshProvider = new DebugEndCapMeshProvider(renderer);

        final B.Color4 rangePreviewColour = new B.Color4(0.4,1.0,0.4,0.65);
        final B.Color4 rangeIndicatorColour = new B.Color4(0.9,0.2,0.2,0.65);

        final B.Mesh rangeCircle = B.CylinderBuilder.CreateCylinder("rangePreview", B.CylinderBuilderCreateCylinderOptions(
            diameter: 2,
            height: 200,
            tessellation: 24,
        ), renderer.scene)
            ..isVisible = false
            ..material = rangeMaterial
        ;
        final B.Mesh rangeCircle2 = rangeCircle.clone("rangeIndicator")!;

        this.rangePreview = rangeCircle..onBeforeDrawObservable.add(JS.allowInterop((B.Mesh mesh, B.EventState eventState) {
            rangeMaterial.setColor4("colour", rangePreviewColour);
        }));
        this.rangeIndicator = rangeCircle2..onBeforeDrawObservable.add(JS.allowInterop((B.Mesh mesh, B.EventState eventState) {
        rangeMaterial.setColor4("colour", rangeIndicatorColour);
        }));

        this.hoverIndicator = B.PlaneBuilder.CreatePlane("hover", B.PlaneBuilderCreatePlaneOptions(size:1))
            ..rotation.x = Math.pi * 0.5
            ..isVisible = false;
        renderer.scene.addMesh(hoverIndicator);

        this.selectionIndicator = B.PlaneBuilder.CreatePlane("selection", B.PlaneBuilderCreatePlaneOptions(size:1))
            ..rotation.x = Math.pi * 0.5
            ..isVisible = false;
        renderer.scene.addMesh(selectionIndicator);

        // ########## Miscellaneous ##########

        this.pickerPredicateInterop = JS.allowInterop(renderer.pickerPredicate);
        this.gridPickerPredicateInterop = JS.allowInterop(renderer.gridPickerPredicate);

    }
}