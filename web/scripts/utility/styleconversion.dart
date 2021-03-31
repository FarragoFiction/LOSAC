import "dart:html";

class CanvasStyle {
    static final RegExp _lengthPattern = new RegExp(r"([\d.]+)([a-zA-Z%]+)");
    static final RegExp _shadowPattern = new RegExp(r"((rgba?\(\d+,\s*\d+,\s*\d+(,\s*\d+)?\))|([\d.]+)([a-zA-Z%]+))");

    final CssStyleDeclaration css;

    // text ------------------------------
    bool computedText = false;
    late String textFont;
    late String textColour;
    late String textAlign;
    late String textShadowColour;
    late num textLineHeight;
    late num textShadowX;
    late num textShadowY;
    late num textShadowBlur;

    // -----------------------------------

    CanvasStyle(CssStyleDeclaration this.css);

    void computeTextStyle() {
        if (computedText) { return; }
        computedText = true;

        textFont = css.font;
        textColour = css.color;
        textAlign = css.textAlign;
        textLineHeight = cssLengthToPixels(css.fontSize, compareHeight: true) ?? 10; // arbitrary fallback

        final List<Match> shadow = _shadowPattern.allMatches(css.textShadow).toList();

        if (shadow.length < 4) {
            textShadowColour = "";
            textShadowX = 0;
            textShadowY = 0;
            textShadowBlur = 0;
        } else {
            textShadowColour = shadow[0].group(0)!;
            textShadowX = cssLengthToPixels(shadow[1].group(0)!) ?? 0;
            textShadowY = cssLengthToPixels(shadow[2].group(0)!, compareHeight: true) ?? 0;
            textShadowBlur = cssLengthToPixels(shadow[3].group(0)!) ?? 0;
        }
    }

    void applyTextStyle(CanvasRenderingContext2D ctx) {
        this.computeTextStyle();

        ctx
            ..fillStyle = textColour
            ..font = textFont
            ..textAlign = textAlign
            ..shadowColor = textShadowColour
            ..shadowOffsetX = textShadowX
            ..shadowOffsetY = textShadowY
            ..shadowBlur = textShadowBlur
        ;
    }

    num? cssLengthToPixels(String len, {bool compareHeight = false, Element? parent}) {

        // if there's nothing to parse, null
        if (len.isEmpty) { return null; }

        // get the number and the unit
        final Match? match = _lengthPattern.matchAsPrefix(len);
        // if either is missing, null
        if (match == null) { return null; }

        // get the base value, and the unit string for checking
        final num value = num.tryParse(match.group(1)!) ?? 0;
        final String unit = match.group(2)!;

        if (unit == "em") { throw ArgumentError("Don't use font relative measures for canvas drawing styles (em, ex, rem, ch): $unit"); }


        switch(unit) {
            // absolute units
            case "px": // pixels are 1:1, easy
                return value;
            case "in":
                return value * 96; // 96 pixels to an inch
            case "cm":
                return value * 37.795; // 2.54cm to an inch
            case "mm":
                return value * 3.7795; // 10mm to a cm
            case "pt":
                return value * 72; // 72 pixels to a pt
            case "pc":
                return value * 8640; // 12 pts to a pc

            // relative units
            case "%": // percentage of parent width or height based on the compareHeight argument
                final int compare = (compareHeight ? (parent != null ? parent.offsetHeight : window.innerHeight) : (parent != null ? parent.offsetWidth : window.innerWidth))!;
                return value * 0.01 * compare;
            case "vw": // percentage of viewport width
                return value * 0.01 * window.innerWidth!;
            case "vh": // percentage of viewport height
                return value * 0.01 * window.innerHeight!;
            case "vmin": // percentage of lesser of viewport width and height
                return value * 0.01 * (window.innerWidth! < window.innerHeight! ? window.innerWidth : window.innerHeight)!;
            case "vmax": // percentage of greater of viewport width and height
                return value * 0.01 * (window.innerWidth! > window.innerHeight! ? window.innerWidth : window.innerHeight)!;
        }

        // if we somehow haven't returned now, it's null, bub
        return null;
    }
}