// ============================================================
// obj_ui_manager — Draw GUI Event
// ============================================================

// [1.1] Safety check
if (!instance_exists(obj_game_manager)) exit;

// [1.2] Reset draw state
draw_set_alpha(1.0);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(-1);

// ============================================================
// [2.0] TOP BAR
// ============================================================

// [2.1] Background top bar
draw_panel(0, 0, SW, HUD.top_h, COL.bg_dark, COL.border_gold);

// [2.2] Gold treasury
var _gold_str = "Gold: " + string(obj_game_manager.kingdom.treasury) + "g";
draw_text_shadow(HUD.padding, 12, _gold_str, COL.text_gold);

// [2.3] Wave & Season info
var _wave_str = "Wave " + string(obj_game_manager.wave.current)
              + "  Season " + string(obj_game_manager.wave.season);
draw_set_halign(fa_center);
draw_text_shadow(SW / 2, 12, _wave_str, COL.text_white);
draw_set_halign(fa_left);

// [2.4] Wave countdown atau enemy count
if (instance_exists(obj_wave_manager)) {
    var _wm = obj_wave_manager;
    if (_wm.state == _wm.WAVE_STATE.ACTIVE
    ||  _wm.state == _wm.WAVE_STATE.BOSS) {

        // [2.4.1] Kira enemies yang masih hidup dalam room
        var _alive_count = 0;
        with (obj_enemy) {
            if (estate != ESTATE.DIE) _alive_count++;
        }

        var _enemy_str = "Enemies: " + string(_alive_count);
        draw_set_halign(fa_right);
        draw_text_shadow(SW - HUD.padding, 12, _enemy_str, COL.text_red);
    } else {
        var _secs     = ceil(_wm.wave_timer / room_speed);
        var _next_str = "Next wave: " + string(_secs) + "s";
        draw_set_halign(fa_right);
        draw_text_shadow(SW - HUD.padding, 12, _next_str, COL.text_grey);
    }
    draw_set_halign(fa_left);
}

// ============================================================
// [3.0] BOTTOM BAR
// ============================================================

// [3.0.1] Background bottom bar
draw_panel(0, SH - HUD.bottom_h, SW, HUD.bottom_h,
    COL.bg_dark, COL.border_gold);

// [3.1] Butang TH UPGRADE
var _btn_th_x    = SW - HUD.padding - 210;
var _btn_th_y    = SH - HUD.bottom_h + 8;
var _th_data     = instance_exists(obj_townhall) ? obj_townhall.get_ui_data() : undefined;
var _can_upgrade  = !is_undefined(_th_data) ? _th_data.can_upgrade   : false;
var _is_upgrading = !is_undefined(_th_data) ? _th_data.is_upgrading  : false;
var _th_level     = !is_undefined(_th_data) ? _th_data.th_level      : 1;

var _btn_label = "";
if (_is_upgrading) {
    var _pct   = !is_undefined(_th_data) ? floor(_th_data.upgrade_progress * 100) : 0;
    _btn_label = "UPGRADING " + string(_pct) + "%";
} else if (_th_level >= 10) {
    _btn_label = "TH MAX";
} else {
    var _cost  = !is_undefined(_th_data) ? _th_data.upgrade_cost : 0;
    _btn_label = "TH Lv." + string(_th_level);
}

draw_panel(_btn_th_x, _btn_th_y, 100, 32,
    _can_upgrade ? COL.bg_panel2 : COL.bg_dark,
    _can_upgrade ? COL.border_gold : COL.border);
draw_set_halign(fa_center);
draw_text_shadow(_btn_th_x + 50, _btn_th_y + 9, _btn_label,
    _can_upgrade ? COL.text_gold : COL.text_grey);
draw_set_halign(fa_left);

// [3.2] Butang POTION SHOP
var _btn_ps_x = SW - HUD.padding - 560;
var _btn_ps_y = SH - HUD.bottom_h + 8;

draw_panel(_btn_ps_x, _btn_ps_y, 110, 32,
    active_panel == PANEL.POTION_SHOP ? COL.bg_panel : COL.bg_panel2,
    COL.border_gold);
draw_set_halign(fa_center);
draw_text_shadow(_btn_ps_x + 55, _btn_ps_y + 9,
    "POTION", COL.text_white);
draw_set_halign(fa_left);

// [3.3] Butang BLACKSMITH
var _btn_bs_x = SW - HUD.padding - 450;
var _btn_bs_y = SH - HUD.bottom_h + 8;

draw_panel(_btn_bs_x, _btn_bs_y, 100, 32,
    active_panel == PANEL.BLACKSMITH ? COL.bg_panel : COL.bg_panel2,
    COL.border_gold);
draw_set_halign(fa_center);
draw_text_shadow(_btn_bs_x + 50, _btn_bs_y + 9,
    "BLACKSMITH", COL.text_white);
draw_set_halign(fa_left);

// [3.4] Butang WAREHOUSE
var _btn_wh_x = SW - HUD.padding - 340;
var _btn_wh_y = SH - HUD.bottom_h + 8;

draw_panel(_btn_wh_x, _btn_wh_y, 100, 32,
    active_panel == PANEL.WAREHOUSE ? COL.bg_panel : COL.bg_panel2,
    COL.border_gold);
draw_set_halign(fa_center);
draw_text_shadow(_btn_wh_x + 50, _btn_wh_y + 9,
    "WAREHOUSE", COL.text_white);
draw_set_halign(fa_left);

// [3.5] Hero slots
var _slot_x   = HUD.padding + 55;
var _slot_y   = SH - HUD.bottom_h + 4;
var _slot_w   = 42;
var _slot_h   = 42;
var _slot_gap = 3;

draw_text_shadow(HUD.padding, _slot_y + 14, "Heroes:", COL.text_grey);

for (var i = 0; i < obj_game_manager.kingdom.hero_slots; i++) {
    var _is_occupied = (i < array_length(obj_game_manager.hero_roster));
    var _sx = _slot_x + (i * (_slot_w + _slot_gap));

    if (_is_occupied) {
        var _hero    = obj_game_manager.hero_roster[i];
        var _rar_col = get_rarity_colour(_hero.rarity);

        // [3.5.1] Cari live instance untuk HP
        var _hp_pct    = 1.0;
        var _hero_name = _hero.name;
        with (obj_hero) {
            if (!variable_instance_exists(id, "identity")) continue;
            if (identity.name == _hero_name) {
                _hp_pct = stats.hp / stats.hp_max;
                break;
            }
        }

        // [3.5.2] Background slot
        draw_set_color(COL.bg_panel2);
        draw_rectangle(_sx, _slot_y,
            _sx + _slot_w, _slot_y + _slot_h, false);

        // [3.5.3] Highlight kalau selected
        if (i == selected_hero_idx && active_panel == PANEL.HERO_INFO) {
            draw_set_color(COL.border_gold);
            draw_set_alpha(0.4);
            draw_rectangle(_sx, _slot_y,
                _sx + _slot_w, _slot_y + _slot_h, false);
            draw_set_alpha(1.0);
        }

        // [3.5.4] Border rarity
        draw_set_color(_rar_col);
        draw_rectangle(_sx, _slot_y,
            _sx + _slot_w, _slot_y + _slot_h, true);

        // [3.5.5] Huruf nama hero
        draw_set_halign(fa_center);
        draw_set_color(COL.bg_dark);
        draw_text(_sx + _slot_w/2 + 1, _slot_y + 8,
            string_char_at(_hero.name, 1));
        draw_set_color(COL.text_white);
        draw_text(_sx + _slot_w/2, _slot_y + 7,
            string_char_at(_hero.name, 1));
        draw_set_halign(fa_left);

        // [3.5.6] HP bar
        var _bar_x = _sx + 2;
        var _bar_y = _slot_y + _slot_h - 9;
        var _bar_w = _slot_w - 4;
        var _bar_h = 6;

        draw_set_color(COL.bar_bg);
        draw_rectangle(_bar_x, _bar_y,
            _bar_x + _bar_w, _bar_y + _bar_h, false);

        var _hp_col = _hp_pct > 0.5
            ? COL.text_green
            : (_hp_pct > 0.25 ? COL.text_gold : COL.text_red);
        draw_set_color(_hp_col);
        draw_rectangle(_bar_x, _bar_y,
            _bar_x + floor(_bar_w * _hp_pct),
            _bar_y + _bar_h, false);

        draw_set_color(COL.border);
        draw_rectangle(_bar_x, _bar_y,
            _bar_x + _bar_w, _bar_y + _bar_h, true);

    } else {
        // [3.5.7] Slot kosong
        draw_set_color(COL.bg_panel);
        draw_rectangle(_sx, _slot_y,
            _sx + _slot_w, _slot_y + _slot_h, false);
        draw_set_color(COL.border);
        draw_rectangle(_sx, _slot_y,
            _sx + _slot_w, _slot_y + _slot_h, true);

        // [3.5.8] Tanda +
        draw_set_halign(fa_center);
        draw_set_color(COL.text_grey);
        draw_text(_sx + _slot_w/2, _slot_y + 13, "+");
        draw_set_halign(fa_left);
    }
}

// [3.6] Butang TAVERN
var _btn_tavern_x = SW - HUD.padding - 100;
var _btn_tavern_y = SH - HUD.bottom_h + 8;
var _btn_w        = 90;
var _btn_h        = 32;

draw_panel(_btn_tavern_x, _btn_tavern_y, _btn_w, _btn_h,
    active_panel == PANEL.TAVERN ? COL.bg_panel : COL.bg_panel2,
    COL.border_gold);
draw_set_halign(fa_center);
draw_text_shadow(_btn_tavern_x + _btn_w / 2, _btn_tavern_y + 9,
    "TAVERN", COL.text_gold);
draw_set_halign(fa_left);

// ============================================================
// [4.0] ACTIVE PANELS
// ============================================================

// [4.1] Draw panel aktif
switch (active_panel) {
    case PANEL.TAVERN       : _draw_tavern_panel();       break;
    case PANEL.HERO_INFO    : _draw_hero_info_panel();    break;
    case PANEL.WAREHOUSE    : _draw_warehouse_panel();    break;
    case PANEL.BLACKSMITH   : _draw_blacksmith_panel();   break;
    case PANEL.POTION_SHOP  : _draw_potion_shop_panel();  break;
}

// [4.2] Job panel overlay
if (show_job_panel) {
    _draw_job_panel();
}

// ============================================================
// [5.0] NOTIFICATIONS
// ============================================================

// [5.1] Draw semua notification aktif
_draw_notifications();

// ============================================================
// [6.0] RESET DRAW STATE
// ============================================================
draw_set_alpha(1.0);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);