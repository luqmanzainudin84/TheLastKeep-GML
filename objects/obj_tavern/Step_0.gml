// ============================================================
// obj_tavern — Step Event
// ============================================================

// [1.1] Delayed init — tunggu game manager ready
if (!_ready) {
    if (instance_exists(obj_game_manager)
    && variable_struct_exists(obj_game_manager, "kingdom")) {
        _ready = true;
        open_tavern();
    }
    exit;
}

// [1.2] Game start — paksa player pilih hero dulu
if (is_first_open && state == TAVERN_STATE.OPEN) {
    // [1.2.1] Block semua input lain sehingga ada hero
    if (array_length(obj_game_manager.hero_roster) > 0) {
        is_first_open = false;
    }
}