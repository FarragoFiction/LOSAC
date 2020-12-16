import "dart:html";

import "package:CubeLib/CubeLib.dart" as B;

import "../../level/levelobject.dart";
import "../../utility/extensions.dart";
import "../../utility/styleconversion.dart";
import "renderer3d.dart";

class FloaterOverlay {
    static Element styleElement = querySelector("#stylecontainer");

    final Renderer3D renderer;
    final CanvasElement canvas;

    final Map<String,_FloaterStyleEntry> _styleMap = <String,_FloaterStyleEntry>{};

    bool _drewSomethingLastFrame = false;

    FloaterOverlay(Renderer3D this.renderer, CanvasElement this.canvas);

    void updateCanvasSize() {
        canvas.width = renderer.canvas.width;
        canvas.height = renderer.canvas.height;
        draw();
    }

    void draw() {
        final CanvasRenderingContext2D ctx = canvas.context2D;
        final int w = canvas.width;
        final int h = canvas.height;

        if (_drewSomethingLastFrame) {
            ctx.clearRect(0, 0, w, h);
            _drewSomethingLastFrame = false;
        }

        B.Matrix identity;
        B.Matrix transform;
        B.Viewport viewport;

        final List<_FloaterRenderEntry> toRender = <_FloaterRenderEntry>[];

        for (final HasFloater floater in renderer.floaterList) {
            if (!floater.shouldDrawFloater()) {
                continue;
            }
            if (identity == null) {
                identity = B.Matrix.Identity();
                transform = renderer.scene.getTransformMatrix();
                viewport = renderer.camera.viewport.toGlobal(w, h);
            }

            final B.Vector3 projected = B.Vector3.Project(floater.getFloaterPos(), identity, transform, viewport);

            toRender.add(new _FloaterRenderEntry(projected, floater));
        }

        toRender.sort();

        for (final _FloaterRenderEntry entry in toRender) {
            final bool drawn = entry.floater.drawFloater(entry.pos, ctx);

            _drewSomethingLastFrame |= drawn;
        }
    }

    void destroy() {
        // clear out the style map items
        for (final _FloaterStyleEntry entry in _styleMap.values) {
            entry.element.remove();
        }
    }

    CanvasStyle getCanvasStyle(String className) {
        if (!_styleMap.containsKey(className)) {
            final Element element = new DivElement()..className = className;
            styleElement.append(element);

            final CanvasStyle style = new CanvasStyle(element.getComputedStyle());

            _styleMap[className] = new _FloaterStyleEntry(element, style);
            return style;
        }

        return _styleMap[className].style;
    }
}

class _FloaterStyleEntry {
    final Element element;
    final CanvasStyle style;

    _FloaterStyleEntry(Element this.element, CanvasStyle this.style);
}

class _FloaterRenderEntry implements Comparable<_FloaterRenderEntry> {
    final B.Vector3 pos;
    final HasFloater floater;

    _FloaterRenderEntry(B.Vector3 this.pos, HasFloater this.floater);

    @override
    int compareTo(_FloaterRenderEntry other) {
        return other.pos.z.compareTo(this.pos.z);
    }
}

mixin HasFloater on SimpleLevelObject {
    B.Vector3 getFloaterPos() {
        if (this.mesh != null) { return this.mesh.position; }

        return new B.Vector3()..setFromGameCoords(this.getModelPosition(), this.getZPosition());
    }

    bool shouldDrawFloater() => true;
    bool drawFloater(B.Vector3 pos, CanvasRenderingContext2D ctx) {
        ctx.fillStyle = "red";
        ctx.textAlign = "center";

        final String text = "$runtimeType $hashCode";

        ctx.fillText(text, pos.x, pos.y);

        return true;
    }
}