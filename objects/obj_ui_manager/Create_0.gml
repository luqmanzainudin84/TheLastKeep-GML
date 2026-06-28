// ============================================================
// obj_ui_manager — Create Event
// ============================================================

// [1.1] Rujukan ke game manager
gm = obj_game_manager;

// [1.2] Screen dimensions
SW = display_get_gui_width();
SH = display_get_gui_height();

// ============================================================
// [2.0] COLOURS & STYLE
// ============================================================
COL = {
    bg_dark      : make_color_rgb(20,  20,  25),
    bg_panel     : make_color_rgb(35,  32,  28),
    bg_panel2    : make_color_rgb(48,  44,  38),
    border       : make_color_rgb(90,  75,  55),
    border_gold  : make_color_rgb(180, 145, 60),
    text_white   : make_color_rgb(240, 235, 220),
    text_gold    : make_color_rgb(255, 200, 50),
    text_grey    : make_color_rgb(150, 140, 125),
    text_red     : make_color_rgb(220, 80,  60),
    text_green   : make_color_rgb(80,  200, 100),
    common       : make_color_rgb(180, 180, 180),
    uncommon     : make_color_rgb(80,  180, 80),
    rare         : make_color_rgb(60,  120, 220),
    legendary    : make_color_rgb(220, 150, 30),
    hp_bar       : make_color_rgb(200, 60,  60),
    mana_bar     : make_color_rgb(60,  100, 220),
    bar_bg       : make_color_rgb(30,  30,  35),
};

// ============================================================
// [3.0] HUD DIMENSIONS
// ============================================================
HUD = {
    top_h    : 40,
    bottom_h : 50,
    padding  : 10,
};

// [4.0] PANEL STATE
PANEL = {
    NONE        : 0,
    TAVERN      : 1,
    HERO_INFO   : 2,
    WAREHOUSE   : 3,
    BLACKSMITH  : 4,
    POTION_SHOP : 5,
};

active_panel      = PANEL.NONE;
selected_hero_idx = -1;
show_job_panel    = false;
job_panel_hero_idx = -1;

// [4.1] Simpan koordinat Change Job button untuk click detection
_job_btn_y = 0;

// ============================================================
// [5.0] NOTIFICATION SYSTEM
// ============================================================
notifications  = [];
notif_duration = room_speed * 3;

add_notification = function(_msg, _col) {
    _col = _col ?? COL.text_white;
    array_push(notifications, {
        message : _msg,
        timer   : notif_duration,
        colour  : _col,
    });
    if (array_length(notifications) > 5) {
        array_delete(notifications, 0, 1);
    }
};

// ============================================================
// [6.0] PANEL HELPERS
// ============================================================

// [6.1] Open panel
open_panel = function(_panel) {
    active_panel = _panel;
};

// [6.2] Close panel
close_panel = function() {
    active_panel      = PANEL.NONE;
    selected_hero_idx = -1;
};

// [6.3] Toggle panel
toggle_panel = function(_panel) {
    if (active_panel == _panel) {
        close_panel();
    } else {
        open_panel(_panel);
    }
};

// ============================================================
// [7.0] DRAW HELPERS
// ============================================================

// [7.1] Draw panel dengan border
draw_panel = function(_x, _y, _w, _h, _bg_col, _border_col) {
    draw_set_color(_bg_col);
    draw_set_alpha(0.92);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_color(_border_col);
    draw_set_alpha(1.0);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    draw_set_alpha(1.0);
};

// [7.2] Draw text dengan shadow
draw_text_shadow = function(_x, _y, _str, _col) {
    draw_set_color(COL.bg_dark);
    draw_text(_x + 1, _y + 1, _str);
    draw_set_color(_col);
    draw_text(_x, _y, _str);
};

// [7.3] Draw progress bar
draw_bar = function(_x, _y, _w, _h, _pct, _col_fill, _col_bg) {
    draw_set_color(_col_bg);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    var _fill_w = floor(_w * clamp(_pct, 0, 1));
    if (_fill_w > 0) {
        draw_set_color(_col_fill);
        draw_rectangle(_x, _y, _x + _fill_w, _y + _h, false);
    }
    draw_set_color(COL.border);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
};

// [7.4] Rarity colour
get_rarity_colour = function(_rarity) {
    switch (_rarity) {
        case "Common"    : return COL.common;
        case "Uncommon"  : return COL.uncommon;
        case "Rare"      : return COL.rare;
        case "Legendary" : return COL.legendary;
        default          : return COL.common;
    }
};

// ============================================================
// [8.0] TAVERN PANEL
// ============================================================
_draw_tavern_panel = function() {
    if (!instance_exists(obj_tavern)) return;

    var _data = obj_tavern.get_ui_data();
    if (_data.state == obj_tavern.TAVERN_STATE.IDLE) return;

    var _pw = 620;
    var _ph = 420;
    var _px = (SW - _pw) / 2;
    var _py = (SH - _ph) / 2;

    draw_panel(_px, _py, _pw, _ph, COL.bg_panel, COL.border_gold);

    // [8.1] Title
    draw_set_halign(fa_center);
    draw_text_shadow(_px + _pw/2, _py + 12, "THE TAVERN", COL.text_gold);
    draw_set_halign(fa_left);

    // [8.2] Refresh info
    var _ref_str = "Refresh: " + string(_data.refresh_cost) + "g";
    draw_text_shadow(_px + 10, _py + 12, _ref_str,
        _data.can_refresh ? COL.text_white : COL.text_red);

    // [8.3] Slots available
    var _slot_str = "Slots: " + string(_data.slots_available) + " open";
    draw_set_halign(fa_right);
    draw_text_shadow(_px + _pw - 10, _py + 12, _slot_str, COL.text_grey);
    draw_set_halign(fa_left);

    // [8.4] Divider
    draw_set_color(COL.border_gold);
    draw_line(_px + 10, _py + 35, _px + _pw - 10, _py + 35);

    // [8.5] Hero cards
    var _card_w        = 180;
    var _card_h        = 310;
    var _card_gap      = 15;
    var _cards_total_w = (_card_w * 3) + (_card_gap * 2);
    var _card_start_x  = _px + (_pw - _cards_total_w) / 2;
    var _card_y        = _py + 45;

    for (var i = 0; i < array_length(_data.heroes); i++) {
        var _h  = _data.heroes[i];
        var _cx = _card_start_x + (i * (_card_w + _card_gap));
        _draw_hero_card(_cx, _card_y, _card_w, _card_h, _h);
    }

    // [8.6] Butang Refresh
    var _rbtn_x = _px + _pw - 110;
    var _rbtn_y = _py + _ph - 45;
    draw_panel(_rbtn_x, _rbtn_y, 90, 32,
        _data.can_refresh ? COL.bg_panel2 : COL.bg_dark,
        _data.can_refresh ? COL.border_gold : COL.border);
    draw_set_halign(fa_center);
    draw_text_shadow(_rbtn_x + 45, _rbtn_y + 9, "REFRESH",
        _data.can_refresh ? COL.text_gold : COL.text_grey);

    // [8.7] Butang Close
    draw_set_halign(fa_right);
    draw_text_shadow(_px + _pw - 12, _py + 8, "X", COL.text_red);
    draw_set_halign(fa_left);
};

// ============================================================
// [9.0] HERO CARD
// ============================================================
_draw_hero_card = function(_cx, _cy, _cw, _ch, _hero_data) {
    var _rar_col = get_rarity_colour(_hero_data.rarity);

    // [9.1] Card background
    draw_panel(_cx, _cy, _cw, _ch, COL.bg_panel2, _rar_col);

    // [9.2] Rarity bar atas kad
    draw_set_color(_rar_col);
    draw_set_alpha(0.8);
    draw_rectangle(_cx, _cy, _cx + _cw, _cy + 5, false);
    draw_set_alpha(1.0);

    // [9.3] Legacy indicator
    if (_hero_data.is_legacy) {
        draw_set_color(COL.legendary);
        draw_set_alpha(0.3);
        draw_rectangle(_cx, _cy, _cx + _cw, _cy + _ch, false);
        draw_set_alpha(1.0);
    }

    var _ty = _cy + 10;

    // [9.4] Nama hero
    draw_set_halign(fa_center);
    draw_text_shadow(_cx + _cw/2, _ty, _hero_data.name, COL.text_white);
    _ty += 16;

    // [9.5] Rarity label
    var _legacy_str = _hero_data.is_legacy ? " LEGACY" : "";
    draw_text_shadow(_cx + _cw/2, _ty,
        "[" + _hero_data.rarity + "]" + _legacy_str, _rar_col);
    draw_set_halign(fa_left);
    _ty += 20;

    // [9.6] Divider
    draw_set_color(COL.border);
    draw_line(_cx + 8, _ty, _cx + _cw - 8, _ty);
    _ty += 8;

    // [9.7] Stats
    draw_text_shadow(_cx + 10, _ty, "STR: " + string(_hero_data.str), COL.text_white);
    _ty += 14;
    draw_text_shadow(_cx + 10, _ty, "INT: " + string(_hero_data.int), COL.text_white);
    _ty += 14;
    draw_text_shadow(_cx + 10, _ty, "AGI: " + string(_hero_data.agi), COL.text_white);
    _ty += 18;

    // [9.8] HP & Mana
    draw_set_color(COL.border);
    draw_line(_cx + 8, _ty, _cx + _cw - 8, _ty);
    _ty += 8;
    draw_text_shadow(_cx + 10, _ty, "HP:   " + string(_hero_data.hp_max),   COL.hp_bar);
    _ty += 14;
    draw_text_shadow(_cx + 10, _ty, "Mana: " + string(_hero_data.mana_max), COL.mana_bar);
    _ty += 18;

    // [9.9] Personality labels
    draw_set_color(COL.border);
    draw_line(_cx + 8, _ty, _cx + _cw - 8, _ty);
    _ty += 8;
    draw_text_shadow(_cx + 10, _ty, "IQ:    " + _hero_data.iq_label,        COL.text_grey);
    _ty += 14;
    draw_text_shadow(_cx + 10, _ty, "Brave: " + _hero_data.braveness_label, COL.text_grey);
    _ty += 14;
    draw_text_shadow(_cx + 10, _ty, "Greed: " + _hero_data.greed_label,     COL.text_grey);
    _ty += 18;

    // [9.10] Job
    draw_set_halign(fa_center);
    draw_text_shadow(_cx + _cw/2, _ty, "Job: " + _hero_data.job, COL.text_white);
    _ty += 20;

    // [9.11] Recruit button
    var _btn_y   = _cy + _ch - 40;
    var _can_rec = _hero_data.can_recruit;
    draw_panel(_cx + 10, _btn_y, _cw - 20, 30,
        _can_rec ? COL.bg_dark : COL.bg_panel,
        _can_rec ? COL.border_gold : COL.border);
    var _btn_str = "RECRUIT " + string(_hero_data.recruit_cost) + "g";
    draw_text_shadow(_cx + _cw/2, _btn_y + 8, _btn_str,
        _can_rec ? COL.text_gold : COL.text_grey);
    draw_set_halign(fa_left);
};

// ============================================================
// [10.0] HERO INFO PANEL
// ============================================================
_draw_hero_info_panel = function() {
    if (selected_hero_idx < 0) return;
    if (selected_hero_idx >= array_length(gm.hero_roster)) return;

    var _raw = gm.hero_roster[selected_hero_idx];

    // [10.0.1] Cuba cari obj_hero instance yang matching
    var _live_hero = noone;
    with (obj_hero) {
        if (!variable_instance_exists(id, "identity")) continue;
        if (identity.name == _raw.name) {
            _live_hero = id;
            break;
        }
    }

    // [10.0.2] Normalize data — guna live instance untuk stats
    var _hero = {
        name        : _raw.name      ?? "Unknown",
        rarity      : _raw.rarity    ?? "Common",
        job         : is_string(_raw.job) ? _raw.job : (_raw.job.current ?? "Gatherer"),
        gold        : variable_struct_exists(_raw, "wallet")
                    ? _raw.wallet.gold
                    : (_raw.gold ?? 0),
        base_stats  : _raw.base_stats,
        personality : _raw.personality,
        history     : _raw.history,
        titles      : _raw.titles ?? [],

        // [10.0.3] Stats dari live instance kalau ada
        stats : _live_hero != noone ? _live_hero.stats : _raw.stats,
    };

    var _pw  = 260;
    var _ph  = 460;
    var _px  = SW - _pw - 10;
    var _py  = HUD.top_h + 10;

    draw_panel(_px, _py, _pw, _ph, COL.bg_panel, COL.border_gold);

    var _rar_col = get_rarity_colour(_hero.rarity);
    var _ty      = _py + 10;

    // [10.1] Nama + rarity
    draw_set_halign(fa_center);
    draw_text_shadow(_px + _pw/2, _ty, _hero.name, COL.text_white);
    _ty += 16;
    draw_text_shadow(_px + _pw/2, _ty,
        "[" + _hero.rarity + "]", _rar_col);
    draw_set_halign(fa_left);
    _ty += 22;

    // [10.2] HP Bar
    draw_text_shadow(_px + 10, _ty, "HP", COL.hp_bar);
    var _hp_pct = _hero.stats.hp / _hero.stats.hp_max;
    draw_bar(_px + 35, _ty + 2, _pw - 50, 12, _hp_pct,
             COL.hp_bar, COL.bar_bg);
    draw_set_halign(fa_center);
    draw_set_color(COL.text_white);
    draw_text(_px + 35 + (_pw-50)/2, _ty + 2,
        string(_hero.stats.hp) + "/" + string(_hero.stats.hp_max));
    draw_set_halign(fa_left);
    _ty += 20;

    // [10.3] Mana Bar
    draw_text_shadow(_px + 10, _ty, "MP", COL.mana_bar);
    var _mp_pct = _hero.stats.mana / _hero.stats.mana_max;
    draw_bar(_px + 35, _ty + 2, _pw - 50, 12, _mp_pct,
             COL.mana_bar, COL.bar_bg);
    draw_set_halign(fa_center);
    draw_set_color(COL.text_white);
    draw_text(_px + 35 + (_pw-50)/2, _ty + 2,
        string(_hero.stats.mana) + "/" + string(_hero.stats.mana_max));
    draw_set_halign(fa_left);
    _ty += 22;

    // [10.4] Divider
    draw_set_color(COL.border);
    draw_line(_px + 8, _ty, _px + _pw - 8, _ty);
    _ty += 8;

    // [10.5] Base stats
    draw_text_shadow(_px + 10, _ty,
        "STR: " + string(_hero.base_stats.strength), COL.text_white);
    draw_text_shadow(_px + 130, _ty,
        "MS: " + string(floor(_hero.stats.move_speed)), COL.text_white);
    _ty += 16;
    draw_text_shadow(_px + 10, _ty,
        "INT: " + string(_hero.base_stats.intelligence), COL.text_white);
    draw_text_shadow(_px + 130, _ty,
        "AS: " + string(floor(_hero.stats.attack_speed)), COL.text_white);
    _ty += 16;
    draw_text_shadow(_px + 10, _ty,
        "AGI: " + string(_hero.base_stats.agility), COL.text_white);
    _ty += 22;

    // [10.6] Personality
    draw_set_color(COL.border);
    draw_line(_px + 8, _ty, _px + _pw - 8, _ty);
    _ty += 8;
    draw_text_shadow(_px + 10, _ty,
        "IQ:    " + _hero.personality.iq_label,        COL.text_grey);
    _ty += 15;
    draw_text_shadow(_px + 10, _ty,
        "Brave: " + _hero.personality.braveness_label, COL.text_grey);
    _ty += 15;
    draw_text_shadow(_px + 10, _ty,
        "Greed: " + _hero.personality.greed_label,     COL.text_grey);
    _ty += 22;

    // [10.7] Job + wallet
    draw_set_color(COL.border);
    draw_line(_px + 8, _ty, _px + _pw - 8, _ty);
    _ty += 8;
    draw_text_shadow(_px + 10, _ty,
        "Job:  " + _hero.job, COL.text_white);
    _ty += 15;
    draw_text_shadow(_px + 10, _ty,
        "Gold: " + string(_hero.gold) + "g", COL.text_gold);
    _ty += 22;

    // [10.8] Change Job button
    _job_btn_y = _ty;
    draw_panel(_px + 10, _ty, _pw - 20, 24,
        show_job_panel ? COL.bg_panel : COL.bg_panel2, COL.border);
    draw_set_halign(fa_center);
    draw_text_shadow(_px + _pw/2, _ty + 5,
        "CHANGE JOB", COL.text_gold);
    draw_set_halign(fa_left);
    _ty += 32;

    // [10.9] Titles
    if (array_length(_hero.titles) > 0) {
        draw_set_color(COL.border);
        draw_line(_px + 8, _ty, _px + _pw - 8, _ty);
        _ty += 8;
        draw_text_shadow(_px + 10, _ty, "Titles:", COL.text_gold);
        _ty += 15;
        for (var t = 0; t < array_length(_hero.titles); t++) {
            draw_text_shadow(_px + 15, _ty, _hero.titles[t], COL.legendary);
            _ty += 14;
        }
        _ty += 4;
    }

    // [10.10] History
    draw_set_color(COL.border);
    draw_line(_px + 8, _ty, _px + _pw - 8, _ty);
    _ty += 8;
    draw_text_shadow(_px + 10, _ty,
        "Kills:  " + string(_hero.history.kills), COL.text_white);
    _ty += 14;
    draw_text_shadow(_px + 10, _ty,
        "Saved:  " + string(_hero.history.deaths_avoided), COL.text_green);
    _ty += 14;
    draw_text_shadow(_px + 10, _ty,
        "Earned: " + string(_hero.history.gold_earned) + "g", COL.text_gold);

    // [10.11] Close button
    draw_set_halign(fa_right);
    draw_text_shadow(_px + _pw - 10, _py + 8, "X", COL.text_red);
    draw_set_halign(fa_left);
};

// ============================================================
// [11.0] JOB PANEL
// ============================================================
_draw_job_panel = function() {

    // [11.1] Safety check
    if (!show_job_panel) return;
    if (job_panel_hero_idx < 0) return;

    // [11.2] Job list
    var _jobs = [
        "Gatherer", "Warrior", "Archer", "Explorer",
        "Miner", "Guard", "Healer", "Wizard", "Rogue", "Paladin"
    ];

    // [11.3] Panel dimensions
    var _pw  = 200;
    var _ph  = array_length(_jobs) * 28 + 20;
    var _px  = SW - 270 - _pw - 10;
    var _py  = HUD.top_h + 10;

    // [11.4] Draw panel background
    draw_panel(_px, _py, _pw, _ph, COL.bg_panel, COL.border_gold);

    // [11.5] Title
    draw_set_halign(fa_center);
    draw_text_shadow(_px + _pw/2, _py + 6, "ASSIGN JOB", COL.text_gold);
    draw_set_halign(fa_left);

    // [11.6] Dapatkan job semasa — handle blueprint (string) vs instance (struct)
    var _raw         = gm.hero_roster[job_panel_hero_idx];
    var _current_job = is_string(_raw.job) ? _raw.job : _raw.job.current;

    // [11.7] Draw setiap job dalam list
    for (var i = 0; i < array_length(_jobs); i++) {
        var _job        = _jobs[i];
        var _jy         = _py + 24 + (i * 28);
        var _is_current = (_current_job == _job);

        // [11.7.1] Highlight job semasa
        if (_is_current) {
            draw_set_color(COL.border_gold);
            draw_set_alpha(0.2);
            draw_rectangle(_px + 5, _jy - 2,
                _px + _pw - 5, _jy + 22, false);
            draw_set_alpha(1.0);
        }

        // [11.7.2] Draw job label
        draw_text_shadow(_px + 15, _jy, _job,
            _is_current ? COL.text_gold : COL.text_white);
    }
};

// ============================================================
// [12.0] WAREHOUSE PANEL
// ============================================================
_draw_warehouse_panel = function() {
    if (!instance_exists(obj_warehouse)) return;

    var _pw = 280;
    var _ph = 380;
    var _px = 10;
    var _py = HUD.top_h + 10;

    draw_panel(_px, _py, _pw, _ph, COL.bg_panel, COL.border_gold);

    // [12.1] Title
    draw_set_halign(fa_center);
    draw_text_shadow(_px + _pw/2, _py + 10, "WAREHOUSE", COL.text_gold);
    draw_set_halign(fa_left);

    draw_set_color(COL.border);
    draw_line(_px + 8, _py + 30, _px + _pw - 8, _py + 30);

    // [12.2] Resource list
    var _ty   = _py + 38;
    var _data = obj_warehouse.get_all_status();

    for (var i = 0; i < array_length(_data); i++) {
        var _r = _data[i];

        draw_text_shadow(_px + 10, _ty, _r.resource, COL.text_white);

        draw_bar(_px + 100, _ty + 2, 100, 10, _r.ratio,
            _r.is_scarce ? COL.text_red : COL.text_green,
            COL.bar_bg);

        draw_set_halign(fa_right);
        draw_text_shadow(_px + _pw - 10, _ty,
            string(_r.amount) + "/" + string(_r.cap)
            + "  " + string(_r.price) + "g",
            _r.is_scarce ? COL.text_red : COL.text_grey);
        draw_set_halign(fa_left);

        _ty += 18;
        if (_ty > _py + _ph - 20) break;
    }

    // [12.3] Close button
    draw_set_halign(fa_right);
    draw_text_shadow(_px + _pw - 10, _py + 8, "X", COL.text_red);
    draw_set_halign(fa_left);
};

// ============================================================
// [13.0] BLACKSMITH PANEL
// ============================================================
_draw_blacksmith_panel = function() {
    if (!instance_exists(obj_blacksmith)) return;

    var _pw = 360;
    var _ph = 580;
    var _px = 10;
    var _py = HUD.top_h + 10;

    draw_panel(_px, _py, _pw, _ph, COL.bg_panel, COL.border_gold);

    // [13.1] Title
    draw_set_halign(fa_center);
    draw_text_shadow(_px + _pw/2, _py + 10, "BLACKSMITH", COL.text_gold);
    draw_set_halign(fa_left);

    draw_set_color(COL.border);
    draw_line(_px + 8, _py + 30, _px + _pw - 8, _py + 30);

    // [13.2] Recipe list
    var _data   = obj_blacksmith.get_ui_data();
    var _ty     = _py + 38;
    var _row_h  = 18;
    var _ing_h  = 16;
    var _btn_h  = 30;
    var _div_h  = 12;
    var _pad    = 8;
    var _limit  = _py + _ph - 65;

    for (var i = 0; i < array_length(_data.recipes); i++) {
        var _r       = _data.recipes[i];
        var _num_ing = array_length(_r.ingredients);
        var _entry_h = _row_h + (_num_ing * _ing_h) + _pad + _btn_h + _div_h;

        if (_ty + _entry_h > _limit) break;

        // [13.2.1] Recipe name
        draw_text_shadow(_px + 10, _ty, _r.name,
            _r.can_craft ? COL.text_gold : COL.text_grey);
        _ty += _row_h;

        // [13.2.2] Ingredients
        for (var j = 0; j < _num_ing; j++) {
            var _ing     = _r.ingredients[j];
            var _wh_amt  = instance_exists(obj_warehouse)
                         ? (obj_warehouse.storage[$ _ing.type] ?? 0)
                         : 0;
            var _ing_col = (_wh_amt >= _ing.amount)
                         ? COL.text_green : COL.text_red;
            draw_text_shadow(_px + 16, _ty,
                _ing.type + ": " + string(_wh_amt)
                + "/" + string(_ing.amount), _ing_col);
            _ty += _ing_h;
        }

        // [13.2.3] Padding sebelum button
        _ty += _pad;

        // [13.2.4] Craft button
        draw_panel(_px + 10, _ty, _pw - 20, 22,
            _r.can_craft ? COL.bg_panel2 : COL.bg_dark,
            _r.can_craft ? COL.border_gold : COL.border);
        draw_set_halign(fa_center);
        draw_text_shadow(_px + _pw/2, _ty + 5,
            "CRAFT — " + string(_r.price) + "g",
            _r.can_craft ? COL.text_gold : COL.text_grey);
        draw_set_halign(fa_left);
        _ty += _btn_h;

        // [13.2.5] Divider
        draw_set_color(COL.border);
        draw_line(_px + 8, _ty, _px + _pw - 8, _ty);
        _ty += _div_h;
    }

    // [13.3] Queue status
    if (_data.is_crafting && array_length(_data.queue) > 0) {
        var _q      = _data.queue[0];
        var _recipe = obj_blacksmith.RECIPES[$ _q.recipe_key];
        var _pct    = _q.timer / _recipe.craft_time;

        draw_set_color(COL.border);
        draw_line(_px + 8, _py + _ph - 35,
                  _px + _pw - 8, _py + _ph - 35);
        draw_text_shadow(_px + 10, _py + _ph - 28,
            "Crafting: " + _recipe.name, COL.text_white);
        draw_bar(_px + 10, _py + _ph - 14,
                 _pw - 20, 8, _pct,
                 COL.text_gold, COL.bar_bg);
    }

    // [13.4] Close button
    draw_set_halign(fa_right);
    draw_text_shadow(_px + _pw - 10, _py + 8, "X", COL.text_red);
    draw_set_halign(fa_left);
};

// ============================================================
// [14.0] NOTIFICATIONS
// ============================================================
_draw_notifications = function() {
    var _nx = SW / 2;
    var _ny = HUD.top_h + 20;

    for (var i = array_length(notifications) - 1; i >= 0; i--) {
        var _n   = notifications[i];
        _n.timer--;

        if (_n.timer <= 0) {
            array_delete(notifications, i, 1);
            continue;
        }

        var _alpha = clamp(_n.timer / (room_speed * 0.5), 0, 1);
        draw_set_alpha(_alpha);
        draw_set_halign(fa_center);
        draw_text_shadow(_nx, _ny, _n.message, _n.colour);
        draw_set_halign(fa_left);
        draw_set_alpha(1.0);

        _ny += 22;
    }
};

// ============================================================
// [15.0] POTION SHOP PANEL
// ============================================================
_draw_potion_shop_panel = function() {
    if (!instance_exists(obj_potion_shop)) return;

    var _pw = 280;
    var _ph = 280;
    var _px = 10;
    var _py = HUD.top_h + 10;

    draw_panel(_px, _py, _pw, _ph, COL.bg_panel, COL.border_gold);

    // [15.1] Title
    draw_set_halign(fa_center);
    draw_text_shadow(_px + _pw/2, _py + 10, "POTION SHOP", COL.text_gold);
    draw_set_halign(fa_left);

    draw_set_color(COL.border);
    draw_line(_px + 8, _py + 30, _px + _pw - 8, _py + 30);

    // [15.2] Gold display
    var _gold_str = "Gold: " + string(obj_game_manager.kingdom.treasury) + "g";
    draw_text_shadow(_px + 10, _py + 40, _gold_str, COL.text_gold);

    // [15.3] Potion list
    var _data = obj_potion_shop.get_ui_data();
    var _ty   = _py + 60;

    for (var i = 0; i < array_length(_data.potions); i++) {
        var _p = _data.potions[i];

        // [15.3.1] Potion name + cost
        draw_text_shadow(_px + 10, _ty, _p.name + " — " + string(_p.cost) + "g",
            _p.can_buy ? COL.text_white : COL.text_grey);
        _ty += 16;

        // [15.3.2] Description
        draw_text_shadow(_px + 10, _ty, _p.description,
            COL.text_grey);
        _ty += 14;

        // [15.3.3] Buy button
        draw_panel(_px + 10, _ty, _pw - 20, 24,
            _p.can_buy ? COL.bg_panel2 : COL.bg_dark,
            _p.can_buy ? COL.border_gold : COL.border);
        draw_set_halign(fa_center);
        draw_text_shadow(_px + _pw/2, _ty + 6, "BUY",
            _p.can_buy ? COL.text_gold : COL.text_grey);
        draw_set_halign(fa_left);
        _ty += 32;

        if (_ty > _py + _ph - 20) break;
    }

    // [15.4] Close button
    draw_set_halign(fa_right);
    draw_text_shadow(_px + _pw - 10, _py + 8, "X", COL.text_red);
    draw_set_halign(fa_left);
};