import "dart:html";

import "package:CommonLib/Logging.dart";
import "package:CommonLib/Utility.dart";
import "package:CubeLib/CubeLib.dart" as B;
import "package:yaml/yaml.dart";

import "../engine/engine.dart";
import "../entities/tower.dart";
import '../entities/towertype.dart';
import "../renderer/3d/renderable3d.dart";
import "../utility/fileutils.dart";
import "connectible.dart";
import "curve.dart";
import "endcap.dart";
import "grid.dart";
import "level.dart";
import "levelobject.dart";
import "pathnode.dart";

class Level3D extends Level with Renderable3D {

    /*@override
    void drawUIToCanvas(CanvasRenderingContext2D ctx, double scaleFactor) {
        for (final LevelObject o in objects) {
            o.drawUIToCanvas(ctx, scaleFactor);
        }

        //drawPathNodes(ctx, scaleFactor);

        //drawBoundingBoxes(ctx, scaleFactor);

        drawRoutes(ctx, scaleFactor);
    }*/

    void drawBoundingBoxes(CanvasRenderingContext2D ctx, double scaleFactor) {
        const double cross = 10;
        ctx.strokeStyle = "rgba(255,200,20)";
        for (final LevelObject o in objects.whereType()) {
            final Rectangle<num> bounds = o.bounds;
            ctx.strokeRect(bounds.left * scaleFactor, bounds.top * scaleFactor, bounds.width * scaleFactor, bounds.height * scaleFactor);

            final B.Vector2 v = o.getWorldPosition() * scaleFactor;

            ctx
                ..beginPath()
                ..moveTo(v.x - cross, v.y)
                ..lineTo(v.x + cross, v.y)
                ..stroke()
                ..beginPath()
                ..moveTo(v.x, v.y - cross)
                ..lineTo(v.x, v.y + cross)
                ..stroke();
        }
    }

    void drawPathNodes(CanvasRenderingContext2D ctx, double scaleFactor) {
        final Set<PathNode> drawn = <PathNode>{};

        ctx.fillStyle = "#60A0FF";
        ctx.strokeStyle = "#60A0FF";
        double size = 4;

        for (final PathNode node in connectedNodes) {
            drawn.add(node);

            ctx.save();

            if (node is SpawnNode) {
                ctx.fillStyle = "#44EE44";
                size = 8;
            } else if (node is ExitNode) {
                ctx.fillStyle = "#FF3030";
                size = 8;
            }

            ctx.fillRect(node.position.x * scaleFactor - size/2, node.position.y * scaleFactor - size/2, size, size);

            ctx.fillText(node.distanceToExitFraction.toStringAsFixed(3), node.position.x * scaleFactor + size, node.position.y * scaleFactor - 5);

            ctx.restore();

            for (final PathNode other in node.connections.keys) {
                if (other.isolated || drawn.contains(other)) { continue; }

                ctx
                    ..beginPath()
                    ..lineTo(node.position.x * scaleFactor, node.position.y * scaleFactor)
                    ..lineTo(other.position.x * scaleFactor, other.position.y * scaleFactor)
                    ..stroke();
            }
        }
    }

    void drawRoutes(CanvasRenderingContext2D ctx, double scaleFactor) {
        ctx.save();
        final Set<PathNode> routeNodes = <PathNode>{};
        routeNodes.addAll(spawners.values);

        for (final SpawnNode spawn in spawners.values) {
            PathNode node = spawn;
            while (node.targetNode != null) {
                if (routeNodes.contains(node.targetNode)) {
                    break;
                }
                routeNodes.add(node.targetNode!);
                node = node.targetNode!;
            }
        }

        ctx.strokeStyle = "rgba(30,50,255, 0.3)";

        for (final PathNode node in pathNodes) {
            if (node.targetNode == null) { continue; }
            ctx.save();
            if (routeNodes.contains(node)) {
                ctx.strokeStyle = "rgba(30,50,255, 1.0)";
                ctx.lineWidth = 2;
            }

            final B.Vector2 pos = node.position;
            final B.Vector2 tpos = node.targetNode!.position;

            ctx
                ..beginPath()
                ..moveTo(pos.x * scaleFactor, pos.y * scaleFactor)
                ..lineTo(tpos.x * scaleFactor, tpos.y * scaleFactor)
                ..stroke();

            ctx.restore();
        }

        ctx.restore();
    }

    //##############################################################################################################################################
    // Level Loading
    //##############################################################################################################################################

    /// temporary map for placing towers defined in the level, since they need to be after the game kicks off
    Map<GridCell, TowerType>? prePlacedTowers = <GridCell, TowerType>{};

    @override
    Future<void> load(YamlMap yaml, String levelName) async {
        final Logger logger = Engine.logger;
        final Map<String,Tuple<YamlMap,SimpleLevelObject>> loadingObjects = <String,Tuple<YamlMap,SimpleLevelObject>>{};
        final Map<String,Grid> levelGrids = <String,Grid>{};
        final Map<String,Curve> levelCurves = <String,Curve>{};
        final Map<String,SpawnerObject> levelSpawners = <String,SpawnerObject>{};
        ExitObject? levelExit;

        final Set<String> fields = <String>{};
        final DataSetter levelData = FileUtils.dataSetter(yaml, Level.typeDesc, levelName, fields);

        // UTILITY FUNCTIONS ####################################################################

        void setMeshProvider(SimpleLevelObject object, YamlMap yaml) {
            if (!yaml.containsKey("model")) { return; }

            final dynamic value = yaml["model"];
            if (value is String) {
                object.meshProvider = engine.renderer.getMeshProviderFor(object, new YamlMap.wrap(<String,dynamic>{"type": value}));
            } else if (value is YamlMap) {
                object.meshProvider = engine.renderer.getMeshProviderFor(object, value);
            }
        }

        bool isNameLegal(String name) {
            // forbidden names!
            if (name == "exit") {
                Engine.logger.warn("Illegal level object name: '$name'");
                return false;
            }
            // duplicate of existing object
            if (loadingObjects.keys.contains(name)){
                Engine.logger.warn("Duplicate level object name: '$name', skipping");
                return false;
            }
            return true;
        }

        /// Parse and fetch a connector from a named object, otherwise null
        Connector? readConnector(YamlMap map, String key, int index) {
            // the starting connector
            if(map.containsKey(key)) {
                final dynamic item = map[key];
                if (item is String) {
                    // if it's a string then we check if it's an EndCap, otherwise it's not allowed
                    final SimpleLevelObject? object = loadingObjects[item]?.second;
                    if (object != null) {
                        if (object is! EndCap<dynamic>) {
                            Engine.logger.warn("${Level.typeDesc} '$levelName' connection entry $index '$key' value is not an EndCap, and requires a 'connector' field");
                            return null;
                        }
                        // EndCaps only have one connector
                        return object.connector;
                    } else {
                        // if there's no item by this name
                        Engine.logger.warn("${Level.typeDesc} '$levelName' connection entry $index '$key' value '$item' does not exist");
                        return null;
                    }
                } else if (item is YamlMap) {
                    // if it's a map we need to get the name and connector properties, and deal with parsing those
                    final dynamic? name = item["name"];
                    if (name != null) {
                        if (name is String) {
                            // if the name is a string, move on to getting the object
                            final SimpleLevelObject? object = loadingObjects[name]?.second;
                            if (object != null) {
                                // we have the object, now get the connector string
                                final dynamic? connector = item["connector"];
                                if (connector != null) {
                                    if (connector is String) {
                                        // now we have the connector string, ask the object for the corresponding connector
                                        final Connector? con = (object as Connectible).getConnector(connector);
                                        if (con != null) {
                                            // if the connector isn't null, hooray we have it!
                                            return con;
                                        } else {
                                            // connector is null, bail
                                            Engine.logger.warn("${Level.typeDesc} '$levelName' connection entry $index '$key' object '$name' does not have a connector named '$connector'");
                                            return null;
                                        }
                                    } else {
                                        // if the connector isn't a string
                                        Engine.logger.warn("${Level.typeDesc} '$levelName' connection entry $index '$key' object '$name' 'connector' value '$item' is not a String");
                                        return null;
                                    }
                                } else {
                                    // if there's no connector string, bail
                                    Engine.logger.warn("${Level.typeDesc} '$levelName' connection entry $index '$key' object '$name' is missing a 'connector' field");
                                    return null;
                                }
                            } else {
                                // if there's no item by this name
                                Engine.logger.warn("${Level.typeDesc} '$levelName' connection entry $index '$key' value '$name' does not exist");
                                return null;
                            }
                        } else {
                            // if the name isn't a string
                            Engine.logger.warn("${Level.typeDesc} '$levelName' connection entry $index '$key' 'name' value '$name' is not a String");
                            return null;
                        }
                    } else {
                        // if there's no name, bail
                        Engine.logger.warn("${Level.typeDesc} '$levelName' connection entry $index '$key' is missing a 'name' field");
                        return null;
                    }
                } else {
                    Engine.logger.warn("${Level.typeDesc} '$levelName' connection entry $index '$key' 'connect' value is an invalid type: $item");
                    return null;
                }
            } else {
                Engine.logger.warn("${Level.typeDesc} '$levelName' connection entry $index '$key' requires a 'connect' value");
                return null;
            }
        }

        // READING THE LEVEL STUFF ####################################################################

        // set up grids
        levelData("grids", (YamlList grids) {
            FileUtils.typedList("${Level.typeDesc} '$levelName' grids", grids, (YamlMap entry, int index) {
                if (!entry.containsTypedEntry<String>("name")) {
                    logger.warn("${Level.typeDesc} '$levelName' grid definition $index is missing a 'name' field, skipping");
                    return;
                }

                final String name = entry["name"];
                if (!isNameLegal(name)){
                    logger.warn("${Level.typeDesc} '$levelName' grid definition $index has a conflicting name '$name', skipping");
                    return;
                }

                final Grid grid = new Grid.fromYaml(entry);
                setMeshProvider(grid, entry);

                loadingObjects[name] = new Tuple<YamlMap,SimpleLevelObject>(entry, grid);
                levelGrids[name] = grid;
            });
        });

        // set up curves
        levelData("curves", (YamlList curves) {
            FileUtils.typedList("${Level.typeDesc} '$levelName' curves", curves, (YamlMap entry, int index) {
                if (!entry.containsTypedEntry<String>("name")) {
                    logger.warn("${Level.typeDesc} '$levelName' curve definition $index is missing a 'name' field, skipping");
                    return;
                }

                final String name = entry["name"];
                if (!isNameLegal(name)){
                    logger.warn("${Level.typeDesc} '$levelName' curve definition $index has a conflicting name '$name', skipping");
                    return;
                }

                final Curve curve = new Curve.fromYaml(entry);
                setMeshProvider(curve, entry);

                loadingObjects[name] = new Tuple<YamlMap,SimpleLevelObject>(entry, curve);
                levelCurves[name] = curve;
            });
        });

        // set up exit
        levelData("exit", (YamlMap entry) {
            final ExitObject exit = new ExitObject.fromYaml(entry);
            setMeshProvider(exit, entry);

            loadingObjects["exit"] = new Tuple<YamlMap,SimpleLevelObject>(entry, exit);
            levelExit = exit;
        });

        // set up entrances
        levelData("spawners", (YamlList curves) {
            FileUtils.typedList("${Level.typeDesc} '$levelName' spawners", curves, (YamlMap entry, int index) {
                if (!entry.containsTypedEntry<String>("name")) {
                    logger.warn("${Level.typeDesc} '$levelName' spawner definition $index is missing a 'name' field, skipping");
                    return;
                }

                final String name = entry["name"];
                if (!isNameLegal(name)){
                    logger.warn("${Level.typeDesc} '$levelName' spawner definition $index has a conflicting name '$name', skipping");
                    return;
                }

                final SpawnerObject spawner = new SpawnerObject.fromYaml(entry)..name = name;
                setMeshProvider(spawner, entry);

                loadingObjects[name] = new Tuple<YamlMap,SimpleLevelObject>(entry, spawner);
                levelSpawners[name] = spawner;

                logger.debug("Added spawner '$name'");
            });
        });

        // connect all the things
        levelData("connections", (YamlList connections) {
            FileUtils.typedList("${Level.typeDesc} '$levelName' connections", connections, (YamlMap entry, int index) {
                final Connector? fromConnector = readConnector(entry, "connect", index);
                final Connector? toConnector = readConnector(entry, "to", index);

                if (fromConnector == null || toConnector == null) {
                    return;
                }

                if (fromConnector.canConnectToType(toConnector)) {
                    fromConnector.connectAndOrient(toConnector);
                } else {
                    Engine.logger.warn("${Level.typeDesc} '$levelName' connections entry $index does not describe compatible connector types. Grids cannot connect to other grids, curves cannot connect to other curves.");
                }

                FileUtils.warnInvalidFields(entry, "${Level.typeDesc} '$levelName' connections", index.toString(), <String>{"connect","to"});
            });
        });

        // pre-placed towers
        levelData("towers", (YamlList towers) {
            FileUtils.typedList("${Level.typeDesc} '$levelName' pre-placed towers", towers, (YamlMap entry, int index) {
                final Set<String> fields = <String>{};
                final DataSetter set = FileUtils.dataSetter(entry, "${Level.typeDesc} '$levelName' pre-placed towers", index.toString(), fields);

                TowerType? type;
                Grid? grid;
                int x = 0;
                int y = 0;

                set("type", (String s) => type = engine.towerTypeRegistry.get(s), required: true);
                set("grid", (String s) => grid = levelGrids[s], required: true);
                set("x", (num n) => x = n.toInt(), required: true);
                set("y", (num n) => y = n.toInt(), required: true);

                if(type == null || grid == null) {
                    Engine.logger.warn("${Level.typeDesc} '$levelName' pre-placed tower entry $index requires 'name', 'grid', 'x' and 'y' fields");
                    return;
                }

                if (x < 0 || x >= grid!.xSize || y < 0 || y >= grid!.ySize) {
                    Engine.logger.warn("${Level.typeDesc} '$levelName' pre-placed tower entry $index coordinates are out of range. Allowed values: x between 0 and ${grid!.xSize-1}, y between 0 and ${grid!.ySize-1}");
                    return;
                }

                final GridCell? cell = grid!.getCell(x, y);

                if (cell == null || cell.state != GridCellState.clear) {
                    Engine.logger.warn("${Level.typeDesc} '$levelName' pre-placed tower entry $index placement is invalid, skipping");
                    return;
                }

                prePlacedTowers![cell] = type!;

                FileUtils.warnInvalidFields(entry, "${Level.typeDesc} '$levelName' pre-placed towers", index.toString(), fields);
            });
        });

        // cleanup
        FileUtils.warnInvalidFields(yaml, "Level", levelName, fields);

        for (final Curve curve in levelCurves.values) {
            curve
                ..rebuildSegments()
                ..recentreOrigin();
        }

        // level validity checks
        //TODO: hook this up when hardcoded is gone
        if (levelExit == null) {
            throw Exception("${Level.typeDesc} '$levelName' is missing an exit");
        }
        if (levelSpawners.isEmpty) {
            throw Exception("${Level.typeDesc} '$levelName' requires at least one spawner");
        }

        // set things up
        for(final String key in loadingObjects.keys) {
            this.addObject(loadingObjects[key]!.second);
        }

        // make sure all the spawners can reach the exit
        //TODO: when we have all the bits and can comment out the hardcoded, hook this up
        //final Set<PathNode> unreachables = new Set<PathNode>.from(await engine.pathfinder.connectivityCheck(this));


    }

    @override
    Future<void> postLoad() async {
        if (prePlacedTowers == null) { return; }
        final Map<GridCell, TowerType> towers = prePlacedTowers!;

        for(final GridCell cell in towers.keys) {
            await cell.placeTower(new Tower(towers[cell]!));
        }
        prePlacedTowers = null;
    }
}