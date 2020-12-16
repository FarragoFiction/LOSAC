import "dart:html";

import "package:CubeLib/CubeLib.dart" as B;

import "../engine/entity.dart";
import "../level/levelobject.dart";
import "../renderer/3d/floateroverlay.dart";
import "../utility/styleconversion.dart";

abstract class FloaterEntity extends LevelObject with Entity, HasFloater {
    final String cssClass;

    CanvasStyle _styleDef;
    CanvasStyle get styleDef {
        _styleDef ??= renderer.floaterOverlay.getCanvasStyle(cssClass);
        return _styleDef;
    }

    FloaterEntity(String this.cssClass);

    @override
    void logicUpdate([num dt = 0]) {
    }

    @override
    void renderUpdate([num interpolation = 0]) {
    }

    @override
    void generateMesh() {
        // floater entities specifically don't have a model, so this is a no-op on purpose
    }
}

class FloatingText extends FloaterEntity {
    String caption;

    FloatingText(String this.caption, String cssClass) : super(cssClass);

    @override
    bool drawFloater(B.Vector3 pos, CanvasRenderingContext2D ctx) {
        styleDef.applyTextStyle(ctx);

        ctx.fillText(caption, pos.x, pos.y);

        return true;
    }
}