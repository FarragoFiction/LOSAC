import "dart:html";

import '../entities/enemy.dart';
import '../entities/towertype.dart';
import '../level/grid.dart';
import "../level/selectable.dart";
import 'ui.dart';

class SelectionWindow extends UIComponent {

    Selectable selected;
    SelectionDisplay<dynamic> display;

    SelectionWindow(UIController controller) : super(controller);

    @override
    void update() {
        final Selectable selected = engine.selected;

        // check if selected has changed, otherwise keep going
        if (selected == this.selected) { return; }
        this.selected = selected;

        if (this.display != null) {
            if (this.selected == null) {
                new Future<void>.delayed(const Duration(milliseconds: 160), (){
                    this.removeChild(display);
                });
            } else {
                this.removeChild(display);
            }
        }

        // exit early if it's null since we don't need a new display
        if (this.selected == null) {
            element.style.bottom = "-100vh";
            return;
        }

        final SelectionDisplay<dynamic> disp = this.selected.createSelectionUI(controller);

        // if it's not giving anything, abort
        if (disp == null) { return; }

        this.display = disp;
        display.selected = this.selected;
        display.postSelect();
        this.addChild(display);

        element.style.bottom = "";
    }

    @override
    Element createElement() {
        return new DivElement()
            ..className="bottom left SelectionWindow"
        ;
    }
}

class SelectionDisplay<Type extends Selectable> extends UIComponent {

    Type selected;

    SelectionDisplay(UIController controller) : super(controller);

    @override
    Element createElement() {
        return new DivElement()
            ..className = "uibackground bottom SelectionDisplay"

            ..append(new SpanElement()..text = localise("${selected.name}.name"))
        ;
    }

    /// called after selection is set
    Future<void> postSelect() async {}

    @override
    void update() {}
}

class GridCellSelectionDisplay extends SelectionDisplay<GridCell> {

    ButtonGrid grid;
    bool blockChecked = false;
    bool placementAllowed = false;

    GridCellSelectionDisplay(UIController controller) : super(controller) {
        this.grid = new ButtonGrid(controller);
        this.addChild(grid);

        for(final TowerType tower in controller.engine.towerTypeRegistry.whereValue((TowerType tested) => true)) {
            grid.addButton(new BuildButton(controller, this, tower));
        }
    }

    @override
    Future<void> postSelect() async {
        placementAllowed = await engine.placementCheck(selected.node);
        blockChecked = true;
        print("placement allowed: $placementAllowed");

        update();
    }

    @override
    void resize() {
        grid.element
            ..style.top = "0px"
            ..style.left = "100%"
            ..style.maxWidth = "${window.innerWidth - grid.element.offset.left}px"
        ;
    }
}