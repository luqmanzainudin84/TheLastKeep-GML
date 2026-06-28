// ============================================================
// obj_wave_manager — Create Event
// ============================================================

// [1.1] Rujukan ke game manager
gm = obj_game_manager;

// [1.X] Announcement flags (selepas existing initialization)
announced_wave_start = false
announced_wave_complete = false
announced_boss_wave = false

// ============================================================
// [2.0] WAVE STATE ENUM
// ============================================================
WAVE_STATE = {
    WAITING  : 0,
    ACTIVE   : 1,
    BOSS     : 2,
    COOLDOWN : 3,
};

// ============================================================
// [3.0] WAVE STATE
// ============================================================
state          = WAVE_STATE.WAITING;
current_wave   = 0;
current_season = 1;
enemies_alive  = 0;
wave_reward    = 0;

// [3.1] Wave timer — mula countdown selepas hero pertama recruit
wave_interval  = room_speed * 30; // 30 saat selepas recruit
wave_timer     = wave_interval;
_wave_can_start = false;          // flag — tunggu hero dulu

// ============================================================
// [4.0] SEASON SYSTEM
// ============================================================

// [4.1] Tentukan season berdasarkan wave
get_current_season = function(_wave) {
    if (_wave <= 10) return 1;
    if (_wave <= 25) return 2;
    if (_wave <= 45) return 3;
    if (_wave <= 70) return 4;
    return 5;
};

// [4.2] Semak sama ada boss wave
is_boss_wave = function(_wave) {
    return (_wave == 10 || _wave == 25
         || _wave == 45 || _wave == 70);
};

// ============================================================
// [5.0] DIFFICULTY SCALING
// ============================================================
get_difficulty_scale = function(_wave) {
    return {
        hp_mult    : 1.0 + (_wave * 0.05),
        dmg_mult   : 1.0 + (_wave * 0.03),
        count_mult : 1.0 + (_wave * 0.02),
        speed_mult : min(1.5, 1.0 + (_wave * 0.008)),
    };
};

// ============================================================
// [6.0] WAVE INTERVAL SCALING
// ============================================================
get_wave_interval = function(_season) {
    switch (_season) {
        case 1: return gm.TIME.ticks_per_day * 3;
        case 2: return gm.TIME.ticks_per_day * 2;
        case 3: return gm.TIME.ticks_per_day * 1;
        case 4: return gm.TIME.ticks_per_hour * 12;
        default: return gm.TIME.ticks_per_hour * 6;
    }
};

// ============================================================
// [7.0] WAVE CONFIG
// ============================================================
get_wave_config = function(_wave, _season) {
    var _scale     = get_difficulty_scale(_wave);
    var _is_boss   = is_boss_wave(_wave);
    var _base_count = floor(3 + (_wave * 0.8));
    var _count      = floor(_base_count * _scale.count_mult);

    // [7.1] Enemy types berdasarkan season
    var _types = [];
    switch (_season) {
        case 1:
            _types = ["goblin", "bandit"];
        break;
        case 2:
            _types = ["orc", "bandit_archer", "goblin"];
        break;
        case 3:
            _types = ["orc_warrior", "dark_mage", "troll"];
        break;
        case 4:
            _types = ["orc_warrior", "dragon_spawn", "dark_mage"];
        break;
        default:
            _types = ["orc_warrior", "dark_mage", "dragon_spawn",
                      "troll", "bandit_archer"];
        break;
    }

    // [7.2] Boss type
    var _boss_type = "";
    if (_is_boss) {
        switch (_season) {
            case 1: _boss_type = "bandit_warlord";   break;
            case 2: _boss_type = "orc_siege_leader"; break;
            case 3: _boss_type = "lich";             break;
            case 4: _boss_type = "elder_dragon";     break;
            default: _boss_type = "void_titan";      break;
        }
    }

    return {
        wave        : _wave,
        season      : _season,
        enemy_types : _types,
        enemy_count : _count,
        is_boss     : _is_boss,
        boss_type   : _boss_type,
        scale       : _scale,
        reward      : floor(50 + (_wave * 20)),
    };
};

// ============================================================
// [8.0] RANDOM EVENT SYSTEM
// ============================================================
RANDOM_EVENTS = [
    { name: "Plague",       desc: "All heroes suffer reduced max HP.", effect: "plague"      },
    { name: "Drought",      desc: "Food resource output halved.",      effect: "drought"     },
    { name: "Gold Rush",    desc: "Resources doubled, more enemies.",  effect: "gold_rush"   },
    { name: "Desertion",    desc: "Low morale heroes may leave.",      effect: "desertion"   },
    { name: "Hero Legend",  desc: "One hero gains permanent boost.",   effect: "hero_legend" },
    { name: "Siege Engines",desc: "Enemies target buildings first.",   effect: "siege_mode"  },
];

active_event   = undefined;
event_duration = 0;

trigger_random_event = function() {
    var _idx       = irandom(array_length(RANDOM_EVENTS) - 1);
    active_event   = RANDOM_EVENTS[_idx];
    event_duration = 5;

    show_debug_message("[WAVE EVENT] " + active_event.name
        + ": " + active_event.desc);

    // [8.1] Apply hero_legend effect
    if (active_event.effect == "hero_legend") {
        if (array_length(gm.hero_roster) > 0) {
            var _idx2 = irandom(array_length(gm.hero_roster) - 1);
            var _hero = gm.hero_roster[_idx2];
            _hero.base_stats.strength     += irandom_range(2, 5);
            _hero.base_stats.intelligence += irandom_range(2, 5);
            _hero.base_stats.agility      += irandom_range(2, 5);
            show_debug_message("[WAVE EVENT] " + _hero.name + " has been blessed!");
        }
    }
};

// ============================================================
// [9.0] SPAWN SYSTEM
// ============================================================

// [9.1] Dapatkan spawn positions dari tepi map
_get_edge_spawn_positions = function(_count) {
    var _cfg   = obj_map_manager.config;
    var _cx    = _cfg.start_col * _cfg.cell_size;
    var _cy    = _cfg.start_row * _cfg.cell_size;
    var _r     = 350;
    var _map_w = _cfg.cols * _cfg.cell_size;
    var _map_h = _cfg.rows * _cfg.cell_size;

    var _positions = [];
    var _angles    = [0, 90, 180, 270];

    for (var i = 0; i < _count; i++) {
        var _angle = _angles[i mod 4];
        var _px    = clamp(_cx + lengthdir_x(_r, _angle), 64, _map_w - 64);
        var _py    = clamp(_cy + lengthdir_y(_r, _angle), 64, _map_h - 64);
        array_push(_positions, { x: _px, y: _py });
    }

    return _positions;
};

// [9.2] Spawn enemies
_spawn_enemies = function(_config) {
    var _sc            = _config.scale;
    var _spawn_positions = _get_edge_spawn_positions(4);

    // [9.2.1] Spawn regular enemies
    for (var i = 0; i < _config.enemy_count; i++) {
        var _spawn = _spawn_positions[i mod array_length(_spawn_positions)];
        var _type  = _config.enemy_types[
            irandom(array_length(_config.enemy_types) - 1)
        ];

        var _wx = clamp(_spawn.x + irandom_range(-20, 20), 32,
                  obj_map_manager.config.cols * obj_map_manager.config.cell_size - 32);
        var _wy = clamp(_spawn.y + irandom_range(-20, 20), 32,
                  obj_map_manager.config.rows * obj_map_manager.config.cell_size - 32);

        if (layer_exists("Enemies")) {
            var _inst = instance_create_layer(_wx, _wy, "Enemies", obj_enemy);
            _inst.init_enemy(_type, _sc);
            enemies_alive++;
            show_debug_message("[WAVE] Spawned: " + _type
                + " at " + string(floor(_wx)) + "," + string(floor(_wy)));
        } else {
            show_debug_message("[WAVE] ERROR: Layer Enemies not found!");
        }
    }

    // [9.2.2] Spawn boss
    if (_config.is_boss && _config.boss_type != "") {
        var _spawn = _spawn_positions[0];
        if (layer_exists("Enemies")) {
            var _boss     = instance_create_layer(
                _spawn.x, _spawn.y, "Enemies", obj_enemy);
            _boss.init_enemy(_config.boss_type, _sc);
            _boss.is_boss = true;
            enemies_alive++;
            show_debug_message("[WAVE] BOSS spawned: " + _config.boss_type);
        }
    }
};

// ============================================================
// [10.0] WAVE CONTROL
// ============================================================

// [10.1] Start wave
start_wave = function() {
    current_wave++;
    current_season = get_current_season(current_wave);

    var _config   = get_wave_config(current_wave, current_season);
    wave_reward   = _config.reward;
    enemies_alive = 0;

    gm.wave.current   = current_wave;
    gm.wave.season    = current_season;
    gm.wave.is_active = true;

    // [10.1.1] Random event setiap 10 wave
    if (current_wave mod 10 == 0) {
        trigger_random_event();
    }

    // [10.1.2] Kurangkan event duration
    if (!is_undefined(active_event)) {
        event_duration--;
        if (event_duration <= 0) active_event = undefined;
    }

    state = _config.is_boss ? WAVE_STATE.BOSS : WAVE_STATE.ACTIVE;

    show_debug_message("[WAVE] === WAVE " + string(current_wave)
        + " START === Season " + string(current_season)
        + " | Enemies: " + string(_config.enemy_count)
        + (_config.is_boss ? " | BOSS: " + _config.boss_type : ""));

    _spawn_enemies(_config);

    wave_interval = get_wave_interval(current_season);
};

// [10.2] Wave complete
_complete_wave = function() {
	gm.wave.is_active = false;
	state             = WAVE_STATE.COOLDOWN;
	wave_timer        = wave_interval;

	gm.kingdom.treasury += wave_reward;

	// [10.2.1] Announcement - Wave Complete
	if (instance_exists(obj_announcement_manager)) {
		obj_announcement_manager.add_announcement(
			"WAVE COMPLETE!",
			global.ANNOUNCE_COLOR.GREEN,
			1.5,
			"wave_complete_chime"
		)
	}
	announced_wave_complete = true

	show_debug_message("[WAVE] Wave " + string(current_wave)
		+ " complete! Reward: " + string(wave_reward) + "g"
		+ " | Treasury: " + string(gm.kingdom.treasury) + "g");
};

// [10.3] Enemy death notification
on_enemy_death = function() {
    enemies_alive = max(0, enemies_alive - 1);
    if (enemies_alive <= 0) {
        _complete_wave();
    }
};

// ============================================================
// [11.0] UI DATA
// ============================================================
get_ui_data = function() {
    return {
        wave          : current_wave,
        season        : current_season,
        state         : state,
        is_active     : (state == WAVE_STATE.ACTIVE || state == WAVE_STATE.BOSS),
        is_boss       : (state == WAVE_STATE.BOSS),
        enemies_alive : enemies_alive,
        wave_timer    : wave_timer,
        wave_interval : wave_interval,
        countdown_pct : (wave_timer / wave_interval),
        active_event  : active_event,
        next_reward   : floor(50 + ((current_wave + 1) * 20)),
    };
};