// ============================================================
// obj_wave_manager — Step Event
// ============================================================

// [1.1] Safety check — game manager ready
if (!instance_exists(obj_game_manager)) exit;
if (!variable_struct_exists(obj_game_manager, "kingdom")) exit;

// [1.1.5] Jangan start wave kalau tiada hero
if (!_wave_can_start) {
    if (array_length(obj_game_manager.hero_roster) > 0) {
        _wave_can_start = true;
        wave_timer      = wave_interval;
        show_debug_message("[WAVE] Hero recruited. Wave countdown started.");
    }
    exit;
}

// [1.2] Handle wave states
switch (state) {
    // [1.2.1] Waiting / Cooldown — countdown ke wave seterusnya
    case WAVE_STATE.WAITING:
    case WAVE_STATE.COOLDOWN:
        wave_timer--;
        if (wave_timer <= 0) {
            start_wave();
        }
    break;
    
    // [1.2.2] Active wave — semak sama ada semua musuh dah mati
    case WAVE_STATE.ACTIVE:
    case WAVE_STATE.BOSS:
        // enemies_alive dikurangkan oleh on_enemy_death()
        // Failsafe — kalau tiada musuh dalam world tapi counter salah
        if (enemies_alive > 0) {
            if (instance_number(obj_enemy) == 0) {
                show_debug_message("[WAVE] Failsafe triggered — no enemies found.");
                enemies_alive = 0;
                _complete_wave();
            }
        }
    break;
}

// [1.3] Update game manager wave display
if (variable_struct_exists(obj_game_manager, "wave")) {
    obj_game_manager.wave.current   = current_wave;
    obj_game_manager.wave.season    = current_season;
    obj_game_manager.wave.is_active = (state == WAVE_STATE.ACTIVE
                                    || state == WAVE_STATE.BOSS);
}

// ========== [2.0] ANNOUNCEMENTS ==========

// [2.10] Announcement - Wave Start
if (state == WAVE_STATE.ACTIVE && announced_wave_start == false) {
    if (instance_exists(obj_announcement_manager)) {
        obj_announcement_manager.add_announcement(
            $"WAVE {current_wave} STARTING!",
            global.ANNOUNCE_COLOR.GOLD,
            1.5,
            "wave_start_horn"
        );
    }
    announced_wave_start = true;
}

// [2.12] Announcement - Boss Wave
if (state == WAVE_STATE.BOSS && announced_boss_wave == false) {
    if (instance_exists(obj_announcement_manager)) {
        obj_announcement_manager.add_announcement(
            "BOSS WAVE!",
            global.ANNOUNCE_COLOR.GOLD,
            2.0,
            "boss_arrival"
        );
    }
    announced_boss_wave = true;
}