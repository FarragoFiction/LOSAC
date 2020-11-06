import "dart:html";
import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "../../level/levelobject.dart";

Rectangle<num> polyBounds(List<B.Vector2> vertices) {
    const double buffer = 3;

    double left   = double.infinity;
    double right  = double.negativeInfinity;
    double top    = double.infinity;
    double bottom = double.negativeInfinity;

    for(final B.Vector2 v in vertices) {
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

Rectangle<num> polyBoundsLocal(LevelObject object, List<B.Vector2> vertices) {
    final List<B.Vector2> worldVertices = new List<B.Vector2>(vertices.length);

    for (int i=0; i<vertices.length; i++) {
        final B.Vector2 local = vertices[i];

        final B.Vector2 world = object.getWorldPosition(local);

        worldVertices[i] = world;
    }

    return polyBounds(worldVertices);
}

Rectangle<num> rectBounds(LevelObject object, double width, double height) {
    final double x = width/2;
    final double y = height/2;
    return polyBoundsLocal(object, <B.Vector2>[ new B.Vector2(-x,-y), new B.Vector2(x,-y), new B.Vector2(-x, y), new B.Vector2(x,y)]);
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