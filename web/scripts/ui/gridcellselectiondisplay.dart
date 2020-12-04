import "dart:html";

import '../entities/towertype.dart';
import '../level/grid.dart';
import "selectionwindow.dart";
import "ui.dart";

class GridCellSelectionDisplay extends SelectionDisplayWithGrid<GridCell> {
    static int placementUpdateSteps = 30;

    bool blockChecked = false;
    bool placementAllowed = false;

    int placementUpdateStep = 0;

    GridCellSelectionDisplay(UIController controller) : super(controller) {
        for(final TowerType tower in controller.engine.towerTypeRegistry.whereValue((TowerType tested) => tested.buildable)) {
            grid.addButton(new BuildButton(controller, this, tower));
        }
    }

    @override
    void update() {
        // re-check the placement blocking for when enemies move in or out of cells
        placementUpdateStep++;
        if (placementUpdateStep >= placementUpdateSteps) {
            placementUpdateStep = 0;

            // async, but that's fine
            engine.placementCheck(selected.node).then((bool result) {
                placementAllowed = result;
            });
        }
    }

    @override
    Future<void> postSelect() async {
        placementAllowed = await engine.placementCheck(selected.node);
        blockChecked = true;

        update();
    }
}