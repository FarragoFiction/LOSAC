
import 'dart:html';

import "../engine/game.dart";
import '../engine/wavemanager.dart';
import "ui.dart";

class WaveTracker extends UIComponent {
    static double secondsAhead = 75;

    Element waveCounter;
    Element totalWaveCounter;

    Element barElement;
    Game get game => engine;

    WaveTracker(UIController controller) : super(controller);

    @override
    Element createElement() {
        final Element element = new DivElement()..className="WaveTracker uibackground";

        waveCounter = new SpanElement();
        totalWaveCounter = new SpanElement();

        final Element waveContainer = new DivElement()
            ..className = "WaveCounter"
            ..append(waveCounter)
            ..appendText("/")
            ..append(totalWaveCounter)
        ;
        element.append(waveContainer);

        barElement = new DivElement()..className="WaveBar";
        element.append(barElement);

        return element;
    }

    @override
    Element getChildContainer() => barElement;

    @override
    void update() {
        barElement.children.clear();

        final WaveManager waveManager = game.waveManager;

        waveCounter.text = waveManager.currentWaveNumber.toString();
        totalWaveCounter.text = waveManager.totalWaveNumber.toString();

        for (final WaveItemDescriptor wave in waveManager.descriptors(secondsAhead)) {
            final double start = wave.timestamp / secondsAhead;
            if (wave.duration > 0) {
                final double width = wave.duration / secondsAhead;
                barElement.append(new DivElement()
                    ..className = wave.spawn ? "bar spawnTimer" : "bar waveTimer"
                    ..style.setProperty("--left", "${(start*100).toStringAsFixed(2)}%")
                    ..style.setProperty("--width", "${(width*100).toStringAsFixed(2)}%")
                );
            }
        }
    }

    @override
    void resize() {

    }
}