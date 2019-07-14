import "dart:html";
import "dart:math" as Math;
import "dart:typed_data";

import "package:CommonLib/Colours.dart";
import "package:CommonLib/Random.dart";

import "../renderer/2d/vector.dart";

class DomainMap {
    static const int cellSize = 4;
    static const int cellBuffer = 3;

    final num pos_x;
    final num pos_y;
    final int width;
    final int height;

    Uint16List _array;
    Uint16List get array => _array;

    CanvasElement debugCanvas;

    factory DomainMap(num x, num y, num levelWidth, num levelHeight) {
        final int width = (levelWidth/cellSize).ceil() + cellBuffer * 2;
        final int height = (levelHeight/cellSize).ceil() + cellBuffer * 2;
        final Uint16List array = new Uint16List(width*height);
        return new DomainMap.fromData(x, y, width, height, array);
    }

    DomainMap.fromData(num x, num y, int this.width, int this.height, Uint16List array) : pos_x = x - cellSize * cellBuffer, pos_y = y - cellSize * cellBuffer {
        _array = array;
        if (array.length != width * height) {
            throw Exception("DomainMap array length does not match dimensions! $width*$height = ${width*height} vs ${array.length}");
        }
    }

    int getVal(num x, num y) {
        final Vector local = getLocalCoords(x, y);
        return getValLocal(local.x, local.y);
    }

    int getID(int x, int y) {
        if (x < 0 || x >= width || y < 0 || y >= height) {
            return -1;
        }
        return y * width + x;
    }
    int getValLocal(int x, int y) {
        final int id = getID(x,y);
        if (id == -1) {
            return 0;
        }
        return array[id];
    }
    void setValLocal(int x, int y, int val) {
        final int id = getID(x,y);
        if (id == -1) {
            return;
        }
        array[id] = val;
    }

    Vector getWorldCoords(int x, int y) {
        if (getID(x, y) == -1) {
            return null;
        }

        return new Vector((x + 0.5) * cellSize + pos_x, (y + 0.5) * cellSize + pos_y);
    }

    Vector getLocalCoords(num x, num y) => new Vector(((x - pos_x) / cellSize).floor(), ((y - pos_y) / cellSize).floor());

    DomainMapRegion subRegion(int x, int y, int w, int h) => new DomainMapRegion(this, x, y, w, h);
    DomainMapRegion subRegionForBounds(Rectangle<num> bounds) {
        final Vector topLeft = getLocalCoords(bounds.left, bounds.top);
        final Vector bottomRight = getLocalCoords(bounds.left + bounds.width, bounds.top + bounds.height);

        return subRegion(topLeft.x, topLeft.y, bottomRight.x - topLeft.x + 1, bottomRight.y - topLeft.y + 1);
    }

    void updateDebugCanvas() {
        debugCanvas = new CanvasElement(width: this.width * cellSize, height: this.height * cellSize);
        final CanvasRenderingContext2D ctx = debugCanvas.context2D;

        final Map<int,String> colours = <int,String>{};
        final Random rand = new Random(1);

        int id, nodeId;
        for (int y = 0; y<height; y++) {
            for (int x = 0; x<width; x++) {
                id = getID(x, y);
                nodeId = array[id];

                if (nodeId == 0) { continue; }

                if (!colours.containsKey(nodeId)) {
                    final Colour col = new Colour()..setLABScaled(rand.nextDouble(0.5)+ 0.5, rand.nextDouble(),rand.nextDouble());
                    colours[nodeId] = col.toStyleString();
                }
                ctx.fillStyle = colours[nodeId];

                ctx.fillRect(x * cellSize, y * cellSize, cellSize, cellSize);
            }
        }
    }

    Set<int> nodesAlongLine(double x1, double y1, double x2, double y2, double thickness) {
        final Set<int> nodes = <int>{};
        final Vector p1 = getLocalCoords(x1, y1);
        final Vector p2 = getLocalCoords(x2, y2);
        final double distTest = (thickness) / cellSize;

        final double a = p1.y - p2.y;
        final double b = p2.x - p1.x;
        final double c = p1.x * p2.y - p2.x * p1.y;

        final double divisor = Math.sqrt(a*a + b*b);

        final int left = Math.min(p1.x, p2.x);
        final int right = Math.max(p1.x, p2.x);
        final int top = Math.min(p1.y, p2.y);
        final int bottom = Math.max(p1.y, p2.y);

        //print("line <= $distTest");

        for (int y = top; y<=bottom; y++) {
            for (int x = left; x<=right; x++) {
                final double dist = (a * x + b * y + c).abs() / divisor;

                if (dist <= distTest) {
                    //print("true: $x,$y -> $dist");
                    nodes.add(getValLocal(x, y));
                } else {
                    //print("false: $x,$y -> $dist");
                }
            }
        }

        //print("$p1 -> $p2 : $nodes");
        return nodes;
    }
}

class DomainMapRegion {
    final DomainMap map;
    final int ox;
    final int oy;
    final int width;
    final int height;

    DomainMapRegion(DomainMap this.map, int this.ox, int this.oy, int this.width, int this.height);

    int getID(int x, int y) {
        if (x < 0 || x >= width || y < 0 || y >= height) {
            return -1;
        }

        final int px = x + ox;
        final int py = y + oy;

        if (px < 0 || px >= map.width || py < 0 || py >= map.height) {
            return -1;
        }

        return py * map.width + px;
    }

    int getVal(int x, int y) {
        final int id = getID(x,y);
        if (id == -1) {
            return 0;
        }
        return map.array[id];
    }
    void setVal(int x, int y, int val) {
        final int id = getID(x,y);
        if (id == -1) {
            return;
        }
        map.array[id] = val;
    }

    Vector getWorldCoords(int x, int y) {
        if (getID(x, y) == -1) {
            return null;
        }

        return new Vector((x + ox + 0.5) * DomainMap.cellSize + map.pos_x, (y + oy + 0.5) * DomainMap.cellSize + map.pos_y);
    }

    Vector getLocalCoords(double x, double y) {
        final Vector mapLocal = map.getLocalCoords(x, y);
        return new Vector(mapLocal.x - ox, mapLocal.y - oy);
    }
}