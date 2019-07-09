import 'dart:html';

import "level/curve.dart";
import "level/grid.dart";
import "level/level.dart";
import "level/levelobject.dart";
import "renderer/2d/renderer2d.dart";

void main() {
    print("LOSAC yo");

    final CanvasElement testCanvas = new CanvasElement(width: 800, height: 600)..style.border="1px solid black";

    document.body.append(testCanvas);

    final Level testLevel = new Level();

    final LevelObject testObject = new LevelObject()..pos_x = 250..pos_y = 250..rot_angle = 0.5..scale=8.0;

    testObject.addSubObject(new LevelObject()..pos_x = -10..rot_angle=-0.6..scale=0.5);
    testObject.addSubObject(new LevelObject()..pos_x = 10..rot_angle=0.6..scale=0.5);

    testLevel.objects.add(testObject);

    final Grid testGrid = new Grid(6, 10)..pos_x = 500..pos_y = 400..rot_angle = 0.1;

    List<GridCell> cells = testGrid.getCells(0, 4, 1, 5);
    for (final GridCell c in cells) {
        c.state = GridCellState.hole;
    }

    cells = testGrid.getCells(4, 4, 5, 5);
    for (final GridCell c in cells) {
        c.state = GridCellState.hole;
    }

    testGrid.updateConnectors();

    testLevel.objects.add(testGrid);

    /*for (int i=0; i<testGrid.cells.length; i++) {
        final Point<num> coord = testGrid.cellCoordsById(i);
        testLevel.objects.add(new LevelObject()..pos_x = coord.x + testGrid.pos_x..pos_y = coord.y + testGrid.pos_y);
    }*/

    final Curve testPath = new Curve()
        //..renderVertices=true
        //..renderSegments = true
    ;

    testPath.addVertex(new CurveVertex()..pos_x = 50..pos_y=30..rot_angle = 1.2..handle2 = 60);
    testPath.addVertex(new CurveVertex()..pos_x = 220..pos_y=40..rot_angle = 2.4..handle1 = 60..handle2 = 60);
    testPath.addVertex(new CurveVertex()..pos_x = 280..pos_y=180..rot_angle = 2.0..handle1 = 50);

    testPath.rebuildSegments();
    testPath.updateConnectors();
    print(testPath.segments.length);

    testLevel.objects.add(testPath);

    Renderer2D renderer = new Renderer2D(testCanvas, testLevel);
}
