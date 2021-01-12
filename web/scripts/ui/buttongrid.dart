import 'dart:async';
import "dart:html";

import "../utility/extensions.dart";
import 'ui.dart';

class ButtonGrid extends UIComponent {

    _ButtonGridInner buttonContainer;
    Element scrollLeft;
    Element scrollRight;

    int scrollStep = 0;

    Set<UIButton> buttons = <UIButton>{};

    StreamSubscription<MouseEvent> _scrollLeftClick;
    StreamSubscription<MouseEvent> _scrollRightClick;

    ButtonGrid(UIController controller) : super(controller) {
        this.buttonContainer = this.addChild(new _ButtonGridInner(controller));
    }

    @override
    Element createElement() {
        final Element outer = new DivElement()
            ..className = "ButtonGrid"
        ;

        this.scrollLeft = new DivElement()..className = "ButtonGridScroll left";
        _scrollLeftClick = scrollLeft.onClick.listen((Event e) {
            this
                ..scrollStep -= 1
                ..updateScrolling();
        });
        outer.append(scrollLeft);

        outer.append(buttonContainer.element);

        this.scrollRight = new DivElement()..className = "ButtonGridScroll right";
        _scrollRightClick = scrollRight.onClick.listen((Event e) {
                this
                    ..scrollStep += 1
                    ..updateScrolling();
            })
        ;
        outer.append(scrollRight);

        /*for (int i=0; i<20; i++) {
            this.addButton(new UIButton(controller));
        }*/

        return outer;
    }

    void addButton(UIButton button) {
        this.buttons.add(button);
        buttonContainer.addChild(button);
    }

    @override
    void update() {}

    @override
    void resize() {
        final int thisWidth = element.offsetWidth;
        final int containerWidth = buttonContainer.element.offsetWidth;

        if (containerWidth > thisWidth) {
            // there isn't enough space, show the scroll buttons
            // also make the background solid so there's not a hole at the end

            element.classes.add("background");
            scrollLeft.classes.remove("hidden");
            scrollRight.classes.remove("hidden");
        } else {
            // there is enough space, hide the scroll buttons
            // clear the background again so it doesn't cover the whole screen

            element.classes.remove("background");
            scrollLeft.classes.add("hidden");
            scrollRight.classes.add("hidden");
        }

        updateScrolling();
    }

    void updateScrolling() {
        if (buttonContainer.children.isEmpty) { return; }

        final int outerWidth = element.totalWidth;
        final int innerWidth = buttonContainer.element.totalWidth;
        final int buttonWidth = buttonContainer.children.first.element.totalWidth;

        final int scrollButtonWidth = this.scrollLeft.totalWidth;

        final int xButtons = innerWidth ~/ buttonWidth;
        final int fitButtons = (outerWidth - scrollButtonWidth*2) ~/ buttonWidth;

        final int maxScroll = xButtons - fitButtons;

        this.scrollStep = scrollStep.clamp(0, maxScroll);

        if (scrollStep == 0) {
            scrollLeft.classes.add("disabled");
        } else {
            scrollLeft.classes.remove("disabled");
        }

        if (scrollStep == maxScroll) {
            scrollRight.classes.add("disabled");
        } else {
            scrollRight.classes.remove("disabled");
        }

        int offset = 0;
        if (maxScroll > 0) {
            offset = scrollStep * buttonWidth - scrollButtonWidth;
        }

        this.buttonContainer.element.style.setProperty("--scroll", "${-offset}px");
    }

    @override
    void dispose() {
        super.dispose();
        _scrollLeftClick.cancel();
        _scrollRightClick.cancel();
    }
}

class _ButtonGridInner extends UIComponent {

    _ButtonGridInner(UIController controller) : super(controller);

    @override
    Element createElement() {
        return new DivElement()
            ..className = "ButtonGridInner"
        ;
    }

    @override
    void update() {}

    @override
    void resize() {
        if (this.children.isEmpty) { return; }

        final int height = this.element.totalHeight;
        final int buttonHeight = this.children.first.element.totalHeight;

        if (buttonHeight == 0) { return; }

        final int rows = height ~/ buttonHeight;
        final int columns = (this.children.length / rows).ceil();

        element.style.setProperty("--columns", columns.toString());

        this?.parent?.resize();
    }

}