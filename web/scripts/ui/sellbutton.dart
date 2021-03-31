import "dart:html";

import "../engine/game.dart";
import "../entities/tower.dart";
import "ui.dart";

class SellButton extends UIButton {

    final TowerSelectionDisplay selectionDisplay;

    Tower? get selected => selectionDisplay.selected;
    Game get game => engine as Game;

    late Map<String,String> _sellInfo;

    SellButton(UIController controller, TowerSelectionDisplay this.selectionDisplay) : super(controller) {
        _sellInfo = <String,String>{ "percent" : (game.rules.sellReturn * 100).floor().toString() };
    }

    @override
    Future<void> onUse() async {
        selected?.sell();
    }

    @override
    bool usable() {
        if (selected?.state != TowerState.ready) {
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
        tooltip.append(new HeadingElement.h1()..appendFormattedLocalisation("ui.sell.name", engine.localisation));

        selected?.sellValue.populateTooltip(tooltip, engine.localisation, displayMultiplier: game.rules.sellReturn, showInsufficient: false, plus: true);
        tooltip..append(new BRElement())..append(new BRElement());

        tooltip.appendFormattedLocalisation("ui.sell.description", engine.localisation, data: _sellInfo);
    }
}