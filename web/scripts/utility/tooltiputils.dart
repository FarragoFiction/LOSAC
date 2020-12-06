import "dart:collection";
import "dart:html";

import "../localisation/localisation.dart";

abstract class TooltipUtils {

    static void appendFormattedText(Element element, String text, LocalisationEngine localisationEngine, {Map<String,String> data}) {
        final List<String> paragraphs = text.split("\n");

        for (final String paragraph in paragraphs) {
            if (paragraph != paragraphs.first) {
                element.append(new BRElement());
            }
            _processParagraph(element, paragraph, localisationEngine, data:data);
        }
    }

    static void _processParagraph(Element element, String paragraph, LocalisationEngine localisationEngine, {Map<String,String> data}) {
        final int symbolAt = "@".codeUnitAt(0);
        final int symbolOpenBracket = "[".codeUnitAt(0);
        final int symbolCloseBracket = "]".codeUnitAt(0);

        //print("Process paragraph: $paragraph");

        int position = 0;
        int depth = 0;
        int stylePos = 0;
        String style;
        for (int i = 0; i < paragraph.length; i++) {
            // current symbol is @
            if (paragraph.codeUnits[i] == symbolAt) {
                // end of string or next symbol is not [, so we are exiting a block
                if (((i == paragraph.length-1) || (paragraph.codeUnits[i+1] != symbolOpenBracket))) {
                    depth--;

                    if (depth == 0) {
                        //print("close at: ${paragraph.substring(i)}");
                        // create a span element with the current style and process the contained section inside into it recursively
                        final Element span = new SpanElement()
                            ..className = style;
                        _processParagraph(span, paragraph.substring(position, i), localisationEngine, data:data);
                        element.append(span);

                        position = i + 1;
                    }
                } else { // next symbol is [, so we are entering a block
                    depth++;

                    if (depth == 1) {
                        //print("open at: ${paragraph.substring(i)}");
                        style = null;

                        // just process the previous section straight into the element as it's outside a style
                        _processSection(element, paragraph.substring(position, i), localisationEngine, data:data);

                        stylePos = i + 2;
                    }
                }
            } else if(depth==1 && paragraph.codeUnits[i] == symbolCloseBracket) {
                style = paragraph.substring(stylePos,i);
                position = i+1;
            }

        }
        if (position < paragraph.length) {
            //sections.add(paragraph.substring(position));
            _processSection(element, paragraph.substring(position), localisationEngine, data:data);
        }

    }

    static void _processSection(Element element, String section, LocalisationEngine localisationEngine, {Map<String,String> data}) {
        //print("Process section: $section");

        int position = 0;
        for (final Match match in LocalisationEngine.replacementPattern.allMatches(section)) {
            final String before = section.substring(position, match.start);
            if (!before.isEmpty) {
                element.appendText(before);
            }

            final String result = localisationEngine.translate(match.group(1), data:data);

            if (match.group(3) == null) {
                appendFormattedText(element, result, localisationEngine, data:data);
            } else {
                final Element span = new SpanElement()
                    ..className = match.group(3);

                appendFormattedText(span, result, localisationEngine, data:data);

                element.append(span);
            }

            position = match.end;
        }

        if (position < section.length) {
            element.appendText(section.substring(position));
        }
    }
}

extension TooltipAppend on Element {

    void appendFormattedText(String text, LocalisationEngine localisationEngine, {Map<String,String> data}) {
        TooltipUtils.appendFormattedText(this, text, localisationEngine, data:data);
    }

    void appendFormattedLocalisation(String key, LocalisationEngine localisationEngine, {Map<String,String> data}) {
        //this.appendFormattedText("Here is some test text.\\n\\nIt has line breaks in it.");

        this.appendFormattedText(localisationEngine.translate(key), localisationEngine, data:data);
    }
}

// ignore: prefer_mixin
abstract class DataSurrogate<T> with MapMixin<String,String> {
    T owner;

    @override
    String operator [](Object key);
    @override
    Iterable<String> get keys;

    @override
    void operator []=(Object key, Object value) => throw UnimplementedError();
    @override
    void clear() => throw UnimplementedError();
    @override
    String remove(Object key) => throw UnimplementedError();
}