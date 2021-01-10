import 'dart:async';
import "dart:html";
import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;
import "package:js/js.dart" as JS;
import "package:js/js_util.dart" as JsUtil;

import '../../engine/engine.dart';
import "../../entities/towertype.dart";
import "../../level/datamap.dart";
import "../../level/grid.dart";
import "../../level/level.dart";
import '../../level/levelobject.dart';
import '../../level/selectable.dart';
import "../../utility/extensions.dart";
import "../renderer.dart";
import "floateroverlay.dart";
import 'models/standardassets.dart';
import 'renderable3d.dart';

typedef PickerPredicate = bool Function(B.AbstractMesh mesh);

class Renderer3D extends Renderer {
    static const double _rotationRate = 0.01;
    static const double _panRate = 1.1;
    final CanvasElement canvas;
    final CanvasElement _floaterCanvas;
    FloaterOverlay floaterOverlay;

    B.Engine babylon;
    B.Scene scene;
    B.ArcRotateCamera camera;
    B.Vector2 camPos = B.Vector2.Zero();

    B.Vector2 cameraAnchor;
    double cameraAnchorRange;

    Set<Renderable3D> renderList = <Renderable3D>{};
    Iterable<HasFloater> floaterList;

    /// container for various standard default models and textures
    Renderer3DStandardAssets standardAssets;

    B.DepthRenderer depthRenderer;
    B.Texture depthTexture;

    B.AbstractMesh towerPreviewMesh;
    TowerType towerPreviewType;
    GridCell towerPreviewCell;

    StreamSubscription<Event> resizeHandler;

    Element pointerElement;

    Renderer3D(CanvasElement this.canvas, CanvasElement this._floaterCanvas);
    @override
    Future<void> initialise() async {
        this.floaterList = this.renderList.whereType();

        this.babylon = new B.Engine(this.canvas, false);
        this.canvas.draggable = false;
        this.floaterOverlay = new FloaterOverlay(this, _floaterCanvas);
        this.updateCanvasSize();

        this.scene = new B.Scene(this.babylon);
        this.container = this.canvas;

        this.canvas.onContextMenu.listen((MouseEvent event) {
            event.preventDefault();
        });

        this.camera = new B.ArcRotateCamera("Camera", Math.pi/2, 0, 1000, new B.Vector3(0,0,0), scene)
            ..maxZ = 5000.0
            ..allowUpsideDown = false
        ;

        this.depthRenderer = scene.enableDepthRenderer(camera);
        this.depthTexture = depthRenderer.getDepthMap();

        this.scene.addLight(new B.DirectionalLight("sun", new B.Vector3(1,-5,1), scene));

        // init standard models and textures
        this.standardAssets = new Renderer3DStandardAssets(this);
        await standardAssets.initialise();

        this.resizeHandler = window.onResize.listen((Event event) { this.updateCanvasSize(); });
    }

    @override
    void initUiEventHandlers() {
        final dynamic manager = JsUtil.getProperty(this.scene, "_inputManager");
        //window.console.log(manager);

        this.pointerElement = engine.uiController.container.parent;

        manager.detachControl();
        manager.attachControl(false,false,true, pointerElement);
        manager.attachControl(true,true,false);
    }

    void updatePointer() {
        if (engine.input.dragging) {
            pointerElement.classes.remove("hovering");
            pointerElement.classes.add("dragging");
        } else if (engine.hovering != null) {
            pointerElement.classes.add("hovering");
        } else {
            pointerElement.classes.remove("dragging");
            pointerElement.classes.remove("hovering");
        }
    }

    void initCameraBounds(Level level) {
        final Rectangle<num> bounds = level.bounds;
        this.cameraAnchor = new B.Vector2(bounds.left + bounds.width * 0.5, bounds.top + bounds.height * 0.5);
        this.cameraAnchorRange = Math.sqrt(bounds.width * bounds.width + bounds.height * bounds.height) * 0.5;
        //print("anchor: $cameraAnchor, range: $cameraAnchorRange");
    }

    @override
    void runRenderLoop(RenderLoopFunction loop) {
        babylon.runRenderLoop(JS.allowInterop(() {
            loop(this.babylon.getDeltaTime());
        }));
    }

    @override
    void stopRenderLoop() {
        babylon.stopRenderLoop();
    }

    @override
    void draw([double interpolation = 0]) {
        this.updateSelectionIndicator(interpolation);
        this.scene.render();
        this.floaterOverlay.draw();

        this.updatePointer();
    }

    void updateCanvasSize() {
        babylon.setSize(window.innerWidth, window.innerHeight);
        depthRenderer?.getDepthMap()?.resize(JsUtil.jsify(<String,int>{"width":window.innerWidth, "height":window.innerHeight}));
        engine?.uiController?.resize();
        floaterOverlay.updateCanvasSize();
    }

    void updateSelectionIndicator(double interpolation) {
        final Selectable hover = this.engine.hovering;
        final Selectable selected = this.engine.selected;

        if (hover == null || hover == selected) {
            this.standardAssets.hoverIndicator.isVisible = false;
        } else {
            this.standardAssets.hoverIndicator.isVisible = true;
            this.standardAssets.hoverIndicator.position.setFromGameCoords(hover.getModelPosition(), hover.getZPosition() + 3.0);
            this.standardAssets.hoverIndicator.rotation.y = hover.getModelRotation();
            this.standardAssets.hoverIndicator.scaling.setAll(20);
        }

        if (selected == null) {
            this.standardAssets.selectionIndicator.isVisible = false;
            this.standardAssets.rangeIndicator.isVisible = false;
            this.clearTowerPreview();
        } else {
            this.standardAssets.selectionIndicator.isVisible = true;
            this.standardAssets.selectionIndicator.position.setFromGameCoords(selected.getModelPosition(), selected.getZPosition() + 3.0);
            this.standardAssets.selectionIndicator.rotation.y = selected.getModelRotation();
            this.standardAssets.selectionIndicator.scaling.setAll(25);
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
        final SelectionInfo selection = getSelectableAtScreenPos(e.offset.x, e.offset.y);
        if (button == MouseButtons.left) {
            engine.click(button, selection?.world, selection?.selectable);
        } else {
            engine.click(button, selection?.world, null);
        }
    }

    @override
    void drag(int button, Point<num> offset, MouseEvent e) {
        if (button == MouseButtons.right) {
            camera
                ..alpha -= offset.x * _rotationRate
                ..beta -= offset.y * _rotationRate
                //..update()
            ;
        } else if (button == MouseButtons.left) {
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
        this.floaterOverlay.destroy();
        resizeHandler.cancel();
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
    SelectionInfo getSelectableAtScreenPos([int x, int y]) {
        x ??= this.scene.pointerX;
        y ??= this.scene.pointerY;

        final B.Ray ray = scene.createPickingRay(x, y, null, camera);
        final B.PickingInfo pick = scene.pickWithRay(ray, standardAssets.pickerPredicateInterop, true);

        if (pick.pickedMesh == null) {
            final B.PickingInfo gridPick = scene.pickWithRay(ray, standardAssets.gridPickerPredicateInterop, true);
            if (gridPick.pickedMesh == null) {
                return null;
            } else if (gridPick.pickedMesh?.metadata?.owner is Grid) {
                final Grid grid = gridPick.pickedMesh.metadata.owner;
                final B.Vector2 world = gridPick.pickedPoint.toGameCoords();
                return new SelectionInfo(grid.getSelectable(world), world.toPoint());
            }
        } else if (pick.pickedMesh?.metadata?.owner is Selectable) {
            final Selectable selectable = pick.pickedMesh.metadata.owner;
            final B.Vector2 world = pick.pickedPoint.toGameCoords();
            return new SelectionInfo(selectable.getSelectable(world), world.toPoint());
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

    void updateTowerPreview(TowerType type, GridCell cell) {
        if (type == towerPreviewType && cell == towerPreviewCell) { return; }

        if (type == null || cell == null) {
            towerPreviewMesh?.dispose();
            towerPreviewMesh = null;
            towerPreviewCell = null;
            towerPreviewType = null;
            standardAssets.rangePreview.isVisible = false;
        } else {
            if (towerPreviewMesh == null || towerPreviewType != type) {
                towerPreviewMesh?.dispose();

                B.Mesh mesh = type.mesh;
                mesh ??= standardAssets.defaultMeshProvider.provide(null);

                towerPreviewMesh = mesh..material = standardAssets.towerPreviewMaterial;
            }

            towerPreviewMesh.position.setFromGameCoords(cell.getWorldPosition(), cell.getZPosition());
            towerPreviewMesh.rotation.y = cell.getWorldRotation();

            if (type.weapon != null) {
                standardAssets.rangePreview.position.setFrom(towerPreviewMesh.position);
                standardAssets.rangePreview.scaling.set(type.weapon.range, 1, type.weapon.range);
                standardAssets.rangePreview.isVisible = true;
            } else {
                standardAssets.rangePreview.isVisible = false;
            }

            towerPreviewType = type;
            towerPreviewCell = cell;
        }
    }
    void clearTowerPreview() => updateTowerPreview(null, null);
}

class MeshInfo {
    SimpleLevelObject owner;
}


