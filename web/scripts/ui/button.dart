import "dart:html";

import "../entities/towertype.dart";
import "../level/grid.dart";
import 'ui.dart';

class UIButton extends UIComponent with HasTooltip {

    UIButton(UIController controller) : super(controller);

    @override
    Element createElement() {
        return new DivElement()
            ..className="Button"
        ;
    }

    @override
    void update() {}

    Future<bool> usable() async => true;
    Future<void> onUse() async {}

    @override
    Future<void> populateTooltip(Element tooltip) async {}
}


class BuildButton extends UIButton {

    TowerType towerType;

    GridCell get selected {
        final GridCellSelectionDisplay display = parent.parent;
        return display.selected;
    }

    BuildButton(UIController controller, TowerType this.towerType) : super(controller);

    @override
    Future<void> populateTooltip(Element tooltip) async { tooltip.text = localise(towerType.getDisplayName()); }
}