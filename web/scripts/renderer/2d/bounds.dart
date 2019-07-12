import "dart:html";
import "dart:math" as Math;

import "../../level/levelobject.dart";
import "vector.dart";

Rectangle<num> polyBounds(List<Vector> vertices) {
    const double buffer = 3;

    double left   = double.infinity;
    double right  = double.negativeInfinity;
    double top    = double.infinity;
    double bottom = double.negativeInfinity;

    for(final Vector v in vertices) {
        left   = Math.min(left,   v.x);
        right  = Math.max(right,  v.x);
        top    = Math.min(top,    v.y);
        bottom = Math.max(bottom, v.y);
    }

    left -= buffer;
    right += buffer;
    top -= buffer;
    bottom += buffer;

    return new Rectangle<num>(left, top, right-left, bottom-top);
}

Rectangle<num> polyBoundsLocal(LevelObject object, List<Vector> vertices) {
    final List<Vector> worldVertices = new List<Vector>(vertices.length);

    for (int i=0; i<vertices.length; i++) {
        final Vector local = vertices[i];

        final Vector world = object.getWorldPosition(local);

        worldVertices[i] = world;
    }

    return polyBounds(worldVertices);
}

Rectangle<num> rectBounds(LevelObject object, double width, double height) {
    final double x = width/2;
    final double y = height/2;
    return polyBoundsLocal(object, <Vector>[ new Vector(-x,-y), new Vector(x,-y), new Vector(-x, y), new Vector(x,y)]);
}

Rectangle<num> outerBounds(Iterable<Rectangle<num>> bounds) {

    num left = double.infinity;
    num right = double.negativeInfinity;
    num top = double.infinity;
    num bottom = double.negativeInfinity;

    for (final Rectangle<num> b in bounds) {
        left = Math.min(left, b.left);
        right = Math.max(right, b.left + b.width);
        top = Math.min(top, b.top);
        bottom = Math.max(bottom, b.top + b.height);
    }

    return new Rectangle<num>(left, top, right-left, bottom-top);
}