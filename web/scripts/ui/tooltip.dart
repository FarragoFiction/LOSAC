import 'dart:async';
import "dart:html";

import "../renderer/3d/renderer3d.dart";
import "../utility/extensions.dart";
import 'ui.dart';

class TooltipComponent extends UIComponent {
    static const int updateSteps = 20;
    static const int paddingDistance = 4;
    static const int mouseSize = 16;
    int updateStep = 0;
    Point<num> mousePos = const Point<num>(0,0);

    HasTooltip? currentObject;
    Element? contentElement;

    TooltipComponent(UIController controller) : super(controller);
    late StreamSubscription<MouseEvent> _mouseMoveHandler;
    late StreamSubscription<MouseEvent> _mouseClickHandler;
    late StreamSubscription<MouseEvent> _mouseOutHandler;

    @override
    Element createElement() {
        _mouseMoveHandler = window.onMouseMove.listen(onMouseEvents);
        _mouseClickHandler = window.onClick.listen(onMouseEvents);
        _mouseOutHandler = window.onMouseOut.listen(onMouseOut);

        final Element outer = new DivElement()
            ..className = "Tooltip hidden"
        ;

        final Element inner = new DivElement()
            ..className = "TooltipInner uibackground"
        ;
        outer.append(inner);
        contentElement = inner;

        return outer;
    }

    @override
    void update() {
        if (!this.hasElement) { return; }
        if (updateStep < updateSteps) {
            updateStep++;
            return;
        }
        updateStep = 0;

        final bool updatedObject = updateTooltipObject();
        if (!updatedObject) {
            updateTooltipContents();
        }
    }

    bool updateTooltipObject() {
        if (currentObject != null && currentObject!.disposed) {
            currentObject = null;
        }

        if (engine.input.mousePos == null) { return false; }

        final Point<num> pos = mousePos; //engine.input.mousePos!;

        if (pos.x < 0 || pos.x >= window.innerWidth! || pos.y < 0 || pos.y >= window.innerHeight!) {
            currentObject = null;
            return true;
        }

        final UIComponent? comp = controller.queryComponentAtCoords(pos, (UIComponent c) => c is HasTooltip);
        final HasTooltip? object = comp == null ? null : comp as HasTooltip;

        if (currentObject != object) {
            currentObject = object;
            updateTooltipContents();
            return true;
        }

        return false;
    }

    void updateTooltipContents() {
        if (currentObject == null) {
            element!.classes.add("hidden");
        } else {
            this.contentElement!.children.clear();
            currentObject!.populateTooltip(this.contentElement!);
            element!.classes.remove("hidden");

            updateTooltipPosition();
        }
    }

    void updateTooltipPosition() {
        if (!this.hasElement || this.currentObject == null) { return; }

        final int width = this.element!.offsetWidth;
        final int height = this.element!.offsetHeight;

        final Point<num>? mousePos = this.mousePos; //engine.input.mousePos;
        if (mousePos == null) { return; }
        final int windowWidth = window.innerWidth!;
        final int windowHeight = window.innerHeight!;

        final num spaceLeft = mousePos.x - paddingDistance;
        final num spaceRight = windowWidth - mousePos.x - paddingDistance - mouseSize;

        final num spaceTop = mousePos.y - paddingDistance;
        final num spaceBottom = windowHeight - mousePos.y - paddingDistance - mouseSize;

        final bool enoughRight = spaceRight >= width;
        final bool enoughLeft = spaceLeft >= width;
        final bool enoughTop = spaceTop >= height;
        final bool enoughBottom = spaceBottom >= height;

        num x,y;

        if (enoughRight) {
            x = mousePos.x + paddingDistance + mouseSize;
        } else if (enoughLeft) {
            x = mousePos.x - paddingDistance - width;
        } else {
            x = 0;
            print("temp x fallback");
        }

        if (enoughBottom) {
            y = mousePos.y + paddingDistance + mouseSize;
        } else if (enoughTop) {
            y = mousePos.y - paddingDistance - height;
        } else {
            y = 0;
            print("temp y fallback");
        }

        element!.style
            ..setProperty("--x", x.toInt().toString())
            ..setProperty("--y", y.toInt().toString());
    }

    void onMouseEvents(MouseEvent e) {
        print("tooltip mouse event");
        mousePos = e.page;
        updateTooltipObject();
        updateTooltipPosition();
    }
    void onMouseOut(MouseEvent e) {
        this.currentObject = null;
        updateTooltipContents();
    }

    @override
    void resize() {
        updateTooltipPosition();
    }

    @override
    void dispose() {
        super.dispose();
        _mouseMoveHandler.cancel();
        _mouseClickHandler.cancel();
        _mouseOutHandler.cancel();
    }
}

mixin HasTooltip on UIComponent {
    Future<void> populateTooltip(Element tooltip);
}