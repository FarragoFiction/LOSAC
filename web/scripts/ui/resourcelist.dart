
import 'dart:html';

import "../engine/game.dart";
import "../resources/resourcetype.dart";
import "ui.dart";

class ResourceList extends UIComponent {

    ResourceList(UIController controller) : super(controller) {
        final Game game = engine;

        for (final ResourceType type in game.resourceTypeRegistry.mapping.values) {
            this.addChild(new ResourceDisplay(controller, type));
        }
    }

    @override
    Element createElement() {
        return new DivElement()..className="ResourceListWindow";
    }

    @override
    void update() {}

}

class ResourceDisplay extends UIComponent with HasTooltip {
    ResourceType resource;
    
    Element resourceCounter;

    ResourceDisplay(UIController controller, ResourceType this.resource) : super(controller);

    @override
    Element createElement() {
        final Game game = engine;

        final Element div = new DivElement()
            ..className = "ResourceDisplay uibackground"
        ;

        final String name = resource.getRegistrationKey();

        final Element resourceIcon = new DivElement()
            ..className="ResourceIcon"
            ..style.setProperty("--icon", 'url("${controller.localisation.formatting.getIconPath("resource.$name")}")')
        ;
        div.append(resourceIcon);

        this.resourceCounter = new DivElement()
            ..className="ResourceCounter"
            ..text = game.resourceStockpile[resource].round().toString()
        ;
        div.append(resourceCounter);

        return div;
    }

    @override
    void update() {
        final Game game = engine;
        this.resourceCounter?.text = game.resourceStockpile[resource].floor().toString();
    }

    @override
    Future<void> populateTooltip(Element tooltip) async {
        tooltip.append(new HeadingElement.h1()..appendFormattedLocalisation("resource.${resource.getRegistrationKey()}.name", engine.localisation));

        tooltip.appendFormattedLocalisation("resource.${resource.getRegistrationKey()}.description", engine.localisation);
    }
}