
import "package:CubeLib/CubeLib.dart" as B;

import '../ui/ui.dart';
import 'levelobject.dart';

mixin Selectable on SimpleLevelObject {
    //bool selectable = true;

    String get name;

    Selectable getSelectable(B.Vector2 loc) => this;

    SelectionDisplay<Selectable> createSelectionUI(UIController controller) => new SelectionDisplay<Selectable>(controller);
}