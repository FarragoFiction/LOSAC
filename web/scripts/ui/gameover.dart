import 'dart:html';

import 'ui.dart';

class GameOverBox extends UIComponent {
    final bool isWin;

    GameOverBox(UIController controller, bool this.isWin) : super(controller);

    @override
    Element createElement() {
        return new DivElement()
            ..className = "GameOver fullscreen"
            ..append(new DivElement()
                ..className = "uibackground"
                ..append(new HeadingElement.h1()
                    ..appendFormattedLocalisation(isWin ? "ui.gameover.victory.name" : "ui.gameover.defeat.name", engine.localisation)
                )
                ..append(new ParagraphElement()
                    ..appendFormattedLocalisation(isWin ? "ui.gameover.victory.description" : "ui.gameover.defeat.description", engine.localisation)
                )
                ..append(new ButtonElement()
                    ..appendFormattedLocalisation("ui.gameover.continue", engine.localisation)
                    ..onClick.first.then((MouseEvent e) {
                        this.dispose();
                        controller.addComponent(new ExitButton(controller));
                    })
                )
                ..append(new ButtonElement()
                    ..appendFormattedLocalisation("ui.gameover.exit", engine.localisation)
                    ..onClick.first.then((MouseEvent e) {
                        print("exit to menu");
                        // TODO: exit to menu here
                    })
                )
            )
        ;
    }

    @override
    void update() {}
}

class ExitButton extends UIComponent {
    ExitButton(UIController controller) : super(controller);

    @override
    Element createElement() {
        return new ButtonElement()
            ..className = "ExitButton"
            ..appendFormattedLocalisation("ui.gameover.exit", engine.localisation)
            ..onClick.first.then((MouseEvent e) {
                print("exit to menu");
                // TODO: exit to menu here
            })
        ;
    }

    @override
    void update() {}
}