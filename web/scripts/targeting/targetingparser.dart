import "package:petitparser/petitparser.dart";

import "../engine/entity.dart";
import "../entities/enemy.dart";
import "../entities/tower.dart";
import 'strategies.dart';

class TargetingParser<T extends Entity> {
    static final TargetingParser<Enemy> enemy = new TargetingParser<Enemy>(TargetingStrategies.enemyStrategies);
    static final TargetingParser<Tower> tower = new TargetingParser<Tower>(TargetingStrategies.towerStrategies);

    final Map<String, TargetingStrategy<T> Function()> strategies;
    late final Parser<TargetingStrategy<T>> _parser;

    TargetingParser(Map<String, TargetingStrategy<T> Function()> this.strategies) {
        _parser = _build(strategies);
    }

    TargetingStrategy<T>? parse(String input) {
        try {
            return _parser.parse(input).value;
        } on Exception catch (e) {
            print(e.toString());
        }
    }

    static TargetingStrategy<T> _strategify<T extends Entity>(dynamic n) {
        if (n is num) {
            return new ScaledTargetingStrategy<T>(null, n);
        } else if (n is TargetingStrategy<T>) {
            return n;
        }
        throw Exception("Somehow returned neither a strategy nor a number from the TargetingStrategy parser");
    }

    static Parser<TargetingStrategy<T>> _build<T extends Entity>(Map<String, TargetingStrategy<T> Function()> strategyMap) {
        final ExpressionBuilder builder = new ExpressionBuilder();

        final Iterable<Parser<String>> strategyNames = strategyMap.keys.map(stringIgnoreCase);
        Parser<dynamic> strategyNameCheck = strategyNames.first;
        for (final Parser<dynamic> p in strategyNames.skip(1)) {
            strategyNameCheck |= p;
        }

        builder.group()
            // numbers
            ..primitive(
                (
                    pattern("+-").optional() &
                    digit().plus() &
                    (char(".") & digit().plus()).optional() &
                    (pattern("eE") & pattern("+-").optional() & digit().plus()).optional()
                )
                .flatten("Number expected")
                .trim()
                .map(num.tryParse)
            )

            // strategies
            ..primitive(
                ( strategyNameCheck )
                    .flatten("Strategy name expected. Valid options: [ ${strategyMap.keys.join(", ")} ]")
                    .trim()
                    .map((String input) {
                        return strategyMap[input]!();
                    }
                )
            )

            // parentheses
            ..wrapper(char("(").trim(), char(")").trim(), (String left, dynamic value, String right) => value)
        ;
        // negation
        builder.group().prefix(char("-").trim(), (String op, dynamic a) => -a);
        // multiplication and division
        builder.group()
            ..left(char("*").trim(), (dynamic a, String op, dynamic b) => _strategify<T>(a) * b)
            ..left(char("/").trim(), (dynamic a, String op, dynamic b) => _strategify<T>(a) / b);
        // addition and subtraction
        builder.group()
            ..left(char("+").trim(), (dynamic a, String op, dynamic b) => _strategify<T>(a) + b)
            ..left(char("-").trim(), (dynamic a, String op, dynamic b) => _strategify<T>(a) - b);

        return builder.build().map((dynamic n) => _strategify<T>(n)).end().cast();
    }

    static void test() {
        final TargetingParser<Enemy> p = enemy;

        dynamic result = p.parse("2.5");
        print("$result -> ${result.runtimeType}");

        result = p.parse("(random + 69 + progress) / (69 * sticky)");
        print("$result -> ${result.runtimeType}");

        result = p.parse("bob");
        print("$result -> ${result.runtimeType}");
    }
}