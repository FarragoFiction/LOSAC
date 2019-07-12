import "dart:typed_data";


class DomainMap {
    static const int cellSize = 4;
    static const int cellBuffer = 3;

    final num pos_x;
    final num pos_y;
    final int width;
    final int height;

    Uint16List _array;
    Uint16List get array => _array;

    DomainMap(num x, num y, num levelWidth, num levelHeight) :
        pos_x = x - cellSize * cellBuffer,
        pos_y = y - cellSize * cellBuffer,
        width = (levelWidth/cellSize).ceil() + cellBuffer * 2,
        height = (levelHeight/cellSize).ceil() + cellBuffer * 2
    {
        _array = new Uint16List(width*height);
        print("DomainMap size: ${array.length}");
    }

    int getID(int x, int y) {
        if (x < 0 || x >= width || y < 0 || y >= height) {
            return -1;
        }
        return y * width + x;
    }
    int getVal(int x, int y) {
        final int id = getID(x,y);
        if (id == -1) {
            return 0;
        }
        return array[id];
    }
    void setVal(int x, int y, int val) {
        final int id = getID(x,y);
        if (id == -1) {
            return;
        }
        array[id] = val;
    }

    DomainMapRegion subRegion(int x, int y, int w, int h) => new DomainMapRegion(this, x, y, w, h);
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
}