
import "package:CubeLib/CubeLib.dart" as B;

import 'levelobject.dart';

class Terrain extends SimpleLevelObject {

    B.GroundMesh get groundMesh => mesh;

    Terrain();

    @override
    void generateMesh() {
        this.mesh = B.GroundBuilder.CreateGroundFromHeightMap("terrain", "assets/textures/heightTest.png", new B.GroundBuilderCreateGroundFromHeightMapOptions(
            width:2000,
            height:2000,
            minHeight: 0,
            maxHeight: 200,
            subdivisions: 512
        ))..isPickable = false;

        this.mesh.material = new B.StandardMaterial("terrain", renderer.scene)
            ..diffuseColor.set(0.25, 0.25, 0.25)
            ..specularColor.set(0.1, 0.1, 0.1)
        ;
    }

}