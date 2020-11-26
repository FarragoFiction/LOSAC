import "dart:html";

import '../entities/enemy.dart';
import '../entities/tower.dart';
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

    @override
    void update() {}
}

class GridCellSelectionDisplay extends SelectionDisplay<GridCell> {

    GridCellSelectionDisplay(UIController controller) : super(controller);
}