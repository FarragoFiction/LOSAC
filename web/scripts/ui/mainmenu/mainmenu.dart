import "dart:html";

import "package:CommonLib/Logging.dart";

import "../../utility/extensions.dart";
import "mainmenu.dart";

export "gamestate.dart";
export "levelselectstate.dart";
export "mainmenustate.dart";

abstract class MainMenu {
    static Logger logger = new Logger("Menu System", false);
    static bool _lock = false;

    // states
    static final GameMenuState game = new GameMenuState();
    static final MenuState mainMenu = new MainMenuState();
    static final MenuState levelSelect = new LevelSelectState();

    // global elements
    static final Element menuElement = querySelector("#menu")!;
    static final Element loadingElement = querySelector("#loadscreen")!;

    // current working state
    static MenuState? currentState;

    static Future<void> init() async {
        await changeState(mainMenu);
    }

    static Future<void> changeState(MenuState state) async {
        if (currentState == state) { logger.warn("Attempting to switch state to $currentState, which is already the current state"); return; }
        if (_lock) { throw Exception("Menu state change already in progress!"); }

        logger.debug("Switching state from ${currentState ?? "no state"} to $state");

        _lock = true;
        loadingElement.show();
        await currentState?.exitState();
        await state.enterState();
        currentState = state;
        loadingElement.hide();
        _lock = false;
    }
}

typedef MenuAction = Future<void> Function();

abstract class MenuState {
    String get name;

    Future<void> enterState() async {}
    Future<void> exitState() async {}

    @override
    String toString() => name;

    bool get active => MainMenu.currentState == this;
}

