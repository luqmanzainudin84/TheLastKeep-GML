// ============================================================
// obj_townhall — Create Event
// ============================================================

// [1.1] Safety check — game manager mesti wujud dulu
if (!instance_exists(obj_game_manager)) {
    show_debug_message("[TH] ERROR: obj_game_manager not found!");
    exit;
}

// [1.2] Rujukan ke game manager
gm = obj_game_manager;

// [1.3] Init flags
_initialized = false;
_sync_timer  = 0;

// ============================================================
// [2.0] UPGRADE COST & DURATION
// ============================================================

// [2.1] Kira kos upgrade — formula: floor(150 * (level ^ 1.6))
get_upgrade_cost = function(_current_level) {
    if (_current_level >= 10) return -1;
    return floor(150 * power(_current_level, 1.6));
};

// [2.2] Kira duration upgrade dalam ticks
get_upgrade_duration = function(_current_level) {
    return _current_level * gm.TIME.ticks_per_day;
};

// ============================================================
// [3.0] CONSTRUCTION STATE
// ============================================================
construction = {
    is_upgrading  : false,
    progress_tick : 0,
    total_ticks   : 0,
    target_level  : 0,

    get_progress : function() {
        if (!is_upgrading) return 0;
        return clamp(progress_tick / total_ticks, 0, 1);
    },
};

// ============================================================
// [4.0] SLOT SYSTEM
// ============================================================
slot_layout = {
    owner : id,
    slots : [],

    // [4.1] Bina semula slot array bila hero_slots berubah
    rebuild : function() {
        slots = [];
        var _total = obj_game_manager.kingdom.hero_slots;
        for (var i = 0; i < _total; i++) {
            array_push(slots, {
                index       : i,
                is_occupied : false,
                hero_name   : "",
            });
        }
        _sync_with_roster();
    },

    // [4.2] Sync visual slots dengan hero_roster dalam game_manager
    _sync_with_roster : function() {
        var _roster = obj_game_manager.hero_roster;
        for (var i = 0; i < array_length(slots); i++) {
            slots[i].is_occupied = false;
            slots[i].hero_name   = "";
        }
        for (var i = 0; i < array_length(_roster); i++) {
            if (i < array_length(slots)) {
                slots[i].is_occupied = true;
                slots[i].hero_name   = _roster[i].name;
            }
        }
    },

    // [4.3] Berapa slot kosong
    get_empty_count : function() {
        var _count = 0;
        for (var i = 0; i < array_length(slots); i++) {
            if (!slots[i].is_occupied) _count++;
        }
        return _count;
    },
};

// ============================================================
// [5.0] UPGRADE FUNCTIONS
// ============================================================

// [5.1] Semak boleh upgrade
can_upgrade = function() {
    if (construction.is_upgrading) return false;
    if (gm.kingdom.th_level >= 10) return false;
    var _cost = get_upgrade_cost(gm.kingdom.th_level);
    return gm.kingdom.treasury >= _cost;
};

// [5.2] Mulakan upgrade
start_upgrade = function() {
    if (!can_upgrade()) {
        var _reason = "";
        if (construction.is_upgrading) {
            _reason = "already upgrading";
        } else if (gm.kingdom.th_level >= 10) {
            _reason = "maximum level reached";
        } else {
            _reason = "insufficient gold";
        }
        show_debug_message("[TH] Cannot upgrade: " + _reason);
        return false;
    }

    var _current_level = gm.kingdom.th_level;
    var _cost          = get_upgrade_cost(_current_level);
    var _duration      = get_upgrade_duration(_current_level);

    gm.kingdom.treasury        -= _cost;
    construction.is_upgrading   = true;
    construction.progress_tick  = 0;
    construction.total_ticks    = _duration;
    construction.target_level   = _current_level + 1;

    show_debug_message("[TH] Upgrade started: TH"
        + string(_current_level) + " to TH"
        + string(construction.target_level)
        + " | Cost: " + string(_cost) + "g"
        + " | Duration: " + string(_current_level) + " days");
    return true;
};

// [5.3] Siapkan upgrade
_complete_upgrade = function() {
    construction.is_upgrading = false;
    gm.upgrade_townhall();
    slot_layout.rebuild();
    show_debug_message("[TH] Upgrade complete! Now TH"
        + string(gm.kingdom.th_level)
        + " | Hero slots: " + string(gm.kingdom.hero_slots));
};

// [5.4] Update construction tick — dipanggil dalam Step Event
update_construction = function() {
    if (!construction.is_upgrading) exit;
    construction.progress_tick++;
    if (construction.progress_tick >= construction.total_ticks) {
        _complete_upgrade();
    }
};

// ============================================================
// [6.0] UI DATA
// ============================================================
get_ui_data = function() {
    var _level    = gm.kingdom.th_level;
    var _is_max   = (_level >= 10);
    return {
        th_level         : _level,
        is_max           : _is_max,
        is_upgrading     : construction.is_upgrading,
        upgrade_progress : construction.get_progress(),
        upgrade_cost     : get_upgrade_cost(_level),
        can_upgrade      : can_upgrade(),
        hero_slots_total : gm.kingdom.hero_slots,
        hero_slots_used  : array_length(gm.hero_roster),
        hero_slots_empty : slot_layout.get_empty_count(),
        slots            : slot_layout.slots,
        treasury         : gm.kingdom.treasury,
    };
};