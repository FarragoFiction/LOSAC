import "dart:html";

import "../../renderer/2d/vector.dart";
import "../enemy.dart";
import "../moverentity.dart";
import "../tower.dart";

export "beamprojectile.dart";
export "chaserprojectile.dart";
export "interpolatorprojectile.dart";

abstract class Projectile extends MoverEntity {

    Tower parent;
    Enemy target;

    double age = 0;
    double maxAge = 10; // might need changing elsewhere for very slow and long range projectiles, but why would you go that slow?

    /// Not used by all types of projectile
    Vector targetPos;

    Projectile(Tower this.parent, Enemy this.target, Vector this.targetPos);

    @override
    void draw2D(CanvasRenderingContext2D ctx) {
        ctx
            ..fillStyle = "#201D00"
            ..fillRect(-3, -3, 6, 6)
            ..fillStyle = "#FFDD00"
            ..fillRect(-2, -2, 4, 4);
    }

    void impact() {
        target.health -= parent.towerType.weaponDamage;
    }

    @override
    void logicUpdate([num dt = 0]) {
        super.logicUpdate(dt);
        this.age += dt;
        if (this.age >= this.maxAge) {
            this.kill();
        }
    }
}