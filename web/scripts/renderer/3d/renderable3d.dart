import "package:CubeLib/CubeLib.dart" as B;

import 'renderer3d.dart';

mixin Renderable3D {
    bool hidden = false;
    bool invisible = false;
    bool drawUI = true;

    Renderer3D renderer;
    B.AbstractMesh mesh;

    void generateMesh() {

    }
}