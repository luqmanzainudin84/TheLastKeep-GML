// ============================================================
// obj_hero — Step Event
// ============================================================

// [1.1] Safety check — ai belum ready
if (!variable_instance_exists(id, "ai")) exit;
if (is_undefined(ai)) exit;

// [1.2] AI state machine update
if (status.is_alive() || status.is_unconscious()) {
    ai.update();
}

// [1.3] Regen tick
if (status.is_alive()) {
    tick_regen();
}

// [1.4] Auto debug setiap 3 saat
if (!variable_instance_exists(id, "_debug_timer")) {
    _debug_timer = 0;
}
_debug_timer++;
if (_debug_timer >= 180) {
    _debug_timer = 0;
    if (!is_undefined(ai.current_state)) {
        show_debug_message("[HERO:" + identity.name + "]"
            + " State:" + ai.current_state.name
            + " | Job:" + job.current
            + " | Combat weight:" + string(job.weights.combat));

        var _result = decision.evaluate();
        if (is_undefined(_result)) {
            show_debug_message("  evaluate = UNDEFINED");
        } else {
            show_debug_message("  evaluate = " + _result.type
                + " score:" + string(_result.score));
        }

        var _radius      = decision.get_scan_radius();
        var _enemy_count = 0;
        with (obj_enemy) {
            if (point_distance(x, y, other.x, other.y) <= _radius) {
                _enemy_count++;
            }
        }
        show_debug_message("  Enemies in radius(" + string(_radius) + "): "
            + string(_enemy_count));
    }
}