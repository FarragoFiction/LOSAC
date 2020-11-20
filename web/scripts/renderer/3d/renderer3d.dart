import "dart:html";
import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;
import "package:js/js.dart" as JS;
import "package:js/js_util.dart" as JsUtil;

import "../../level/datamap.dart";
import "../../level/grid.dart";
import "../../level/level.dart";
import '../../level/levelobject.dart';
import '../../level/selectable.dart';
import "../../utility/extensions.dart";
import "../renderer.dart";
import 'models/meshprovider.dart';
import 'renderable3d.dart';

typedef PickerPredicate = bool Function(B.AbstractMesh mesh);

class Renderer3D extends Renderer {
    static const double _rotationRate = 0.01;
    static const double _panRate = 1.1;
    final CanvasElement canvas;

    B.Engine babylon;
    B.Scene scene;
    B.ArcRotateCamera camera;
    B.Vector2 camPos = B.Vector2.Zero();

    B.Vector2 cameraAnchor;
    double cameraAnchorRange;

    Set<Renderable3D> renderList = <Renderable3D>{};

    B.Material defaultMaterial;
    MeshProvider<SimpleLevelObject> defaultMeshProvider;

    B.Mesh selectionIndicator;
    PickerPredicate pickerPredicateInterop;
    PickerPredicate gridPickerPredicateInterop;

    Renderer3D(CanvasElement this.canvas) {
        this.babylon = new B.Engine(this.canvas, false);
        this.scene = new B.Scene(this.babylon);//..constantlyUpdateMeshUnderPointer = true;
        this.container = this.canvas;

        this.pickerPredicateInterop = JS.allowInterop(this.pickerPredicate);
        this.gridPickerPredicateInterop = JS.allowInterop(this.gridPickerPredicate);

        this.selectionIndicator = B.PlaneBuilder.CreatePlane("selection", B.PlaneBuilderCreatePlaneOptions(size:1))
            ..rotation.x = Math.pi * 0.5
            ..isVisible = false;
        this.scene.addMesh(selectionIndicator);

        this.canvas.onContextMenu.listen((MouseEvent event) {
            event.preventDefault();
        });

        /*this.camera = new B.FreeCamera("Camera", B.Vector3(0,150,00), scene)
            ..rotation.x = Math.pi * 0.5
            ..upVector.set(0, 0, 1)
            ..maxZ = 5000
            ..attachControl(canvas);*/

        this.camera = new B.ArcRotateCamera("Camera", Math.pi/2, 0, 1000, new B.Vector3(0,0,0), scene)
            ..maxZ = 5000.0
            ..allowUpsideDown = false
            //..attachControl(canvas, true, false, 1)
            //..panningSensibility = 10
        ;
        /*window.console.log(camera.inputs.attached);
        final B.ArcRotateCameraPointersInput pointers = JsUtil.getProperty(camera.inputs.attached, "pointers");
        window.console.log(pointers);
        camera.panningAxis.set(1, 1, 1);
        camera.inertia = 0;
        camera.panningInertia = 0;
        pointers.buttons.removeAt(0);*/


        this.scene.addLight(new B.DirectionalLight("sun", new B.Vector3(1,-5,1), scene));

        this.defaultMaterial = new B.StandardMaterial("defaultMaterial", scene);
        this.defaultMeshProvider = new MeshProvider<SimpleLevelObject>(this);
    }

    void initCameraBounds(Level level) {
        final Rectangle<num> bounds = level.bounds;
        this.cameraAnchor = new B.Vector2(bounds.left + bounds.width * 0.5, bounds.top + bounds.height * 0.5);
        this.cameraAnchorRange = Math.sqrt(bounds.width * bounds.width + bounds.height * bounds.height) * 0.5;
        print("anchor: $cameraAnchor, range: $cameraAnchorRange");
    }

    @override
    void runRenderLoop(RenderLoopFunction loop) {
        babylon.runRenderLoop(JS.allowInterop(() {
            loop(this.babylon.getDeltaTime());
        }));
    }

    @override
    void draw([double interpolation = 0]) {
        this.updateSelectionIndicator(interpolation);
        this.scene.render();
    }

    void updateSelectionIndicator(double interpolation) {
        final Selectable hover = this.engine.hovering;
        if (hover == null) {
            this.selectionIndicator.isVisible = false;
        } else {
            this.selectionIndicator.isVisible = true;
            this.selectionIndicator.position.setFromGameCoords(hover.getModelPosition(), hover.getZPosition() + 3.0);
            this.selectionIndicator.rotation.y = hover.getModelRotation();
            this.selectionIndicator.scaling.setAll(20);
        }
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
    void click(int button, MouseEvent e) {
        final B.AbstractMesh picked = scene.meshUnderPointer;

        if (picked != null) {
            print(picked?.metadata?.owner);
        }

    }

    @override
    void drag(int button, Point<num> offset, MouseEvent e) {
        if (button == 2) { // right mouse rotate
            camera
                ..alpha -= offset.x * _rotationRate
                ..beta -= offset.y * _rotationRate
                //..update()
            ;
        } else if (button == 0) { // left mouse pan
            final B.Vector2 direction = new B.Vector2(offset.y,offset.x)..rotateInPlace(camera.alpha);
            moveTo(camPos.x + direction.x * _panRate, camPos.y - direction.y * _panRate);
        }
    }

    @override
    void moveTo(num x, num y) {
        //print("moving to $x,$y");
        if (cameraAnchor == null) {
            setCameraLocation(x, y);
        } else {
            final B.Vector2 difference = new B.Vector2(x,y) - cameraAnchor;
            final double dist = difference.length();
            if (dist > cameraAnchorRange) {
                difference..normalize()..scaleInPlace(cameraAnchorRange);
                setCameraLocation(cameraAnchor.x + difference.x, cameraAnchor.y + difference.y);
            } else {
                setCameraLocation(x, y);
            }
        }
    }

    void setCameraLocation(num x, num y) {
        camPos.set(x, y);
        if (this.engine?.level?.levelHeightMap != null) {
            final double z = this.engine.level.cameraHeightMap.getSmoothVal(x, y);
            camera.target.set(-x, z, y);
        } else {
            camera.target.set(-x, 0, y);
        }
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
        this.camera.radius += e.deltaY;
    }

    @override
    void destroy() {
        this.babylon.dispose();
    }

    void createDataMapDebugModel<D,A extends List<D>>(DataMap<D,A> map) {
        if (map.debugCanvas == null) { map.updateDebugCanvas(); }

        final String name = "DataMapDebug_${map.runtimeType}";
        final num w = map.width * DataMap.cellSize;
        final num h = map.height * DataMap.cellSize;

        final B.Texture texture = new B.DynamicTexture(name, JsUtil.jsify(<String,dynamic>{"width":w, "height":h}), scene, false)
            ..hasAlpha = true
            ..getContext().drawImage(map.debugCanvas, 0,0)
            ..update()
        ;

        final B.Material material = new B.StandardMaterial(name, scene)
            ..emissiveColor.set(1, 1, 1)
            ..alphaCutOff = 0.5
            ..diffuseTexture = texture
            ..specularColor.set(0, 0, 0)
        ;

        final B.Mesh plane = B.PlaneBuilder.CreatePlane(name, new B.PlaneBuilderCreatePlaneOptions(width: w, height: h))
            ..position.setFromGameCoords(new B.Vector2(map.pos_x + w/2, map.pos_y + h/2), 0)
            ..material = material
            ..rotation.x = Math.pi * 0.5
            ..rotation.y = Math.pi
        ;

        scene.addMesh(plane);
    }

    @override
    Selectable getSelectableAtScreenPos([int x, int y]) {
        x ??= this.scene.pointerX;
        y ??= this.scene.pointerY;

        final B.Ray ray = scene.createPickingRay(x, y, null, camera);
        final B.PickingInfo pick = scene.pickWithRay(ray, pickerPredicateInterop, true);

        if (pick.pickedMesh == null) {
            final B.PickingInfo gridPick = scene.pickWithRay(ray, gridPickerPredicateInterop, true);
            if (gridPick.pickedMesh == null) {
                return null;
            } else if (gridPick.pickedMesh?.metadata?.owner is Grid) {
                final Grid grid = gridPick.pickedMesh.metadata.owner;
                return grid.getSelectable(gridPick.pickedPoint.toGameCoords());
            }
        } else if (pick.pickedMesh?.metadata?.owner is Selectable) {
            final Selectable selectable = pick.pickedMesh.metadata.owner;
            return selectable.getSelectable(pick.pickedPoint.toGameCoords());
        }

        return null;
    }

    bool pickerPredicate(B.AbstractMesh mesh) {

        return mesh.isPickable &&
            mesh.isVisible &&
            mesh.isReady() &&
            mesh.isEnabled() &&
            (mesh?.metadata?.owner is Selectable) &&
            !(mesh?.metadata?.owner is Grid);
    }

    bool gridPickerPredicate(B.AbstractMesh mesh) {
        return mesh.isPickable &&
            !mesh.isVisible &&
            mesh.isReady() &&
            mesh.isEnabled() &&
            (mesh?.metadata?.owner is Grid);
    }
}

class MeshInfo {
    SimpleLevelObject owner;
}
