import "dart:collection";

import "../entities/enemy.dart";
import "../entities/enemytype.dart";
import "../resources/resourcetype.dart";
import "game.dart";

class WaveManager {
    final Game engine;

    /// Once a wave is cleared or times out, wait this long before starting a new wave
    double timeBetweenWaves = 5;
    /// When a wave has finished spawning, wait at most this long before counting down a new wave
    double waveTimeout = 60;
    /// Delay between enemy spawns in seconds. Can be overridden by a wave
    double spawnDelay = 1.5;

    /// Time remaining until the next wave starts
    double timeToNextWave;
    /// Time remaining until the next enemy spawns
    double spawnTimer = 0;

    /// No more spawns - once this is true no active enemies means victory
    bool doneSpawning = false;

    /// List of waves to spawn
    final Queue<Wave> waves = new Queue<Wave>();
    /// Enemies out on the field, when they're all dead we either skip forward the remaining wave timer or declare victory
    final Set<Enemy> activeEnemies = <Enemy>{};
    /// Currently spawning wave
    Wave currentWave;

    int currentWaveNumber = 0;
    int totalWaveNumber;

    WaveManager(Game this.engine) {
        timeToNextWave = timeBetweenWaves; // TODO: change this to a longer start time to allow initial inspection and building
    }

    void update(double dt) {
        totalWaveNumber ??= waves.length;

        if (!doneSpawning) { // there is spawning to do!
            if (currentWave == null) { // if there is no currently spawning wave
                if (!waves.isEmpty) { // and the list of waves to come isn't empty
                    if (timeToNextWave > 0) { // if we still have time left until the next wave
                        // skip some remaining time if all the enemies are dead
                        if (activeEnemies.isEmpty && timeToNextWave > timeBetweenWaves) {
                            timeToNextWave = timeBetweenWaves;
                        }
                        timeToNextWave -= dt;
                    } else { // we should get a new wave now and start spawning
                        currentWave = waves.removeFirst();
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
                            final Enemy enemy = engine.spawnEnemy(entry.type, engine.level.spawners[entry.spawner].pathObject)..bounty = entry.bounty;
                            activeEnemies.add(enemy);
                        }
                        // set spawn timer to the wave's delay, or default if absent
                        if (!currentWave.entries.isEmpty) {
                            spawnTimer = currentWave.delay ?? spawnDelay;
                        }
                    } else if (timeToNextWave <= 0) { // current wave exhausted, set the long countdown
                        timeToNextWave = waveTimeout;
                        currentWave = null;
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
}

class Wave {
    /// Delay between enemy spawns in this wave in seconds.
    /// When null, fall back to default delay.
    double delay;

    /// Spawn order for this wave.
    /// When exhausted, the manager will begin the long countdown to the next wave, if applicable.
    /// When all of the generated enemies are dead, short countdown begins if shorter than remaining long countdown.
    Queue<Set<WaveEntry>> entries = new Queue<Set<WaveEntry>>();
}

class WaveEntry {
    final EnemyType type;
    final int spawner;
    final ResourceValue bounty;

    WaveEntry(EnemyType this.type, int this.spawner, ResourceValue this.bounty);
}

class WaveItemDescriptor {
    final double timestamp;
    final double duration;
    final bool spawn;

    WaveItemDescriptor(double this.timestamp, double this.duration, bool this.spawn);
}