
import "../engine/entity.dart";
import "../entities/enemy.dart";
import "../entities/tower.dart";

abstract class TargetingStrategy<T extends Entity> {
    const TargetingStrategy();

    double evaluate(Tower tower, T target);

    TargetingStrategy<T> operator -() {
        return this * -1;
    }

    TargetingStrategy<T> operator *(Object other) {
        if (other is num) {
            return new ScaledTargetingStrategy<T>(this, other.toDouble());
        } else if (other is TargetingStrategy<T>) {
            return new CompositeTargetingStrategy<T>(CompositeMode.multiply, this, other);
        }
        throw Exception("Invalid operand $other must be a number or TargetingStrategy");
    }

    TargetingStrategy<T> operator /(Object other) {
        if (other is num) {
            return new ScaledTargetingStrategy<T>(this, 1 / other);
        } else if (other is TargetingStrategy<T>) {
            return new CompositeTargetingStrategy<T>(CompositeMode.multiply, this, new InverseTargetingStrategy<T>(other));
        }
        throw Exception("Invalid operand $other must be a number or TargetingStrategy");
    }

    CompositeTargetingStrategy<T> operator +(Object other) {
        if (other is num) {
            return new CompositeTargetingStrategy<T>(CompositeMode.add, this, new ScaledTargetingStrategy<T>(null, other.toDouble()));
        } else if (other is TargetingStrategy<T>) {
            return new CompositeTargetingStrategy<T>(CompositeMode.add, this, other);
        }
        throw Exception("Invalid operand $other must be a number or TargetingStrategy");
    }

    CompositeTargetingStrategy<T> operator -(Object other) {
        if (other is num) {
            return new CompositeTargetingStrategy<T>(CompositeMode.add, this, new ScaledTargetingStrategy<T>(null, -other.toDouble()));
        } else if (other is TargetingStrategy<T>) {
            return new CompositeTargetingStrategy<T>(CompositeMode.add, this, new ScaledTargetingStrategy<T>(other, -1));
        }
        throw Exception("Invalid operand $other must be a number or TargetingStrategy");
    }
}

/// Can also be used with a null source as a constant value
class ScaledTargetingStrategy<T extends Entity> extends TargetingStrategy<T> {
    final TargetingStrategy<T>? source;
    final double scale;

    factory ScaledTargetingStrategy(TargetingStrategy<T>? source, num scale) {
        if (source is ScaledTargetingStrategy<T>) {
            final ScaledTargetingStrategy<T> s = source;
            return new ScaledTargetingStrategy<T>._(s.source, scale * s.scale);
        } else {
            return new ScaledTargetingStrategy<T>._(source, scale.toDouble());
        }
    }

    const ScaledTargetingStrategy._(TargetingStrategy<T>? this.source, double this.scale);

    @override
    double evaluate(Tower tower, T target) => source == null ? scale : source!.evaluate(tower, target) * scale;

    @override
    String toString() => source == null ? scale.toString() : "( $source * $scale )";
}

class InverseTargetingStrategy<T extends Entity> extends TargetingStrategy<T> {
    final TargetingStrategy<T> source;

    const InverseTargetingStrategy(TargetingStrategy<T> this.source);

    static TargetingStrategy<T> getInverse<T extends Entity>(TargetingStrategy<T> source) {
        if (source is InverseTargetingStrategy<T>) {
            return source.source;
        } else if (source is ScaledTargetingStrategy<T>) {
            if (source.source is InverseTargetingStrategy<T>) {
                final InverseTargetingStrategy<T> inv = source.source as InverseTargetingStrategy<T>;
                return new ScaledTargetingStrategy<T>(inv.source, source.scale);
            } else {
                return new InverseTargetingStrategy<T>(source);
            }
        } else {
            return new InverseTargetingStrategy<T>(source);
        }
    }

    @override
    double evaluate(Tower tower, T target) => 1.0 / source.evaluate(tower, target);

    @override
    String toString() => "( 1 / $source )";
}

enum CompositeMode {
    add,
    multiply
}

class CompositeTargetingStrategy<T extends Entity> extends TargetingStrategy<T> {
    final CompositeMode mode;
    final Set<TargetingStrategy<T>> strategies = <TargetingStrategy<T>>{};

    factory CompositeTargetingStrategy(CompositeMode mode, TargetingStrategy<T> first, TargetingStrategy<T> second) {
        final bool firstComp = first is CompositeTargetingStrategy<T>;
        final bool secondComp = second is CompositeTargetingStrategy<T>;
        final CompositeTargetingStrategy<T>? firstC = firstComp ? first : null;
        final CompositeTargetingStrategy<T>? secondC = secondComp ? second : null;

        if (firstComp && firstC!.mode == mode) {
            if (secondComp && secondC!.mode == mode) {
                firstC.strategies.addAll(secondC.strategies);
                return firstC;
            } else {
                firstC.strategies.add(second);
                return firstC;
            }
        } else if (secondComp && secondC!.mode == mode) {
            final CompositeTargetingStrategy<T> secondC = second;
            secondC.strategies.add(first);
            return secondC;
        } else {
            return new CompositeTargetingStrategy<T>._(mode, first, second);
        }
    }

    CompositeTargetingStrategy._(CompositeMode this.mode, TargetingStrategy<T> first, TargetingStrategy<T> second) {
        this.strategies.add(first);
        this.strategies.add(second);
    }

    @override
    double evaluate(Tower tower, T target) {
        late double val;

        if (this.mode == CompositeMode.add) {
            val = 0;

            for (final TargetingStrategy<T> strategy in strategies) {
                val += strategy.evaluate(tower, target);
            }
        } else if (this.mode == CompositeMode.multiply) {
            val = 1;

            for (final TargetingStrategy<T> strategy in strategies) {
                val *= strategy.evaluate(tower, target);
            }
        }

        return val;
    }

    @override
    String toString() => "( ${strategies.join(" ${mode == CompositeMode.add ? "+" : "*"} ")} )";
}

abstract class EnemyTargetingStrategy extends TargetingStrategy<Enemy> {}
abstract class TowerTargetingStrategy extends TargetingStrategy<Tower> {}