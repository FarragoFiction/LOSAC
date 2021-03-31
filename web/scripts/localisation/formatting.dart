import "dart:collection";
import "dart:html";

import "package:LoaderLib/Loader.dart";

import 'localisation.dart';

class FormattingEngine {
    static const String _defaultIconPath = "assets/icons/default.png";

    final LocalisationEngine _locEngine;
    final Map<String,String?> _iconPaths = <String,String?>{};
    final Map<String,ImageElement> _iconImages = <String,ImageElement>{};

    FormattingEngine(LocalisationEngine this._locEngine);

    Future<void> initialise() async {
        await registerIcon("default", _defaultIconPath);
    }

    void appendFormattedText(Element element, String text, {Map<String,String>? data}) {
        final List<String> paragraphs = text.split("\n");

        for (final String paragraph in paragraphs) {
            if (paragraph != paragraphs.first) {
                element.append(new BRElement());
            }
            _processParagraph(element, paragraph, data:data);
        }
    }

    void _processParagraph(Element element, String paragraph, {Map<String,String>? data}) {
        final int symbolAt = "@".codeUnitAt(0);
        final int symbolOpenBracket = "[".codeUnitAt(0);
        final int symbolCloseBracket = "]".codeUnitAt(0);

        //print("Process paragraph: $paragraph");

        int position = 0;
        int depth = 0;
        int stylePos = 0;
        String? style;
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
                            ..className = style ?? "";
                        _processParagraph(span, paragraph.substring(position, i), data:data);
                        element.append(span);

                        position = i + 1;
                    }
                } else { // next symbol is [, so we are entering a block
                    depth++;

                    if (depth == 1) {
                        //print("open at: ${paragraph.substring(i)}");
                        style = null;

                        // just process the previous section straight into the element as it's outside a style
                        //_processSection(element, paragraph.substring(position, i), data:data);
                        _processIconsInText(element, paragraph.substring(position, i), data:data);

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
            //_processSection(element, paragraph.substring(position), data:data);
            _processIconsInText(element, paragraph.substring(position), data:data);
        }

    }

    void _processSection(Element element, String section, {Map<String,String>? data}) {
        //print("Process section: $section");

        int position = 0;
        for (final Match match in LocalisationEngine.replacementPattern.allMatches(section)) {
            final String before = section.substring(position, match.start);
            if (!before.isEmpty) {
                //_processIconsInText(element, before, data:data);
                element.appendText(before);
            }

            final String result = _locEngine.translate(match.group(1)!, data:data);

            if (match.group(3) == null) {
                appendFormattedText(element, result, data:data);
            } else {
                final Element span = new SpanElement()
                    ..className = match.group(3)!;

                appendFormattedText(span, result, data:data);

                element.append(span);
            }

            position = match.end;
        }

        if (position < section.length) {
            element.appendText(section.substring(position));
            //_processIconsInText(element, section.substring(position), data:data);
        }
    }

    void _processIconsInText(Element element, String input, {Map<String,String>? data}) {
        int position = 0;
        for (final Match iconMatch in LocalisationEngine.iconPattern.allMatches(input)) {
            final String textBefore = input.substring(position, iconMatch.start);
            if (!textBefore.isEmpty) {
               // element.appendText(textBefore);
                _processSection(element, textBefore, data:data);
            }

            final String iconKey = iconMatch.group(1)!;

            if (LocalisationEngine.replacementPattern.hasMatch(iconKey)) {
                String text = iconKey.substring(1, iconKey.length-1);

                if (data != null && data.containsKey(text)) {
                    text = data[text]!;
                }

                appendIcon(element, text);
            } else {
                appendIcon(element, iconMatch.group(1)!);
            }

            position = iconMatch.end;
        }

        if (position < input.length) {
            //element.appendText(input.substring(position));
            _processSection(element, input.substring(position), data:data);
        }
    }

    Future<void> registerIcon(String name, String path) async {
        if (_iconPaths.containsKey(name)) {
            window.console.warn("Duplicate icon registry name: $name");
            return;
        }

        // reserve the space
        _iconPaths[name] = null;

        ImageElement icon;

        try {
            icon = await Loader.getResource(path, format: Formats.png, forceCanonical: true);
        } on LoaderException {
            window.console.warn("Missing icon: $name at $path");
            return;
        }

        _iconPaths[name] = icon.src;
    }

    String getIconPath(String? name) {
        name ??= "default";
        if (!_iconPaths.containsKey(name)) {
            name = "default";
        }

        return _iconPaths[name] ?? _iconPaths["default"]!;
    }

    void appendIcon(Element element, String name) {
        final String path = getIconPath(name);

        final Element iconContainer = new DivElement()
            ..className="TooltipIcon"
            ..style.setProperty("--icon", 'url("$path")')
        ;
        element.append(iconContainer);
    }

    /// Gets the image for the icon if it's loaded, otherwise requests it and returns null
    ImageElement? getIconMaybe(String name) {

        if (_iconImages.containsKey(name)) {
            return _iconImages[name];
        }
        final String path = this.getIconPath(name);
        Loader.getResource(path, format: Formats.png, forceCanonical: true).then((ImageElement icon) {
            _iconImages[name] = icon;
        });

        return null;
    }
}

extension TooltipAppend on Element {

    void appendFormattedText(String text, LocalisationEngine localisationEngine, {Map<String,String>? data}) {
        localisationEngine.formatting.appendFormattedText(this, text, data:data);
    }

    void appendFormattedLocalisation(String key, LocalisationEngine localisationEngine, {Map<String,String>? data}) {
        //this.appendFormattedText("Here is some test text.\\n\\nIt has line breaks in it.");

        this.appendFormattedText(localisationEngine.translate(key), localisationEngine, data:data);
    }
}

// ignore: prefer_mixin
abstract class DataSurrogate<T> with MapMixin<String,String> {
    late T owner;

    @override
    String? operator [](Object? key);
    @override
    Iterable<String> get keys;

    @override
    void operator []=(Object key, Object value) => throw UnimplementedError();
    @override
    void clear() => throw UnimplementedError();
    @override
    String? remove(Object? key) => throw UnimplementedError();
}