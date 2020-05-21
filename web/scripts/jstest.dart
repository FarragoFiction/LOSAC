@JS("BABYLON")
library BabylonMaterialExtension;

import "package:CubeLib/CubeLib.dart";
import "package:js/js.dart";

@JS()
class ShaderMaterialWithAlphaTestTexture extends ShaderMaterial {
    external factory ShaderMaterialWithAlphaTestTexture(String name, Scene scene, dynamic shaderPath, [IShaderMaterialOptions options, Texture alphaTexture]);
}