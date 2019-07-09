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

    void clearConnectors() {
        final List<Connector> conlist = connectors.toList();
        for (final Connector connector in conlist) {
            connector.disconnect();
            this.removeSubObject(connector);
        }
    }
}

abstract class Connector extends LevelObject {
    static const num displaySize = 8;
    final String fillStyle;

    Connector other;

    PathNode node;

    Connector(String this.fillStyle);

    void disconnect() {
        if (other != null) {
            this.other = null;
            other.disconnect();
        }
    }

    @override
    void draw2D(CanvasRenderingContext2D ctx) {
        ctx.fillStyle = fillStyle;

        ctx
            ..beginPath()
            ..moveTo(-displaySize, 0)
            ..lineTo(0, -displaySize)
            ..lineTo(displaySize, 0)
            ..closePath()
            ..fill();
    }
}

class ConnectorPositive extends Connector {

    ConnectorPositive() : super("#40C0FF");
}

class ConnectorNegative extends Connector {

    ConnectorNegative() : super("#FF8000");
}