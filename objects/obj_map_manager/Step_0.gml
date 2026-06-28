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