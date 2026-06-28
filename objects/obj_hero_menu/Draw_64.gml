// Object: obj_hero_menu | Event: Draw GUI
if (!is_open) exit;

var _xx = 100;
var _yy = 50;
var _w = 400;
var _h = 300;

// Draw Panel Utama
draw_rectangle_color(_xx, _yy, _xx + _w, _yy + _h, c_black, c_black, c_black, c_black, false);
draw_text(_xx + 20, _yy + 10, "HERO MANAGEMENT (Click to change Job)");

// Loop melalui senarai hero
if (instance_exists(obj_townhall)) {
    var _list = obj_townhall.hero_list;
    var _count = ds_list_size(_list);
    
    for (var i = 0; i < _count; i++) {
        var _hero = _list[| i]; // Ambil ID hero
        if (!instance_exists(_hero)) continue;
        
        var _line_y = _yy + 40 + (i * 30);
        var _text = "Hero " + string(i+1) + " [" + _hero.job + "]";
        
        // Cek klik untuk tukar job
        if (point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _xx, _line_y, _xx + _w, _line_y + 25)) {
            draw_set_color(c_yellow);
            if (mouse_check_button_pressed(mb_left)) {
                // Cycle job (logic sama macam tadi)
                var _jobs = ["idle", "gatherer", "builder", "farmer", "warrior", "scout"];
                var _current_idx = 0;
                for(var j=0; j<array_length(_jobs); j++) { if(_hero.job == _jobs[j]) _current_idx = j; }
                _hero.job = _jobs[( _current_idx + 1) % array_length(_jobs)];
            }
        } else {
            draw_set_color(c_white);
        }
        
        draw_text(_xx + 20, _line_y, _text);
    }
}

// Butang Tutup
if (draw_button_custom(_xx + _w - 60, _yy + 10, 50, 20, "Close")) {
    is_open = false;
}