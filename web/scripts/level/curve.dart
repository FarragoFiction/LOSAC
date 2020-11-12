import "dart:html";
import "dart:math" as Math;

import "package:collection/collection.dart";
import "package:CubeLib/CubeLib.dart" as B;

import "../renderer/2d/bounds.dart";
import "../renderer/2d/matrix.dart";
import '../renderer/3d/models/curvemeshprovider.dart';
import "../utility/extensions.dart";
import "connectible.dart";
import "domainmap.dart";
import 'levelheightmap.dart';
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

    /*@override
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

                final Vector offset = seg.norm * width * seg.cornerMultiplier;

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
    }*/

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

                final B.Vector2 v1pos = new B.Vector2(v1.position.x, v1.position.y);
                final B.Vector2 v2pos = new B.Vector2(v2.position.x, v2.position.y);
                final B.Vector2 o1 = v1.handle2pos + v1pos;
                final B.Vector2 o2 = v2.handle1pos + v2pos;

                final double maxlength = v1.handle2pos.length() + v2.handle1pos.length() + (o2-o1).length();

                final int segmentCount = getSegmentCountForLength(maxlength);

                final int skip = i > 1 ? 1 : 0;
                for (int j=skip; j<segmentCount; j++) {
                    final double fraction = j / (segmentCount - 1);

                    segments.add(bezier(fraction, v1pos, o1, v2pos, o2));
                }

                v1 = v2;
            }

            for(int i=0; i<segments.length; i++) {
                final CurveSegment seg = segments[i];
                final B.Vector2 pos = seg.position;
                double mult = 1.0;

                if (i != 0 && i != segments.length - 1) {
                    final B.Vector2 v1 = (pos - segments[i - 1].position).normalize();
                    final B.Vector2 v2 = (segments[i + 1].position - pos).normalize();
                    final double dot = v1.dot(v2);
                    mult = Math.sqrt(2 / (dot + 1));
                }

                seg.cornerMultiplier = mult;
            }
        }
    }

    static const int minSegments = 8;
    int getSegmentCountForLength(double length) {
        final double segs = length/(width*4);

        return Math.sqrt(segs * segs * 0.6 + minSegments * minSegments).ceil();
    }

    CurveSegment bezier(double fraction, B.Vector2 v1, B.Vector2 v1handle, B.Vector2 v2, B.Vector2 v2handle) {
        final double t = fraction;
        final double nt = 1 - t;

        final B.Vector2 b1 = v1 * nt*nt*nt;
        final B.Vector2 b2 = v1handle * 3*nt*nt*t;
        final B.Vector2 b3 = v2handle * 3*nt*t*t;
        final B.Vector2 b4 = v2 * t*t*t;

        final B.Vector2 point = b1+b2+b3+b4;

        final B.Vector2 p1 = v1 * -3*nt*nt;
        final B.Vector2 p2 = v1handle * 3 * (1 - 4*t + 3*t*t);
        final B.Vector2 p3 = v2handle * 3 * (2*t - 3*t*t);
        final B.Vector2 p4 = v2 * 3*t*t;

        B.Vector2 norm = (p1 + p2 + p3 + p4).normalize();
        norm = new B.Vector2(-norm.y, norm.x);

        return new CurveSegment()..position.setFrom(point)..norm = norm..parentObject=this;
    }

    @override
    Iterable<PathNode> generatePathNodes() {
        final List<PathNode> nodes = <PathNode>[];

        CurveSegment seg;
        CurveSegment prev;

        for(int i=0; i<segments.length; i++) {
            seg = segments[i];

            final PathNode node = new PathNode()
                ..position.setFrom(seg.getWorldPosition())
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
        final B.Vector2 newCentreWorld = new B.Vector2(bounds.left + bounds.width / 2, bounds.top + bounds.height / 2);
        final B.Vector2 offset = getLocalPositionFromWorld(newCentreWorld);

        this.position.addInPlace(offset);
        for (final LevelObject obj in subObjects) {
            obj.position.subtractInPlace(offset);
        }
        for (final CurveSegment segment in segments) {
            segment.position.subtractInPlace(offset);
        }
    }

    @override
    Rectangle<num> calculateBounds() {
        final List<B.Vector2> points = <B.Vector2>[];

        for (final CurveSegment segment in segments) {
            final B.Vector2 vpos = segment.position;
            points.add(vpos + segment.norm * width * segment.cornerMultiplier);
            points.add(vpos - segment.norm * width * segment.cornerMultiplier);
        }

        return polyBoundsLocal(this, points);
    }

    @override
    void fillDataMaps(DomainMapRegion domainMap, LevelHeightMapRegion heightMap) {

        final List<List<B.Vector2>> polys = new List<List<B.Vector2>>.generate(segments.length, (int i) => new List<B.Vector2>(4));

        for(int i=0; i<segments.length; i++) {
            final CurveSegment seg = segments[i];
            final B.Vector2 pos = seg.getWorldPosition();

            final List<B.Vector2> poly = polys[i];

            final B.Vector2 left = pos - seg.norm * width * seg.cornerMultiplier * 1.1;
            final B.Vector2 right = pos + seg.norm * width * seg.cornerMultiplier * 1.1;

            // not first, do previous side
            if (i != 0) {
                // shouldn't need to do anything here
                // the loop fills the first two verts of later polys when it does the second two of the previous one
            } else {
                poly[0] = left;
                poly[1] = right;
            }
            // not last, do next side
            if(i != segments.length - 1) {
                final CurveSegment next = segments[i+1];
                final List<B.Vector2> nextPoly = polys[i+1];
                final B.Vector2 nextPos = next.getWorldPosition();

                final B.Vector2 nextLeft = nextPos - next.norm * width * next.cornerMultiplier;
                final B.Vector2 nextRight = nextPos + next.norm * width * next.cornerMultiplier;

                final B.Vector2 aveLeft = (left + nextLeft) / 2;
                final B.Vector2 aveRight = (right + nextRight) / 2;

                poly[2] = aveRight;
                poly[3] = aveLeft;

                nextPoly[0] = aveLeft;
                nextPoly[1] = aveRight;
            } else {
                poly[2] = right;
                poly[3] = left;
            }
        }

        for (int i=0; i<segments.length; i++) {
            final CurveSegment seg = segments[i];
            final List<B.Vector2> worldPoly = polys[i];
            final List<B.Vector2> poly = worldPoly.map((B.Vector2 v) => domainMap.getLocalCoords(v.x, v.y)).toList();

            final int top = Math.min(Math.min(poly[0].y, poly[1].y), Math.min(poly[2].y, poly[3].y)).floor();
            final int bottom = Math.max(Math.max(poly[0].y, poly[1].y), Math.max(poly[2].y, poly[3].y)).ceil();

            // polygon fill
            // http://alienryderflex.com/polygon_fill/
            {
                const int polyCorners = 4;

                for (int y = top; y <= bottom; y++) {
                    int nodes = 0;
                    final List<int> nodeX = new List<int>(polyCorners);

                    int j = polyCorners-1;
                    for (int i=0; i<polyCorners; i++) {
                        if (poly[i].y < y && poly[j].y >= y || poly[j].y < y && poly[i].y >= y) {
                            nodeX[nodes++] = (poly[i].x + (y - poly[i].y) / (poly[j].y-poly[i].y) * (poly[j].x-poly[i].x)).round();
                        }
                        j = i;
                    }

                    int i=0;
                    while (i < nodes-1) {
                        if (nodeX[i] > nodeX[i+1]) {
                            final int swap = nodeX[i];
                            nodeX[i] = nodeX[i+1];
                            nodeX[i+1] = swap;
                            if(i != 0) {
                                i--;
                            }
                        } else {
                            i++;
                        }
                    }

                    for (int i=0; i<nodes; i+=2) {
                        for (int pixelX = nodeX[i]; pixelX<=nodeX[i+1]; pixelX++) {
                            domainMap.setVal(pixelX, y, seg.node.id);
                        }
                    }
                }
            }
        }
    }
}

class CurveSegment extends LevelObject {
    B.Vector2 norm;
    double cornerMultiplier = 1.0;

    PathNode node;
}

class CurveVertex extends LevelObject with HasMatrix {
    double _handle1 = 10.0;
    double _handle2 = 10.0;
    B.Vector2 _handle1pos;
    B.Vector2 _handle2pos;

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

    B.Vector2 get handle1pos {
        _handle1pos ??= new B.Vector2(-handle1,0).applyMatrix(matrix);
        return _handle1pos;
    }
    B.Vector2 get handle2pos {
        _handle2pos ??= new B.Vector2(handle2,0)..applyMatrixInPlace(matrix);
        return _handle2pos;
    }

    @override
    void drawUI2D(CanvasRenderingContext2D ctx, double scaleFactor) {
        final B.Vector2 v = new B.Vector2(0,1)..applyMatrixInPlace(matrix);

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