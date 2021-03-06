import "package:CommonLib/Utility.dart";

import "../engine/entity.dart";
import "../entities/enemy.dart";
import "../entities/tower.dart";

// A file importing itself to get the exports will never not be weird to me
import "strategies.dart";
import 'targetingparser.dart';

export "progress.dart";
export "random.dart";
export "sticky.dart";
export "targetingstrategy.dart";

abstract class TargetingStrategies {

    static final Map<String,Generator<TargetingStrategy<Enemy>>> enemyStrategies = <String,Generator<EnemyTargetingStrategy>>{
        "progress": () => new ProgressTargetingStrategy(),
        "random"  : () => new RandomTargetingStrategy(),
        "sticky"  : () => new StickyTargetingStrategy(),
    };

    static final Map<String,Generator<TargetingStrategy<Tower>>> towerStrategies = <String,Generator<TowerTargetingStrategy>>{

    };

    static TargetingStrategy<Enemy>? parseEnemyStrategy(String input) => TargetingParser.enemy.parse(input);
    static TargetingStrategy<Tower>? parseTowerStrategy(String input) => TargetingParser.tower.parse(input);
}