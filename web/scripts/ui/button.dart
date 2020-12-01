import "dart:html";

import 'ui.dart';

export "buildbutton.dart";

class UIButton extends UIComponent with HasTooltip {

    bool clicked = false;

    UIButton(UIController controller) : super(controller);

    @override
    Element createElement() {
        final Element e = new DivElement()
            ..className="Button"
        ;

        e.onClick.listen((MouseEvent event) async {
            if (!usable()) { return; }

            clicked = true;

            await this.onUse();

            clicked = false;
        });

        return e;
    }

    @override
    void update() {
        if (!hasElement) { return; }

        if(!usable()) {
            this.element.classes.add("disabled");
        } else {
            this.element.classes.remove("disabled");
        }
    }

    bool usable() => !clicked;
    Future<void> onUse() async {}

    @override
    Future<void> populateTooltip(Element tooltip) async {}
}


