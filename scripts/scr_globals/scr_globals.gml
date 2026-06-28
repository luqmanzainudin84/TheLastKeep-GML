// ============================================================
// scr_globals
// Dipanggil PERTAMA sebelum mana-mana object create
// ============================================================
function init_globals() {
    global.legacy_hero       = undefined;
    global.legacy_item       = undefined;
    global.last_score        = 0;
    global.last_wave         = 0;
    global.last_season       = 0;
    global.hall_of_fallen    = [];
    global.score_breakdown   = undefined;
    global.surviving_heroes  = [];  // ← tambah ini
}

// ========== AUDIO COLORS ENUM ==========
// Add dengan constants lain

global.ANNOUNCE_COLOR = {
    RED: 0,      // Danger/Loss
    GREEN: 1,    // Success/Gain
    GOLD: 2,     // Milestone/Event
    BLUE: 3      // Info/Neutral
}