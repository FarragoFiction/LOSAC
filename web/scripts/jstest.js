
BABYLON.ShaderMaterialWithAlphaTestTexture = class extends BABYLON.ShaderMaterial {
    constructor(name, scene, shaderPath, options, alphaTexture) {
        super(name, scene, shaderPath, options);

        this.extension_alphaTestTexture = alphaTexture;
    }

    getAlphaTestTexture() {
        return this.extension_alphaTestTexture;
    }
}