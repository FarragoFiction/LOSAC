
import 'dart:html';

import "../engine/game.dart";
import "ui.dart";

class LifeDisplay extends UIComponent with HasTooltip {

    Game get game => engine as Game;
    late Element bar;
    late Element caption;

    LifeDisplay(UIController controller) : super(controller);

    @override
    Element createElement() {
        final Element element = new DivElement()..className="LifeDisplay uibackground";

        final Element outer = new DivElement()
            ..className = "ProgressBar";

        final Element ghost = new DivElement()
            ..className = "ProgressBarGhost";
        outer.append(ghost);

        final Element inner = new DivElement()
            ..className = "ProgressBarInner";
        outer.append(inner);

        final Element text = new DivElement()
            ..className = "text";

        element.append(outer);
        element.append(text);
        bar = outer;
        caption = text;

        return element;
    }

    @override
    void update() {
        final double fraction = game.currentLife / game.maxLife;
        this.bar.style.setProperty("--progress", fraction.toStringAsFixed(2));
        this.caption.text = game.currentLife.floor().toString();
    }

    @override
    Future<void> populateTooltip(Element tooltip) async {
        tooltip.append(new HeadingElement.h1()..appendFormattedLocalisation("ui.life.name", engine.localisation));
        tooltip.appendFormattedLocalisation("ui.life.description", engine.localisation);
    }
}