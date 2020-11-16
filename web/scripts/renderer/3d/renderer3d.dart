import "dart:html";
import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;
import "package:js/js.dart" as JS;

import "../../level/level.dart";
import '../../level/levelobject.dart';
import "../../utility/extensions.dart";
import "../renderer.dart";
import 'models/meshprovider.dart';
import 'renderable3d.dart';

class Renderer3D extends Renderer {
    final CanvasElement canvas;

    B.Engine babylon;
    B.Scene scene;
    B.ArcRotateCamera camera;

    Set<Renderable3D> renderList = <Renderable3D>{};

    B.Material defaultMaterial;
    MeshProvider<SimpleLevelObject> defaultMeshProvider;

    Renderer3D(CanvasElement this.canvas) {
        this.babylon = new B.Engine(this.canvas, false);
        this.scene = new B.Scene(this.babylon);
        this.container = this.canvas;

        /*this.camera = new B.FreeCamera("Camera", B.Vector3(0,150,00), scene)
            ..rotation.x = Math.pi * 0.5
            ..upVector.set(0, 0, 1)
            ..maxZ = 5000
            ..attachControl(canvas);*/

        this.camera = new B.ArcRotateCamera("Camera", Math.pi/2, 0, 1000, new B.Vector3(0,0,0), scene)
            ..maxZ = 5000.0
            ..allowUpsideDown = false
        ;

        this.scene.addLight(new B.DirectionalLight("sun", new B.Vector3(1,-5,1), scene));

        this.defaultMaterial = new B.StandardMaterial("defaultMaterial", scene);
        this.defaultMeshProvider = new MeshProvider<SimpleLevelObject>(this);
    }

    @override
    void runRenderLoop(RenderLoopFunction loop) {
        babylon.runRenderLoop(JS.allowInterop(() {
            loop(this.babylon.getDeltaTime());
        }));
    }

    @override
    void draw([double interpolation = 0]) {
        this.scene.render();
    }

    @override
    void addRenderable(Object object) {
        if (object is Renderable3D) {
            this.renderList.add(object);

            final Renderable3D renderable = object;
            renderable.renderer = this;
            if (renderable.mesh == null) {
                renderable.generateMesh();
            }

            if (renderable.mesh != null) {
                this.scene.addMesh(renderable.mesh);
            }
        }
    }
    @override
    void removeRenderable(Object object) {
        if (object is Renderable3D) {
            this.renderList.remove(object);

            final Renderable3D renderable = object;
            if (renderable.mesh != null) {
                this.scene.removeMesh(renderable.mesh);
                renderable.mesh.dispose();
            }
        }
    }

    @override
    void click(MouseEvent e) {
        final B.Ray ray = scene.createPickingRay(scene.pointerX, scene.pointerY, B.Matrix.Identity(), camera);

        // pick models first
        final B.PickingInfo pick = scene.pickWithRay(ray);

        if (pick.hit) {
            print("mesh:");
            print(pick.pickedMesh);

            final MeshInfo info = pick.pickedMesh?.metadata;

            final B.Vector2 worldPos = pick.pickedPoint.toGameCoords();
            this.engine.click(new Point<num>(worldPos.x,worldPos.y), info?.owner);
        }
    }

    @override
    void drag(MouseEvent e, Point<num> offset) {
        // TODO: implement drag
    }

    @override
    void moveTo(num x, num y) {
        final B.ArcRotateCamera c = this.camera;
        c.target.set(-x, 0, y);
    }

    @override
    void centreOnObject(Object object) {
        if (object is LevelObject) {
            final Math.Rectangle<num> bounds = object.bounds;
            this.moveTo((bounds.left + bounds.right)*0.5, (bounds.top + bounds.bottom)*0.5);
        } else if (object is Level) {
            final Math.Rectangle<num> bounds = object.bounds;
            this.moveTo((bounds.left + bounds.right)*0.5, (bounds.top + bounds.bottom)*0.5);
        }
    }

    @override
    void onMouseDown(MouseEvent e) {}

    @override
    void onMouseMove(MouseEvent e) {}

    @override
    void onMouseUp(MouseEvent e) {}

    @override
    void onMouseWheel(WheelEvent e) {
        // TODO: implement onMouseWheel
    }

    @override
    void destroy() {
        this.babylon.dispose();
    }
}

class MeshInfo {
    SimpleLevelObject owner;
}