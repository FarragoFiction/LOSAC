
/// Various game rules, loaded from a file so that they can be altered per map
class RuleSet {

    /// Should enemies return to their entry point when they reach an exit?
    bool enemiesLoop = true;

    /// What fraction of purchase price should be refunded when a tower is sold?
    double sellReturn = 0.75;

    /// Default gravity to use for projectiles if the level doesn't override it
    double gravity = 300;
}