import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "../level/domainmap.dart";
import "../level/pathnode.dart";
import "../utility/extensions.dart";
import "moverentity.dart";

mixin TerrainCollider on MoverEntity {

    @override
    void applyVelocity(num dt) {
        if (this.velocity.length() == 0) { return; }

        final B.Vector2 projected = this.velocity * dt;

        if (this.engine.level == null) {
            this.previousPos.setFrom(this.position);
            this.position.addInPlace(projected);
            this.makeBoundsDirty();
            return;
        }

        final Math.Rectangle<num> movedBounds = new Math.Rectangle<num>(bounds.left + projected.x, bounds.top + projected.y, bounds.width, bounds.height);

        final DomainMap dMap = this.engine.level.domainMap;

        final B.Vector2 topLeft = dMap.getLocalCoords(movedBounds.left, movedBounds.top);
        final B.Vector2 bottomRight = dMap.getLocalCoords(movedBounds.right, movedBounds.bottom);

        final B.Vector2 vc = B.Vector2.Zero();
        int col = 0;

        for (int y=topLeft.y; y<=bottomRight.y; y++) {
            for (int x=topLeft.x; x<=bottomRight.x; x++) {
                final int id = dMap.getValLocal(x, y);
                if (id == 0) {
                    col++;
                    vc.addInPlace(dMap.getWorldCoords(x, y) - this.position);
                    continue;
                }

                final PathNode node = this.engine.level.pathNodes[id-1];
                if (node.isolated || node.blocked) {
                    col++;
                    vc.addInPlace(dMap.getWorldCoords(x, y) - this.position);
                }
            }
        }

        if (col > 0) {
            vc.scaleInPlace(1.0/col);

            final B.Vector2 dir = vc.normalized();
            projected.subtractInPlace(dir * dir.dot(this.velocity.normalized()));
        }

        this.previousPos.setFrom(this.position);
        this.position.addInPlace(projected);
    }

    Set<PathNode> getNodesAtPos() {
        if (this.engine.level == null) { return null; }

        final DomainMap dMap = this.engine.level.domainMap;

        final B.Vector2 topLeft = dMap.getLocalCoords(bounds.left, bounds.top);
        final B.Vector2 bottomRight = dMap.getLocalCoords(bounds.right, bounds.bottom);

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