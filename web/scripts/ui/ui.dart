import "dart:html";

import "../engine/engine.dart";
import '../localisation/localisation.dart';
import 'tooltip.dart';

export '../localisation/formatting.dart';
export "button.dart";
export "buttongrid.dart";
export "progressbar.dart";
export "resourcelist.dart";
export "selectionwindow.dart";
export "tooltip.dart";
export "wavetracker.dart";

class UIController {
    final Engine engine;
    final Element container;

    final Set<UIComponent> components = <UIComponent>{};

    TooltipComponent tooltip;

    UIController(Engine this.engine, Element this.container);

    void update() {
        for (final UIComponent comp in components) {
            comp.updateAndPropagate();
        }
    }

    void resize() {
        for (final UIComponent comp in components) {
            comp.resizeAndPropagate();
        }
    }

    UIComponent addComponent(UIComponent component) {
        this.components.add(component);
        this.container.append(component.element);
        component.resizeAndPropagate();
        return component;
    }

    String localise(String key, {Map<String,String> data}) => engine.localisation.translate(key, data:data);
    LocalisationEngine get localisation => engine.localisation;

    UIComponent queryComponentAtCoords(Point<num> coords, [bool Function(UIComponent c) test]) {
        for (final UIComponent component in components) {
            if (component.hasElement) {
                final UIComponent picked = component.queryComponentAtCoords(coords, test);
                if (picked != null) {
                    return picked;
                }
            }
        }
        return null;
    }
}

abstract class UIComponent {
    final UIController controller;
    Element _element;

    bool disposed = false;

    Element get element {
        if (_element == null && !disposed) {
            this._element = this.createElementAndPropagate();

        }
        return this._element;
    }

    bool get hasElement => _element != null;

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

    void resizeAndPropagate() {
        if (this.element != null) {
            this.resize();
        }
        for (final UIComponent child in children) {
            child.resizeAndPropagate();
        }
    }

    Element getChildContainer() => _element;

    void resize() {}

    Element createElementAndPropagate() {
        final Element element = this.createElement();
        _element = element;

        final Element childContainer = getChildContainer();
        for (final UIComponent child in children) {
            childContainer.append(child.element);
        }
        return element;
    }

    Element createElement();

    UIComponent addChild(UIComponent component) {
        this.children.add(component);
        component.parent = this;
        if (this._element != null) {
            getChildContainer().append(component.element);
            this.resizeAndPropagate();
        }
        return component;
    }

    void removeChild(UIComponent component) {
        this.children.remove(component);
        component.element?.remove();
        component.parent = null;
    }

    String localise(String key, {Map<String,String> data}) => controller.localise(key, data:data);

    UIComponent queryComponentAtCoords(Point<num> coords, [bool Function(UIComponent c) test]) {
        if(disposed) { return null; }
        for (final UIComponent child in children) {
            if (child.hasElement) {
                final UIComponent picked = child.queryComponentAtCoords(coords, test);
                if (picked != null) {
                    return picked;
                }
            }
        }
        if (this.element.getBoundingClientRect().containsPoint(coords) && ((test == null) || test(this))) {
            return this;
        }
        return null;
    }

    void dispose() {
        this.disposed = true;
        this.element.remove();
        for (final UIComponent child in children) {
            child.dispose();
        }
    }
}