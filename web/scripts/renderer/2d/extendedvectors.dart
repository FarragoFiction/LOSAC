
import "package:CommonLib/Utility.dart";
import "package:CubeLib/CubeLib.dart" as B;

abstract class ExtendableVector2 implements B.Vector2 {
    B.Vector2 _v;

    ExtendableVector2(num x, num y) {
        _v = new B.Vector2(x,y);
    }

    @override
    num get x => _v.x;
    @override
    set x(num n) => _v.x = n;

    @override
    num get y => _v.y;
    @override
    set y(num n) => _v.y = n;

    @override
    B.Vector2 add(B.Vector2 otherVector) => _v.add(otherVector);

    @override
    B.Vector2 addInPlace(B.Vector2 otherVector) { _v.addInPlace(otherVector); return this; }

    @override
    B.Vector2 addToRef(B.Vector2 otherVector, B.Vector2 result) { _v.addToRef(otherVector, result); return this; }

    @override
    B.Vector2 addVector3(B.Vector3 otherVector) => _v.addVector3(otherVector);

    @override
    List<num> asArray() => _v.asArray();

    @override
    B.Vector2 clone() => _v.clone();

    @override
    B.Vector2 copyFrom(B.Vector2 source) { _v.copyFrom(source); return this; }

    @override
    B.Vector2 copyFromFloats(num x, num y) { _v.copyFromFloats(x, y); return this; }

    @override
    B.Vector2 divide(B.Vector2 otherVector) => _v.divide(otherVector);

    @override
    B.Vector2 divideInPlace(B.Vector2 otherVector) { _v.divideInPlace(otherVector); return this; }

    @override
    B.Vector2 divideToRef(B.Vector2 otherVector, B.Vector2 result) { _v.divideToRef(otherVector, result); return this; }

    @override
    bool equals(B.Vector2 otherVector) => _v.equals(otherVector);

    @override
    bool equalsWithEpsilon(B.Vector2 otherVector, [num epsilon]) => _v.equalsWithEpsilon(otherVector, epsilon);

    @override
    B.Vector2 floor() => _v.floor();

    @override
    B.Vector2 fract() => _v.fract();

    @override
    String getClassName() => _v.getClassName();

    @override
    num getHashCode() => _v.getHashCode();

    @override
    num length() => _v.length();

    @override
    num lengthSquared() => _v.lengthSquared();

    @override
    B.Vector2 multiply(B.Vector2 otherVector) => _v.multiply(otherVector);

    @override
    B.Vector2 multiplyByFloats(num x, num y) => _v.multiplyByFloats(x, y);

    @override
    B.Vector2 multiplyInPlace(B.Vector2 otherVector) { _v.multiplyInPlace(otherVector); return this; }

    @override
    B.Vector2 multiplyToRef(B.Vector2 otherVector, B.Vector2 result) { _v.multiplyToRef(otherVector, result); return this; }

    @override
    B.Vector2 negate() => _v.negate();

    @override
    B.Vector2 negateInPlace() { _v.negateInPlace(); return this; }

    @override
    B.Vector2 negateToRef(B.Vector2 result) { _v.negateToRef(result); return this; }

    @override
    B.Vector2 normalize() { _v.normalize(); return this; }

    @override
    B.Vector2 scale(num scale) => _v.scale(scale);

    @override
    B.Vector2 scaleAndAddToRef(num scale, B.Vector2 result) { _v.scaleAndAddToRef(scale, result); return this; }

    @override
    B.Vector2 scaleInPlace(num scale) { _v.scaleInPlace(scale); return this; }

    @override
    B.Vector2 scaleToRef(num scale, B.Vector2 result) { _v.scaleToRef(scale, result); return this; }

    @override
    B.Vector2 set(num x, num y) { _v.set(x,y); return this; }

    @override
    B.Vector2 subtract(B.Vector2 otherVector) => _v.subtract(otherVector);

    @override
    B.Vector2 subtractInPlace(B.Vector2 otherVector) { _v.subtractInPlace(otherVector); return this; }

    @override
    B.Vector2 subtractToRef(B.Vector2 otherVector, B.Vector2 result) { _v.subtractToRef(otherVector, result); return this; }

    @override
    B.Vector2 toArray(dynamic array, [num index]) { _v.toArray(array, index); return this; }
}

class Vector2WithCallback extends ExtendableVector2 {
    Lambda<B.Vector2> callback;

    Vector2WithCallback(num x, num y) : super(x,y);

    @override
    set x(num n) { super.x = n; callback(this); }

    @override
    set y(num n) { super.y = n; callback(this); }

    @override
    B.Vector2 addInPlace(B.Vector2 otherVector) { callback(this); return super.addInPlace(otherVector); }
    @override
    B.Vector2 divideInPlace(B.Vector2 otherVector) { callback(this); return super.divideInPlace(otherVector); }
    @override
    B.Vector2 multiplyInPlace(B.Vector2 otherVector) { callback(this); return super.multiplyInPlace(otherVector); }
    @override
    B.Vector2 negateInPlace() { callback(this); return super.negateInPlace(); }
    @override
    B.Vector2 scaleInPlace(num scale) { callback(this); return super.scaleInPlace(scale); }
    @override
    B.Vector2 subtractInPlace(B.Vector2 otherVector) { callback(this); return super.subtractInPlace(otherVector); }
}

