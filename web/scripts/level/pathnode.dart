import "dart:math" as Math;

import "domainmap.dart";
import "levelobject.dart";

/// Interface for LevelObjects which provide PathNodes
abstract class PathNodeObject {
    Iterable<PathNode> generatePathNodes();
    void connectPathNodes();
    void clearPathNodes();
    void fillDomainMap(DomainMapRegion map);
}

class PathNode extends SimpleLevelObject {
    int id;
    PathNodeObject pathObject;

    bool blocked = false;
    bool validShortcut = false;

    double distanceToExit = double.infinity;
    PathNode targetNode;

    final Map<PathNode,double> connections = <PathNode,double>{};

    void connectTo(PathNode other) {
        if (connections.keys.contains(other)) { return; }

        final double dx = other.pos_x - this.pos_x;
        final double dy = other.pos_y - this.pos_y;
        final double distance = Math.sqrt(dx*dx + dy*dy);

        this.connections[other] = distance;
        other.connections[this] = distance;
    }
}

class ExitNode extends PathNode {}

class SpawnNode extends PathNode {}