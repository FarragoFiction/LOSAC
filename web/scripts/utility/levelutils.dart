import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "../level/domainmap.dart";
import "../level/pathnode.dart";
import "extensions.dart";

abstract class LevelUtils {

    /*static void prunePathNodeList(List<PathNode> nodes, Iterable<PathNode> toPrune) {

        for (final PathNode prunee in toPrune) {
            nodes.remove(prunee);
        }

        for (int i=0; i<nodes.length; i++) {
            nodes[i].id = i+1;
        }
    }*/

    static bool isLineClear(DomainMap domainMap, List<PathNode> pathNodes, PathNode fromNode, PathNode toNode) {
        final Set<int> trace = domainMap.valuesAlongLine(fromNode.position.x, fromNode.position.y, toNode.position.x, toNode.position.y, 50);

        if (trace.contains(0)) { return false; }

        for (final int id in trace) {
            final PathNode testNode = pathNodes[id - 1];
            if (testNode.blocked) {
                return false;
            }
        }

        return true;
    }

    static B.Vector2 inverseBilinear(B.Vector2 p, B.Vector2 a, B.Vector2 b, B.Vector2 c, B.Vector2 d) {
        final B.Vector2 e = b-a;
        final B.Vector2 f = d-a;
        final B.Vector2 g = (a-b)+(c-d);
        final B.Vector2 h = p-a;

        final num k2 = g.cross(f);
        final num k1 = e.cross(f) + h.cross(g);
        final num k0 = h.cross(e);

        num w = k1 * k1 - 4 * k0 * k2;
        if (w < 0.0) {
            return new B.Vector2(-1,-1);
        }
        w = Math.sqrt(w);

        final double v1 = k2 != 0 ? (-k1 - w) / (2*k2) : -k0/k1;
        final double u1 = (h.x - f.x * v1) / (e.x + g.x * v1);

        final double v2 = k2 != 0 ? (-k1 + w) / (2*k2) : -k0/k1;
        final double u2 = (h.x - f.x * v2) / (e.x + g.x * v2);

        double u = u1;
        double v = v2;

        if (v.isNaN || u.isNaN || v < 0 || v > 1 || u < 0 || u > 1) {
            u = u2;
            v = v2;
        }

        final B.Vector2 uv = new B.Vector2(u.clamp(0,1),v.clamp(0,1));

        return uv;
    }

}