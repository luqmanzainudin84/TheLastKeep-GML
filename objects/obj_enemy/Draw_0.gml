// ============================================================
// obj_enemy — Draw Event
// ============================================================

// [1.1] Safety check
if (!variable_instance_exists(id, "stats")) exit;
if (stats.hp_max <= 0) exit;

// ============================================================
// [2.0] BODY COLOUR BERDASARKAN TYPE
// ============================================================

// [2.1] Default colour
var _col = c_red;

// [2.2] Pilih warna ikut enemy type
switch (enemy_type) {
    case "goblin"          : _col = make_color_rgb(80,  160, 80);  break;
    case "bandit"          : _col = make_color_rgb(160, 120, 60);  break;
    case "bandit_archer"   : _col = make_color_rgb(140, 100, 50);  break;
    case "orc"             : _col = make_color_rgb(60,  140, 60);  break;
    case "orc_warrior"     : _col = make_color_rgb(40,  120, 40);  break;
    case "dark_mage"       : _col = make_color_rgb(100, 60,  180); break;
    case "troll"           : _col = make_color_rgb(80,  100, 80);  break;
    case "dragon_spawn"    : _col = make_color_rgb(200, 80,  40);  break;
    case "bandit_warlord"  : _col = make_color_rgb(180, 80,  20);  break;
    case "orc_siege_leader": _col = make_color_rgb(20,  100, 20);  break;
    case "lich"            : _col = make_color_rgb(140, 60,  200); break;
    case "elder_dragon"    : _col = make_color_rgb(220, 60,  20);  break;
    case "void_titan"      : _col = make_color_rgb(60,  0,   80);  break;
}

// [2.3] Boss dapat warna override
if (is_boss) _col = make_color_rgb(180, 0, 220);

// ============================================================
// [3.0] BODY
// ============================================================

// [3.1] Radius ikut type
var _radius = is_boss ? 20 : 12;

// [3.2] Death fade
var _alpha = 1.0;
if (estate == ESTATE.DIE) {
    _alpha = 1.0 - (die_timer / die_duration);
}

// [3.3] Draw body
draw_set_alpha(_alpha);
draw_set_color(_col);
draw_circle(x, y, _radius, false);

// [3.4] Border
draw_set_color(c_black);
draw_set_alpha(_alpha * 0.8);
draw_circle(x, y, _radius, true);

// ============================================================
// [4.0] HP BAR
// ============================================================

// [4.1] Bar dimensions
var _bar_w = is_boss ? 50 : 30;
var _bar_h = 5;
var _bar_x = x - _bar_w / 2;
var _bar_y = y - _radius - 10;
var _hp_pct = stats.hp / stats.hp_max;

// [4.2] Background bar
draw_set_color(make_color_rgb(30, 30, 30));
draw_set_alpha(_alpha);
draw_rectangle(_bar_x, _bar_y,
    _bar_x + _bar_w, _bar_y + _bar_h, false);

// [4.3] HP fill
var _hp_col = _hp_pct > 0.5
    ? make_color_rgb(80, 200, 80)
    : make_color_rgb(200, 60, 60);
draw_set_color(_hp_col);
draw_rectangle(_bar_x, _bar_y,
    _bar_x + floor(_bar_w * _hp_pct),
    _bar_y + _bar_h, false);

// [4.4] Bar border
draw_set_color(c_black);
draw_set_alpha(_alpha * 0.5);
draw_rectangle(_bar_x, _bar_y,
    _bar_x + _bar_w, _bar_y + _bar_h, true);

// ============================================================
// [5.0] BOSS LABEL
// ============================================================
if (is_boss) {
    draw_set_color(make_color_rgb(220, 180, 255));
    draw_set_alpha(_alpha);
    draw_set_halign(fa_center);
    draw_text(x, y - _radius - 22, "BOSS");
    draw_set_halign(fa_left);
}

// ============================================================
// [6.0] RESET DRAW STATE
// ============================================================
draw_set_alpha(1.0);
draw_set_color(c_white);
draw_set_halign(fa_left);