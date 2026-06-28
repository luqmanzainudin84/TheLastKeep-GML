// ============================================================
// obj_map_manager — Create Event
// ============================================================

// [1.1] Rujukan ke game manager
gm = obj_game_manager;

// [1.2] Map config dan terrain constants
config  = map_get_config();
TERRAIN = map_get_terrain_types();
VIS     = map_get_visibility_types();

// [1.3] Generate map
grid = map_generate(config);
show_debug_message("[MAP] Generated "
    + string(config.cols) + "x" + string(config.rows) + " map.");

// ============================================================
// [2.0] FORCE VISIBILITY — start zone
// ============================================================

// [2.1] Set semua cells dalam radius besar dari start VISIBLE
var _start_c    = config.start_col;
var _start_r    = config.start_row;
var _vis_radius = 15;

for (var c = _start_c - _vis_radius; c <= _start_c + _vis_radius; c++) {
    for (var r = _start_r - _vis_radius; r <= _start_r + _vis_radius; r++) {
        if (!map_is_valid_cell(c, r, config)) continue;
        var _dist = point_distance(c, r, _start_c, _start_r);
        if (_dist <= _vis_radius) {
            grid[c][r].visibility = VIS.VISIBLE;
        }
    }
}

show_debug_message("[MAP] Visibility initialized for start zone.");

// ============================================================
// [3.0] FOG OF WAR
// ============================================================
fog_update_interval = 10;
fog_timer           = 0;

// [3.1] Dapatkan vision radius hero berdasarkan job
get_hero_vision_radius = function(_hero_instance) {
    var _base = 4;
    switch (_hero_instance.job.current) {
        case "Explorer" : return _base + 3;
        case "Guard"    : return _base - 1;
        default         : return _base;
    }
};

// [3.2] Update fog of war
update_fog = function() {

    // [3.2.1] Reset semua VISIBLE ke EXPLORED
    for (var c = 0; c < config.cols; c++) {
        for (var r = 0; r < config.rows; r++) {
            if (grid[c][r].visibility == VIS.VISIBLE) {
                grid[c][r].visibility = VIS.EXPLORED;
            }
        }
    }

    // [3.2.2] Set VISIBLE untuk radius setiap hero
    with (obj_hero) {
        if (!variable_instance_exists(id, "status")) continue;
        if (!status.is_alive()) continue;

        var _cell   = map_world_to_cell(x, y, other.config);
        var _radius = other.get_hero_vision_radius(id);

        for (var c = _cell.col - _radius; c <= _cell.col + _radius; c++) {
            for (var r = _cell.row - _radius; r <= _cell.row + _radius; r++) {
                var _dist = point_distance(_cell.col, _cell.row, c, r);
                if (_dist <= _radius) {
                    var _target_cell = map_get_cell(other.grid, c, r, other.config);
                    if (!is_undefined(_target_cell)) {
                        _target_cell.visibility = other.VIS.VISIBLE;
                    }
                }
            }
        }
    }
};

// ============================================================
// [4.0] RESOURCE REGEN
// ============================================================

// [4.1] Tick resource regen — dipanggil setiap game day
tick_resource_regen = function() {
    for (var c = 0; c < config.cols; c++) {
        for (var r = 0; r < config.rows; r++) {
            var _cell = grid[c][r];
            if (!is_undefined(_cell.resource)) {
                _cell.resource.tick_regen();
            }
        }
    }
};

// [4.2] Daftar sebagai daily callback
gm.register_daily_callback(tick_resource_regen);

// ============================================================
// [5.0] FIND NEAREST RESOURCE
// ============================================================
find_nearest_resource = function(_wx, _wy, _resource_type, _search_radius_cells) {
    var _cell      = map_world_to_cell(_wx, _wy, config);
    var _best      = undefined;
    var _best_dist = infinity;
    var _min_dist  = 5;

    for (var c = _cell.col - _search_radius_cells;
             c <= _cell.col + _search_radius_cells; c++) {
        for (var r = _cell.row - _search_radius_cells;
                 r <= _cell.row + _search_radius_cells; r++) {

            var _target = map_get_cell(grid, c, r, config);
            if (is_undefined(_target)) continue;
            if (is_undefined(_target.resource)) continue;
            if (_target.resource.is_depleted()) continue;
            if (_target.resource.type != _resource_type) continue;
            if (_target.visibility == VIS.HIDDEN) continue;

            var _dist = point_distance(_cell.col, _cell.row, c, r);
            if (_dist < _min_dist) continue;

            if (_dist < _best_dist) {
                _best_dist = _dist;
                _best      = _target;
            }
        }
    }

    return _best;
};

// ============================================================
// [6.0] UTILITY FUNCTIONS
// ============================================================

// [6.1] Dapatkan cell pada world position
get_cell_at = function(_wx, _wy) {
    var _c = map_world_to_cell(_wx, _wy, config);
    return map_get_cell(grid, _c.col, _c.row, config);
};