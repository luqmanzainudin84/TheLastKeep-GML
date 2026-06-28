// ============================================================
// obj_map_manager — Draw Event
// ============================================================

// [1.1] Safety check
if (!instance_exists(obj_game_manager)) exit;
if (!variable_struct_exists(obj_game_manager, "cam")) exit;

// [1.2] Ambil camera position dari game manager
var _cam_x = obj_game_manager.cam.x;
var _cam_y = obj_game_manager.cam.y;
var _cam_w = 1280;
var _cam_h = 720;

// [1.3] Kira cell range yang visible dalam camera
// Hanya draw cell yang dalam screen — optimise performance
var _col_start = max(0, floor(_cam_x / config.cell_size));
var _row_start = max(0, floor(_cam_y / config.cell_size));
var _col_end   = min(config.cols - 1, ceil((_cam_x + _cam_w) / config.cell_size));
var _row_end   = min(config.rows - 1, ceil((_cam_y + _cam_h) / config.cell_size));

// [1.4] Terrain colors
var _col_water    = make_color_rgb(40,  80,  160);
var _col_grass    = make_color_rgb(60,  140, 60);
var _col_forest   = make_color_rgb(30,  90,  30);
var _col_mountain = make_color_rgb(120, 100, 80);
var _col_ruins    = make_color_rgb(130, 110, 90);

// [1.5] Draw setiap cell
var _cell_size = config.cell_size;

for (var c = _col_start; c <= _col_end; c++) {
    for (var r = _row_start; r <= _row_end; r++) {
        var _cell = grid[c][r];
        var _px   = c * _cell_size;
        var _py   = r * _cell_size;

        // [1.5.1] Draw terrain kalau pernah explored
        if (_cell.visibility != VIS.HIDDEN) {

            // [1.5.1.1] Pilih warna terrain
            var _col = _col_grass;
            switch (_cell.terrain) {
                case TERRAIN.WATER    : _col = _col_water;    break;
                case TERRAIN.GRASS    : _col = _col_grass;    break;
                case TERRAIN.FOREST   : _col = _col_forest;   break;
                case TERRAIN.MOUNTAIN : _col = _col_mountain; break;
                case TERRAIN.RUINS    : _col = _col_ruins;    break;
            }

            // [1.5.1.2] Draw terrain tile
            draw_set_color(_col);
            draw_set_alpha(1.0);
            draw_rectangle(_px, _py,
                _px + _cell_size - 1,
                _py + _cell_size - 1, false);

            // [1.5.1.3] Draw grid line (subtle)
            draw_set_color(make_color_rgb(0, 0, 0));
            draw_set_alpha(0.1);
            draw_rectangle(_px, _py,
                _px + _cell_size - 1,
                _py + _cell_size - 1, true);
            draw_set_alpha(1.0);

            // [1.5.1.4] Draw resource node indicator
            if (!is_undefined(_cell.resource)
            &&  !_cell.resource.is_depleted()) {
                var _cx = _px + _cell_size / 2;
                var _cy = _py + _cell_size / 2;
                draw_set_color(c_yellow);
                draw_set_alpha(0.8);
                draw_circle(_cx, _cy, 4, false);
                draw_set_alpha(1.0);
            }
        }

        // [1.5.2] Draw fog overlay
        if (_cell.visibility == VIS.HIDDEN) {
            // [1.5.2.1] Fully hidden — hitam penuh
            draw_set_color(c_black);
            draw_set_alpha(1.0);
            draw_rectangle(_px, _py,
                _px + _cell_size - 1,
                _py + _cell_size - 1, false);
        }
        else if (_cell.visibility == VIS.EXPLORED) {
            // [1.5.2.2] Explored tapi hero tidak ada — gelap separuh
            draw_set_color(c_black);
            draw_set_alpha(0.5);
            draw_rectangle(_px, _py,
                _px + _cell_size - 1,
                _py + _cell_size - 1, false);
        }
        draw_set_alpha(1.0);
    }
}

// [1.6] Reset draw state
draw_set_color(c_white);
draw_set_alpha(1.0);