import "dart:html";

import "../level/selectable.dart";
import 'ui.dart';

class SelectionWindow extends UIComponent {

    SelectionWindow(UIController controller) : super(controller);

    @override
    void update() {
        final Selectable selected = engine.selected;

        element.text = selected?.name;
    }

    @override
    Element createElement() {
        return new DivElement()
            ..className="uibackground bottom right"
            ..style.width="200px"
            ..style.height="150px"
        ;
    }
}