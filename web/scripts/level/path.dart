import "dart:html";
import "dart:math" as Math;

import "../renderer/2d/matrix.dart";
import "../renderer/2d/vector.dart";
import "levelobject.dart";

class Path extends LevelObject {
    final List<PathVertex> vertices = <PathVertex>[];
    bool renderVertices = false;

    final List<Vector> subDivisions = <Vector>[];

    @override
    void draw2D(CanvasRenderingContext2D ctx) {

        if (vertices.length > 1) {
            PathVertex v1 = vertices.first;
            PathVertex v2;

            ctx
                ..strokeStyle = "#BBBBBB"
                ..beginPath()
                ..moveTo(v1.pos_x, v1.pos_y);

            for (int i=1; i<vertices.length; i++) {
                v2 = vertices[i];

                final Vector o1 = new Vector(0,-v1.handle2).applyMatrix(v1.matrix) + new Vector(v1.pos_x, v1.pos_y);
                final Vector o2 = new Vector(0,v2.handle1).applyMatrix(v2.matrix) + new Vector(v2.pos_x, v2.pos_y);

                ctx.bezierCurveTo(o1.x, o1.y, o2.x, o2.y, v2.pos_x, v2.pos_y);

                v1 = v2;
            }

            ctx.stroke();
        }

        if (renderVertices) {
            for (final PathVertex vertex in vertices) {
                vertex.drawToCanvas(ctx);
            }
        }
    }
}

class PathVertex extends LevelObject with HasMatrix {
    double handle1 = 10.0;
    double handle2 = 10.0;

    @override
    void draw2D(CanvasRenderingContext2D ctx) {

        ctx
            ..strokeStyle = "#3333FF"
            ..beginPath()
            ..moveTo(0, handle1-3)
            ..lineTo(0, -(handle2-3))
            ..stroke();

        ctx
            ..strokeStyle = "#AAAAAA"
            ..beginPath()
            ..arc(0,handle1, 3, 0, Math.pi * 2)
            ..stroke()
            ..beginPath()
            ..arc(0,-handle2, 3, 0, Math.pi * 2)
            ..stroke();

        ctx
            ..fillStyle = "#FF0000"
            ..beginPath()
            ..arc(0,0, 3, 0, Math.pi * 2)
            ..fill();
    }
}