import "dart:html";

import "../renderer/2d/bounds.dart";
import "connectible.dart";
import "domainmap.dart";
import "levelheightmap.dart";
import "levelobject.dart";
import "pathnode.dart";

class Level {

    Set<LevelObject> objects = <LevelObject>{};
    Iterable<Connectible> connectibles;

    final List<PathNode> pathNodes = <PathNode>[];
    Iterable<PathNode> connectedNodes;
    final List<SpawnNode> spawners = <SpawnNode>[];
    ExitNode exit;

    DomainMap domainMap;
    LevelHeightMap levelHeightMap;
    Rectangle<num> bounds;

    Level() {
        connectibles = objects.whereType();
        connectedNodes = pathNodes.where((PathNode node) => !node.isolated);
    }

    void derivePathNodes() {
        this.pathNodes.clear();

        this.spawners.clear();
        this.exit = null;

        // starts at 1 because 0 is "no node"
        int id = 1;

        for (final Connectible object in connectibles) {
            object.clearPathNodes();
        }

        for (final Connectible object in connectibles) {
            final Iterable<PathNode> nodes = object.generatePathNodes();

            for(final PathNode node in nodes) {
                node.id = id;
                id++;
                if (id >= 65536) {
                    throw Exception("WHAT ARE YOU DOING?! THIS IS FAR TOO MANY NODES!");
                }
                pathNodes.add(node);

                if (node is SpawnNode) {
                    this.spawners.add(node);
                } else if (node is ExitNode) {
                    if (this.exit != null) {
                        throw Exception("ONLY ONE EXIT, DUNKASS");
                    }
                    this.exit = node;
                }
            }
        }

        for (final Connectible object in connectibles) {
            object.connectPathNodes();
        }
    }

    void prunePathNodes(Iterable<PathNode> toPrune) {
        //LevelUtils.prunePathNodeList(this.pathNodes, toPrune.toList());
        for (final PathNode node in toPrune) {
            node.isolated = true;
        }
    }

    void buildDataMaps() {
        this.bounds = outerBounds(objects.map((LevelObject o) => o.bounds));

        domainMap = new DomainMap(bounds.left, bounds.top, bounds.width, bounds.height);
        levelHeightMap = new LevelHeightMap(bounds.left, bounds.top, bounds.width, bounds.height);

        for (final Connectible object in connectibles) {
            final Rectangle<num> bounds = object.bounds;

            final DomainMapRegion domainRegion = domainMap.subRegionForBounds(bounds);
            final LevelHeightMapRegion heightRegion = levelHeightMap.subRegionForBounds(bounds);

            object.fillDataMaps(domainRegion, heightRegion);
        }
    }

    PathNode getNodeFromPos(Point<num> pos) {
        final int id = domainMap.getVal(pos.x, pos.y);
        if (id != 0) {
            return pathNodes[id-1];
        }
        return null;
    }
}