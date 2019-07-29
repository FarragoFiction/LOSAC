import "dart:math" as Math;

import "../level/domainmap.dart";
import "../level/pathnode.dart";
import "../renderer/2d/vector.dart";
import "moverentity.dart";

mixin TerrainCollider on MoverEntity {

    @override
    void applyVelocity(num dt) {
        if (this.velocity.length == 0) { return; }

        Vector projected = this.velocity * dt;

        if (this.engine.level == null) {
            this.previousPos = this.posVector;
            this.posVector += projected;
            return;
        }

        final Math.Rectangle<num> movedBounds = new Math.Rectangle<num>(bounds.left + projected.x, bounds.top + projected.y, bounds.width, bounds.height);

        final DomainMap dMap = this.engine.level.domainMap;

        final Vector topLeft = dMap.getLocalCoords(movedBounds.left, movedBounds.top);
        final Vector bottomRight = dMap.getLocalCoords(movedBounds.right, movedBounds.bottom);

        Vector vc = Vector.zero();
        int col = 0;

        for (int y=topLeft.y; y<=bottomRight.y; y++) {
            for (int x=topLeft.x; x<=bottomRight.x; x++) {
                final int id = dMap.getValLocal(x, y);
                if (id == 0) {
                    col++;
                    vc += dMap.getWorldCoords(x, y) - this.posVector;
                    continue;
                }

                final PathNode node = this.engine.level.pathNodes[id-1];
                if (node.isolated || node.blocked) {
                    col++;
                    vc += dMap.getWorldCoords(x, y) - this.posVector;
                }
            }
        }

        if (col > 0) {
            vc /= col;

            final Vector dir = vc.norm();
            projected -= dir * dir.dot(this.velocity.norm());
        }

        this.previousPos = this.posVector;
        this.posVector += projected;
    }

    Set<PathNode> getNodesAtPos() {
        if (this.engine.level == null) { return null; }

        final DomainMap dMap = this.engine.level.domainMap;

        final Vector topLeft = dMap.getLocalCoords(bounds.left, bounds.top);
        final Vector bottomRight = dMap.getLocalCoords(bounds.right, bounds.bottom);

        final Set<PathNode> nodes = <PathNode>{};

        for (int y=topLeft.y; y<=bottomRight.y; y++) {
            for (int x=topLeft.x; x<=bottomRight.x; x++) {
                final int id = dMap.getValLocal(x, y);
                final PathNode node = this.engine.level.pathNodes[id-1];
                nodes.add(node);
            }
        }

        return nodes;
    }
}