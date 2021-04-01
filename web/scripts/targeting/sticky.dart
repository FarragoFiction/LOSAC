
import "../entities/enemy.dart";
import "../entities/tower.dart";
import "targetingstrategy.dart";

class StickyTargetingStrategy extends EnemyTargetingStrategy {
    static final StickyTargetingStrategy _instance = new StickyTargetingStrategy._();
    factory StickyTargetingStrategy() => _instance;
    StickyTargetingStrategy._();

    @override
    double evaluate(Tower tower, Enemy target) => tower.targets.contains(target) ? 1.0 : 0.0;

    @override
    String toString() => "Sticky";
}