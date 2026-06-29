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

// ============================================================
// FLAG PLACEMENT (add dalam Step Event)
// ============================================================

// [4.1] Check if player ready to place flag
if (global.flag_ready_to_place) {
    if (mouse_check_button_pressed(mb_left)) {
        var m_x = mouse_x;
        var m_y = mouse_y;
        
        // Check if click NOT on UI buttons (bottom 80px)
        if (m_y < (room_height - 80)) {
            // Convert screen coords to world coords
			var world_x = mouse_x;
			var world_y = mouse_y;;
            
            // Create flag at location
            var new_flag = instance_create_layer(world_x, world_y, "Instances", obj_flag);
            new_flag.flag_type = global.flag_placement_mode;
            new_flag.bounty = 150 + (global.flag_placement_mode * 20);
            
            // Add to active flags list
            ds_list_add(global.active_flags, new_flag);
            
            // Reset placement mode
            global.flag_ready_to_place = false;
            global.flag_placement_mode = -1;
            
            show_debug_message("[FLAG] Placed flag at " + string(world_x) + "," + string(world_y));
        }
    }
}