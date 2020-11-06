import "dart:html";
import "dart:math" as Math;
import "dart:typed_data";

import "package:CommonLib/Colours.dart";
import "package:CommonLib/Random.dart";
import "package:CubeLib/CubeLib.dart" as B;

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
        final int pos_x = (x - cellSize * cellBuffer).floor();
        final int pos_y = (y - cellSize * cellBuffer).floor();
        final int width = (levelWidth/cellSize).ceil() + cellBuffer * 2;
        final int height = (levelHeight/cellSize).ceil() + cellBuffer * 2;
        final Uint16List array = new Uint16List(width*height);
        return new DomainMap.fromData(pos_x, pos_y, width, height, array);
    }

    DomainMap.fromData(int this.pos_x, int this.pos_y, int this.width, int this.height, Uint16List array) {
        _array = array;
        if (array.length != width * height) {
            throw Exception("DomainMap array length does not match dimensions! $width*$height = ${width*height} vs ${array.length}");
        }
    }

    int getVal(num x, num y) {
        final B.Vector2 local = getLocalCoords(x, y);
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

    B.Vector2 getWorldCoords(int x, int y) {
        if (getID(x, y) == -1) {
            return null;
        }

        return new B.Vector2((x + 0.5) * cellSize + pos_x, (y + 0.5) * cellSize + pos_y);
    }

    B.Vector2 getLocalCoords(num x, num y) => new B.Vector2(((x - pos_x) / cellSize).floor(), ((y - pos_y) / cellSize).floor());

    DomainMapRegion subRegion(int x, int y, int w, int h) => new DomainMapRegion(this, x, y, w, h);
    DomainMapRegion subRegionForBounds(Rectangle<num> bounds) {
        final B.Vector2 topLeft = getLocalCoords(bounds.left, bounds.top);
        final B.Vector2 bottomRight = getLocalCoords(bounds.left + bounds.width, bounds.top + bounds.height);

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

    void debugHighlight(Iterable<B.Vector2> cells) {
        if (this.debugCanvas == null) { return; }

        final CanvasRenderingContext2D ctx = debugCanvas.context2D;
        ctx.save();

        ctx.globalAlpha = 0.75;
        ctx.fillStyle = "#FF0000";

        for (final B.Vector2 c in cells) {
            ctx.fillRect(c.x * cellSize, c.y * cellSize, cellSize, cellSize);
        }

        ctx.restore();
    }

    Set<int> valuesAlongLine(double x1, double y1, double x2, double y2, double thickness) => traceLine(x1, y1, x2, y2, thickness, getValLocal);
    Set<B.Vector2> cellsAlongLine(num x1, num y1, num x2, num y2, num thickness) => traceLine(x1, y1, x2, y2, thickness, (int x, int y) => new B.Vector2(x,y));

    Set<T> traceLine<T>(num x1, num y1, num x2, num y2, num thickness, T Function(int x, int y) getter) {
        final Set<T> nodes = <T>{};
        final B.Vector2 p1 = getLocalCoords(x1, y1);
        final B.Vector2 p2 = getLocalCoords(x2, y2);
        final double distTest = (thickness * 0.5) / (cellSize * Math.sqrt2);
        final int buffer = distTest.floor();

        final double a = p1.y - p2.y;
        final double b = p2.x - p1.x;
        final double c = p1.x * p2.y - p2.x * p1.y;

        final double divisor = Math.sqrt(a*a + b*b);

        final int left = Math.min(p1.x, p2.x) - buffer;
        final int right = Math.max(p1.x, p2.x) + buffer;
        final int top = Math.min(p1.y, p2.y) - buffer;
        final int bottom = Math.max(p1.y, p2.y) + buffer;

        for (int y = top; y<=bottom; y++) {
            for (int x = left; x<=right; x++) {
                final double dist = (a * x + b * y + c).abs() / divisor;

                if (dist < distTest) {
                    nodes.add(getter(x,y));
                }
            }
        }

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

    B.Vector2 getWorldCoords(int x, int y) {
        if (getID(x, y) == -1) {
            return null;
        }

        return new B.Vector2((x + ox + 0.5) * DomainMap.cellSize + map.pos_x, (y + oy + 0.5) * DomainMap.cellSize + map.pos_y);
    }

    B.Vector2 getLocalCoords(double x, double y) {
        final B.Vector2 mapLocal = map.getLocalCoords(x, y);
        return new B.Vector2(mapLocal.x - ox, mapLocal.y - oy);
    }
}