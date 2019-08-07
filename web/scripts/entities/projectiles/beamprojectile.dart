
import "../../renderer/2d/vector.dart";
import "../enemy.dart";
import "../tower.dart";
import "../towertype.dart";
import "projectile.dart";

class BeamProjectile extends Projectile {

    BeamWeaponType get type => projectileType;

    BeamProjectile(Tower parent, Enemy target, Vector targetPos) : super.impl(parent, target, targetPos) {
        //TODO: STUFF
    }
}

class BeamWeaponType extends WeaponType {

    BeamWeaponType(TowerType towerType) : super(towerType);

    @override
    Projectile spawnProjectile(Tower parent, Enemy target, Vector targetPos) => new BeamProjectile(parent, target, targetPos);
}