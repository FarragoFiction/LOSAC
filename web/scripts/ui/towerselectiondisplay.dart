import "dart:html";

import "../entities/tower.dart";
import '../entities/towertype.dart';
import '../level/grid.dart';
import "selectionwindow.dart";
import "ui.dart";

class TowerSelectionDisplay extends SelectionDisplayWithGrid<Tower> {

    bool blockChecked = false;
    bool placementAllowed = false;

    TowerSelectionDisplay(UIController controller) : super(controller) {
        /*for(final TowerType tower in controller.engine.towerTypeRegistry.whereValue((TowerType tested) => true)) {
            grid.addButton(new BuildButton(controller, this, tower));
        }*/
    }

    /*@override
    Future<void> postSelect() async {
        placementAllowed = await engine.placementCheck(selected.node);
        blockChecked = true;

        update();
    }*/
}