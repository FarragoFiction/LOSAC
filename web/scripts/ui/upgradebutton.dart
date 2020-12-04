import "dart:html";

import '../entities/tower.dart';
import '../entities/towertype.dart';
import "../renderer/3d/renderer3d.dart";
import 'ui.dart';

class UpgradeButton extends UIButton {

    final TowerType towerType;
    final TowerSelectionDisplay selectionDisplay;

    Tower get selected => selectionDisplay.selected;

    UpgradeButton(UIController controller, TowerSelectionDisplay this.selectionDisplay, TowerType this.towerType) : super(controller);

    @override
    Element createElement() {
        final Element e = super.createElement();

        e.onMouseOver.listen((MouseEvent e) {
            final Renderer3D r = engine.renderer;
            if (selected != null && canBuildHere()) {
                r.updateTowerPreview(towerType, selected.gridCell);
            }
        });

        e.onMouseOut.listen((MouseEvent e) {
            final Renderer3D r = engine.renderer;
            r.clearTowerPreview();
        });

        return e;
    }

    @override
    Future<void> onUse() async {
        if (!canBuildHere()) { return; }

        selected.upgrade(towerType);
    }

    @override
    bool usable() {
        if (!(super.usable())) { return false; }

        // check for switching from non-blocking to blocking
        if (!canBuildHere()) { return false; }

        // TODO: resource checks go here

        return true;
    }

    /// Separated from the usable() check to allow the preview to be shown even if resources are missing
    bool canBuildHere() {
        // if the tower is doing something else, nope
        if (selected.state != TowerState.ready) { return false; }

        final bool blocked = selected.gridCell.node.blocked;

        if ((!blocked) && towerType.blocksPath && (!selectionDisplay.placementAllowed)) {
            return false;
        }

        return true;
    }

    @override
    Future<void> populateTooltip(Element tooltip) async {
        towerType.populateTooltip(tooltip, controller);
    }
}