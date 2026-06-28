// ============================================================
// obj_game_manager — Step Event
// ============================================================

// [1.1] Delayed load — tunggu semua object ready
if (_load_pending) {
    _load_timer++;
    if (_load_timer >= 5) {
        _load_pending = false;
        var _loaded = load_run();
        if (!_loaded) {
            show_debug_message("[SAVE] New game. Treasury: "
                + string(kingdom.treasury));
            load_legacy_hero();
        } else {
            show_debug_message("[SAVE] Loaded. Treasury: "
                + string(kingdom.treasury));
            // [1.1.1] Treasury kosong dari save lama — reset
            if (kingdom.treasury <= 0) {
                kingdom.treasury = 2000;
                show_debug_message("[SAVE] Treasury reset to 2000g.");
            }
        }
        debug_print_state();
    }
    exit;
}

// [1.2] Time system update
update_time();

// [1.3] Game over check
check_game_over();

// [1.4] Camera update
cam.update();

// [1.5] Autosave timer
save_timer++;
if (save_timer >= save_interval) {
    save_timer = 0;
    autosave();
}