import "package:petitparser/petitparser.dart";

import "../engine/entity.dart";
import "../entities/enemy.dart";
import 'strategies.dart';

abstract class TargetingParser {
    static Parser<TargetingStrategy<Enemy>>? _parser;
    static Parser<TargetingStrategy<Enemy>> get parser {
        _parser ??= _build<Enemy>(TargetingStrategies.enemyStrategies).cast();
        return _parser!;
    }

    static TargetingStrategy<T> _strategify<T extends Entity>(dynamic n) {
        if (n is num) {
            return new ScaledTargetingStrategy<T>(null, n);
        } else if (n is TargetingStrategy<T>) {
            return n;
        }
        throw Exception("Shouldn't reach here");
    }

    static Parser _build<T extends Entity>(Map<String, TargetingStrategy<T> Function()> strategyMap) {
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
                    .flatten("Strategy name expected")
                    .trim()
                    .map((String input) {
                        return strategyMap[input]!();
                    }
                )
            )

            // parentheses
            ..wrapper(char("(").trim(), char(")").trim(), (Object? left, Object? value, Object? right) => value)
        ;
        // negation
        builder.group().prefix(char("-").trim(), (String op, dynamic a) => -a);
        // multiplication and division
        builder.group()
            ..left(char("*").trim(), (dynamic a, dynamic op, dynamic b) => _strategify<T>(a) * b)
            ..left(char("/").trim(), (dynamic a, dynamic op, dynamic b) => _strategify<T>(a) / b);
        // addition and subtraction
        builder.group()
            ..left(char("+").trim(), (dynamic a, dynamic op, dynamic b) => _strategify<T>(a) + b)
            ..left(char("-").trim(), (dynamic a, dynamic op, dynamic b) => _strategify<T>(a) - b);

        return builder.build().map((dynamic n) => (n is num) ? _strategify<T>(n) : n).end();
    }

    static void test() {
        final Parser p = parser;

        Result<dynamic> result = p.parse("2.5");
        print("${result.value} -> ${result.value.runtimeType}");

        /*result = p.parse("bob");
        print("${result.value} -> ${result.value.runtimeType}");

        result = p.parse("foo");
        print("${result.value} -> ${result.value.runtimeType}");

        result = p.parse("(bob - (foo+3)) * (6 + 2)");
        print("${result.value} -> ${result.value.runtimeType}");*/

        result = p.parse("(random + 69 + progress) / (69 * sticky)");
        print("${result.value} -> ${result.value.runtimeType}");
    }
}