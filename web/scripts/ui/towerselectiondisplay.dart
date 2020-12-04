import "../entities/tower.dart";
import "../entities/towertype.dart";
import "selectionwindow.dart";
import "ui.dart";

class TowerSelectionDisplay extends SelectionDisplayWithGrid<Tower> {

    bool blockChecked = false;
    bool placementAllowed = false;

    int placementUpdateStep = 0;

    SellButton sellButton;
    CancelButton cancelButton;
    ProgressBarUI progressBar;

    TowerSelectionDisplay(UIController controller) : super(controller) {
        this.sellButton = this.addChild(new SellButton(controller, this));
        this.cancelButton = this.addChild(new CancelButton(controller, this));
        this.progressBar = this.addChild(new ProgressBarUI(controller));
    }

    @override
    void update() {
        // re-check the placement blocking for when enemies move in or out of cells
        placementUpdateStep++;
        if (placementUpdateStep >= GridCellSelectionDisplay.placementUpdateSteps) {
            placementUpdateStep = 0;

            // async, but that's fine
            if (selected.gridCell.node.blocked) {
                placementAllowed = false;
            } else {
                engine.placementCheck(selected.gridCell.node).then((bool result) {
                    placementAllowed = result;
                });
            }
        }

        this.progressBar.progressFraction = selected.getProgress();
    }

    @override
    Future<void> postSelect() async {
        for(final TowerType tower in selected.towerType.upgradeList) {
            grid.addButton(new UpgradeButton(controller, this, tower));
        }

        if (selected.gridCell.node.blocked) {
            placementAllowed = false;
        } else {
            placementAllowed = await engine.placementCheck(selected.gridCell.node);
        }
        blockChecked = true;

        update();
    }
}