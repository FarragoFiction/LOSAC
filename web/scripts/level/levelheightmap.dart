import "dart:html";
import 'dart:typed_data';

import "datamap.dart";

class LevelHeightMap extends DataMap<double, Float32List> {
    factory LevelHeightMap(num x, num y, num levelWidth, num levelHeight) {
        final int pos_x = (x - DataMap.cellSize * DataMap.cellBuffer).floor();
        final int pos_y = (y - DataMap.cellSize * DataMap.cellBuffer).floor();
        final int width = (levelWidth/DataMap.cellSize).ceil() + DataMap.cellBuffer * 2;
        final int height = (levelHeight/DataMap.cellSize).ceil() + DataMap.cellBuffer * 2;
        final Float32List array = new Float32List(width*height);
        return new LevelHeightMap.fromData(pos_x, pos_y, width, height, array);
    }

    LevelHeightMap.fromData(int pos_x, int pos_y, int width, int height, Float32List array) : super.fromData(pos_x, pos_y, width, height, array);

    @override
    double getDefaultValue() => 0;

    @override
    LevelHeightMapRegion subRegion(int x, int y, int w, int h) => new LevelHeightMapRegion(this, x, y, w, h);

    @override
    void updateDebugCanvas() {
        debugCanvas = new CanvasElement(width: this.width * DataMap.cellSize, height: this.height * DataMap.cellSize);
        final CanvasRenderingContext2D ctx = debugCanvas.context2D;

        int id;
        double altitude;
        int val;
        for (int y = 0; y<height; y++) {
            for (int x = 0; x<width; x++) {
                id = getID(x, y);
                altitude = array[id];

                if (altitude == null) { continue; }

                val = (((altitude * 0.01) % 1.0) * 255).floor();

                ctx.fillStyle = "rgb($val, $val, $val)";

                ctx.fillRect(x * DataMap.cellSize, y * DataMap.cellSize, DataMap.cellSize, DataMap.cellSize);
            }
        }
    }
}

class LevelHeightMapRegion extends DataMapRegion<double, Float32List> {
    LevelHeightMapRegion(LevelHeightMap map, int x, int y, int w, int h) : super(map,x,y,w,h);
}