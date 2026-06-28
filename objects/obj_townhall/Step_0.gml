// ============================================================
// obj_townhall — Step Event
// ============================================================

// [1.1] Delayed init — tunggu game manager ready
if (!_initialized) {
    if (instance_exists(obj_game_manager)
    && variable_struct_exists(obj_game_manager, "kingdom")) {
        slot_layout.rebuild();
        _initialized = true;

        // [1.1.1] Snap camera ke townhall
        obj_game_manager.cam.jump_to(x, y);
        show_debug_message("[TH] Initialized. Camera snapped to: "
            + string(x) + ", " + string(y));
    }
    exit;
}

// [1.2] Update construction progress
update_construction();

// [1.3] Sync slot visual setiap 30 frame
_sync_timer++;
if (_sync_timer >= 30) {
    _sync_timer = 0;
    slot_layout._sync_with_roster();
}