import "dart:html";

import "../entities/tower.dart";
import "../entities/towertype.dart";
import "../level/grid.dart";
import "../renderer/3d/renderer3d.dart";
import "ui.dart";

class CancelButton extends UIButton {

    final TowerSelectionDisplay selectionDisplay;

    Tower get selected => selectionDisplay.selected;

    CancelButton(UIController controller, TowerSelectionDisplay this.selectionDisplay) : super(controller);

    @override
    Future<void> onUse() async {
        selected.cancelBuilding();
    }

    @override
    bool usable() {
        if (selected.state == TowerState.building || selected.state == TowerState.upgrading || selected.state == TowerState.selling) {
            return true;
        }

        return false;
    }

    @override
    Element createElement() {
        return super.createElement()..classes.add("DisplayButton");
    }

    @override
    Future<void> populateTooltip(Element tooltip) async {
        String name = "name";
        String description = "description";

        if (selected.state == TowerState.selling) {
            name = "ui.cancelsell.name";
            description = "ui.cancelsell.description";
        } else if (selected.state == TowerState.upgrading) {
            name = "ui.cancelupgrade.name";
            description = "ui.cancelupgrade.description";
        } else if (selected.state == TowerState.building) {
            name = "ui.cancelbuild.name";
            description = "ui.cancelbuild.description";
        }

        tooltip.append(new HeadingElement.h1()..appendFormattedLocalisation(name, engine.localisation));
        tooltip.appendFormattedLocalisation(description, engine.localisation);
    }
}