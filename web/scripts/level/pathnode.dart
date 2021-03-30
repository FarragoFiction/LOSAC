import "dart:math" as Math;

import "domainmap.dart";
import 'endcap.dart';
import 'levelheightmap.dart';
import "levelobject.dart";

/// Interface for LevelObjects which provide PathNodes
abstract class PathNodeObject {
    bool generateLevelHeightData = true;

    Iterable<PathNode> generatePathNodes();
    void connectPathNodes();
    void clearPathNodes();
    void fillDataMaps(DomainMapRegion domainMap, LevelHeightMapRegion heightMap);
}

class PathNode extends SimpleLevelObject {
    late int id;
    late PathNodeObject pathObject;

    bool blocked = false;
    bool validShortcut = false;

    /// Isolated from the pathing graph - not walkable
    bool isolated = false;

    double distanceToExit = double.infinity;
    double distanceToExitFraction = double.infinity;
    PathNode? targetNode;

    final Map<PathNode,double> connections = <PathNode,double>{};

    void connectTo(PathNode other) {
        if (connections.keys.contains(other)) { return; }

        final num dx = other.position.x - this.position.x;
        final num dy = other.position.y - this.position.y;
        final double distance = Math.sqrt(dx*dx + dy*dy);

        this.connections[other] = distance;
        other.connections[this] = distance;
    }

    @override
    String toString() => "($runtimeType $id)";
}

class ExitNode extends PathNode {
    @override
    // ignore: overridden_fields
    covariant late ExitObject pathObject;
}

class SpawnNode extends PathNode {
    @override
    // ignore: overridden_fields
    covariant late SpawnerObject pathObject;
}