import "dart:html";
import "dart:math" as Math;

import "../targeting/strategies.dart";
import "enemy.dart";

class TowerType {
    /// "close enough" angle delta for turrets - within this, we are considered to be pointing at the target
    static const double fireAngleFuzz = 0.01;
    static final TargetingStrategy<Enemy> defaultTargetingStrategy = new ProgressTargetingStrategy() + new StickyTargetingStrategy() * 0.1;

    /// Maximum target count
    /// This isn't the amount of targets which can be hit (since AoE is a thing),
    /// but how many enemies may be independently targeted at once.
    int maxTargets = 1;
    /// Minimum time between shots.
    /// Turreted towers may need more time to line up the shot
    double weaponCooldown = 0.2;
    /// Damage per hit inflicted upon target.
    double weaponDamage = 1.0;
    /// Targeting strategies evaluate each enemy in range when targets are being selected.
    /// The enemy/enemies rated highest will be targeted.
    TargetingStrategy<Enemy> targetingStrategy = defaultTargetingStrategy;
    /// Weapon range, in pixels at 100% zoom.
    double range = 200;
    /// Weapon projectile speed, in pixels per second at 100% zoom.
    double projectileSpeed = 450;

    /// Does this tower have a turret?
    bool turreted = true;
    /// Does this tower lead targets with its turret?
    bool leadTargets = true;
    /// When leading targets, allow leading points which are within this many times [range].
    double leadingRangeGraceFactor = 1.1;
    /// Turret turn rate per second in radians.
    double turnRate = Math.pi * 0.5;
    /// How close the turret angle needs to be to fire, in radians.
    /// This might be greater than 0 for something like a missile launcher which doesn't require precise aim
    double fireAngle = 0;



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
}