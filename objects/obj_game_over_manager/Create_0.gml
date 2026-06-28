// ============================================================
// obj_game_over_manager — Create Event
// Standalone — tidak bergantung pada game objects
// ============================================================

// ============================================================
// SCREEN SIZE
// ============================================================
SW = display_get_gui_width();
SH = display_get_gui_height();

// ============================================================
// COLOURS (sama seperti obj_ui_manager)
// ============================================================
COL = {
    bg_dark      : make_color_rgb(12,  10,  15),
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
};

// ============================================================
// SCREEN STATES
// ============================================================
SCREEN = {
    FADE_IN      : 0,
    SCORE        : 1,
    LEGACY_SELECT: 2,
    HALL         : 3,
    FADE_OUT     : 4,
};

screen_state  = SCREEN.FADE_IN;
fade_alpha    = 1.0;
fade_timer    = 0;
fade_duration = 60; // 1 saat

// ============================================================
// DATA DARI GLOBAL
// ============================================================
final_score   = global.last_score  ?? 0;
final_wave    = global.last_wave   ?? 1;
final_season  = global.last_season ?? 1;
score_data    = global.score_breakdown ?? undefined;
hall_data     = global.hall_of_fallen  ?? [];

// Hero yang masih hidup semasa game over
// (diambil dari roster sebelum game objects destroy)
surviving_heroes = global.surviving_heroes ?? [];
selected_legacy  = -1;     // index dalam surviving_heroes
selected_item    = undefined;
show_hall        = false;

// ============================================================
// LEADERBOARD
// ============================================================
leaderboard = get_leaderboard();

// ============================================================
// HELPERS
// ============================================================
draw_panel = function(_x, _y, _w, _h, _bg, _border) {
    draw_set_color(_bg);
    draw_set_alpha(0.92);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_color(_border);
    draw_set_alpha(1.0);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
};

draw_text_shadow = function(_x, _y, _str, _col) {
    draw_set_color(COL.bg_dark);
    draw_text(_x + 1, _y + 1, _str);
    draw_set_color(_col);
    draw_text(_x, _y, _str);
};

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
// CONFIRM LEGACY — player dah pilih, proceed ke run baru
// ============================================================
confirm_legacy = function() {
    if (selected_legacy < 0
    ||  selected_legacy >= array_length(surviving_heroes)) {
        // Tiada hero dipilih — start fresh
        global.legacy_hero = undefined;
        global.legacy_item = undefined;
    } else {
        var _hero = surviving_heroes[selected_legacy];
        global.legacy_hero = _hero;
        global.legacy_item = selected_item;

        // Simpan ke legacy file
        save_legacy(
            _hero,
            selected_item,
            final_score,
            final_wave,
            final_season
        );
    }

    // Reset globals untuk run baru
    global.last_score         = 0;
    global.last_wave          = 0;
    global.last_season        = 0;
    global.surviving_heroes   = [];
    global.hall_of_fallen     = [];
    global.score_breakdown    = undefined;

    screen_state = SCREEN.FADE_OUT;
};

// ============================================================
// SKIP LEGACY — start fresh tanpa hero
// ============================================================
skip_legacy = function() {
    global.legacy_hero = undefined;
    global.legacy_item = undefined;

    save_legacy(
        undefined,
        undefined,
        final_score,
        final_wave,
        final_season
    );

    global.surviving_heroes = [];
    screen_state = SCREEN.FADE_OUT;
};

// ============================================================
// SCORE SCREEN
// ============================================================
_draw_score_screen = function() {
    // Title
    draw_set_halign(fa_center);
    draw_text_shadow(SW/2, 40, "THE LAST KEEP HAS FALLEN", COL.text_red);
    draw_set_halign(fa_left);

    // Score panel
    var _pw = 500;
    var _ph = 320;
    var _px = (SW - _pw) / 2;
    var _py = 90;

    draw_panel(_px, _py, _pw, _ph, COL.bg_panel, COL.border_gold);

    var _ty = _py + 15;

    // Final score
    draw_set_halign(fa_center);
    draw_text_shadow(SW/2, _ty, "FINAL SCORE", COL.text_grey);
    _ty += 20;
    draw_text_shadow(SW/2, _ty,
        string(final_score), COL.text_gold);
    draw_set_halign(fa_left);
    _ty += 30;

    // Divider
    draw_set_color(COL.border);
    draw_line(_px + 10, _ty, _px + _pw - 10, _ty);
    _ty += 10;

    // Wave & Season
    draw_text_shadow(_px + 20, _ty,
        "Wave Reached:", COL.text_grey);
    draw_set_halign(fa_right);
    draw_text_shadow(_px + _pw - 20, _ty,
        "Wave " + string(final_wave)
        + "  (Season " + string(final_season) + ")",
        COL.text_white);
    draw_set_halign(fa_left);
    _ty += 22;

    // Score breakdown kalau ada
    if (!is_undefined(score_data)) {
        var _items = [
            { label: "Wave Score",       val: score_data.wave_score,       col: COL.text_white },
            { label: "Season Bonus",     val: score_data.season_score,     col: COL.text_white },
            { label: "Survival Days",    val: score_data.day_score,        col: COL.text_white },
            { label: "Hero Bonus",       val: score_data.hero_bonus,       col: COL.text_green },
            { label: "Treasury Bonus",   val: score_data.treasury_bonus,   col: COL.text_green },
            { label: "Title Bonus",      val: score_data.title_bonus,      col: COL.text_gold  },
            { label: "Hero Deaths",      val: -score_data.death_penalty,   col: COL.text_red   },
            { label: "Bankruptcy",       val: -score_data.bankrupt_penalty,col: COL.text_red   },
        ];

        for (var i = 0; i < array_length(_items); i++) {
            var _item = _items[i];
            if (_item.val == 0) continue;

            draw_text_shadow(_px + 20, _ty, _item.label, COL.text_grey);
            draw_set_halign(fa_right);
            draw_text_shadow(_px + _pw - 20, _ty,
                (_item.val > 0 ? "+" : "") + string(_item.val),
                _item.col);
            draw_set_halign(fa_left);
            _ty += 20;
        }
    }

    // Butang
    var _btn_y = _py + _ph + 20;

    // Butang: Choose Legacy
    var _has_survivors = array_length(surviving_heroes) > 0;
    draw_panel((SW/2) - 210, _btn_y, 200, 40,
        _has_survivors ? COL.bg_panel2 : COL.bg_dark,
        _has_survivors ? COL.border_gold : COL.border);
    draw_set_halign(fa_center);
    draw_text_shadow(SW/2 - 110, _btn_y + 12,
        "CHOOSE LEGACY",
        _has_survivors ? COL.text_gold : COL.text_grey);

    // Butang: Hall of Fallen
    draw_panel((SW/2) + 10, _btn_y, 200, 40,
        COL.bg_panel2, COL.border_gold);
    draw_text_shadow(SW/2 + 110, _btn_y + 12,
        "HALL OF FALLEN", COL.text_white);
    draw_set_halign(fa_left);

    // Leaderboard (kanan)
    _draw_leaderboard_mini(_px + _pw + 20, _py);
};

// ============================================================
// LEADERBOARD MINI (dalam score screen)
// ============================================================
_draw_leaderboard_mini = function(_lx, _ly) {
    var _lw = 200;
    var _lh = 280;

    draw_panel(_lx, _ly, _lw, _lh, COL.bg_panel, COL.border_gold);

    draw_set_halign(fa_center);
    draw_text_shadow(_lx + _lw/2, _ly + 10, "TOP SCORES", COL.text_gold);
    draw_set_halign(fa_left);

    draw_set_color(COL.border);
    draw_line(_lx + 8, _ly + 28, _lx + _lw - 8, _ly + 28);

    var _ty = _ly + 35;

    for (var i = 0; i < min(8, array_length(leaderboard)); i++) {
        var _entry = leaderboard[i];
		var _col = COL.text_grey;
		if (i == 0)      _col = COL.text_gold;
		else if (i == 1) _col = COL.text_white;

        draw_text_shadow(_lx + 10, _ty,
            string(i+1) + ". " + string(_entry.score), _col);

        draw_set_halign(fa_right);
        draw_text_shadow(_lx + _lw - 8, _ty,
            "W" + string(_entry.wave), COL.text_grey);
        draw_set_halign(fa_left);

        // Legacy hero name kalau ada
        if (variable_struct_exists(_entry, "legacy_hero")
		&&  !is_undefined(_entry.legacy_hero)) {
            draw_text_shadow(_lx + 10, _ty + 12,
                _entry.legacy_hero.name, COL.text_grey);
        }

        _ty += 28;
        if (_ty > _ly + _lh - 10) break;
    }
};

// ============================================================
// LEGACY SELECTION SCREEN
// ============================================================
_draw_legacy_screen = function() {
    draw_set_halign(fa_center);
    draw_text_shadow(SW/2, 30, "CHOOSE YOUR LEGACY HERO", COL.text_gold);
    draw_text_shadow(SW/2, 55,
        "One hero will carry your legacy to the next run.",
        COL.text_grey);
    draw_set_halign(fa_left);

    if (array_length(surviving_heroes) == 0) {
        draw_set_halign(fa_center);
        draw_text_shadow(SW/2, SH/2,
            "No heroes survived.", COL.text_red);
        draw_set_halign(fa_left);

        // Butang Start Fresh
        var _bx = SW/2 - 100;
        var _by = SH/2 + 40;
        draw_panel(_bx, _by, 200, 40,
            COL.bg_panel2, COL.border_gold);
        draw_set_halign(fa_center);
        draw_text_shadow(_bx + 100, _by + 12,
            "START FRESH", COL.text_white);
        draw_set_halign(fa_left);
        return;
    }

    // Hero cards
    var _card_w     = 160;
    var _card_h     = 340;
    var _card_gap   = 15;
    var _total_w    = min(array_length(surviving_heroes), 5)
                    * (_card_w + _card_gap) - _card_gap;
    var _start_x    = (SW - _total_w) / 2;
    var _card_y     = 80;

    for (var i = 0; i < min(array_length(surviving_heroes), 5); i++) {
        var _hero = surviving_heroes[i];
        var _cx   = _start_x + (i * (_card_w + _card_gap));
        var _is_selected = (i == selected_legacy);
        var _rar_col = get_rarity_colour(_hero.rarity);

        // Highlight kalau selected
        if (_is_selected) {
            draw_set_color(COL.border_gold);
            draw_set_alpha(0.3);
            draw_rectangle(_cx - 4, _card_y - 4,
                _cx + _card_w + 4, _card_y + _card_h + 4, false);
            draw_set_alpha(1.0);
        }

        draw_panel(_cx, _card_y, _card_w, _card_h,
            COL.bg_panel2, _is_selected ? COL.border_gold : _rar_col);

        var _ty = _card_y + 10;

        // Nama
        draw_set_halign(fa_center);
        draw_text_shadow(_cx + _card_w/2, _ty, _hero.name, COL.text_white);
        _ty += 16;

        // Rarity
        draw_text_shadow(_cx + _card_w/2, _ty,
            "[" + _hero.rarity + "]", _rar_col);
        draw_set_halign(fa_left);
        _ty += 20;

        // Stats
        draw_set_color(COL.border);
        draw_line(_cx + 8, _ty, _cx + _card_w - 8, _ty);
        _ty += 8;

        draw_text_shadow(_cx + 10, _ty,
            "STR: " + string(_hero.base_stats.strength), COL.text_white);
        _ty += 14;
        draw_text_shadow(_cx + 10, _ty,
            "INT: " + string(_hero.base_stats.intelligence), COL.text_white);
        _ty += 14;
        draw_text_shadow(_cx + 10, _ty,
            "AGI: " + string(_hero.base_stats.agility), COL.text_white);
        _ty += 18;

        // Personality
        draw_set_color(COL.border);
        draw_line(_cx + 8, _ty, _cx + _card_w - 8, _ty);
        _ty += 8;

        draw_text_shadow(_cx + 10, _ty,
            "IQ: " + _hero.personality.iq_label, COL.text_grey);
        _ty += 14;
        draw_text_shadow(_cx + 10, _ty,
            _hero.personality.braveness_label, COL.text_grey);
        _ty += 14;
        draw_text_shadow(_cx + 10, _ty,
            _hero.personality.greed_label, COL.text_grey);
        _ty += 18;

        // History
        draw_set_color(COL.border);
        draw_line(_cx + 8, _ty, _cx + _card_w - 8, _ty);
        _ty += 8;

        draw_text_shadow(_cx + 10, _ty,
            "Kills: " + string(_hero.history.kills), COL.text_white);
        _ty += 14;
        draw_text_shadow(_cx + 10, _ty,
            "Saved: " + string(_hero.history.deaths_avoided),
            COL.text_green);
        _ty += 18;

        // Titles
        if (array_length(_hero.titles) > 0) {
            draw_text_shadow(_cx + 10, _ty,
                _hero.titles[0], COL.legendary);
            _ty += 14;
        }

        // SELECT button
        var _btn_y = _card_y + _card_h - 35;
        draw_panel(_cx + 8, _btn_y, _card_w - 16, 28,
            _is_selected ? COL.border_gold : COL.bg_dark,
            _is_selected ? COL.text_gold : COL.border);
        draw_set_halign(fa_center);
        draw_text_shadow(_cx + _card_w/2, _btn_y + 7,
            _is_selected ? "SELECTED" : "SELECT",
            _is_selected ? COL.bg_dark : COL.text_white);
        draw_set_halign(fa_left);
    }

    // Butang Confirm + Skip
    var _btn_y = _card_y + _card_h + 20;

    // Confirm (active kalau ada selection)
    var _can_confirm = (selected_legacy >= 0);
    draw_panel(SW/2 - 210, _btn_y, 190, 40,
        _can_confirm ? COL.bg_panel2 : COL.bg_dark,
        _can_confirm ? COL.border_gold : COL.border);
    draw_set_halign(fa_center);
    draw_text_shadow(SW/2 - 115, _btn_y + 12,
        "CONFIRM LEGACY",
        _can_confirm ? COL.text_gold : COL.text_grey);

    // Skip
    draw_panel(SW/2 + 20, _btn_y, 190, 40,
        COL.bg_panel2, COL.border);
    draw_text_shadow(SW/2 + 115, _btn_y + 12,
        "START FRESH", COL.text_white);
    draw_set_halign(fa_left);
};

// ============================================================
// HALL OF THE FALLEN
// ============================================================
_draw_hall_screen = function() {
    draw_set_halign(fa_center);
    draw_text_shadow(SW/2, 30,
        "HALL OF THE FALLEN", COL.text_gold);
    draw_text_shadow(SW/2, 55,
        "Heroes who gave their lives for The Last Keep.",
        COL.text_grey);
    draw_set_halign(fa_left);

    if (array_length(hall_data) == 0) {
        draw_set_halign(fa_center);
        draw_text_shadow(SW/2, SH/2,
            "No heroes fell this run.", COL.text_grey);
        draw_set_halign(fa_left);
    } else {
        var _cols     = 3;
        var _entry_w  = 380;
        var _entry_h  = 90;
        var _gap      = 10;
        var _start_x  = (SW - (_cols * (_entry_w + _gap))) / 2;
        var _start_y  = 80;

        for (var i = 0; i < min(array_length(hall_data), 9); i++) {
            var _fallen = hall_data[i];
            var _col    = i mod _cols;
            var _row    = floor(i / _cols);
            var _ex     = _start_x + _col * (_entry_w + _gap);
            var _ey     = _start_y + _row * (_entry_h + _gap);

            draw_panel(_ex, _ey, _entry_w, _entry_h,
                COL.bg_panel, COL.border);

            var _rar_col = get_rarity_colour(_fallen.rarity);

            draw_text_shadow(_ex + 10, _ey + 10,
                _fallen.name, COL.text_white);
            draw_text_shadow(_ex + 10, _ey + 26,
                "[" + _fallen.rarity + "]", _rar_col);

            draw_text_shadow(_ex + 150, _ey + 10,
                "Died: Wave " + string(_fallen.wave_died),
                COL.text_red);
            draw_text_shadow(_ex + 150, _ey + 26,
                "Kills: " + string(_fallen.kills),
                COL.text_grey);

            // Titles
            if (array_length(_fallen.titles) > 0) {
                draw_text_shadow(_ex + 10, _ey + 58,
                    _fallen.titles[0], COL.legendary);
            }
        }
    }

    // Back button
    var _bx = SW/2 - 80;
    var _by = SH - 70;
    draw_panel(_bx, _by, 160, 40,
        COL.bg_panel2, COL.border_gold);
    draw_set_halign(fa_center);
    draw_text_shadow(_bx + 80, _by + 12, "BACK", COL.text_white);
    draw_set_halign(fa_left);
};