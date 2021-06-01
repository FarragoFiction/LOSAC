import "dart:collection";

import "package:yaml/yaml.dart";

import "../entities/enemy.dart";
import "../entities/enemytype.dart";
import "../level/level.dart";
import "../level/pathnode.dart";
import "../resources/resourcetype.dart";
import "../utility/fileutils.dart";
import "game.dart";

class WaveManager {
    static const String typeDesc = "Wave Manager";
    final Game engine;

    /// Once a wave is cleared or times out, wait this long before starting a new wave
    double timeBetweenWaves = 5;
    /// When a wave has finished spawning, wait at most this long before counting down a new wave
    double waveTimeout = 60;
    /// Delay between enemy spawns in seconds. Can be overridden by a wave
    double spawnDelay = 1.5;

    /// Time remaining until the next wave starts
    late double timeToNextWave;
    /// Time remaining until the next enemy spawns
    double spawnTimer = 0;

    /// No more spawns - once this is true no active enemies means victory
    bool doneSpawning = false;

    /// List of waves to spawn
    final Queue<Wave> waves = new Queue<Wave>();
    /// Enemies out on the field, when they're all dead we either skip forward the remaining wave timer or declare victory
    final Set<Enemy> activeEnemies = <Enemy>{};
    /// Currently spawning wave
    Wave? currentWave;

    int currentWaveNumber = 0;
    int? totalWaveNumber;

    WaveManager(Game this.engine) {
        timeToNextWave = timeBetweenWaves; // TODO: change this to a longer start time to allow initial inspection and building
    }

    void update(double dt) {
        totalWaveNumber ??= waves.length;

        if (!doneSpawning) { // there is spawning to do!
            final Wave? currentWave = this.currentWave;
            if (currentWave == null) { // if there is no currently spawning wave
                if (!waves.isEmpty) { // and the list of waves to come isn't empty
                    if (timeToNextWave > 0) { // if we still have time left until the next wave
                        // skip some remaining time if all the enemies are dead
                        if (activeEnemies.isEmpty && timeToNextWave > timeBetweenWaves) {
                            timeToNextWave = timeBetweenWaves;
                        }
                        timeToNextWave -= dt;
                    } else { // we should get a new wave now and start spawning
                        this.currentWave = waves.removeFirst();
                        spawnTimer = 0;
                        currentWaveNumber++;
                    }
                } else { // no waves left! we're done!
                    doneSpawning = true;
                }
            } else { // there is a currently spawning wave
                if (spawnTimer > 0) { // if we're waiting to spawn an enemy
                    spawnTimer -= dt;
                } else { // it's time to spawn an enemy
                    if (currentWave.entries.isNotEmpty) { // if we have enemies still to spawn
                        final Set<WaveEntry> entries = currentWave.entries.removeFirst();

                        // spawn all the enemies for this step, add them to the active list
                        for (final WaveEntry entry in entries) {
                            final Enemy enemy = engine.spawnEnemy(entry.type, entry.spawner.pathObject)..bounty = entry.bounty;
                            activeEnemies.add(enemy);
                        }
                        // set spawn timer to the wave's delay, or default if absent
                        if (!currentWave.entries.isEmpty) {
                            spawnTimer = currentWave.delay ?? spawnDelay;
                        }
                    } else if (timeToNextWave <= 0) { // current wave exhausted, set the long countdown
                        timeToNextWave = waveTimeout;
                        this.currentWave = null;
                    }
                }
            }
        }

        // clean dead enemies out from the active list
        activeEnemies.removeWhere((Enemy e) => e.dead);

        if (doneSpawning && activeEnemies.isEmpty) {
            engine.win();
        }
    }

    Iterable<WaveItemDescriptor> descriptors(double maxTime) sync* {
        double time = 0;
        final Wave? currentWave = this.currentWave;
        if (currentWave == null) {
            if (!waves.isEmpty) {
                yield new WaveItemDescriptor(0, timeToNextWave, false);
                time += timeToNextWave;
            }
        } else {
            yield new WaveItemDescriptor(0, spawnTimer, true);
            time += spawnTimer;

            for (final Set<WaveEntry> entries in currentWave.entries) {
                final double duration = entries == currentWave.entries.last ? 0 : currentWave.delay ?? spawnDelay;
                yield new WaveItemDescriptor(time, duration, true);
                time += duration;
                if (time >= maxTime) { return; }
            }

            if (!waves.isEmpty) {
                yield new WaveItemDescriptor(time, waveTimeout, false);
                time += waveTimeout;
                if (time >= maxTime) { return; }
            }
        }

        for (final Wave wave in waves) {

            for (final Set<WaveEntry> entries in wave.entries) {
                final double duration = entries == wave.entries.last ? 0 : wave.delay ?? spawnDelay;
                yield new WaveItemDescriptor(time, duration, true);
                time += duration;
                if (time >= maxTime) { return; }
            }

            if (wave != waves.last) {
                yield new WaveItemDescriptor(time, waveTimeout, false);
                time += waveTimeout;
                if (time >= maxTime) { return; }
            }
        }
    }

    void load(YamlMap yaml, Level level) {
        final Set<String> fields = <String>{};
        final DataSetter set = FileUtils.dataSetter(yaml, typeDesc, level.name, fields);

        // global settings
        set("timeBetweenWaves", (num n) => timeBetweenWaves = n.toDouble());
        set("waveTimeout", (num n) => waveTimeout = n.toDouble());
        set("spawnDelay", (num n) => spawnDelay = n.toDouble());

        // list of all waves
        set("waves", (YamlList list) => FileUtils.typedList("waves", list, (YamlMap item, int index) {
            final Set<String> waveFields = <String>{};
            final DataSetter waveSet = FileUtils.dataSetter(item, "$typeDesc Wave", index.toString(), waveFields);

            final Wave wave = new Wave();

            // spawn delay override for this wave
            waveSet("spawnDelay", (num n) => wave.delay = n.toDouble());

            // list of spawn events in the wave
            waveSet("spawn", (YamlList waveList) => FileUtils.typedList("Wave $index spawn", waveList, (YamlMap waveItem, int waveIndex) {

                // go through each spawner to find what gets spawned during this spawn event
                for (final dynamic spawnerName in waveItem.keys) {
                    print("wave $index spawn $waveIndex key: $spawnerName, ${spawnerName.runtimeType}");
                }

            }), required: true);

            FileUtils.warnInvalidFields(item, "$typeDesc Wave", index.toString(), waveFields);

            this.waves.add(wave);
        }));

        FileUtils.warnInvalidFields(yaml, typeDesc, level.name, fields);
    }
}

class Wave {
    /// Delay between enemy spawns in this wave in seconds.
    /// When null, fall back to default delay.
    double? delay;

    /// Spawn order for this wave.
    /// When exhausted, the manager will begin the long countdown to the next wave, if applicable.
    /// When all of the generated enemies are dead, short countdown begins if shorter than remaining long countdown.
    Queue<Set<WaveEntry>> entries = new Queue<Set<WaveEntry>>();
}

class WaveEntry {
    final EnemyType type;
    final SpawnNode spawner;
    final ResourceValue bounty;

    WaveEntry(EnemyType this.type, SpawnNode this.spawner, ResourceValue this.bounty);
}

class WaveItemDescriptor {
    final double timestamp;
    final double duration;
    final bool spawn;

    WaveItemDescriptor(double this.timestamp, double this.duration, bool this.spawn);
}