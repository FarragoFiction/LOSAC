import "../entities/tower.dart";
import "selectionwindow.dart";
import "ui.dart";

class TowerSelectionDisplay extends SelectionDisplayWithGrid<Tower> {

    bool blockChecked = false;
    bool placementAllowed = false;

    SellButton sellButton;
    CancelButton cancelButton;

    TowerSelectionDisplay(UIController controller) : super(controller) {
        /*for(final TowerType tower in controller.engine.towerTypeRegistry.whereValue((TowerType tested) => true)) {
            grid.addButton(new BuildButton(controller, this, tower));
        }*/

        this.sellButton = this.addChild(new SellButton(controller, this));
        this.cancelButton = this.addChild(new CancelButton(controller, this));
    }

    /*@override
    Future<void> postSelect() async {
        placementAllowed = await engine.placementCheck(selected.node);
        blockChecked = true;

        update();
    }*/
}