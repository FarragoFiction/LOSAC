import "dart:html";

import 'ui.dart';

class ProgressBarUI extends UIComponent {

    double progressFraction = 0;

    ProgressBarUI(UIController controller) : super(controller);

    @override
    Element createElement() {
        final Element outer = new DivElement()
            ..className = "ProgressBar";

        final Element inner = new DivElement()
            ..className = "ProgressBarInner";
        outer.append(inner);

        return outer;
    }

    @override
    void update() {
        this.element?.style?.setProperty("--progress", progressFraction.toStringAsFixed(2));
    }
}