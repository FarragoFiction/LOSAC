import "dart:html";

import "mainmenu.dart";

class MainMenuState extends MenuState {
    static final Element startGame = querySelector("#newgame")!;

    @override
    String get name => "Main Menu";

    MainMenuState() {
        startGame.onClick.listen((MouseEvent e) async {
            if(!active) { return; }

            MainMenu.changeState(MainMenu.levelSelect);
        });
    }
}