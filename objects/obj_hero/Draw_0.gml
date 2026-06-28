// ============================================================
// obj_hero — Draw Event
// ============================================================

// [1.0] Draw sprite hero
draw_self();

// [2.0] Debug line — padam bila dah confirm betul
if (!variable_instance_exists(id, "ai")) exit;
if (is_undefined(ai)) exit;
if (is_undefined(ai.current_state)) exit;

var _state_name = ai.current_state.name;

// [2.1] Line ke target semasa
var _tx = 0;
var _ty = 0;
var _show_line = false;
var _line_col  = c_white;

switch (_state_name) {

    case "move_to_target":
    case "attack":
    case "attack_ranged":
        // [2.1.1] Line ke enemy target
        if (current_target_type == "combat"
        &&  instance_exists(current_target)) {
            _tx        = current_target.x;
            _ty        = current_target.y;
            _show_line = true;
            _line_col  = c_red;
        }
        // [2.1.2] Line ke resource target
        else if (current_target_type == "resource"
        &&  !is_undefined(current_target)
        &&  instance_exists(obj_map_manager)) {
            var _world = map_cell_to_world(
                current_target.col,
                current_target.row,
                obj_map_manager.config
            );
            _tx        = _world.x;
            _ty        = _world.y;
            _show_line = true;
            _line_col  = c_yellow;
        }
    break;

    case "returning":
        // [2.1.3] Line ke warehouse/townhall
        if (instance_exists(obj_warehouse)) {
            _tx = obj_warehouse.x;
            _ty = obj_warehouse.y;
        } else {
            _tx = obj_townhall.x;
            _ty = obj_townhall.y;
        }
        _show_line = true;
        _line_col  = c_lime;
    break;

    case "flee":
        // [2.1.4] Line ke titik flee
        if (variable_struct_exists(ai.current_state, "flee_x")) {
            _tx        = ai.current_state.flee_x;
            _ty        = ai.current_state.flee_y;
            _show_line = true;
            _line_col  = c_orange;
        }
    break;
}

// [2.2] Draw line
if (_show_line) {
    draw_set_color(_line_col);
    draw_set_alpha(0.5);
    draw_line(x, y, _tx, _ty);

    // [2.2.1] Draw bulatan kecil kat destination
    draw_set_alpha(0.8);
    draw_circle(_tx, _ty, 6, false);
    draw_set_alpha(1.0);
}

// [2.3] Draw state label atas hero
draw_set_color(c_white);
draw_set_halign(fa_center);
draw_text(x, y - 48, ai.current_state.name);
draw_set_halign(fa_left);