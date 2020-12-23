import "dart:html";
import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "../engine/entity.dart";
import "../level/levelobject.dart";
import "../renderer/3d/floateroverlay.dart";
import '../resources/resourcetype.dart';
import "../utility/extensions.dart";
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

    void fillText(String caption, num x, num y, {Map<String,String> data}) {
        // TODO: line splitting and stuff for floating text, tutorial or dialogue use?
    }
}

class FloatingText extends FloaterEntity {
    String caption;

    FloatingText(String this.caption, String cssClass) : super(cssClass);

    @override
    bool drawFloater(B.Vector3 pos, CanvasRenderingContext2D ctx) {
        styleDef.applyTextStyle(ctx);

        ctx.fillText(engine.localisation.translate(caption), pos.x, pos.y);

        return true;
    }
}

mixin RisingFade on FloaterEntity {
    double duration = 2;
    double fadeFraction = 0.25;
    double fateState = 1;
    double riseMaxHeight = 50;
    double riseHeight = 0;
    double age = 0;
    double previousAge = 0;
    B.Vector3 floaterPos = B.Vector3.Zero();

    @override
    void logicUpdate([num dt = 0]) {
        super.logicUpdate(dt);
        previousAge = age;
        age += dt;

        if (age > duration) {
            this.kill();
        }
    }

    @override
    void renderUpdate([num interpolation = 0]) {
        final double displayAge = (previousAge * (1-interpolation)) + (age * interpolation);
        this.riseHeight = riseMaxHeight * (displayAge / duration);
        this.fateState = 1.0 - (Math.max(0, displayAge - (duration * (1 - fadeFraction))) / (duration * fadeFraction));

        super.renderUpdate(interpolation);
    }

    @override
    bool drawFloater(B.Vector3 pos, CanvasRenderingContext2D ctx) {
        floaterPos..setFrom(pos)..y -= this.riseHeight;
        ctx.globalAlpha = fateState;
        return super.drawFloater(floaterPos, ctx);
    }
}

class RisingText extends FloatingText with RisingFade {
    RisingText(String caption, String cssClass) : super(caption, cssClass);
}

class ResourceFloater extends FloaterEntity {
    ResourceValue resources;
    bool positive;

    ResourceFloater(ResourceValue this.resources, [bool this.positive = true]) : super("ResourcePopup");

    @override
    bool drawFloater(B.Vector3 pos, CanvasRenderingContext2D ctx) {
        if (resources.isEmpty) { return false; }

        styleDef.applyTextStyle(ctx);
        ctx.textAlign = "left";
        final double iconSize = styleDef.textLineHeight * 0.8;

        double totalWidth = 0;
        final List<String> captions = <String>[];
        final List<double> iconOffsets = <double>[];
        if (positive) {
            totalWidth += ctx.measureText("+").width + 2;
        } else {
            totalWidth += ctx.measureText("-").width + 2;
        }

        for (final double value in resources.values) {
            iconOffsets.add(totalWidth);
            final String caption = value.floor().toString();
            totalWidth += ctx.measureText(caption).width + iconSize + 6;
            captions.add(caption);
        }

        if (positive) {
            ctx.fillText("+", pos.x - totalWidth * 0.5, pos.y);
        } else {
            ctx.fillText("-", pos.x - totalWidth * 0.5, pos.y);
        }

        int i=0;
        for (final ResourceType type in resources.keys) {
            final double offset = iconOffsets[i];
            final double x = pos.x - totalWidth * 0.5 + offset;

            final ImageElement icon = engine.localisation.formatting.getIconMaybe("resource.${type.getRegistrationKey()}");
            if (icon != null) {
                ctx.drawImageScaled(icon, x + 2, pos.y - iconSize, iconSize, iconSize);
            }

            ctx.fillText(captions[i], x + iconSize + 5, pos.y);
            i++;
        }

        return true;
    }
}

class ResourcePopup extends ResourceFloater with RisingFade {
    ResourcePopup(ResourceValue resources, [bool positive = true]) : super(resources, positive);
}