
import "../level/domainmap.dart";
import "../level/pathnode.dart";

abstract class LevelUtils {

    static void prunePathNodeList(List<PathNode> nodes, Iterable<PathNode> toPrune) {

        for (final PathNode prunee in toPrune) {
            nodes.remove(prunee);
        }

        for (int i=0; i<nodes.length; i++) {
            nodes[i].id = i+1;
        }
    }

    static bool isLineClear(DomainMap domainMap, List<PathNode> pathNodes, PathNode fromNode, PathNode toNode) {
        final Set<int> trace = domainMap.valuesAlongLine(fromNode.pos_x, fromNode.pos_y, toNode.pos_x, toNode.pos_y, 50);

        if (trace.contains(0)) { return false; }

        for (final int id in trace) {
            final PathNode testNode = pathNodes[id - 1];
            if (testNode.blocked) {
                return false;
            }
        }

        return true;
    }

}