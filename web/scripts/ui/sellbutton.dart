import "dart:html";

import "../entities/tower.dart";
import "../entities/towertype.dart";
import "../level/grid.dart";
import "../renderer/3d/renderer3d.dart";
import "ui.dart";

class SellButton extends UIButton {

    final TowerSelectionDisplay selectionDisplay;

    Tower get selected => selectionDisplay.selected;

    SellButton(UIController controller, TowerSelectionDisplay this.selectionDisplay) : super(controller);

    @override
    Future<void> onUse() async {
        selected.sell();
    }

    @override
    bool usable() {
        if (selected.state != TowerState.ready) {
            return false;
        }

        return true;
    }

    @override
    Element createElement() {
        return super.createElement()..classes.add("DisplayButton");
    }

    @override
    Future<void> populateTooltip(Element tooltip) async {
        //tooltip.append(new HeadingElement.h1()..text=localise(towerType.getDisplayName()));
        tooltip.appendText("sell");
    }
}