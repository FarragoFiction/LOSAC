import "dart:html";

import "../entities/towertype.dart";
import "../level/grid.dart";
import '../level/selectable.dart';
import '../renderer/3d/renderer3d.dart';
import 'ui.dart';

class UIButton extends UIComponent with HasTooltip {

    UIButton(UIController controller) : super(controller);

    @override
    Element createElement() {
        return new DivElement()
            ..className="Button"
        ;
    }

    @override
    void update() {
        if (!hasElement) { return; }

        usable().then((bool canUse) {
            if(!canUse) {
                this.element.classes.add("disabled");
            } else {
                this.element.classes.remove("disabled");
            }
        });
    }

    Future<bool> usable() async => true;
    Future<void> onUse() async {}

    @override
    Future<void> populateTooltip(Element tooltip) async {}
}


class BuildButton extends UIButton {

    final TowerType towerType;
    final GridCellSelectionDisplay selectionDisplay;

    GridCell get selected {
        return selectionDisplay.selected;
    }

    BuildButton(UIController controller, GridCellSelectionDisplay this.selectionDisplay, TowerType this.towerType) : super(controller);

    @override
    Element createElement() {
        final Element e = super.createElement();

        e.onMouseOver.listen((MouseEvent e) {
            final Renderer3D r = engine.renderer;
            if (selected != null) {
                r.updateTowerPreview(towerType, selected);
            }
        });

        e.onMouseOut.listen((MouseEvent e) {
            final Renderer3D r = engine.renderer;
            r.clearTowerPreview();
        });

        return e;
    }

    /*@override
    void update() {
        super.update();
    }*/

    @override
    Future<bool> usable() async {
        final bool needsBlockCheck = towerType.blocksPath;

        if (needsBlockCheck) {
            if ((!selectionDisplay.blockChecked) || (!selectionDisplay.placementAllowed)) {
                return false;
            }
        }

        return true;
    }

    @override
    Future<void> populateTooltip(Element tooltip) async {
        tooltip.append(new HeadingElement.h1()..text=localise(towerType.getDisplayName()));

        //final Element p = new ParagraphElement();
        for (int i=0; i<50; i++) {
            //p.appendText("words ");
            tooltip.appendText("words ");
        }

        //tooltip.append(p);
    }
}