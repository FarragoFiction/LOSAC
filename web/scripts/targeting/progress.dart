
import "../entities/enemy.dart";
import "../entities/tower.dart";
import "targetingstrategy.dart";

class ProgressTargetingStrategy extends EnemyTargetingStrategy {
    static final ProgressTargetingStrategy _instance = new ProgressTargetingStrategy._();
    factory ProgressTargetingStrategy() => _instance;
    ProgressTargetingStrategy._();

    @override
    double evaluate(Tower tower, Enemy target) => target.progressToExit;
}