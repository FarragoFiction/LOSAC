
import "package:CubeLib/CubeLib.dart" as B;

import '../../../level/curve.dart';
import "../../../utility/extensions.dart";
import '../renderer3d.dart';
import "meshprovider.dart";

class CurveMeshProvider extends MeshProvider<Curve> {
    CurveMeshProvider(Renderer3D renderer) : super(renderer);
}

class DebugCurveMeshProvider extends CurveMeshProvider {
    DebugCurveMeshProvider(Renderer3D renderer) : super(renderer);

    @override
    B.AbstractMesh provide(Curve curve) {
        if (!curve.segments.isEmpty) {
            final B.Mesh mesh = new B.Mesh(getMeshName(curve));

            final List<B.Vector3> left = <B.Vector3>[];
            final List<B.Vector3> right = <B.Vector3>[];

            for(int i=0; i<curve.segments.length; i++) {
                final CurveSegment seg = curve.segments[i];
                final B.Vector3 pos = new B.Vector3()..setFromGameCoords(seg.position, seg.zPosition);

                final B.Vector3 offset = (new B.Vector3()..setFromGameCoords(seg.norm, 0)) * curve.width * seg.cornerMultiplier;

                left.add(pos + offset);
                right.add(pos - offset);

                mesh.addChild(B.LinesBuilder.CreateLines("segment", new B.LinesBuilderCreateLinesOptions(
                    points: <B.Vector3> [
                        new B.Vector3(pos.x + offset.x, seg.node.getZPosition(), pos.z + offset.z),
                        new B.Vector3(pos.x - offset.x, seg.node.getZPosition(), pos.z - offset.z),
                    ])
                ));
            }

            mesh.addChild(B.LinesBuilder.CreateLines("cell", new B.LinesBuilderCreateLinesOptions(
                points: left
            )));
            mesh.addChild(B.LinesBuilder.CreateLines("cell", new B.LinesBuilderCreateLinesOptions(
                points: right
            )));

            return mesh;
        }
        return null;
    }
}