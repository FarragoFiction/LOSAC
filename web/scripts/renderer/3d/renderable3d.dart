import "package:CubeLib/CubeLib.dart" as B;

import 'renderer3d.dart';

mixin Renderable3D {
    bool hidden = false;
    bool invisible = false;
    bool drawUI = true;

    late Renderer3D renderer;
    B.AbstractMesh? mesh;

    void generateMesh() {}
    void updateMeshPosition({B.Vector2? position, double? height, double? rotation}) {}
}