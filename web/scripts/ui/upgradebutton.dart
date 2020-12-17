import "dart:html";

import "../engine/game.dart";
import '../entities/tower.dart';
import '../entities/towertype.dart';
import "../renderer/3d/renderer3d.dart";
import 'ui.dart';

class UpgradeButton extends UIButton {

    final TowerType towerType;
    final TowerSelectionDisplay selectionDisplay;

    Tower get selected => selectionDisplay.selected;
    Game get game => engine;

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

        game.resourceStockpile.subtract(towerType.buildCost);
        towerType.buildCost.popup(game, selected.getWorldPosition(), selected.getZPosition(), false);
        selected.upgrade(towerType);
    }

    @override
    bool usable() {
        if (!(super.usable())) { return false; }

        // check for switching from non-blocking to blocking
        if (!canBuildHere()) { return false; }

        if (!towerType.isAffordable(engine)) { return false; }

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
        towerType.populateTooltip(tooltip, controller.localisation);

        final bool blocks = !this.canBuildHere();
        final bool resources = !towerType.isAffordable(engine);

        if (blocks || resources) { tooltip.append(new BRElement()); }

        if (blocks) { tooltip..append(new BRElement())..appendFormattedLocalisation("error.build.blocked", engine.localisation); }
        if (resources) { tooltip..append(new BRElement())..appendFormattedLocalisation("error.build.resources", engine.localisation); }
    }
}