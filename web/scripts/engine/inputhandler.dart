import "dart:collection";
import "dart:html";

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

class InputHandler {

    final Map<String, String> _codeToName = <String, String>{};
    //final Map<String, String> _nameToCode = <String, String>{};
    final Map<String, bool> _keyStates = <String, bool>{};

    final Set<_KeyPressCallbackHandler> _keyCallbacks = <_KeyPressCallbackHandler>{};

    InputHandler(Engine engine) {
        engine.container.onMouseDown.listen(_onMouseDown);
        window.onMouseDown.listen(_onMouseUp);
        window.onMouseMove.listen(_onMouseMove);
        engine.container.onMouseWheel.listen(_onMouseWheel);

        window.onKeyDown.listen(_onKeyDown);
        window.onKeyUp.listen(_onKeyUp);
    }


    KeyCallbackToken listen(String key, KeyPressCallback callback, {bool allowRepeats = true, ModifierKeyState shift = ModifierKeyState.any, ModifierKeyState control = ModifierKeyState.unpressed, ModifierKeyState alt = ModifierKeyState.unpressed}) {
        final bool anyKey = key == null;
        final _KeyPressCallbackHandler cb = new _KeyPressCallbackHandler(callback, key: key, anyKey: anyKey, allowsRepeats: allowRepeats, shift: shift, control: control, alt: alt);
        this._keyCallbacks.add(cb);
        return new KeyCallbackToken(this, cb);
    }

    KeyCallbackToken listenMultiple(Iterable<String> keys, KeyPressCallback callback, {bool allowRepeats = true, ModifierKeyState shift = ModifierKeyState.any, ModifierKeyState control = ModifierKeyState.unpressed, ModifierKeyState alt = ModifierKeyState.unpressed}) {
        final bool anyKey = keys == null;
        final _KeyPressCallbackHandler cb = new _KeyPressCallbackHandler(callback, keys: keys, anyKey: anyKey, allowsRepeats: allowRepeats, shift: shift, control: control, alt: alt);
        this._keyCallbacks.add(cb);
        return new KeyCallbackToken(this, cb);
    }

    bool getKeyState(String code) {
        if (_keyStates.containsKey(code)) {
            return _keyStates[code];
        }
        return false;
    }

    String _getKeyName(String code) {
        if (!_codeToName.containsKey(code)) {
            if (code.startsWith("Key")) {
                final String key = code.substring(3,4);
                _codeToName[code] = key;
                //_nameToCode[key] = code;
            } else if (code.startsWith("Digit")) {
                final String key = code.substring(5,6);
                _codeToName[code] = key;
                //_nameToCode[key] = code;
                _codeToName["Numpad$key"] = key;
            } else if (code.startsWith("Numpad")) {
                final String key = code.substring(6,7);
                _codeToName[code] = key;
                //_nameToCode[key] = code;
                _codeToName["Digit$key"] = key;
            } else {
                _codeToName[code] = code;
                //_nameToCode[code] = code;
            }
        }
        return _codeToName[code];
    }
    
    // #######################################################################################
    // Handlers
    // #######################################################################################

    void _onMouseDown(MouseEvent e) {}
    void _onMouseUp(MouseEvent e) {}
    void _onMouseMove(MouseEvent e) {}
    void _onMouseWheel(WheelEvent e) {}

    void _onKeyDown(KeyboardEvent e) {
        // exclude IME composition
        if (e.isComposing || e.keyCode == 229) { return; }

        final String code = _getKeyName(e.code);
        final bool repeat = getKeyState(code) == true;

        _keyStates[code] = true;

        _processKeyEvent(e, repeat);
    }
    void _onKeyUp(KeyboardEvent e) {
        // exclude IME composition
        if (e.isComposing || e.keyCode == 229) { return; }

        final String code = _getKeyName(e.code);

        _keyStates[code] = false;

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

        for (final _KeyPressCallbackHandler cbh in _keyCallbacks) {
            if (repeat && !cbh.allowsRepeats) { continue; }
            if (!cbh.anyKey && !cbh.triggerKeys.contains(key)) { continue; }
            if (!(cbh.shift == ModifierKeyState.any || (e.shiftKey && cbh.shift == ModifierKeyState.pressed) || ((!e.shiftKey) && cbh.shift == ModifierKeyState.unpressed))) { continue; }
            if (!(cbh.control == ModifierKeyState.any || (e.ctrlKey && cbh.control == ModifierKeyState.pressed) || ((!e.ctrlKey) && cbh.control == ModifierKeyState.unpressed))) { continue; }
            if (!(cbh.alt == ModifierKeyState.any || (e.altKey && cbh.alt == ModifierKeyState.pressed) || ((!e.altKey) && cbh.alt == ModifierKeyState.unpressed))) { continue; }

            cbh.callback(key, type, e.shiftKey, e.ctrlKey, e.altKey);
        }
    }
}

typedef KeyPressCallback = void Function(String key, KeyEventType type, bool shift, bool control, bool alt);

class _KeyPressCallbackHandler {
    final ModifierKeyState shift;
    final ModifierKeyState control;
    final ModifierKeyState alt;

    final bool allowsRepeats;

    bool anyKey = false;
    final Set<String> triggerKeys = <String>{};
    final KeyPressCallback callback;

    _KeyPressCallbackHandler(KeyPressCallback this.callback, {String key, Iterable<String> keys, bool this.anyKey = false, bool this.allowsRepeats = true, ModifierKeyState this.shift = ModifierKeyState.any, ModifierKeyState this.control = ModifierKeyState.unpressed, ModifierKeyState this.alt = ModifierKeyState.unpressed}) {
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
    final _KeyPressCallbackHandler _callback;
    final InputHandler _handler;

    KeyCallbackToken(InputHandler this._handler, _KeyPressCallbackHandler this._callback);

    void cancel() => _handler._keyCallbacks.remove(_callback);
}