// ============================================================
// obj_tavern — Create Event
// Hero recruitment hub untuk The Last Keep
// ============================================================

// [1.1] Rujukan ke game manager
gm = obj_game_manager;

// [1.2] Delayed init flag
_ready = false;

// ============================================================
// [2.0] RECRUIT COST TABLE
// ============================================================
recruit_cost = {
    Common    : 50,
    Uncommon  : 120,
    Rare      : 250,
    Legendary : 500,
};

// ============================================================
// [3.0] TAVERN STATE MACHINE
// ============================================================
TAVERN_STATE = {
    IDLE        : 0,
    OPEN        : 1,
    REFRESHING  : 2,
    HERO_PICKED : 3,
};

state         = TAVERN_STATE.IDLE;
is_first_open = true;

// ============================================================
// [4.0] AVAILABLE HEROES
// ============================================================
available_heroes = [];
used_names       = [];
refresh_count    = 0;
selected_index   = -1;

// ============================================================
// [5.0] REFRESH COST
// ============================================================

// [5.1] Kira kos refresh
get_refresh_cost = function() {
    if (refresh_count == 0) return 0;
    return min(80, floor(10 * power(refresh_count, 1.3)));
};

// [5.2] Semak boleh refresh
can_refresh = function() {
    var _cost = get_refresh_cost();
    return gm.kingdom.treasury >= _cost;
};

// ============================================================
// [6.0] HERO GENERATION
// ============================================================
generate_heroes = function() {
    available_heroes = [];

    // [6.1] Semak ada legacy hero
    var _has_legacy = variable_global_exists("legacy_hero")
                   && !is_undefined(global.legacy_hero);

    if (_has_legacy) {
        var _legacy       = global.legacy_hero;
        _legacy.is_legacy = true;
        array_push(available_heroes, _legacy);
        array_push(used_names, _legacy.name);
        global.legacy_hero = undefined;
        show_debug_message("[TAVERN] Legacy hero: " + _legacy.name);
    }

    // [6.2] Generate hero biasa untuk baki slot
    var _slots_needed = 3 - array_length(available_heroes);
    repeat (_slots_needed) {
        var _hero = hero_generate(gm.kingdom.th_level, used_names);
        array_push(available_heroes, _hero);
        array_push(used_names, _hero.name);
    }

    // [6.3] Debug output
    show_debug_message("[TAVERN] Generated heroes:");
    for (var i = 0; i < array_length(available_heroes); i++) {
        var _h = available_heroes[i];
        show_debug_message("  " + string(i+1) + ". ["
            + _h.rarity + "] " + _h.name
            + (_h.is_legacy ? " LEGACY" : "")
            + " | IQ:" + _h.personality.iq_label);
    }
};

// ============================================================
// [7.0] REFRESH
// ============================================================
refresh_heroes = function() {
    if (!can_refresh()) {
        show_debug_message("[TAVERN] Insufficient gold. Need "
            + string(get_refresh_cost()) + "g");
        return false;
    }

    var _cost = get_refresh_cost();
    if (_cost > 0) {
        gm.kingdom.treasury -= _cost;
        show_debug_message("[TAVERN] Refreshed for " + string(_cost) + "g");
    }

    refresh_count++;
    state = TAVERN_STATE.REFRESHING;
    generate_heroes();
    state = TAVERN_STATE.OPEN;
    return true;
};

// ============================================================
// [8.0] RECRUIT
// ============================================================
recruit_hero = function(_index) {
    if (_index < 0 || _index >= array_length(available_heroes)) {
        show_debug_message("[TAVERN] Invalid hero index: " + string(_index));
        return false;
    }

    var _hero = available_heroes[_index];

    // [8.1] Semak slot tersedia
    if (gm.is_roster_full()) {
        show_debug_message("[TAVERN] No available hero slots!");
        return false;
    }

    // [8.2] Semak gold cukup
    var _cost = recruit_cost[$ _hero.rarity];
    if (gm.kingdom.treasury < _cost) {
        show_debug_message("[TAVERN] Cannot afford " + _hero.name
            + ". Need " + string(_cost) + "g");
        return false;
    }

    // [8.3] Bayar recruit cost
    gm.kingdom.treasury -= _cost;

    // [8.4] Tambah ke roster
    var _success = gm.add_hero_to_roster(_hero);

    if (_success) {
        array_delete(available_heroes, _index, 1);

        show_debug_message("[TAVERN] Recruited: " + _hero.name
            + " | Cost: " + string(_cost) + "g"
            + " | Treasury: " + string(gm.kingdom.treasury) + "g");

		// [8.5] Spawn hero dalam world
		var _spawn_x = clamp(
		    obj_townhall.x + irandom_range(-60, 60),
		    64, 64 * 32 - 64
		);
		var _spawn_y = clamp(
		    obj_townhall.y + irandom_range(-60, 60),
		    64, 64 * 32 - 64
		);

		// [8.5.1] Spawn instance
		var _inst = instance_create_layer(_spawn_x, _spawn_y, "Heroes", obj_hero);

		// [8.5.2] Panggil init terus — GMS2 membenarkan ini
		_inst.init_from_blueprint(_hero);

		show_debug_message("[TAVERN] Hero instance created and initialized.");

        // [8.6] Sync slot townhall
        if (instance_exists(obj_townhall)) {
            obj_townhall.slot_layout.rebuild();
        }

        // [8.7] Update state
        state = TAVERN_STATE.HERO_PICKED;
        if (!gm.is_roster_full() && array_length(available_heroes) > 0) {
            state = TAVERN_STATE.OPEN;
        }

        return true;
    }

    return false;
};

// ============================================================
// [9.0] OPEN / CLOSE TAVERN
// ============================================================

// [9.1] Buka tavern
open_tavern = function() {
    if (state != TAVERN_STATE.IDLE) exit;

    refresh_count  = 0;
    selected_index = -1;

    if (array_length(available_heroes) == 0) {
        generate_heroes();
    }

    state = TAVERN_STATE.OPEN;
    show_debug_message("[TAVERN] Tavern opened.");
};

// [9.2] Tutup tavern
close_tavern = function() {
    if (is_first_open && array_length(gm.hero_roster) == 0) {
        show_debug_message("[TAVERN] Must recruit at least one hero!");
        return false;
    }

    is_first_open = false;
    state         = TAVERN_STATE.IDLE;
    used_names    = [];

    show_debug_message("[TAVERN] Tavern closed.");
    return true;
};

// ============================================================
// [10.0] UI DATA
// ============================================================
get_ui_data = function() {
    var _heroes_data = [];

    for (var i = 0; i < array_length(available_heroes); i++) {
        var _h          = available_heroes[i];
        var _cost       = recruit_cost[$ _h.rarity];
        var _can_afford = gm.kingdom.treasury >= _cost;
        var _slot_ok    = !gm.is_roster_full();

        array_push(_heroes_data, {
            index           : i,
            name            : _h.name,
            rarity          : _h.rarity,
            job             : _h.job,
            str             : _h.base_stats.strength,
            int             : _h.base_stats.intelligence,
            agi             : _h.base_stats.agility,
            hp_max          : _h.stats.hp_max,
            mana_max        : _h.stats.mana_max,
            move_spd        : _h.stats.move_speed,
            atk_spd         : _h.stats.attack_speed,
            iq_label        : _h.personality.iq_label,
            braveness_label : _h.personality.braveness_label,
            greed_label     : _h.personality.greed_label,
            recruit_cost    : _cost,
            can_recruit     : (_can_afford && _slot_ok),
            is_legacy       : _h.is_legacy,
        });
    }

    return {
        state           : state,
        is_first_open   : is_first_open,
        heroes          : _heroes_data,
        refresh_cost    : get_refresh_cost(),
        can_refresh     : can_refresh(),
        refresh_count   : refresh_count,
        slots_available : gm.kingdom.hero_slots - array_length(gm.hero_roster),
        treasury        : gm.kingdom.treasury,
        selected_index  : selected_index,
    };
};