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

    /// Isolated from the pathing graph - not walkable
    bool isolated = false;

    double distanceToExit = double.infinity;
    double distanceToExitFraction = double.infinity;
    PathNode targetNode;

    final Map<PathNode,double> connections = <PathNode,double>{};

    void connectTo(PathNode other) {
        if (connections.keys.contains(other)) { return; }

        final double dx = other.posVector.x - this.posVector.x;
        final double dy = other.posVector.y - this.posVector.y;
        final double distance = Math.sqrt(dx*dx + dy*dy);

        this.connections[other] = distance;
        other.connections[this] = distance;
    }

    @override
    String toString() => "($runtimeType $id)";
}

class ExitNode extends PathNode {}

class SpawnNode extends PathNode {}