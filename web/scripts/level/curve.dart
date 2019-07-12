import "dart:html";
import "dart:math" as Math;

import "package:collection/collection.dart";

import "../renderer/2d/bounds.dart";
import "../renderer/2d/matrix.dart";
import "../renderer/2d/vector.dart";
import "connectible.dart";
import "domainmap.dart";
import "levelobject.dart";
import "pathnode.dart";

class Curve extends LevelObject with Connectible {
    final List<CurveVertex> _vertices = <CurveVertex>[];
    List<CurveVertex> vertices;
    bool renderVertices = true;
    bool renderSegments = false;
    double width = 25.0;

    Connector startConnector;
    Connector endConnector;

    final List<CurveSegment> segments = <CurveSegment>[];

    Curve() : super() {
        this.vertices = new UnmodifiableListView<CurveVertex>(_vertices);
        this.drawUI = false;
    }

    @override
    void draw2D(CanvasRenderingContext2D ctx) {

        if (vertices.length > 1) {
            CurveVertex v1 = vertices.first;
            CurveVertex v2;

            ctx
                ..strokeStyle = "#BBBBBB"
                ..beginPath()
                ..moveTo(v1.pos_x, v1.pos_y);

            for (int i=1; i<vertices.length; i++) {
                v2 = vertices[i];

                final Vector o1 = v1.handle2pos + new Vector(v1.pos_x, v1.pos_y);
                final Vector o2 = v2.handle1pos + new Vector(v2.pos_x, v2.pos_y);

                ctx.bezierCurveTo(o1.x, o1.y, o2.x, o2.y, v2.pos_x, v2.pos_y);

                v1 = v2;
            }

            ctx.stroke();
        }

        if (!segments.isEmpty) {
            ctx.strokeStyle="#000000";

            final List<Vector> left = <Vector>[];
            final List<Vector> right = <Vector>[];

            for(int i=0; i<segments.length; i++) {
                final CurveSegment seg = segments[i];
                final Vector pos = seg.posVector;
                double mult = 1.0;

                if (i != 0 && i != segments.length-1) {
                    final Vector v1 = (pos - segments[i - 1].posVector).norm();
                    final Vector v2 = (segments[i + 1].posVector - pos).norm();
                    final double dot = v1.dot(v2);
                    mult = Math.sqrt(2 / (dot + 1));
                }

                mult *= width;

                final Vector offset = seg.norm * mult;

                left.add(pos + offset);
                right.add(pos - offset);

                ctx
                    ..beginPath()
                    ..moveTo(pos.x + offset.x, pos.y + offset.y)
                    ..lineTo(pos.x - offset.x, pos.y - offset.y)
                    ..stroke();
            }

            ctx
                ..beginPath()
                ..moveTo(left.first.x, left.first.y);
            for (final Vector v in left) {
                ctx.lineTo(v.x, v.y);
            }
            ctx.stroke();
            ctx
                ..beginPath()
                ..moveTo(right.first.x, right.first.y);
            for (final Vector v in right) {
                ctx.lineTo(v.x, v.y);
            }
            ctx.stroke();
        }
    }

    void addVertex(CurveVertex vert) {
        this._vertices.add(vert);
        this.addSubObject(vert);
        vert.parentObject = this;
    }

    void rebuildSegments() {
        segments.clear();

        if (vertices.length > 1) {
            CurveVertex v1 = vertices.first;
            CurveVertex v2;

            for (int i = 1; i < vertices.length; i++) {
                v2 = vertices[i];

                final Vector v1pos = new Vector(v1.pos_x, v1.pos_y);
                final Vector v2pos = new Vector(v2.pos_x, v2.pos_y);
                final Vector o1 = v1.handle2pos + v1pos;
                final Vector o2 = v2.handle1pos + v2pos;

                final double maxlength = v1.handle2pos.length + v2.handle1pos.length + (o2-o1).length;

                final int segmentCount = getSegmentCountForLength(maxlength);

                final int skip = i > 1 ? 1 : 0;
                for (int j=skip; j<segmentCount; j++) {
                    final double fraction = j / (segmentCount - 1);

                    segments.add(bezier(fraction, v1pos, o1, v2pos, o2));
                }

                v1 = v2;
            }
        }
    }

    static const int minSegments = 8;
    int getSegmentCountForLength(double length) {
        final double segs = length/(width*4);

        return Math.sqrt(segs * segs * 0.6 + minSegments * minSegments).ceil();
    }

    CurveSegment bezier(double fraction, Vector v1, Vector v1handle, Vector v2, Vector v2handle) {
        final double t = fraction;
        final double nt = 1 - t;

        final Vector b1 = v1 * nt*nt*nt;
        final Vector b2 = v1handle * 3*nt*nt*t;
        final Vector b3 = v2handle * 3*nt*t*t;
        final Vector b4 = v2 * t*t*t;

        final Vector point = b1+b2+b3+b4;

        final Vector p1 = v1 * -3*nt*nt;
        final Vector p2 = v1handle * 3 * (1 - 4*t + 3*t*t);
        final Vector p3 = v2handle * 3 * (2*t - 3*t*t);
        final Vector p4 = v2 * 3*t*t;

        Vector norm = (p1 + p2 + p3 + p4).norm();
        norm = new Vector(-norm.y, norm.x);

        return new CurveSegment()..pos_x = point.x..pos_y = point.y..norm = norm..parentObject=this;
    }

    @override
    Iterable<PathNode> generatePathNodes() {
        final List<PathNode> nodes = <PathNode>[];

        CurveSegment seg;
        CurveSegment prev;

        for(int i=0; i<segments.length; i++) {
            seg = segments[i];

            final PathNode node = new PathNode()
                ..posVector = seg.getWorldPosition()
                ..pathObject = this;
            seg.node = node;
            nodes.add(node);

            if (prev != null) {
                node.connectTo(prev.node);
            }

            prev = seg;
        }

        this.startConnector.node = nodes.first;
        this.endConnector.node = nodes.last;

        return nodes;
    }

    @override
    void clearPathNodes() {
        for (final CurveSegment segment in segments) {
            segment.node = null;
        }

        super.clearPathNodes();
    }

    void updateConnectors() {
        this.clearConnectors();

        if (vertices.length < 2) { return; }

        {
            final CurveVertex vertex = this.vertices.first;
            final Connector connector = new ConnectorNegative()
                ..rot_angle = Math.pi;
            vertex.addSubObject(connector);
            startConnector = connector;
            connector.parentObject = vertex;//this;
        }

        {
            final CurveVertex vertex = this.vertices.last;
            final Connector connector = new ConnectorNegative();
            vertex.addSubObject(connector);
            endConnector = connector;
            connector.parentObject = vertex;//this;
        }
    }

    void recentreOrigin() {
        final Vector newCentreWorld = new Vector(bounds.left + bounds.width / 2, bounds.top + bounds.height / 2);
        final Vector offset = getLocalPositionFromWorld(newCentreWorld);

        this.posVector += offset;
        for (final LevelObject obj in subObjects) {
            obj.posVector -= offset;
        }
        for (final CurveSegment segment in segments) {
            segment.posVector -= offset;
        }
    }

    @override
    Rectangle<num> calculateBounds() {
        final List<Vector> points = <Vector>[];

        for (final CurveSegment segment in segments) {
            final Vector vpos = segment.posVector;
            points.add(vpos + segment.norm * width);
            points.add(vpos - segment.norm * width);
        }

        return polyBoundsLocal(this, points);
    }

    @override
    void fillDomainMap(DomainMapRegion map) {

    }
}

class CurveSegment extends LevelObject {
    Vector norm;

    PathNode node;

    @override
    void draw2D(CanvasRenderingContext2D ctx) {
        ctx.fillStyle="#40CC40";
        ctx.fillRect(-1, -1, 3, 3);

        final Vector o = (this.norm) * 15;

        ctx
            ..strokeStyle = "#40CC40"
            ..beginPath()
            ..moveTo(o.x, o.y)
            ..lineTo(- o.x, -o.y)
            ..stroke();
    }
}

class CurveVertex extends LevelObject with HasMatrix {
    double _handle1 = 10.0;
    double _handle2 = 10.0;
    Vector _handle1pos;
    Vector _handle2pos;

    double get handle1 => _handle1;
    set handle1(double val) {
        _handle1 = val;
        _handle1pos = null;
        _handle2pos = null;
    }
    double get handle2 => _handle2;
    set handle2(double val) {
        _handle2 = val;
        _handle1pos = null;
        _handle2pos = null;
    }

    @override
    set rot_angle(num val) {
        super.rot_angle = val;
        _handle1pos = null;
        _handle2pos = null;
    }

    Vector get handle1pos {
        _handle1pos ??= new Vector(0,handle1).applyMatrix(matrix);
        return _handle1pos;
    }
    Vector get handle2pos {
        _handle2pos ??= new Vector(0,-handle2).applyMatrix(matrix);
        return _handle2pos;
    }

    @override
    void draw2D(CanvasRenderingContext2D ctx) {}

    @override
    void drawUI2D(CanvasRenderingContext2D ctx) {
        final Vector v = new Vector(0,1).applyMatrix(matrix);

        ctx
            ..strokeStyle = "#3333FF"
            ..beginPath()
            ..moveTo(handle1 * v.x, handle1 * v.y)
            ..lineTo(handle2 * -v.x, handle2 * -v.y)
            ..stroke();

        ctx
            ..strokeStyle = "#AAAAAA"
            ..beginPath()
            ..arc(handle1 * v.x, handle1 * v.y, 3, 0, Math.pi * 2)
            ..stroke()
            ..beginPath()
            ..arc(handle2 * -v.x, handle2 * -v.y, 3, 0, Math.pi * 2)
            ..stroke();

        ctx
            ..fillStyle = "#FF0000"
            ..beginPath()
            ..arc(0,0, 3, 0, Math.pi * 2)
            ..fill();
    }
}