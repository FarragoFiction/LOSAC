import "dart:html";

import "package:CubeLib/CubeLib.dart" as B;
import "package:js/js.dart" as JS;

import "../renderer/3d/renderer3d.dart";
import "engine.dart";

enum ModifierKeyState {
    /// Passes if the key is pressed or not
    any,
    /// Passes only if the key is pressed
    pressed,
    /// Passes only if the key is NOT pressed
    unpressed
}
enum KeyEventType {
    keyDown,
    keyUp
}

abstract class InputHandler {
    Engine engine;

    static const double dragDistance = 3;
    static const double dragDistanceSquared = dragDistance * dragDistance;

    final Map<String, String> codeToName = <String, String>{};
    //final Map<String, String> _nameToCode = <String, String>{};
    final Map<String, bool> keyStates = <String, bool>{};

    final Set<KeyPressCallbackHandler> keyCallbacks = <KeyPressCallbackHandler>{};

    final Map<int, bool> mouseStates = <int, bool>{};
    Point<num> mousePos;
    Point<num> mousePosPrev;
    int dragButton; // null means no button, only drag one at a time
    bool dragging = false;

    InputHandler(Engine this.engine);

    KeyCallbackToken listen(String key, KeyPressCallback callback, {bool allowRepeats = true, ModifierKeyState shift = ModifierKeyState.any, ModifierKeyState control = ModifierKeyState.unpressed, ModifierKeyState alt = ModifierKeyState.unpressed}) {
        final bool anyKey = key == null;
        final KeyPressCallbackHandler cb = new KeyPressCallbackHandler(callback, key: key, anyKey: anyKey, allowsRepeats: allowRepeats, shift: shift, control: control, alt: alt);
        this.keyCallbacks.add(cb);
        return new KeyCallbackToken(this, cb);
    }

    KeyCallbackToken listenMultiple(Iterable<String> keys, KeyPressCallback callback, {bool allowRepeats = true, ModifierKeyState shift = ModifierKeyState.any, ModifierKeyState control = ModifierKeyState.unpressed, ModifierKeyState alt = ModifierKeyState.unpressed}) {
        final bool anyKey = keys == null;
        final KeyPressCallbackHandler cb = new KeyPressCallbackHandler(callback, keys: keys, anyKey: anyKey, allowsRepeats: allowRepeats, shift: shift, control: control, alt: alt);
        this.keyCallbacks.add(cb);
        return new KeyCallbackToken(this, cb);
    }

    bool getKeyState(String code) {
        if (keyStates.containsKey(code)) {
            return keyStates[code];
        }
        return false;
    }

    bool getMouseState(int button) {
        if (mouseStates.containsKey(button)) {
            return mouseStates[button];
        }
        return false;
    }

    String _getKeyName(String code) {
        if (!codeToName.containsKey(code)) {
            if (code.startsWith("Key")) {
                final String key = code.substring(3,4);
                codeToName[code] = key;
                //_nameToCode[key] = code;
            } else if (code.startsWith("Digit")) {
                final String key = code.substring(5,6);
                codeToName[code] = key;
                //_nameToCode[key] = code;
                codeToName["Numpad$key"] = key;
            } else if (code.startsWith("Numpad")) {
                final String key = code.substring(6,7);
                codeToName[code] = key;
                //_nameToCode[key] = code;
                codeToName["Digit$key"] = key;
            } else {
                codeToName[code] = code;
                //_nameToCode[code] = code;
            }
        }
        return codeToName[code];
    }

    // #######################################################################################
    // Handlers
    // #######################################################################################

    void _onMouseDown(MouseEvent e) {
        mouseStates[e.button] = true;
        if (dragButton == null) {
            dragButton = e.button;
            mousePosPrev = e.page;
        }
        this.engine.renderer.onMouseDown(e);
    }
    void _onMouseUp(MouseEvent e) {
        //print("up ${e.button}");
        mouseStates[e.button] = false;
        if (dragging){
            //print("undrag $dragButton");
            dragging = false;
        } else {
            _click(e);
        }
        dragButton = null;
        this.engine.renderer.onMouseUp(e);
    }
    void _onMouseMove(MouseEvent e) {
        mousePosPrev ??= e.page;
        final Point<num> diff = e.page - mousePosPrev;

        mousePos = e.page;

        if (!dragging && dragButton != null && mouseStates[dragButton]) {
            final num len = diff.x * diff.x + diff.y * diff.y;

            if (len >= InputHandler.dragDistanceSquared) {
                //print("start drag $dragButton");
                dragging = true;
            }
        }

        if (dragging) {
            mousePosPrev = e.page;
            _drag(e, diff);
        }

        this.engine.renderer.onMouseMove(e);
    }
    void _onMouseWheel(WheelEvent e) {
        this.engine.renderer.onMouseWheel(e);
        e.preventDefault();
    }

    void _click(MouseEvent e) {
        this.engine.renderer.click(e.button, e);
    }
    void _drag(MouseEvent e, Point<num> offset) {
        this.engine.renderer.drag(dragButton, offset, e);
    }

    void _onKeyDown(KeyboardEvent e) {
        // exclude IME composition
        if (e.isComposing || e.keyCode == 229) { return; }

        final String code = _getKeyName(e.code);
        final bool repeat = getKeyState(code) == true;

        keyStates[code] = true;

        _processKeyEvent(e, repeat);
    }
    void _onKeyUp(KeyboardEvent e) {
        // exclude IME composition
        if (e.isComposing || e.keyCode == 229) { return; }

        final String code = _getKeyName(e.code);

        keyStates[code] = false;

        _processKeyEvent(e, false);
    }

    void _processKeyEvent(KeyboardEvent e, bool repeat) {
        KeyEventType type;
        if (e.type == "keydown") {
            type = KeyEventType.keyDown;
        } else if (e.type == "keyup") {
            type = KeyEventType.keyUp;
        } else {
            throw Exception("Somehow processing an incorrect key event?: ${e.type}");
        }

        final String key = _getKeyName(e.code).toLowerCase();

        bool preventDefault = false;

        for (final KeyPressCallbackHandler cbh in keyCallbacks) {
            if (repeat && !cbh.allowsRepeats) { continue; }
            if (!cbh.anyKey && !cbh.triggerKeys.contains(key)) { continue; }
            if (!(cbh.shift == ModifierKeyState.any || (e.shiftKey && cbh.shift == ModifierKeyState.pressed) || ((!e.shiftKey) && cbh.shift == ModifierKeyState.unpressed))) { continue; }
            if (!(cbh.control == ModifierKeyState.any || (e.ctrlKey && cbh.control == ModifierKeyState.pressed) || ((!e.ctrlKey) && cbh.control == ModifierKeyState.unpressed))) { continue; }
            if (!(cbh.alt == ModifierKeyState.any || (e.altKey && cbh.alt == ModifierKeyState.pressed) || ((!e.altKey) && cbh.alt == ModifierKeyState.unpressed))) { continue; }

            preventDefault = preventDefault || cbh.callback(key, type, e.shiftKey, e.ctrlKey, e.altKey);
            cbh.token.lastEvent = e;
        }

        if (preventDefault) {
            e.preventDefault();
        }
    }
}

/*class InputHandler2D extends InputHandler {
    InputHandler2D(Engine engine) : super(engine) {
        engine.container.onMouseDown.listen(_onMouseDown);
        window.onMouseUp.listen(_onMouseUp);
        window.onMouseMove.listen(_onMouseMove);
        engine.container.onMouseWheel.listen(_onMouseWheel);

        window.onKeyDown.listen(_onKeyDown);
        window.onKeyUp.listen(_onKeyUp);
    }
}*/

class InputHandler3D extends InputHandler {
    Renderer3D get renderer => this.engine.renderer;


    InputHandler3D(Engine engine) : super(engine) {
        renderer.scene.onKeyboardObservable.add(JS.allowInterop((B.KeyboardInfo info, B.EventState state) {
            if (info.type == B.KeyboardEventTypes.KEYDOWN) {
                this._onKeyDown(info.event);
            } else if (info.type == B.KeyboardEventTypes.KEYUP) {
                this._onKeyUp(info.event);
            }
        }));

        renderer.scene.onPointerObservable.add(JS.allowInterop((B.PointerInfo info, B.EventState state) {
            if (info.type == B.PointerEventTypes.POINTERDOWN) {
                this._onMouseDown(info.event);
            } else if (info.type == B.PointerEventTypes.POINTERUP) {
                this._onMouseUp(info.event);
            } else if (info.type == B.PointerEventTypes.POINTERMOVE) {
                this._onMouseMove(info.event);
            } else if (info.type == B.PointerEventTypes.POINTERWHEEL) {
                this._onMouseWheel(info.event);
            }
        }));
    }
}

typedef KeyPressCallback = bool Function(String key, KeyEventType type, bool shift, bool control, bool alt);

class KeyPressCallbackHandler {
    final ModifierKeyState shift;
    final ModifierKeyState control;
    final ModifierKeyState alt;

    final bool allowsRepeats;

    bool anyKey = false;
    final Set<String> triggerKeys = <String>{};
    final KeyPressCallback callback;

    KeyCallbackToken token;

    KeyPressCallbackHandler(KeyPressCallback this.callback, {String key, Iterable<String> keys, bool this.anyKey = false, bool this.allowsRepeats = true, ModifierKeyState this.shift = ModifierKeyState.any, ModifierKeyState this.control = ModifierKeyState.unpressed, ModifierKeyState this.alt = ModifierKeyState.unpressed}) {
        if (!anyKey) {
            if (key == null && keys == null) {
                throw ArgumentError("Invalid KeyPressCallback, must specify key or keys or have anyKey set true");
            }

            if (key != null) {
                triggerKeys.add(key.toLowerCase());
            } else {
                triggerKeys.addAll(keys.map((String s) => s.toLowerCase()));
            }
        }
    }
}

class KeyCallbackToken {
    final KeyPressCallbackHandler _callback;
    final InputHandler _handler;

    KeyEvent lastEvent;

    KeyCallbackToken(InputHandler this._handler, KeyPressCallbackHandler this._callback) {
        _callback.token = this;
    }

    void cancel() => _handler.keyCallbacks.remove(_callback);
}