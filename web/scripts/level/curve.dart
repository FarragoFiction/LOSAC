import "dart:html";
import "dart:math" as Math;

import "package:collection/collection.dart";
import "package:CubeLib/CubeLib.dart" as B;
import "package:yaml/yaml.dart";

import "../renderer/2d/bounds.dart";
import "../renderer/2d/matrix.dart";
import "../utility/extensions.dart";
import "../utility/fileutils.dart";
import "../utility/levelutils.dart";
import "connectible.dart";
import "domainmap.dart";
import 'levelheightmap.dart';
import "levelobject.dart";
import "pathnode.dart";

class Curve extends LevelObject with Connectible {
    static const String typeDesc = "Curve";

    final List<CurveVertex> _vertices = <CurveVertex>[];
    late List<CurveVertex> vertices;
    bool renderVertices = true;
    bool renderSegments = false;
    double width = 25.0;

    late Connector startConnector;
    late Connector endConnector;

    final List<CurveSegment> segments = <CurveSegment>[];

    Curve() {
        this.vertices = new UnmodifiableListView<CurveVertex>(_vertices);
        this.drawUI = false;
    }

    factory Curve.fromYaml(YamlMap yaml) {
        final String name = yaml["name"];
        final Set<String> fields = <String>{"name","model"};

        final DataSetter set = FileUtils.dataSetter(yaml, typeDesc, name, fields);

        final Set<CurveVertex> verts = <CurveVertex>{};

        set("points", (YamlList pointsList) => FileUtils.typedList("points", pointsList, (YamlMap item, int index) {
            final Set<String> vertFields = <String>{};
            final DataSetter setVert = FileUtils.dataSetter(item, "$typeDesc vertex", "$name $index", vertFields);

            final CurveVertex vert = new CurveVertex();

            setVert("x", (num n) => vert.position.x = n.toDouble());
            setVert("y", (num n) => vert.position.y = n.toDouble());
            setVert("z", (num n) => vert.zPosition = n.toDouble());
            setVert("rotation", (num n) => vert.rot_angle = n.toDouble());

            setVert("handle1", (num n) => vert.handle1 = n.toDouble());
            setVert("handle2", (num n) => vert.handle2 = n.toDouble());

            verts.add(vert);

            FileUtils.warnInvalidFields(item, "$typeDesc vertex", "$name $index", vertFields);
        }));

        if (verts.length < 2) {
            throw MessageOnlyException("$typeDesc $name must have at least 2 points");
        }

        final Curve curve = new Curve();
        for(final CurveVertex vert in verts) {
            curve.addVertex(vert);
        }

        set("width", (num n) => curve.width = n.toDouble());

        set("affectLevelHeight", (bool b) => curve.generateLevelHeightData = b);

        FileUtils.warnInvalidFields(yaml, typeDesc, name, fields);

        curve.updateConnectors();

        return curve;
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

                final B.Vector3 v1pos = new B.Vector3(v1.position.x, v1.zPosition, v1.position.y);
                final B.Vector3 v2pos = new B.Vector3(v2.position.x, v2.zPosition, v2.position.y);
                final B.Vector3 o1 = v1.handle2pos + v1pos;
                final B.Vector3 o2 = v2.handle1pos + v2pos;

                final num maxlength = v1.handle2pos.length() + v2.handle1pos.length() + (o2-o1).length();

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
                    final num dot = v1.dot(v2);
                    mult = Math.sqrt(2 / (dot + 1));
                }

                seg.cornerMultiplier = mult;
            }
        }
    }

    static const int minSegments = 8;
    int getSegmentCountForLength(num length) {
        final double segs = length/(width*4);

        return Math.sqrt(segs * segs * 0.6 + minSegments * minSegments).ceil();
    }

    CurveSegment bezier(double fraction, B.Vector3 v1, B.Vector3 v1handle, B.Vector3 v2, B.Vector3 v2handle) {
        final double t = fraction;
        final double nt = 1 - t;

        final B.Vector3 b1 = v1 * nt*nt*nt;
        final B.Vector3 b2 = v1handle * 3*nt*nt*t;
        final B.Vector3 b3 = v2handle * 3*nt*t*t;
        final B.Vector3 b4 = v2 * t*t*t;

        final B.Vector3 point = b1+b2+b3+b4;

        final B.Vector3 p1 = v1 * -3*nt*nt;
        final B.Vector3 p2 = v1handle * 3 * (1 - 4*t + 3*t*t);
        final B.Vector3 p3 = v2handle * 3 * (2*t - 3*t*t);
        final B.Vector3 p4 = v2 * 3*t*t;

        final B.Vector3 total = p1 + p2 + p3 + p4;
        B.Vector2 norm = new B.Vector2(total.x,total.z).normalize();
        norm = new B.Vector2(-norm.y, norm.x);

        return new CurveSegment()..position.set(point.x, point.z)..zPosition = point.y.toDouble()..norm = norm..parentObject=this;
    }

    @override
    Iterable<PathNode> generatePathNodes() {
        final List<PathNode> nodes = <PathNode>[];

        CurveSegment seg;
        CurveSegment? prev;

        for(int i=0; i<segments.length; i++) {
            seg = segments[i];

            final PathNode node = new PathNode()
                ..position.setFrom(seg.getWorldPosition())
                ..zPosition = seg.zPosition
                ..pathObject = this;
            seg.node = node;
            nodes.add(node);

            if (prev != null) {
                node.connectTo(prev.node!);
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

        final List<List<B.Vector2>> polys = new List<List<B.Vector2>>.generate(segments.length, (int i) => <B.Vector2>[B.Vector2.Zero(),B.Vector2.Zero(),B.Vector2.Zero(),B.Vector2.Zero()]);

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
            final List<B.Vector2> poly = worldPoly.map((B.Vector2 v) => domainMap.getRawLocalCoords(v.x, v.y)).toList();

            final int top = Math.min(Math.min(poly[0].y, poly[1].y), Math.min(poly[2].y, poly[3].y)).floor();
            final int bottom = Math.max(Math.max(poly[0].y, poly[1].y), Math.max(poly[2].y, poly[3].y)).ceil();

            // polygon fill
            // http://alienryderflex.com/polygon_fill/
            {
                const int polyCorners = 4;

                for (int y = top; y <= bottom; y++) {
                    int nodes = 0;
                    final List<int> nodeX = new List<int>.filled(polyCorners, 0);

                    int j = polyCorners-1;
                    for (int i=0; i<polyCorners; i++) {
                        if (poly[i].y < y && poly[j].y >= y || poly[j].y < y && poly[i].y >= y) {
                            nodeX[nodes++] = (poly[i].x + (y - poly[i].y) / (poly[j].y-poly[i].y) * (poly[j].x-poly[i].x)).round();
                        }
                        j = i;
                    }

                    int k=0;
                    while (k < nodes-1) {
                        if (nodeX[k] > nodeX[k+1]) {
                            final int swap = nodeX[k];
                            nodeX[k] = nodeX[k+1];
                            nodeX[k+1] = swap;
                            if(k != 0) {
                                k--;
                            }
                        } else {
                            k++;
                        }
                    }

                    for (int l=0; l<nodes; l+=2) {
                        for (int pixelX = nodeX[l]; pixelX<=nodeX[l+1]; pixelX++) {
                            domainMap.setVal(pixelX, y, seg.node!.id);

                            if (this.generateLevelHeightData) {
                                final B.Vector2 uv = LevelUtils.inverseBilinear(new B.Vector2(pixelX,y), poly[1], poly[0], poly[3], poly[2]);
                                if (uv.y >= 0) { // make sure the UV isn't broken by coord weirdness
                                    double height = segments[i].zPosition;
                                    if (i == 0) {
                                        // first segment, thin, just interpolate up
                                        final double s = uv.y * 0.5;
                                        height = (segments[i+1].zPosition * s) + (segments[i].zPosition * (1 - s));
                                    } else if (i == segments.length-1) {
                                        // last segment, thin, just interpolate down
                                        final double s = 0.5 - uv.y * 0.5;
                                        height = (segments[i-1].zPosition * s) + (segments[i].zPosition * (1 - s));
                                    } else {
                                        // all the other segments, interpolate both ways
                                        if (uv.y < 0.5) {
                                            final double s = 0.5 - uv.y;
                                            height = (segments[i - 1].zPosition * s) + (segments[i].zPosition * (1 - s));
                                        } else if (uv.y > 0.5) {
                                            final double s = uv.y - 0.5;
                                            height = (segments[i + 1].zPosition * s) + (segments[i].zPosition * (1 - s));
                                        }
                                    }
                                    heightMap.setVal(pixelX, y, height);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @override
    Connector? getConnector(String descriptor) {
        switch(descriptor) {
            case "start":
                return startConnector;
            case "end":
                return endConnector;
        }
    }
}

class CurveSegment extends LevelObject {
    late B.Vector2 norm;
    double cornerMultiplier = 1.0;

    PathNode? node;
}

class CurveVertex extends LevelObject with HasMatrix {
    double slope = 0.0;
    double _handle1 = 10.0;
    double _handle2 = 10.0;
    B.Vector3? _handle1pos;
    B.Vector3? _handle2pos;

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
        super.rot_angle = val.toDouble();
        _handle1pos = null;
        _handle2pos = null;
    }

    B.Vector3 get handle1pos {
        final double z = Math.tan(this.slope) * handle1;
        final B.Vector2 xy = new B.Vector2(-handle1,0)..applyMatrixInPlace(matrix);
        _handle1pos ??= new B.Vector3(xy.x, -z, xy.y);
        return _handle1pos!;
    }
    B.Vector3 get handle2pos {
        final double z = Math.tan(this.slope) * handle2;
        final B.Vector2 xy = new B.Vector2(handle2,0)..applyMatrixInPlace(matrix);
        _handle2pos ??= new B.Vector3(xy.x, z, xy.y);
        return _handle2pos!;
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