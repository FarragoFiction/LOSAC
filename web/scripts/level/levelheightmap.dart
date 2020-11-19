import "dart:collection";
import "dart:html";
import 'dart:typed_data';

import "package:CubeLib/CubeLib.dart" as B;

import "../utility/extensions.dart";
import "datamap.dart";
import "terrain.dart";

class LevelHeightMap extends DataMap<double, Float32List> {
    factory LevelHeightMap(num x, num y, num levelWidth, num levelHeight, [int buffer = DataMap.cellBuffer]) {
        final int pos_x = (x - (x % DataMap.cellSize) - DataMap.cellSize * buffer).floor();
        final int pos_y = (y - (y % DataMap.cellSize) - DataMap.cellSize * buffer).floor();
        final int width = (levelWidth/DataMap.cellSize).ceil() + buffer * 2;
        final int height = (levelHeight/DataMap.cellSize).ceil() + buffer * 2;
        final Float32List array = new Float32List(width*height);
        //for (int i=0; i<array.length; i++) { array[i] = 50.0; } // debug fill
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

        // rough mode
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

        // smooth mode
        /*final int w = this.width * DataMap.cellSize;
        final int h = this.height * DataMap.cellSize;
        final ImageData idata = ctx.getImageData(0, 0, w, h);
        int val, i;
        double altitude;
        for (int y=0;y<h;y++) {
            for (int x=0;x<w;x++) {
                i = (y*w + x) * 4;
                altitude = this.getSmoothVal(x+pos_x, y+pos_y);
                //altitude = this.getVal(x+pos_x, y+pos_y);
                val = ((altitude * 0.01) * 255).floor() % 255;

                idata.data[i] = val;
                idata.data[i+1] = val;
                idata.data[i+2] = val;
                idata.data[i+3] = 255;
            }
        }
        ctx.putImageData(idata, 0, 0);*/
    }

    double getSmoothVal(num x, num y) {
        final B.Vector2 smooth = new B.Vector2(((x - pos_x) / DataMap.cellSize), ((y - pos_y) / DataMap.cellSize));
        final B.Vector2 local = this.getLocalCoords(x, y);
        smooth.subtractInPlace(local);

        final int lx = local.x.floor();
        final int ly = local.y.floor();

        final double tl = this.getValLocal(lx, ly);
        final double tr = this.getValLocal(lx+1, ly);
        final double bl = this.getValLocal(lx, ly+1);
        final double br = this.getValLocal(lx+1, ly+1);

        final double ix = smooth.x;
        final double iy = smooth.y;
        final double rx = 1-ix;
        final double ry = 1-iy;

        return (tl * rx + tr * ix) * ry + (bl * rx + br * ix) * iy;
        //return smooth.x * 100;
    }

    void smoothCameraHeights() {
        const double diagonalFactor = 1.415; // slightly more than root 2 by design
        const double threshold = 5;

        final Queue<Point<int>> open = new Queue<Point<int>>();

        for(int y=0; y<height; y++) {
            for (int x=0; x<width; x++) {
                open.add(new Point<int>(x,y));

                while (open.isNotEmpty) {
                    final Point<int> p = open.removeFirst();

                    final bool l = p.x > 0;
                    final bool r = p.x < width - 1;
                    final bool u = p.y > 0;
                    final bool d = p.y < height - 1;

                    final int id = p.y * width + p.x;
                    final double orthogonal = array[id] - threshold;
                    final double diagonal = array[id] - threshold * diagonalFactor;

                    if (l) {
                        if (array[id-1] < orthogonal) {
                            open.add(new Point<int>(p.x-1,p.y));
                            array[id-1] = orthogonal;
                        }

                        if (u) {
                            if (array[(id-1)-width] < diagonal) {
                                open.add(new Point<int>(p.x-1,p.y-1));
                                array[(id-1)-width] = diagonal;
                            }
                        }
                        if (d) {
                            if (array[(id-1)+width] < diagonal) {
                                open.add(new Point<int>(p.x-1,p.y+1));
                                array[(id-1)+width] = diagonal;
                            }
                        }
                    }

                    if (r) {
                        if (array[id+1] < orthogonal) {
                            open.add(new Point<int>(p.x+1,p.y));
                            array[id+1] = orthogonal;
                        }

                        if (u) {
                            if (array[(id+1)-width] < diagonal) {
                                open.add(new Point<int>(p.x+1,p.y-1));
                                array[(id+1)-width] = diagonal;
                            }
                        }
                        if (d) {
                            if (array[(id+1)+width] < diagonal) {
                                open.add(new Point<int>(p.x+1,p.y+1));
                                array[(id+1)+width] = diagonal;
                            }
                        }
                    }

                    if (u) {
                        if (array[id-width] < orthogonal) {
                            open.add(new Point<int>(p.x,p.y-1));
                            array[id-width] = orthogonal;
                        }
                    }
                    if (d) {
                        if (array[id+width] < orthogonal) {
                            open.add(new Point<int>(p.x,p.y+1));
                            array[id+width] = orthogonal;
                        }
                    }
                }
            }
        }
    }

    void processTerrain(Terrain terrain) {
        for (int y=0; y<height; y++) {
            for (int x=0; x<width; x++) {
                final int id = y * width + x;
                final B.Vector2 world = this.getWorldCoords(x, y);
                final B.Vector3 render = B.Vector3.Zero()..setFromGameCoords(world, 0);
                this.array[id] = terrain.groundMesh.getHeightAtCoordinates(render.x, render.z);
            }
        }
    }
}

class LevelHeightMapRegion extends DataMapRegion<double, Float32List> {
    LevelHeightMapRegion(LevelHeightMap map, int x, int y, int w, int h) : super(map,x,y,w,h);
}