import "dart:html";

import "../engine/engine.dart";

class UIController {
    final Engine engine;
    final Element container;

    final Set<UIComponent> components = <UIComponent>{};

    UIController(Engine this.engine, Element this.container);

    void update() {
        for (final UIComponent comp in components) {
            comp.updateAndPropagate();
        }
    }

    UIComponent addComponent(UIComponent component) {
        this.components.add(component);
        this.container.append(component.element);
        return component;
    }
}

abstract class UIComponent {
    final UIController controller;
    Element _element;

    Element get element {
        if (_element == null) {
            this._element = this.createElementAndPropagate();
        }
        return this._element;
    }

    UIComponent parent;
    final Set<UIComponent> children = <UIComponent>{};

    Engine get engine => this.controller.engine;

    UIComponent(UIController this.controller);

    void updateAndPropagate() {
        this.update();
        for (final UIComponent child in children) {
            child.updateAndPropagate();
        }
    }

    void update();

    Element createElementAndPropagate() {
        final Element element = this.createElement();
        for (final UIComponent child in children) {
            element.append(child.element);
        }
        return element;
    }

    Element createElement();

    void addChild(UIComponent component) {
        this.children.add(component);
        component.parent = this;
        this._element?.append(component.element);
    }

    void removeChild(UIComponent component) {
        this.children.remove(component);
        component.element?.remove();
        component.parent = null;
    }
}