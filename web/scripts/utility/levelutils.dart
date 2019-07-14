
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

}