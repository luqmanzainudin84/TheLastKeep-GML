// ============================================================
// obj_enemy — Create Event
// ============================================================

// [1.1] Rujukan ke game manager
gm = obj_game_manager;

// ============================================================
// [2.0] ENEMY TYPE DEFINITIONS
// ============================================================
_get_type_config = function(_type) {
    var _configs = {

        // [2.1] Tier 1 — Season 1
        goblin : {
            hp_base      : 30,
            damage_base  : 5,
            speed_base   : 90,
            attack_range : 30,
            attack_rate  : 45,
            gold_reward  : 5,
            is_ranged    : false,
            loot_table   : ["hide_common"],
        },

        bandit : {
            hp_base      : 60,
            damage_base  : 10,
            speed_base   : 70,
            attack_range : 35,
            attack_rate  : 55,
            gold_reward  : 10,
            is_ranged    : false,
            loot_table   : ["hide_common", "iron"],
        },

        bandit_archer : {
            hp_base      : 40,
            damage_base  : 12,
            speed_base   : 65,
            attack_range : 200,
            attack_rate  : 70,
            gold_reward  : 12,
            is_ranged    : true,
            loot_table   : ["hide_common", "wood"],
        },

        // [2.2] Tier 2 — Season 2
        orc : {
            hp_base      : 120,
            damage_base  : 18,
            speed_base   : 55,
            attack_range : 40,
            attack_rate  : 80,
            gold_reward  : 20,
            is_ranged    : false,
            loot_table   : ["hide_thick", "iron"],
        },

        orc_warrior : {
            hp_base      : 200,
            damage_base  : 25,
            speed_base   : 50,
            attack_range : 40,
            attack_rate  : 90,
            gold_reward  : 35,
            is_ranged    : false,
            loot_table   : ["hide_thick", "iron", "copper"],
        },

        dark_mage : {
            hp_base      : 55,
            damage_base  : 22,
            speed_base   : 60,
            attack_range : 220,
            attack_rate  : 100,
            gold_reward  : 30,
            is_ranged    : true,
            loot_table   : ["crystal", "hide_common"],
        },

        // [2.3] Tier 3 — Season 3+
        troll : {
            hp_base      : 350,
            damage_base  : 30,
            speed_base   : 40,
            attack_range : 45,
            attack_rate  : 120,
            gold_reward  : 50,
            is_ranged    : false,
            loot_table   : ["hide_thick", "stone"],
        },

        dragon_spawn : {
            hp_base      : 180,
            damage_base  : 35,
            speed_base   : 100,
            attack_range : 60,
            attack_rate  : 75,
            gold_reward  : 60,
            is_ranged    : false,
            loot_table   : ["hide_rare", "crystal"],
        },

        // [2.4] Boss types
        bandit_warlord : {
            hp_base      : 500,
            damage_base  : 40,
            speed_base   : 65,
            attack_range : 50,
            attack_rate  : 60,
            gold_reward  : 200,
            is_ranged    : false,
            loot_table   : ["hide_thick", "iron", "copper", "crystal"],
        },

        orc_siege_leader : {
            hp_base      : 800,
            damage_base  : 55,
            speed_base   : 45,
            attack_range : 55,
            attack_rate  : 80,
            gold_reward  : 350,
            is_ranged    : false,
            loot_table   : ["hide_thick", "mithril", "iron"],
        },

        lich : {
            hp_base      : 600,
            damage_base  : 70,
            speed_base   : 55,
            attack_range : 280,
            attack_rate  : 90,
            gold_reward  : 500,
            is_ranged    : true,
            loot_table   : ["crystal", "mithril", "hide_rare"],
        },

        elder_dragon : {
            hp_base      : 1500,
            damage_base  : 100,
            speed_base   : 90,
            attack_range : 80,
            attack_rate  : 70,
            gold_reward  : 1000,
            is_ranged    : false,
            loot_table   : ["hide_rare", "crystal", "mithril"],
        },

        void_titan : {
            hp_base      : 3000,
            damage_base  : 150,
            speed_base   : 60,
            attack_range : 100,
            attack_rate  : 60,
            gold_reward  : 2000,
            is_ranged    : false,
            loot_table   : ["hide_rare", "mithril", "crystal"],
        },
    };

    return _configs[$ _type] ?? _configs[$ "goblin"];
};

// ============================================================
// [3.0] STATS
// ============================================================
enemy_type  = "goblin";
is_boss     = false;
gold_reward = 0;
loot_table  = [];

stats = {
    hp           : 0,
    hp_max       : 0,
    damage       : 0,
    move_speed   : 0,
    attack_range : 0,
    attack_rate  : 0,
    is_ranged    : false,
};

// ============================================================
// [4.0] COMBAT STATE
// ============================================================
current_target = noone;
attack_timer   = 0;
loot_dropped   = false;

// ============================================================
// [5.0] STATE MACHINE
// ============================================================
ESTATE = {
    MOVE   : 0,
    ATTACK : 1,
    DIE    : 2,
};

estate       = ESTATE.MOVE;
die_timer    = 0;
die_duration = 30;

// ============================================================
// [6.0] TARGET SYSTEM
// ============================================================
find_target = function() {
    var _best      = noone;
    var _best_dist = infinity;

    // [6.1] Priority 1 — Hero yang hidup
    with (obj_hero) {
        if (!variable_instance_exists(id, "status")) continue;
        if (!status.is_alive()) continue;
        var _dist = point_distance(x, y, other.x, other.y);
        if (_dist < _best_dist) {
            _best_dist = _dist;
            _best      = id;
        }
    }
    if (_best != noone) return _best;

    // [6.2] Priority 2 — Bangunan
    with (obj_building_parent) {
        var _dist = point_distance(x, y, other.x, other.y);
        if (_dist < _best_dist) {
            _best_dist = _dist;
            _best      = id;
        }
    }
    if (_best != noone) return _best;

    // [6.3] Priority 3 — Townhall
    if (instance_exists(obj_townhall)) return obj_townhall;

    return noone;
};

// ============================================================
// [7.0] DAMAGE & DEATH
// ============================================================

// [7.1] Terima damage
take_damage = function(_amount) {
    stats.hp = max(0, stats.hp - _amount);
    if (stats.hp <= 0) {
        _trigger_death();
    }
};

// [7.2] Trigger death
_trigger_death = function() {
    if (estate == ESTATE.DIE) return;
    estate = ESTATE.DIE;

    if (!loot_dropped) {
        loot_dropped = true;
        _drop_loot();
    }

    if (instance_exists(obj_wave_manager)) {
        obj_wave_manager.on_enemy_death();
    }

    gm.kingdom.treasury += gold_reward;

    show_debug_message("[ENEMY:" + enemy_type + "] Died."
        + " | Reward: " + string(gold_reward) + "g");
};

// [7.3] Drop loot ke warehouse
_drop_loot = function() {
    if (!instance_exists(obj_warehouse)) return;
    if (array_length(loot_table) == 0) return;

    var _drops = is_boss ? irandom_range(3, 5) : irandom_range(1, 2);

    repeat (_drops) {
        var _idx  = irandom(array_length(loot_table) - 1);
        var _type = loot_table[_idx];
        var _amt  = is_boss ? irandom_range(5, 10) : irandom_range(1, 3);
        obj_warehouse.deposit(_type, _amt);
        show_debug_message("[LOOT] " + string(_amt) + "x " + _type);
    }
};

// ============================================================
// [8.0] INIT FROM TYPE
// ============================================================
init_enemy = function(_type, _scale) {
    enemy_type  = _type;
    var _cfg    = _get_type_config(_type);
    var _sc     = _scale ?? {
        hp_mult    : 1.0,
        dmg_mult   : 1.0,
        count_mult : 1.0,
        speed_mult : 1.0,
    };

    stats.hp_max       = floor(_cfg.hp_base     * _sc.hp_mult);
    stats.hp           = stats.hp_max;
    stats.damage       = floor(_cfg.damage_base * _sc.dmg_mult);
    stats.move_speed   = floor(_cfg.speed_base  * _sc.speed_mult);
    stats.attack_range = _cfg.attack_range;
    stats.attack_rate  = _cfg.attack_rate;
    stats.is_ranged    = _cfg.is_ranged;

    gold_reward = _cfg.gold_reward;
    loot_table  = _cfg.loot_table;

    show_debug_message("[ENEMY] Spawned: " + _type
        + " | HP: " + string(stats.hp_max)
        + " | DMG: " + string(stats.damage)
        + (is_boss ? " [BOSS]" : ""));
};