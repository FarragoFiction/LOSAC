import "dart:html";

import "../renderer/3d/renderer3d.dart";
import 'ui.dart';

class TooltipComponent extends UIComponent {
    static const int updateSteps = 5;
    int updateStep = 0;

    TooltipComponent(UIController controller) : super(controller);

    @override
    Element createElement() {
        return new DivElement()
            ..className = "Tooltip uibackground hidden"
        ;
    }

    @override
    void update() {
        if (!this.hasElement) { return; }
        if (updateStep < updateSteps) {
            updateStep++;
            return;
        }
        updateStep = 0;

        if (engine?.input?.mousePos == null) { return; }

        final HasTooltip object = controller.queryComponentAtCoords(engine.input.mousePos, (UIComponent c) => c is HasTooltip);

        if (object == null) {
            element.classes.add("hidden");
        } else {
            this.element.children.clear();
            object.populateTooltip(this.element);
            element.classes.remove("hidden");
        }
    }


}

mixin HasTooltip on UIComponent {
    Future<void> populateTooltip(Element tooltip);
}