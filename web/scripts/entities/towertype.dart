import "dart:html";
import "dart:math" as Math;

import "package:CubeLib/CubeLib.dart" as B;

import "../engine/registry.dart";
import "../targeting/strategies.dart";
import "enemy.dart";
import "projectiles/projectile.dart";

class TowerType with Registerable {
    /// "close enough" angle delta for turrets - within this, we are considered to be pointing at the target
    static const double fireAngleFuzz = 0.01;
    static final TargetingStrategy<Enemy> defaultTargetingStrategy = new ProgressTargetingStrategy() + new StickyTargetingStrategy() * 0.1;

    /// Localisation string
    /// Will resolve patterns such as "tower.(this value).name"
    String name = "default";
    /// Does this tower block the path of enemies?
    bool blocksPath = true;
    /// How long in seconds does this tower take to construct or upgrade to?
    double buildTime = 5.0;

    /// Does this tower have a turret?
    bool turreted = false;
    /// Does this tower lead targets with its turret?
    bool leadTargets = false;
    /// When leading targets, allow leading points which are within this many times [range].
    double leadingRangeGraceFactor = 1.1;
    /// Turret turn rate per second in radians.
    double turnRate = Math.pi * 0.5;
    /// How close the turret angle needs to be to fire, in radians.
    /// This might be greater than 0 for something like a missile launcher which doesn't require precise aim
    double fireAngle = 1.5;

    WeaponType weapon;

    B.Mesh mesh;

    TowerType() {
        weapon = new ChaserWeaponType(this);
    }

    void draw2D(CanvasRenderingContext2D ctx) {
        ctx.fillStyle="#A0A0A0";

        const int radius = 22;

        ctx
            ..beginPath()
            ..arc(0,0,radius, 0, Math.pi*2)
            ..closePath()
            ..fill();
    }

    void drawTurret(CanvasRenderingContext2D ctx) {
        ctx.fillStyle="#C0C0C0";

        const int radius = 13;
        const int w = 10;

        ctx
            ..beginPath()
            ..arc(0,0,radius, 0, Math.pi*2)
            ..closePath()
            ..fill()
            ..fillRect(0, -w*0.5, 25, w);
    }

    @override
    String getRegistrationKey() => name;

    String getDisplayName() => "tower.$name.name";
}