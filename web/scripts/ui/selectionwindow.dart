import "dart:html";

import "../level/selectable.dart";
import 'ui.dart';

export "gridcellselectiondisplay.dart";
export "towerselectiondisplay.dart";

class SelectionWindow extends UIComponent {

    Selectable? selected;
    SelectionDisplay<dynamic>? display;

    SelectionWindow(UIController controller) : super(controller);

    @override
    void update() {
        final Selectable? selected = engine.selected;

        // check if selected has changed, otherwise keep going
        if (selected == this.selected) { return; }
        this.selected = selected;

        if (this.display != null) {
            if (this.selected == null) {
                new Future<void>.delayed(const Duration(milliseconds: 160), (){
                    this.removeChild(display!);
                });
            } else {
                this.removeChild(display!);
            }
        }

        // exit early if it's null since we don't need a new display
        if (this.selected == null) {
            element!.style.bottom = "-100vh";
            return;
        }

        final SelectionDisplay<dynamic>? disp = this.selected!.createSelectionUI(controller);

        // if it's not giving anything, abort
        if (disp == null) { return; }

        this.display = disp;
        disp.selected = this.selected;
        disp.postSelect();
        this.addChild(disp);

        element!.style.bottom = "";
    }

    @override
    Element createElement() {
        return new DivElement()
            ..className="bottom left SelectionWindow"
        ;
    }
}

class SelectionDisplay<Type extends Selectable> extends UIComponent {

    Type? selected;

    SelectionDisplay(UIController controller) : super(controller);

    @override
    Element createElement() {
        return new DivElement()
            ..className = "uibackground bottom SelectionDisplay"

            ..append(new SpanElement()..text = localise("${(selected?.name) ?? "default"}.name"))
        ;
    }

    /// called after selection is set
    Future<void> postSelect() async {}

    @override
    void update() {}
}

class SelectionDisplayWithGrid<Type extends Selectable> extends SelectionDisplay<Type> {

    late ButtonGrid grid;

    SelectionDisplayWithGrid(UIController controller) : super(controller) {
        this.grid = new ButtonGrid(controller);
        this.addChild(grid);
    }

    @override
    void resize() {
        grid.element?.classes.add("BuildGrid");
        grid.element?.style.setProperty("--width", "${window.innerWidth! - grid.element!.offset.left}px");
    }
}

