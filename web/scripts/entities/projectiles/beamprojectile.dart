import "package:CubeLib/CubeLib.dart" as B;

import "../enemy.dart";
import "../tower.dart";
import "../towertype.dart";
import "projectile.dart";

class BeamProjectile extends Projectile {

    BeamWeaponType get type => projectileType as BeamWeaponType;

    BeamProjectile(Tower parent, Enemy target, B.Vector2 targetPos, double targetHeight) : super.impl(parent, target, targetPos, targetHeight) {
        //TODO: STUFF
    }
}

class BeamWeaponType extends WeaponType {

    //BeamWeaponType(TowerType towerType) : super(towerType);

    @override
    Projectile spawnProjectile(Tower parent, Enemy target, B.Vector2 targetPos, double targetHeight) => new BeamProjectile(parent, target, targetPos, targetHeight);
}