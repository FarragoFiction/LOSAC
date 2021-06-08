import "dart:html";

import "package:LoaderLib/Archive.dart";

import "../../engine/engine.dart";
import "../../main.dart";
import "../../utility/extensions.dart";
import "mainmenu.dart";

class GameMenuState extends MenuState {
    Engine? engine;
    Archive? archiveToLoad;

    @override
    String get name => "Game";

    @override
    Future<void> enterState() async {
        MainMenu.menuElement.hide();

        if (archiveToLoad == null) {
            throw Exception("Level archive not set, aborting");
        }

        engine = await GameInit.losac(archiveToLoad!);

        archiveToLoad = null;
    }

    @override
    Future<void> exitState() async {
        MainMenu.menuElement.show();

        // do cleanup and drop the reference
        engine?.destroy();
        engine = null;
        archiveToLoad = null;

        // rebuild the canvasses, freeing babylon
        final Element container = querySelector("#container")!;
        final Element newContainer = container.clone(true) as Element;
        container.replaceWith(newContainer);
    }
}