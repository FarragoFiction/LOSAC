
import "package:CubeLib/CubeLib.dart" as B;

import 'levelobject.dart';

mixin Selectable on SimpleLevelObject {
    Selectable getSelectable(B.Vector2 loc) => this;
}