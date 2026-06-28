// ============================================================
// obj_hero — User Event 0
// ============================================================

// [DEBUG]
show_debug_message("[HERO USER EVENT 0] Called!");

if (variable_global_exists("_pending_blueprint")
&&  !is_undefined(global._pending_blueprint)) {
    show_debug_message("[HERO USER EVENT 0] Blueprint found: "
        + global._pending_blueprint.name);
    init_from_blueprint(global._pending_blueprint);
    global._pending_blueprint = undefined;
} else {
    show_debug_message("[HERO USER EVENT 0] No blueprint found!");
}