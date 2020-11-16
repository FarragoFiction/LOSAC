
import "package:CubeLib/CubeLib.dart" as B;

import '../../../level/levelobject.dart';
import "../../../utility/extensions.dart";
import "../renderer3d.dart";

class MeshProvider<T extends SimpleLevelObject> {
    Renderer3D renderer;

    MeshProvider(Renderer3D this.renderer);

    String getMeshName(T owner) => "${T.runtimeType.toString()} ${this.hashCode}";

    B.AbstractMesh provide(T owner) {
        final B.AbstractMesh mesh = B.MeshBuilder.CreateBox(getMeshName(owner), new B.MeshBuilderCreateBoxOptions(size: 10));
        mesh.metadata = new MeshInfo()..owner = owner;
        mesh.material = this.renderer.defaultMaterial;
        mesh.position.setFromGameCoords(owner.position, owner.getModelZPosition());
        return mesh;
    }
}

