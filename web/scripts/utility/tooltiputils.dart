import "dart:html";

import "../ui/ui.dart";

abstract class TooltipUtils {

    static void appendFormattedText(Element element, String text) {
        final List<String> sections = text.split("\n");

        for (final String section in sections) {
            if (section != sections.first) { element.append(new BRElement()); }

            element.appendText(section);
        }
    }
}

extension TooltipAppend on Element {

    void appendFormattedText(String text) {
        TooltipUtils.appendFormattedText(this, text);
    }

    void appendFormattedLocalisation(String key, UIController controller) {
        //this.appendFormattedText("Here is some test text.\\n\\nIt has line breaks in it.");

        this.appendFormattedText(controller.localise(key));
    }
}