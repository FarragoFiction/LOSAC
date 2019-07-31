import "dart:math" as Math;

import "../entities/enemy.dart";
import "../entities/tower.dart";
import "targetingstrategy.dart";

class RandomTargetingStrategy extends EnemyTargetingStrategy {
    static final RandomTargetingStrategy _instance = new RandomTargetingStrategy._();
    factory RandomTargetingStrategy() => _instance;
    RandomTargetingStrategy._();

    static final Math.Random _rand = new Math.Random();

    @override
    double evaluate(Tower tower, Enemy target) => _rand.nextDouble();
}