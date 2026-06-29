// ============================================================
// obj_map_manager — Step Event
// ============================================================

// [1.1] Safety check
if (!instance_exists(obj_game_manager)) exit;

// [1.2] Fog of war update setiap 10 frame
fog_timer++;
if (fog_timer >= fog_update_interval) {
    fog_timer = 0;
    update_fog();
}

// ============================================================
// [RUINS] Check hero masuk ruins cell
// ============================================================
with (obj_hero) {
    if (!variable_instance_exists(id, "ai")) continue;
    if (!status.is_alive()) continue;

    var _map  = obj_map_manager;
    var _cell = _map.get_cell_at(x, y);

    if (is_undefined(_cell)) continue;
    if (_cell.terrain != 4) continue;          // 4 = RUINS
    if (!variable_struct_exists(_cell, "ruins")) continue;
    if (_cell.ruins.explored) continue;
    if (_cell.ruins.spawned) continue;

    // [RUINS] Mark sebagai spawned
    _cell.ruins.spawned = true;

    // [RUINS] Spawn enemies
    var _world = map_cell_to_world(_cell.col, _cell.row, _map.config);
    repeat (_cell.ruins.enemy_count) {
        var _ex = _world.x + irandom_range(-48, 48);
        var _ey = _world.y + irandom_range(-48, 48);
        var _en = instance_create_layer(_ex, _ey, "Instances", obj_enemy);
        _en.init_enemy(_cell.ruins.enemy_type, undefined);
        show_debug_message("[RUINS] Spawned " + _cell.ruins.enemy_type
            + " at " + string(floor(_ex)) + "," + string(floor(_ey)));
    }

    // [RUINS] Drop loot ke warehouse
    if (instance_exists(obj_warehouse)) {
        var _loot_type = _cell.ruins.loot_table[irandom(array_length(_cell.ruins.loot_table) - 1)];
        obj_warehouse.deposit(_loot_type, _cell.ruins.loot_amount);
        show_debug_message("[RUINS] Loot: " + string(_cell.ruins.loot_amount)
            + "x " + _loot_type);
    }

    // [RUINS] Mark explored lepas spawn
    _cell.ruins.explored = true;

    // Announcement
if (instance_exists(obj_announcement_manager)) {
        obj_announcement_manager.add_announcement(
            "Ruins discovered! Enemies incoming!",
            1
        );
    }
}