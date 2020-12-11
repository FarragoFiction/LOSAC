import "dart:html";

import "../engine/game.dart";
import "../entities/tower.dart";
import "../entities/towertype.dart";
import "../level/grid.dart";
import "../renderer/3d/renderer3d.dart";
import "ui.dart";

class BuildButton extends UIButton {

    final TowerType towerType;
    final GridCellSelectionDisplay selectionDisplay;

    GridCell get selected => selectionDisplay.selected;

    BuildButton(UIController controller, GridCellSelectionDisplay this.selectionDisplay, TowerType this.towerType) : super(controller);

    @override
    Element createElement() {
        final Element e = super.createElement();

        e.onMouseOver.listen((MouseEvent e) {
            final Renderer3D r = engine.renderer;
            if (selected != null && canBuildHere()) {
                r.updateTowerPreview(towerType, selected);
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
        if (towerType.blocksPath) {
            final bool canPlace = await engine.placementCheck(selected.node);
            selectionDisplay.placementAllowed = canPlace;
            if (!canPlace) { return; }
        }

        final Tower tower = new Tower(towerType);
        await selected.placeTower(tower);
        tower.startBuilding();

        engine.selectObject(tower);
    }

    @override
    bool usable() {
        if (!(super.usable())) { return false; }

        // not usable if this space is not a valid build location for this tower
        if (!canBuildHere()) { return false; }

        if (!towerType.isAffordable(engine)) { return false; }

        return true;
    }

    /// Separated from the usable() check to allow the preview to be shown even if resources are missing
    bool canBuildHere() {
        // if the cell already has a tower, abort
        // this should be rare as it's either temporarily there or not something you're able to select
        if (selectionDisplay.selected.tower != null) { return false; }

        // we shouldn't be able to do anything to an already blocked node, this is mostly so we can assume it's clear
        if (selectionDisplay.selected.node.blocked) { return false; }

        // does the tower that we're placing block the path?
        final bool needsBlockCheck = towerType.blocksPath;

        // check that the cell has had a response from the pathfinder blocking query
        if (needsBlockCheck) {
            if ((!selectionDisplay.blockChecked) || (!selectionDisplay.placementAllowed)) {
                return false;
            }
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