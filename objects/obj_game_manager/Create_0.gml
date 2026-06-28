// ============================================================
// obj_game_manager — Create Event
// Master controller untuk The Last Keep
// ============================================================

// [1.0] GLOBAL VARIABLES
if (!variable_global_exists("legacy_hero"))     global.legacy_hero     = undefined;
if (!variable_global_exists("legacy_item"))     global.legacy_item     = undefined;
if (!variable_global_exists("last_score"))      global.last_score      = 0;
if (!variable_global_exists("last_wave"))       global.last_wave       = 0;
if (!variable_global_exists("last_season"))     global.last_season     = 0;
if (!variable_global_exists("hall_of_fallen"))  global.hall_of_fallen  = [];
if (!variable_global_exists("score_breakdown")) global.score_breakdown = undefined;
if (!variable_global_exists("surviving_heroes"))global.surviving_heroes= [];

// [1.1] Safety check — hanya satu game manager
if (instance_number(obj_game_manager) > 1) {
    instance_destroy();
    exit;
}

// ============================================================
// [2.0] TIME SYSTEM CONSTANTS
// ============================================================
TIME = {
    TICKS_PER_HOUR  : 600,
    HOURS_PER_DAY   : 24,
    DAYS_PER_WEEK   : 7,
    WEEKS_PER_MONTH : 4,
    ticks_per_day   : 0,
    ticks_per_week  : 0,
    ticks_per_month : 0,
    ticks_per_salary: 0,
    ticks_per_hour  : 600,
};

// [2.1] Kira derived time values
TIME.ticks_per_day    = TIME.TICKS_PER_HOUR  * TIME.HOURS_PER_DAY;
TIME.ticks_per_week   = TIME.ticks_per_day   * TIME.DAYS_PER_WEEK;
TIME.ticks_per_month  = TIME.ticks_per_week  * TIME.WEEKS_PER_MONTH;
TIME.ticks_per_salary = floor(TIME.ticks_per_month / 2);

// ============================================================
// [3.0] CALENDAR STATE
// ============================================================
calendar = {
    tick             : 0,
    hour             : 6,
    day              : 1,
    week             : 1,
    month            : 1,
    last_salary_tick : 0,
    last_day_tick    : 0,
    last_week_tick   : 0,
    last_month_tick  : 0,
};

// [4.0] KINGDOM STATE
kingdom = {
    name                 : "The Last Keep",
    th_level             : 1,
    hero_slots           : 1,
    treasury             : 2000,
    salary_rate          : 50,
    is_bankrupt          : false,
    total_days_survived  : 0,
    total_gold_earned    : 0,
    total_heroes_lost    : 0,
};

// ============================================================
// [5.0] WAVE & SEASON STATE
// ============================================================
wave = {
    current                 : 0,
    season                  : 1,
    is_active               : false,
    next_wave_tick          : 0,
    enemy_hp_multiplier     : 1.0,
    enemy_count_multiplier  : 1.0,
    enemy_damage_multiplier : 1.0,
};

// ============================================================
// [6.0] HERO ROSTER
// ============================================================
hero_roster = [];

// ============================================================
// [7.0] TIME TRIGGER CALLBACKS
// ============================================================
on_new_day    = [];
on_new_week   = [];
on_salary_day = [];
on_new_month  = [];

// [7.1] Register callback functions
register_daily_callback = function(_func) {
    array_push(on_new_day, _func);
};
register_weekly_callback = function(_func) {
    array_push(on_new_week, _func);
};
register_salary_callback = function(_func) {
    array_push(on_salary_day, _func);
};
register_monthly_callback = function(_func) {
    array_push(on_new_month, _func);
};

// ============================================================
// [8.0] TIME SYSTEM UPDATE
// ============================================================
_trigger_callbacks = function(_callback_array) {
    for (var i = 0; i < array_length(_callback_array); i++) {
        _callback_array[i]();
    }
};

update_time = function() {
    calendar.tick++;

    // [8.1] Kira hour semasa
    calendar.hour = floor(
        (calendar.tick mod TIME.ticks_per_day) / TIME.TICKS_PER_HOUR
    );

    // [8.2] Daily trigger
    if (calendar.tick - calendar.last_day_tick >= TIME.ticks_per_day) {
        calendar.last_day_tick = calendar.tick;
        calendar.day++;
        kingdom.total_days_survived++;

        // [8.2.1] Weekly trigger
        if (calendar.day > TIME.DAYS_PER_WEEK * calendar.week) {
            calendar.week++;
            _trigger_callbacks(on_new_week);

            // [8.2.2] Monthly trigger
            if (calendar.week > TIME.WEEKS_PER_MONTH * calendar.month) {
                calendar.month++;
                _trigger_callbacks(on_new_month);
            }
        }
        _trigger_callbacks(on_new_day);
    }

    // [8.3] Salary trigger 2x sebulan
    if (calendar.tick - calendar.last_salary_tick >= TIME.ticks_per_salary) {
        calendar.last_salary_tick = calendar.tick;
        _process_salary();
    }
};

// ============================================================
// [9.0] SALARY SYSTEM
// ============================================================
_process_salary = function() {
    var _total_salary = array_length(hero_roster) * kingdom.salary_rate;

    if (kingdom.treasury >= _total_salary) {
        kingdom.treasury -= _total_salary;
        for (var i = 0; i < array_length(hero_roster); i++) {
            hero_roster[i].gold += kingdom.salary_rate;
        }
        kingdom.is_bankrupt = false;
        show_debug_message("[SALARY] Paid " + string(_total_salary) + "g to "
            + string(array_length(hero_roster)) + " heroes.");
    } else {
        // [9.1] Salary crisis
        kingdom.is_bankrupt = true;
        if (array_length(hero_roster) > 0) {
            var _per_hero        = floor(kingdom.treasury / array_length(hero_roster));
            kingdom.treasury     = 0;
            for (var i = 0; i < array_length(hero_roster); i++) {
                hero_roster[i].gold += _per_hero;
            }
        }
        show_debug_message("[SALARY CRISIS] Treasury insufficient!");
    }
};

// ============================================================
// [10.0] KINGDOM MANAGEMENT
// ============================================================

// [10.1] Upgrade townhall
upgrade_townhall = function() {
    if (kingdom.th_level >= 10) return false;
    kingdom.th_level++;
    kingdom.hero_slots = kingdom.th_level;
    show_debug_message("[TH] Upgraded to level " + string(kingdom.th_level));
    return true;
};

// [10.2] Tambah hero ke roster
add_hero_to_roster = function(_hero_blueprint) {
    if (array_length(hero_roster) >= kingdom.hero_slots) {
        show_debug_message("[ROSTER] No available slots.");
        return false;
    }
    array_push(hero_roster, _hero_blueprint);
    show_debug_message("[ROSTER] " + _hero_blueprint.name + " joined the kingdom.");
    return true;
};

// [10.3] Buang hero dari roster
remove_hero_from_roster = function(_hero_name) {
    for (var i = 0; i < array_length(hero_roster); i++) {
        if (hero_roster[i].name == _hero_name) {
            array_delete(hero_roster, i, 1);
            kingdom.total_heroes_lost++;
            show_debug_message("[ROSTER] " + _hero_name + " removed.");
            return true;
        }
    }
    return false;
};

// [10.4] Semak roster penuh
is_roster_full = function() {
    return array_length(hero_roster) >= kingdom.hero_slots;
};

// ============================================================
// [11.0] DIFFICULTY SCALING
// ============================================================
_scale_difficulty = function() {
    wave.enemy_hp_multiplier     += 0.05;
    wave.enemy_count_multiplier  += 0.02;
    wave.enemy_damage_multiplier += 0.03;
    show_debug_message("[DIFFICULTY] Week " + string(calendar.week)
        + " | HP: x" + string(wave.enemy_hp_multiplier));
};

register_weekly_callback(_scale_difficulty);

// ============================================================
// [12.0] GAME OVER
// ============================================================

// [12.1] Semak game over
check_game_over = function() {
    if (array_length(hero_roster) == 0
    &&  kingdom.treasury < 50) {
        _trigger_game_over();
    }
};

// [12.2] Trigger game over
_trigger_game_over = function() {
    var _final_score = calculate_score();

    global.surviving_heroes = [];
    for (var i = 0; i < array_length(hero_roster); i++) {
        array_push(global.surviving_heroes, hero_roster[i]);
    }

    global.last_score      = _final_score;
    global.last_wave       = wave.current;
    global.last_season     = wave.season;
    global.hall_of_fallen  = hall_of_fallen;
    global.score_breakdown = calculate_score_breakdown();

    delete_run_save();

    show_debug_message("[GAME OVER] Score: " + string(_final_score)
        + " | Wave: " + string(wave.current));

    room_goto(rm_game_over);
};

// ============================================================
// [13.0] SCORE SYSTEM
// ============================================================

// [13.1] Kira score breakdown
calculate_score_breakdown = function() {
    var _wave_score     = wave.current * 1000;
    var _season_score   = (wave.season - 1) * 5000;
    var _day_score      = kingdom.total_days_survived * 100;
    var _hero_bonus     = array_length(hero_roster) * 500;
    var _treasury_bonus = floor(kingdom.treasury * 0.5);
    var _title_bonus    = 0;

    for (var i = 0; i < array_length(hero_roster); i++) {
        _title_bonus += array_length(hero_roster[i].titles) * 200;
    }

    var _death_penalty    = kingdom.total_heroes_lost * 300;
    var _bankrupt_penalty = kingdom.is_bankrupt ? 1000 : 0;

    return {
        wave_score       : _wave_score,
        season_score     : _season_score,
        day_score        : _day_score,
        hero_bonus       : _hero_bonus,
        treasury_bonus   : _treasury_bonus,
        title_bonus      : _title_bonus,
        death_penalty    : _death_penalty,
        bankrupt_penalty : _bankrupt_penalty,
        final            : max(0, _wave_score + _season_score
                            + _day_score + _hero_bonus
                            + _treasury_bonus + _title_bonus
                            - _death_penalty - _bankrupt_penalty),
    };
};

// [13.2] Kira score ringkas
calculate_score = function() {
    var _breakdown = calculate_score_breakdown();
    return _breakdown.final;
};

// [13.3] Build leaderboard entry
build_leaderboard_entry = function(_player_name) {
    var _score          = calculate_score();
    var _best_hero_name = "None";

    if (array_length(hero_roster) > 0) {
        _best_hero_name = hero_roster[0].name;
    } else if (array_length(hall_of_fallen) > 0) {
        _best_hero_name = hall_of_fallen[0].name;
    }

    return {
        player_name   : _player_name,
        score         : _score,
        wave          : wave.current,
        season        : wave.season,
        days_survived : kingdom.total_days_survived,
        heroes_lost   : kingdom.total_heroes_lost,
        legacy_hero   : _best_hero_name,
        timestamp     : string(current_year) + "-"
                      + string(current_month) + "-"
                      + string(current_day),
    };
};

// ============================================================
// [14.0] HALL OF THE FALLEN
// ============================================================
hall_of_fallen = [];

add_to_hall = function(_hero_blueprint, _wave_died, _kills) {
    array_push(hall_of_fallen, {
        name      : _hero_blueprint.name,
        rarity    : _hero_blueprint.rarity,
        titles    : _hero_blueprint.titles,
        wave_died : _wave_died,
        kills     : _kills,
        history   : _hero_blueprint.history,
    });
    show_debug_message("[HALL] " + _hero_blueprint.name
        + " added to Hall of the Fallen."
        + " Died on wave " + string(_wave_died));
};

// ============================================================
// [15.0] LEGACY SYSTEM
// ============================================================
legacy = {
    owner         : id,
    selected_hero : undefined,
    selected_item : undefined,

    get_candidates : function() {
        return owner.hero_roster;
    },

    select_hero : function(_hero_blueprint, _item) {
        selected_hero = _hero_blueprint;
        selected_item = _item;
        selected_hero.is_legacy = true;
        array_push(selected_hero.titles, "The Undying Legacy");
        show_debug_message("[LEGACY] Selected: " + selected_hero.name);
    },

    save : function() {
        if (is_undefined(selected_hero)) return;
        global.legacy_hero = selected_hero;
        global.legacy_item = selected_item;
        show_debug_message("[LEGACY] Saved: " + selected_hero.name);
    },
};

// ============================================================
// [16.0] CAMERA SYSTEM
// ============================================================
cam = {
    x            : 0,
    y            : 0,
    target_x     : 0,
    target_y     : 0,
    smooth_speed : 0.15,
    scroll_speed : 8,
    edge_margin  : 5,
    map_w        : 64 * 32,
    map_h        : 64 * 32,
    view_w       : 1280,
    view_h       : 720,
    is_dragging  : false,
    drag_start_x : 0,
    drag_start_y : 0,
    drag_cam_x   : 0,
    drag_cam_y   : 0,

    clamp_position : function() {
        target_x = clamp(target_x, 0, map_w - view_w);
        target_y = clamp(target_y, 0, map_h - view_h);
    },

    update : function() {
        var _mx           = device_mouse_x_to_gui(0);
        var _my           = device_mouse_y_to_gui(0);
        var _top_bar_h    = 40;
        var _bottom_bar_h = 50;
        var _in_ui        = (_my < _top_bar_h
                          || _my > view_h - _bottom_bar_h);

        // [16.1] Edge scrolling
        if (!is_dragging && !_in_ui) {
            if (_mx < edge_margin)                           target_x -= scroll_speed;
            if (_mx > view_w - edge_margin)                  target_x += scroll_speed;
            if (_my < edge_margin + _top_bar_h)              target_y -= scroll_speed;
            if (_my > view_h - edge_margin - _bottom_bar_h) target_y += scroll_speed;
        }

        // [16.2] Keyboard scroll
        var _kspd = scroll_speed * 1.5;
        if (keyboard_check(vk_left)  || keyboard_check(ord("A"))) target_x -= _kspd;
        if (keyboard_check(vk_right) || keyboard_check(ord("D"))) target_x += _kspd;
        if (keyboard_check(vk_up)    || keyboard_check(ord("W"))) target_y -= _kspd;
        if (keyboard_check(vk_down)  || keyboard_check(ord("S"))) target_y += _kspd;

        // [16.3] Middle mouse drag
        if (mouse_check_button_pressed(mb_middle)) {
            is_dragging  = true;
            drag_start_x = device_mouse_x_to_gui(0);
            drag_start_y = device_mouse_y_to_gui(0);
            drag_cam_x   = target_x;
            drag_cam_y   = target_y;
        }
        if (mouse_check_button_released(mb_middle)) {
            is_dragging = false;
        }
        if (is_dragging) {
            var _dx  = device_mouse_x_to_gui(0) - drag_start_x;
            var _dy  = device_mouse_y_to_gui(0) - drag_start_y;
            target_x = drag_cam_x - _dx;
            target_y = drag_cam_y - _dy;
        }

        // [16.4] Clamp dan lerp
        clamp_position();
        x = lerp(x, target_x, smooth_speed);
        y = lerp(y, target_y, smooth_speed);
        camera_set_view_pos(view_camera[0], floor(x), floor(y));
    },

    jump_to : function(_wx, _wy) {
        target_x = _wx - view_w / 2;
        target_y = _wy - view_h / 2;
        x        = target_x;
        y        = target_y;
        clamp_position();
        camera_set_view_pos(view_camera[0], floor(x), floor(y));
    },

    screen_to_world : function(_sx, _sy) {
        return { x: _sx + x, y: _sy + y };
    },

    world_to_screen : function(_wx, _wy) {
        return { x: _wx - x, y: _wy - y };
    },
};

// [16.5] Start camera di center map
cam.target_x = (64 * 32 / 2) - (1280 / 2);
cam.target_y = (64 * 32 / 2) - (720 / 2);
cam.x        = cam.target_x;
cam.y        = cam.target_y;
camera_set_view_pos(view_camera[0], floor(cam.x), floor(cam.y));

// ============================================================
// [17.0] SAVE SYSTEM
// ============================================================
save_timer    = 0;
save_interval = room_speed * 60 * 3;

// [17.1] Delayed load
_load_pending = true;
_load_timer   = 0;