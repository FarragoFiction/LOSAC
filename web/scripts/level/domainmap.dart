import "dart:html";
import "dart:typed_data";

import "package:CommonLib/Colours.dart";
import "package:CommonLib/Random.dart";

import "datamap.dart";

class DomainMap extends DataMap<int, Uint16List> {

    factory DomainMap(num x, num y, num levelWidth, num levelHeight) {
        final int pos_x = (x - DataMap.cellSize * DataMap.cellBuffer).floor();
        final int pos_y = (y - DataMap.cellSize * DataMap.cellBuffer).floor();
        final int width = (levelWidth/DataMap.cellSize).ceil() + DataMap.cellBuffer * 2;
        final int height = (levelHeight/DataMap.cellSize).ceil() + DataMap.cellBuffer * 2;
        final Uint16List array = new Uint16List(width*height);
        return new DomainMap.fromData(pos_x, pos_y, width, height, array);
    }

    DomainMap.fromData(int pos_x, int pos_y, int width, int height, Uint16List array) : super.fromData(pos_x, pos_y, width, height, array);

    @override
    int getDefaultValue() => 0;

    @override
    DomainMapRegion subRegion(int x, int y, int w, int h) => new DomainMapRegion(this, x, y, w, h);

    @override
    DomainMapRegion subRegionForBounds(Rectangle<num> bounds) => super.subRegionForBounds(bounds) as DomainMapRegion;

    @override
    void updateDebugCanvas() {
        debugCanvas = new CanvasElement(width: this.width * DataMap.cellSize, height: this.height * DataMap.cellSize);
        final CanvasRenderingContext2D ctx = debugCanvas!.context2D;

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

                ctx.fillRect(x * DataMap.cellSize, y * DataMap.cellSize, DataMap.cellSize, DataMap.cellSize);
            }
        }
    }
}

class DomainMapRegion extends DataMapRegion<int, Uint16List> {
    DomainMapRegion(DomainMap map, int x, int y, int w, int h) : super(map,x,y,w,h);
}