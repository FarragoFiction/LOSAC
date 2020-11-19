import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "../../../level/endcap.dart";
import "../../../level/grid.dart";
import "../../../utility/extensions.dart";
import "../renderer3d.dart";
import "meshprovider.dart";

abstract class GridMeshProvider extends MeshProvider<Grid> {
    GridMeshProvider(Renderer3D renderer) : super(renderer);
}

class DebugGridMeshProvider extends GridMeshProvider {

    DebugGridMeshProvider(Renderer3D renderer) : super(renderer);

    @override
    B.AbstractMesh provide(Grid grid) {
        final B.Mesh mesh = new B.Mesh(getMeshName(grid));

        for (final GridCell g in grid.cells) {
            if (g.state != GridCellState.hole) {
                mesh.addChild(createCellMesh()
                    ..position.set(g.position.x, 0, g.position.y));
            }
        }
        return mesh;
    }

    static B.AbstractMesh createCellMesh() {
        final double n = Grid.cellSize / 2;
        return B.LinesBuilder.CreateLines("cell", new B.LinesBuilderCreateLinesOptions(
            points: <B.Vector3> [
                new B.Vector3(-n,0,-n),
                new B.Vector3(-n,0, n),
                new B.Vector3( n,0, n),
                new B.Vector3( n,0,-n),
                new B.Vector3(-n,0,-n),
            ]
        ));
    }
}

class EndCapMeshProvider extends MeshProvider<EndCap> {
    EndCapMeshProvider(Renderer3D renderer) : super(renderer);
}

class DebugEndCapMeshProvider extends EndCapMeshProvider {
    DebugEndCapMeshProvider(Renderer3D renderer) : super(renderer);

    @override
    B.AbstractMesh provide(EndCap cap) {
        final B.Mesh outline = DebugGridMeshProvider.createCellMesh();

        if (cap is SpawnerObject || cap is ExitObject) {
            final double size = Grid.cellSize * 0.35;

            final B.LinesMesh arrow = B.LinesBuilder.CreateLines("cell", new B.LinesBuilderCreateLinesOptions(
                points: <B.Vector3> [
                    new B.Vector3(size * 0.5,0,-size),
                    new B.Vector3(-size * 0.75,0, 0),
                    new B.Vector3(size * 0.5,0, size),
                    new B.Vector3(size * 0.5,0,-size),
                ]
            ));

            if (cap is ExitObject) {
                arrow.rotation.y = Math.pi;
            }

            outline.addChild(arrow);
        }

        outline.position.setFromGameCoords(cap.position, cap.zPosition);
        return outline;
    }
}