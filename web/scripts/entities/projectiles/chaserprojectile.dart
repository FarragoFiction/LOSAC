
import "../../renderer/2d/vector.dart";
import "../enemy.dart";
import "../newtonianmover.dart";
import "../tower.dart";
import "projectile.dart";

class ChaserProjectile extends Projectile with NewtonianMover {

    ChaserProjectile(Tower parent, Enemy target, Vector targetPos) : super(parent, target, targetPos) {
        //TODO: STUFF
    }
}