import "dart:collection";

import "package:CubeLib/CubeLib.dart" as B;
import "package:yaml/yaml.dart";

import '../../../level/levelobject.dart';
import '../../../level/selectable.dart';
import "../renderer3d.dart";

class MeshProvider<T extends SimpleLevelObject> {
    Renderer3D renderer;

    MeshProvider(Renderer3D this.renderer);

    String getMeshName(T? owner) => "${_getTypeName(owner)} ${this.hashCode}";
    String _getTypeName(T? owner) => owner == null ? "[No Object]" : owner.runtimeType.toString();

    bool isValidForObject(dynamic object) {
        return (object is T) || (object is MeshProviderProxy<T>);
    }

    B.AbstractMesh? provide(T owner) {
        final B.AbstractMesh mesh = B.MeshBuilder.CreateBox(getMeshName(owner), new B.MeshBuilderCreateBoxOptions(size: 10));
        mesh.isPickable = owner is Selectable;
        mesh.metadata = new MeshInfo()..owner = owner;
        mesh.material = this.renderer.standardAssets.defaultMaterial;
        return mesh;
    }

    void load(YamlMap yaml) {}
}

mixin MeshProviderProxy<T>{}

abstract class MeshProviderType {
    static const String defaultProvider = "defaultProvider";
    static const String debugGrid = "debugGrid";
    static const String debugCurve = "debugCurve";
    static const String debugEndCap = "debugEndCap";
}
