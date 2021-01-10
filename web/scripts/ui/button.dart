import "dart:html";

import 'ui.dart';

export "buildbutton.dart";
export "cancelbutton.dart";
export "sellbutton.dart";
export "upgradebutton.dart";

class UIButton extends UIComponent with HasTooltip {
    static const Duration _tooltipDelay = Duration(milliseconds: 75);

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

            new Future<void>.delayed(_tooltipDelay, ()
            {
                controller.tooltip?.updateTooltipObject();
                controller.tooltip?.updateTooltipContents();
            });

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

    bool usable() => controller.engine.userCanAct() && !clicked;
    Future<void> onUse() async {}

    @override
    Future<void> populateTooltip(Element tooltip) async {}
}


