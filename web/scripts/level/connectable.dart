import "dart:html";

import "levelobject.dart";
import "pathnode.dart";

mixin Connectable on LevelObject implements PathNodeObject {
    Iterable<Connector> connectors;
    bool drawConnectors = false;

    @override
    void initMixins() {
        super.initMixins();
        connectors = this.subObjects.whereType();
    }

    void connectPathNodes() {
        for (final Connector c in connectors) {
            if (c.node != null && c.other != null && c.other.node != null) {
                c.node.connectTo(c.other.node);
            }
        }
    }

    @override
    void draw2D(CanvasRenderingContext2D ctx) {
        super.draw2D(ctx);

        for (final Connector connector in connectors) {
            connector.drawToCanvas(ctx);
        }
    }
}

class Connector extends LevelObject {
    static const num displaySize = 6;

    Connector other;

    PathNode node;

    @override
    void draw2D(CanvasRenderingContext2D ctx) {
        ctx.fillStyle = "#FF8000";

        ctx
            ..beginPath()
            ..moveTo(-displaySize, 0)
            ..lineTo(0, displaySize)
            ..lineTo(displaySize, 0)
            ..closePath()
            ..fill();
    }
}