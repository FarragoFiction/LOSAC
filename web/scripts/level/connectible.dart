import "dart:html";
import "dart:math" as Math;

import "../renderer/2d/vector.dart";
import "levelobject.dart";
import "pathnode.dart";

mixin Connectible on LevelObject implements PathNodeObject {
    Iterable<Connector> connectors;
    bool drawConnectors = false;

    @override
    void initMixins() {
        super.initMixins();
        connectors = this.subObjects.whereType();
    }

    @override
    void connectPathNodes() {
        for (final Connector c in connectors) {
            if (c.node != null && c.other != null && c.other.node != null) {
                c.node.connectTo(c.other.node);
            }
        }
    }

    @override
    void clearPathNodes() {
        for (final Connector c in connectors) {
            c.node = null;
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
    bool get connected => this.other != null;

    PathNode node;

    Connector(String this.fillStyle);

    bool canConnectToType(Connector other);

    void connect(Connector connector) {
        if (!this.connected && !connector.connected) {
            this.other = connector;
            connector.other = this;
        }
    }

    void disconnect() {
        if (connected) {
            other.other = null;
            this.other = null;
        }
    }

    @override
    void draw2D(CanvasRenderingContext2D ctx) {
        if(connected) { return; }

        ctx.fillStyle = fillStyle;

        ctx
            ..beginPath()
            ..moveTo(-displaySize, 0)
            ..lineTo(0, -displaySize)
            ..lineTo(displaySize, 0)
            ..closePath()
            ..fill();
    }

    void connectAndOrient(Connector target) {
        if (target == null || this.connected || target.connected) {
            print("invalid connection: $target");
            return;
        }

        this.connect(target);

        final Vector targetPos = target.getWorldPosition();
        final num targetAngle = target.getWorldRotation() + Math.pi;
        final num thisAngle = this.getWorldRotation();

        final double angleOffset = targetAngle - thisAngle;

        final Vector rotatedPos = this.posVector.rotate(angleOffset);
        final Vector movePos = targetPos - rotatedPos;


        final Vector finalPos = this.getLocalPositionFromWorld(movePos) + this.parentObject.posVector;
        final double finalAngle = this.parentObject.rot_angle + angleOffset;

        this.parentObject.rot_angle = finalAngle;
        this.parentObject.posVector = finalPos;
    }
}

class ConnectorPositive extends Connector {

    ConnectorPositive() : super("#40C0FF");

    @override
    bool canConnectToType(Connector other) => !(other is ConnectorPositive);
}

class ConnectorNegative extends Connector {

    ConnectorNegative() : super("#FF8000");

    @override
    bool canConnectToType(Connector other) => !(other is ConnectorNegative);
}

class ConnectorNeutral extends Connector {

    ConnectorNeutral() : super("#90FF60");

    @override
    bool canConnectToType(Connector other) => true;
}