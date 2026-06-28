// ============================================================
// scr_debug
// Debug functions — padam script ni bila dah siap debug
// ============================================================

function debug_click(_mx, _my, _show_job_panel, _job_panel_hero_idx) {
    show_debug_message("=== CLICK DEBUG ===");
    show_debug_message("Mouse GUI: " + string(floor(_mx)) + "," + string(floor(_my)));
    show_debug_message("show_job_panel: " + string(_show_job_panel));
    show_debug_message("job_panel_hero_idx: " + string(_job_panel_hero_idx));

    if (_show_job_panel) {
        var _jobs = [
            "Gatherer", "Warrior", "Archer", "Explorer",
            "Miner", "Guard", "Healer", "Wizard", "Rogue", "Paladin"
        ];
        var _pw = 200;
        var _px = display_get_gui_width() - 270 - _pw - 10;
        var _py = 40 + 10;

        show_debug_message("Panel X: " + string(_px)
            + " | Panel Y: " + string(_py)
            + " | Panel W: " + string(_pw));

        for (var i = 0; i < array_length(_jobs); i++) {
            var _jy = _py + 24 + (i * 28);
            var _hit = point_in_rectangle(_mx, _my,
                _px + 5, _jy - 2,
                _px + _pw - 5, _jy + 22);
            show_debug_message("Job[" + string(i) + "] "
                + _jobs[i]
                + " Y:" + string(_jy) + "-" + string(_jy + 22)
                + " | Hit: " + string(_hit));
        }
    }
}

// [2.0] Delete save — panggil sekali untuk reset treasury
function debug_delete_save() {
    if (instance_exists(obj_game_manager)) {
        delete_run_save();
        show_debug_message("[DEBUG] Save deleted! Restart game.");
    }
}

// [3.0] Print game state semasa
function debug_print_state() {
    if (!instance_exists(obj_game_manager)) return;
    var _gm = obj_game_manager;
    show_debug_message("=== GAME STATE ===");
    show_debug_message("Treasury: " + string(_gm.kingdom.treasury) + "g");
    show_debug_message("TH Level: " + string(_gm.kingdom.th_level));
    show_debug_message("Heroes: "   + string(array_length(_gm.hero_roster)));
    show_debug_message("Wave: "     + string(_gm.wave.current));
}