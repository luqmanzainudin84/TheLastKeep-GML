// ============================================================
// scr_hero_template
// Blueprint generator untuk hero. Dipanggil oleh Tavern
// untuk hasilkan hero rawak berdasarkan TH level.
// ============================================================

// ------------------------------------------------------------
// [1.0] NAME POOLS
// ------------------------------------------------------------
function hero_get_name_pools() {
    return {
        first : [
            "Aldric", "Brennan", "Corvus", "Darian", "Edric",
            "Fayne", "Gareth", "Haldor", "Idris", "Jareth",
            "Kael", "Lyrian", "Maren", "Nolan", "Oryn",
            "Petra", "Quinn", "Riven", "Sable", "Theron",
            "Uryn", "Vex", "Wren", "Xara", "Yael", "Zephyr"
        ],
        last : [
            "Ashveil", "Blackthorn", "Coldwater", "Duskmantle",
            "Emberholt", "Frostgate", "Grimshaw", "Holloway",
            "Ironveil", "Jadestone", "Kettleburn", "Lowmarch",
            "Mistholm", "Nightvale", "Oakenshield", "Pinecrest",
            "Quarrystone", "Ravenscar", "Stonefield", "Thistledown",
            "Underhill", "Voidmark", "Westgate", "Xanmoor",
            "Yarrowmead", "Zilverstone"
        ],
    };
}

// ------------------------------------------------------------
// [2.0] RARITY SYSTEM
// ------------------------------------------------------------

// [2.1] Tentukan rarity berdasarkan TH level
function hero_get_rarity(_th_level) {
    var _roll = random(100);

    if (_th_level <= 2) {
        if (_roll < 90) return "Common";
        return "Uncommon";
    }
    else if (_th_level <= 4) {
        if (_roll < 70) return "Common";
        if (_roll < 95) return "Uncommon";
        return "Rare";
    }
    else if (_th_level <= 7) {
        if (_roll < 40) return "Common";
        if (_roll < 80) return "Uncommon";
        if (_roll < 98) return "Rare";
        return "Legendary";
    }
    else {
        if (_roll < 20) return "Common";
        if (_roll < 55) return "Uncommon";
        if (_roll < 90) return "Rare";
        return "Legendary";
    }
}

// [2.2] Stat range berdasarkan rarity
function hero_get_stat_range(_rarity) {
    switch (_rarity) {
        case "Common"    : return { min: 5,  max: 15 };
        case "Uncommon"  : return { min: 12, max: 25 };
        case "Rare"      : return { min: 22, max: 40 };
        case "Legendary" : return { min: 35, max: 60 };
        default          : return { min: 5,  max: 15 };
    }
}

// [2.3] Personality range — bebas dari rarity
function hero_get_personality_range() {
    return { min: 1, max: 100 };
}

// ------------------------------------------------------------
// [3.0] PERSONALITY LABELS
// ------------------------------------------------------------

// [3.1] IQ label
function hero_get_iq_label(_iq) {
    if (_iq <= 25) return "Dull";
    if (_iq <= 50) return "Average";
    if (_iq <= 75) return "Sharp";
    return "Brilliant";
}

// [3.2] Braveness label
function hero_get_braveness_label(_braveness) {
    if (_braveness <= 25) return "Coward";
    if (_braveness <= 50) return "Cautious";
    if (_braveness <= 75) return "Bold";
    return "Reckless";
}

// [3.3] Greed label
function hero_get_greed_label(_greed) {
    if (_greed <= 25) return "Generous";
    if (_greed <= 50) return "Content";
    if (_greed <= 75) return "Greedy";
    return "Ravenous";
}

// ------------------------------------------------------------
// [4.0] DERIVED STATS CALCULATOR
// ------------------------------------------------------------
function hero_calculate_derived(_base, _constants) {
    return {
        hp_max       : _constants.base_hp   + (_base.strength     * _constants.hp_per_str),
        mana_max     : _constants.base_mana + (_base.intelligence * _constants.mana_per_int),
        hp_regen     : _constants.base_hp_regen   + (_base.strength     * _constants.regen_per_str),
        mana_regen   : _constants.base_mana_regen + (_base.intelligence * _constants.mregen_per_int),
        move_speed   : _constants.base_move_speed   + (_base.agility * _constants.ms_per_agi),
        attack_speed : max(10, _constants.base_attack_speed - (_base.agility * _constants.as_per_agi)),
    };
}

// [4.1] Stat constants — tweak semua pekali di sini
function hero_get_stat_constants() {
    return {
        base_hp           : 100,
        base_mana         : 50,
        base_hp_regen     : 0.0,
        base_mana_regen   : 0.0,
        base_move_speed   : 150,
        base_attack_speed : 60,
        hp_per_str        : 20,
        regen_per_str     : 0.001,
        mana_per_int      : 12,
        mregen_per_int    : 0.001,
        ms_per_agi        : 0.8,
        as_per_agi        : 0.8,
    };
}

// ------------------------------------------------------------
// [5.0] MAIN GENERATOR
// ------------------------------------------------------------
function hero_generate(_th_level, _used_names) {

    var _pools     = hero_get_name_pools();
    var _rarity    = hero_get_rarity(_th_level);
    var _range     = hero_get_stat_range(_rarity);
    var _p_range   = hero_get_personality_range();
    var _constants = hero_get_stat_constants();

    // [5.1] Generate nama unik
    var _name         = "";
    var _max_attempts = 100;

    repeat (_max_attempts) {
        var _first = _pools.first[irandom(array_length(_pools.first) - 1)];
        var _last  = _pools.last[irandom(array_length(_pools.last) - 1)];
        _name = _first + " " + _last;

        var _duplicate = false;
        for (var i = 0; i < array_length(_used_names); i++) {
            if (_used_names[i] == _name) {
                _duplicate = true;
                break;
            }
        }
        if (!_duplicate) break;
    }

    // [5.2] Base stats
    var _base = {
        strength     : irandom_range(_range.min, _range.max),
        intelligence : irandom_range(_range.min, _range.max),
        agility      : irandom_range(_range.min, _range.max),
    };

    // [5.3] Personality
    var _iq        = irandom_range(_p_range.min, _p_range.max);
    var _braveness = irandom_range(_p_range.min, _p_range.max);
    var _greed     = irandom_range(_p_range.min, _p_range.max);

    // [5.4] Derived stats
    var _derived = hero_calculate_derived(_base, _constants);

    // [5.5] Assemble blueprint
    return {
        // [5.5.1] Identity
        name      : _name,
        rarity    : _rarity,
        job       : "Gatherer",
        is_legacy : false,
        gold      : 0,

        // [5.5.2] Base stats
        base_stats : _base,
        constants  : _constants,

        // [5.5.3] Derived stats
        stats : {
            hp             : _derived.hp_max,
            hp_max         : _derived.hp_max,
            mana           : _derived.mana_max,
            mana_max       : _derived.mana_max,
            hp_regen       : _derived.hp_regen,
            mana_regen     : _derived.mana_regen,
            hp_regen_acc   : 0,
            mana_regen_acc : 0,
            move_speed     : _derived.move_speed,
            attack_speed   : _derived.attack_speed,
        },

        // [5.5.4] Personality
        personality : {
            iq              : _iq,
            braveness       : _braveness,
            greed           : _greed,
            iq_label        : hero_get_iq_label(_iq),
            braveness_label : hero_get_braveness_label(_braveness),
            greed_label     : hero_get_greed_label(_greed),
        },

        // [5.5.5] History — lengkap dengan semua fields
        history : {
            kills          : 0,
            deaths_avoided : 0,
            gold_earned    : 0,
            missions_done  : 0,
            waves_survived : 0,
            retreats       : 0,
        },

        // [5.5.6] Titles
        titles : [],
    };
}