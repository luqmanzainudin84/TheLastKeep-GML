// ============================================================
// obj_hero — Create Event
// ============================================================

// [1.0] Rujukan ke game manager
gm = obj_game_manager;

// ============================================================
// [2.0] IDENTITY
// ============================================================
identity = {
    name      : "",
    rarity    : "Common",
    is_legacy : false,
};

// ============================================================
// [3.0] BASE STATS
// ============================================================
base_stats = {
    strength     : 0,
    intelligence : 0,
    agility      : 0,
};

// ============================================================
// [4.0] STAT CONSTANTS
// ============================================================
stat_constants = hero_get_stat_constants();

// ============================================================
// [5.0] DERIVED STATS
// ============================================================
stats = {
    hp             : 0,
    hp_max         : 0,
    mana           : 0,
    mana_max       : 0,
    hp_regen       : 0,
    mana_regen     : 0,
    hp_regen_acc   : 0,
    mana_regen_acc : 0,
    move_speed     : 0,
    attack_speed   : 0,
};

// ============================================================
// [6.0] PERSONALITY
// ============================================================
personality = {
    iq              : 0,
    braveness       : 0,
    greed           : 0,
    iq_label        : "Average",
    braveness_label : "Cautious",
    greed_label     : "Content",
};

// [7.0] HISTORY & TITLES
history = {
    kills          : 0,
    deaths_avoided : 0,
    gold_earned    : 0,
    missions_done  : 0,
    waves_survived : 0,
    retreats       : 0,
};
titles = [];

// ============================================================
// [8.0] PERSONAL ECONOMY
// ============================================================
wallet = {
    gold : 0,
};

// ============================================================
// [8.1] FLAG TRACKING
// ============================================================
current_flag = noone;

// ============================================================
// [9.0] JOB ENUM — MESTI SEBELUM job struct
// ============================================================
JOB = {
    GATHERER : "Gatherer",
    WARRIOR  : "Warrior",
    ARCHER   : "Archer",
    EXPLORER : "Explorer",
    MINER    : "Miner",
    GUARD    : "Guard",
    HEALER   : "Healer",
    WIZARD   : "Wizard",
    ROGUE    : "Rogue",
    PALADIN  : "Paladin",
};

// ============================================================
// [10.0] JOB SYSTEM
// ============================================================
job = {
    owner   : id,
    current : "Gatherer",
    weights : {
        combat   : 0.1,
        resource : 0.9,
        explore  : 0.0,
        defend   : 0.0,
        heal     : 0.0,
        loot     : 0.0,
    },

    assign : function(_new_job) {
        current = _new_job;
        switch (_new_job) {
            case "Gatherer":
                weights = { combat:0.1, resource:0.9, explore:0.0, defend:0.0, heal:0.0, loot:0.0 };
            break;
            case "Warrior":
                weights = { combat:0.9, resource:0.0, explore:0.1, defend:0.0, heal:0.0, loot:0.0 };
            break;
            case "Archer":
                weights = { combat:0.8, resource:0.1, explore:0.1, defend:0.0, heal:0.0, loot:0.0 };
            break;
            case "Explorer":
                weights = { combat:0.1, resource:0.0, explore:0.9, defend:0.0, heal:0.0, loot:0.0 };
            break;
            case "Miner":
                weights = { combat:0.0, resource:1.0, explore:0.0, defend:0.0, heal:0.0, loot:0.0 };
            break;
            case "Guard":
                weights = { combat:0.0, resource:0.0, explore:0.0, defend:1.0, heal:0.0, loot:0.0 };
            break;
            case "Healer":
                weights = { combat:0.0, resource:0.1, explore:0.0, defend:0.0, heal:0.9, loot:0.0 };
            break;
            case "Wizard":
                weights = { combat:0.85, resource:0.0, explore:0.15, defend:0.0, heal:0.0, loot:0.0 };
            break;
            case "Rogue":
                weights = { combat:0.2, resource:0.0, explore:0.0, defend:0.0, heal:0.0, loot:0.8 };
            break;
            case "Paladin":
                weights = { combat:0.7, resource:0.0, explore:0.0, defend:0.0, heal:0.3, loot:0.0 };
            break;
            default:
                weights = { combat:0.1, resource:0.9, explore:0.0, defend:0.0, heal:0.0, loot:0.0 };
            break;
        }
        show_debug_message("[HERO:" + owner.identity.name + "] Job: " + _new_job);
    },
};

// [11.0] HERO INVENTORY
inventory = {
    owner     : id,
    slots     : [],
    max_items : 20,

    // [11.1] Tambah item ke inventory
    add : function(_type, _amount) {
        // [11.1.1] Kira ruang yang ada
        var _current = total_items();
        if (_current >= max_items) return false;

        // [11.1.2] Cap amount supaya tidak melebihi max
        var _space      = max_items - _current;
        var _actual_amt = min(_amount, _space);

        // [11.1.3] Cuba tambah ke slot sedia ada
        for (var i = 0; i < array_length(slots); i++) {
            if (slots[i].type == _type) {
                slots[i].amount += _actual_amt;
                return true;
            }
        }

        // [11.1.4] Buat slot baru
        array_push(slots, { type: _type, amount: _actual_amt });
        return true;
    },

    // [11.2] Semak inventory penuh
    is_full : function() {
        return total_items() >= max_items;
    },

    // [11.3] Kosongkan inventory
    clear : function() {
        slots = [];
    },

    // [11.4] Kira total units
    total_items : function() {
        var _total = 0;
        for (var i = 0; i < array_length(slots); i++) {
            _total += slots[i].amount;
        }
        return _total;
    },

// [11.5] Deposit semua ke warehouse
    deposit_all : function() {
        if (!instance_exists(obj_warehouse)) return 0;
        var _total_gold = 0;
        var _wh         = obj_warehouse;
        for (var i = 0; i < array_length(slots); i++) {
            var _gold    = _wh.deposit(slots[i].type, slots[i].amount);
            _total_gold += _gold;
        }
        owner.wallet.gold                        += _total_gold;
        owner.history.gold_earned                += _total_gold;
        owner.gm.kingdom.total_gold_earned       += _total_gold;
        show_debug_message("[HERO:" + owner.identity.name + "] Deposited. Earned: "
            + string(_total_gold) + "g");
        clear();
        owner._check_titles();
        return _total_gold;
    },
};

// ============================================================
// [11.5] EQUIPMENT SYSTEM
// ============================================================
equipment = {
    owner  : id,
    weapon : undefined,
    armor  : undefined,

    equip : function(_item) {
        var _category = _get_category(_item.item_type);
        if (_category == "weapon") {
            weapon = _item;
            show_debug_message("[EQUIP:" + owner.identity.name + "] Weapon: " + _item.name);
        } else if (_category == "armor") {
            armor = _item;
            show_debug_message("[EQUIP:" + owner.identity.name + "] Armor: " + _item.name);
        } else {
            return false;
        }
        owner.recalculate_stats(false);
        return true;
    },

    unequip : function(_slot) {
        if (_slot == "weapon") weapon = undefined;
        else if (_slot == "armor") armor = undefined;
        owner.recalculate_stats(false);
    },

    get_bonus : function() {
        var _bonus = { attack:0, hp_max:0, mana_max:0, move_speed:0, attack_speed:0 };
        var _slots = [weapon, armor];
        for (var i = 0; i < array_length(_slots); i++) {
            var _item = _slots[i];
            if (is_undefined(_item)) continue;
            if (is_undefined(_item.stat_bonus)) continue;
            var _keys = variable_struct_get_names(_item.stat_bonus);
            for (var j = 0; j < array_length(_keys); j++) {
                var _k = _keys[j];
                if (variable_struct_exists(_bonus, _k)) {
                    _bonus[$ _k] += _item.stat_bonus[$ _k];
                }
            }
        }
        return _bonus;
    },

    _get_category : function(_item_type) {
        if (string_pos("weapon", _item_type) > 0) return "weapon";
        if (string_pos("armor",  _item_type) > 0) return "armor";
        return "unknown";
    },

    has_weapon : function() { return !is_undefined(weapon); },
    has_armor  : function() { return !is_undefined(armor);  },
};

// ============================================================
// [12.0] STATUS SYSTEM
// ============================================================
STATUS = {
    ALIVE       : 0,
    UNCONSCIOUS : 1,
    DEAD        : 2,
};

status = {
    current           : 0,
    unconscious_timer : 0,
    unconscious_limit : 0,
    rescue_radius     : 150,

    is_alive       : function() { return current == 0; },
    is_unconscious : function() { return current == 1; },
    is_dead        : function() { return current == 2; },
};

// ============================================================
// [13.0] CURRENT TARGET TRACKING
// ============================================================
current_target      = noone;
current_target_type = "";

// ============================================================
// [14.0] DECISION ENGINE
// ============================================================
decision = {
    owner : id,

    get_scan_radius : function() {
        return 200 + (owner.personality.iq * 2);
    },

    score_target : function(_target, _target_type) {
        var _p     = owner.personality;
        var _w     = owner.job.weights;
        var _score = 0;

        switch (_target_type) {
            case "combat":
                var _danger = instance_exists(_target)
                            ? (_target.stats.hp / _target.stats.hp_max) * 100
                            : 50;
                var _reward = instance_exists(_target)
                            ? (_target.gold_reward ?? 10)
                            : 10;
                _score = (_reward * (_p.greed / 100))
                       - (_danger * (1 - _p.braveness / 100))
                       + (10      * (_p.iq / 100));
                _score *= _w.combat;
            break;
            case "resource":
                var _value = 5;
                _score = _value * (_p.greed / 100) * _w.resource;
            break;
            case "explore":
                _score = 50 * (_p.iq / 100) * _w.explore;
            break;
            case "loot":
                var _loot_val = instance_exists(_target)
                              ? (_target.loot_value ?? 10)
                              : 10;
                _score = _loot_val * (_p.greed / 100) * _w.loot;
            break;
            case "heal":
                if (instance_exists(_target)) {
                    var _hp_missing = 1 - (_target.stats.hp / _target.stats.hp_max);
                    _score = _hp_missing * 100 * _w.heal;
                }
            break;
        }
        return _score;
    },

    should_retreat : function() {
        var _hp_pct    = owner.stats.hp / owner.stats.hp_max;
        var _iq        = owner.personality.iq;
        var _braveness = owner.personality.braveness;

        var _threshold = 0.10;
        if (_iq <= 25)      _threshold = 0.10;
        else if (_iq <= 50) _threshold = 0.25;
        else if (_iq <= 75) _threshold = 0.40;
        else                _threshold = 0.55;

        var _brave_mod = (_braveness - 50) * 0.002;
        _threshold     = clamp(_threshold - _brave_mod, 0.05, 0.80);

        return _hp_pct <= _threshold;
    },

    should_buy_potion : function() {
        var _iq = owner.personality.iq;
        if (_iq <= 25) return false;
        if (_iq <= 50) return (irandom(100) < 30);
        return true;
    },

    evaluate : function() {
        var _best       = noone;
        var _best_type  = "";
        var _best_score = -infinity;
        var _radius     = get_scan_radius();

        // [14.1] Scan musuh
        if (owner.job.weights.combat > 0) {
            with (obj_enemy) {
                var _dist = point_distance(x, y, other.owner.x, other.owner.y);
                if (_dist <= _radius) {
                    var _s = other.score_target(id, "combat");
                    if (_s > _best_score) {
                        _best_score = _s;
                        _best       = id;
                        _best_type  = "combat";
                    }
                }
            }
        }

        // [14.2] Scan resource
        if (owner.job.weights.resource > 0 && instance_exists(obj_map_manager)) {
            var _map    = obj_map_manager;
            var _r      = floor(_radius / _map.config.cell_size);
            var _r_type = "wood";

            if (owner.job.current == "Miner") {
                _r_type = (irandom(1) == 0) ? "stone" : "iron";
            }

            var _resource_cell = _map.find_nearest_resource(
                owner.x, owner.y, _r_type, _r
            );

            if (!is_undefined(_resource_cell)) {
                var _s = score_target(_resource_cell, "resource");
                if (_s > _best_score) {
                    _best_score = _s;
                    _best       = _resource_cell;
                    _best_type  = "resource";
                }
            }
        }

        // [14.3] Validate result
        if (_best_type == "combat") {
            if (!instance_exists(_best)) return undefined;
        }
        if (_best_type == "resource") {
            if (is_undefined(_best)) return undefined;
        }
        if (_best_type == "") return undefined;

        return {
            target : _best,
            type   : _best_type,
            score  : _best_score,
        };
    },
};

// ============================================================
// [15.0] REGEN SYSTEM
// ============================================================
tick_regen = function() {
    if (!status.is_alive()) exit;

    if (stats.hp < stats.hp_max) {
        stats.hp_regen_acc += stats.hp_regen;
        if (stats.hp_regen_acc >= 1) {
            var _whole         = floor(stats.hp_regen_acc);
            stats.hp          += _whole;
            stats.hp_regen_acc -= _whole;
            stats.hp           = min(stats.hp, stats.hp_max);
        }
    }

    if (stats.mana < stats.mana_max) {
        stats.mana_regen_acc += stats.mana_regen;
        if (stats.mana_regen_acc >= 1) {
            var _whole           = floor(stats.mana_regen_acc);
            stats.mana          += _whole;
            stats.mana_regen_acc -= _whole;
            stats.mana           = min(stats.mana, stats.mana_max);
        }
    }
};

// ============================================================
// [16.0] RECALCULATE STATS
// ============================================================
recalculate_stats = function(_full_restore = false) {
    var _hp_pct   = (stats.hp_max   > 0) ? (stats.hp   / stats.hp_max)   : 1;
    var _mana_pct = (stats.mana_max > 0) ? (stats.mana / stats.mana_max) : 1;

    var _derived = hero_calculate_derived(base_stats, stat_constants);
    var _bonus   = equipment.get_bonus();

    stats.hp_max       = _derived.hp_max     + _bonus.hp_max;
    stats.mana_max     = _derived.mana_max   + _bonus.mana_max;
    stats.hp_regen     = _derived.hp_regen;
    stats.mana_regen   = _derived.mana_regen;
    stats.move_speed   = _derived.move_speed + _bonus.move_speed;
    stats.attack_speed = max(10, _derived.attack_speed - _bonus.attack_speed);

    if (_full_restore) {
        stats.hp   = stats.hp_max;
        stats.mana = stats.mana_max;
    } else {
        stats.hp   = round(_hp_pct   * stats.hp_max);
        stats.mana = round(_mana_pct * stats.mana_max);
    }

    stats.hp   = clamp(stats.hp,   0, stats.hp_max);
    stats.mana = clamp(stats.mana, 0, stats.mana_max);
};

// ============================================================
// [17.0] DAMAGE & DEATH
// ============================================================

// [17.1] Terima damage
take_damage = function(_amount) {
    if (!status.is_alive()) exit;
    var _bonus      = equipment.get_bonus();
    var _dmg_reduce = clamp(_bonus.hp_max * 0.01, 0, 0.5);
    var _actual_dmg = floor(_amount * (1 - _dmg_reduce));
    stats.hp = max(0, stats.hp - _actual_dmg);
    show_debug_message("[HERO:" + identity.name + "] Took "
        + string(_amount) + " damage | HP: "
        + string(stats.hp) + "/" + string(stats.hp_max));
    if (stats.hp <= 0) _trigger_unconscious();
};

// [17.2] Trigger unconscious
_trigger_unconscious = function() {
    if (!variable_instance_exists(id, "ai")) exit;
    status.current           = 1;
    status.unconscious_timer = 0;
    status.unconscious_limit = gm.TIME.ticks_per_day;
    ai.change_state("unconscious");
    show_debug_message("[HERO:" + identity.name + "] UNCONSCIOUS!");
};

// [17.3] Trigger death
_trigger_death = function() {
    status.current = 2;
    gm.add_to_hall(
        { name: identity.name, rarity: identity.rarity,
          titles: titles, history: history },
        gm.wave.current,
        history.kills
    );
    gm.remove_hero_from_roster(identity.name);
    gm.check_game_over();
    instance_destroy();
};

// [17.4] Receive rescue
receive_rescue = function() {
    if (!status.is_unconscious()) return false;
    status.current = 0;
    stats.hp       = floor(stats.hp_max * 0.25);
    history.deaths_avoided++;
    _check_titles();
    ai.change_state("flee");
    show_debug_message("[HERO:" + identity.name + "] RESCUED!");
    return true;
};

// ============================================================
// [18.0] TITLE SYSTEM
// ============================================================
_check_titles = function() {
    if (history.deaths_avoided >= 10 && !_has_title("The Undying")) {
        _award_title("The Undying");
    }
    if (wallet.gold >= 1000 && !_has_title("The Wealthy")) {
        _award_title("The Wealthy");
    }
    if (history.retreats >= 20 && !_has_title("The Coward")) {
        _award_title("The Coward");
    }
	if (equipment.has_weapon() && equipment.has_armor()
    && !_has_title("The Equipped")) {
        _award_title("The Equipped");
    }
};

_has_title = function(_title) {
    for (var i = 0; i < array_length(titles); i++) {
        if (titles[i] == _title) return true;
    }
    return false;
};

_award_title = function(_title) {
    array_push(titles, _title);
    show_debug_message("[HERO:" + identity.name + "] Title: " + _title);
};

// ============================================================
// [19.0] FLEE CHECK
// ============================================================
should_flee_from_enemy = function() {
    var _flee_jobs   = ["Gatherer", "Miner", "Healer", "Explorer"];
    var _is_flee_job = false;

    for (var i = 0; i < array_length(_flee_jobs); i++) {
        if (job.current == _flee_jobs[i]) {
            _is_flee_job = true;
            break;
        }
    }

    if (!_is_flee_job) return false;

    with (obj_enemy) {
        var _dist = point_distance(x, y, other.x, other.y);
        if (_dist < 150) return true;
    }

    return false;
};

// ============================================================
// [20.0] INIT FROM BLUEPRINT
// ============================================================
init_from_blueprint = function(_blueprint) {
    // [20.1] Identity
    identity.name      = _blueprint.name;
    identity.rarity    = _blueprint.rarity;
    identity.is_legacy = _blueprint.is_legacy;

    // [20.2] Base stats
    base_stats.strength     = _blueprint.base_stats.strength;
    base_stats.intelligence = _blueprint.base_stats.intelligence;
    base_stats.agility      = _blueprint.base_stats.agility;

    // [20.3] Personality
    personality.iq              = _blueprint.personality.iq;
    personality.braveness       = _blueprint.personality.braveness;
    personality.greed           = _blueprint.personality.greed;
    personality.iq_label        = _blueprint.personality.iq_label;
    personality.braveness_label = _blueprint.personality.braveness_label;
    personality.greed_label     = _blueprint.personality.greed_label;

	// [20.4] History & titles — merge supaya field tidak hilang
	history.kills          = _blueprint.history.kills          ?? 0;
	history.deaths_avoided = _blueprint.history.deaths_avoided ?? 0;
	history.gold_earned    = _blueprint.history.gold_earned    ?? 0;
	history.missions_done  = _blueprint.history.missions_done  ?? 0;
	history.waves_survived = _blueprint.history.waves_survived ?? 0;
	history.retreats       = _blueprint.history.retreats       ?? 0;
	titles      = _blueprint.titles;
	wallet.gold = _blueprint.gold;
	// [20.4.1] Restore equipment kalau ada dalam blueprint
    if (variable_struct_exists(_blueprint, "equipment")) {
        equipment.weapon = _blueprint.equipment.weapon ?? undefined;
        equipment.armor  = _blueprint.equipment.armor  ?? undefined;
    }

    // [20.5] Kira stats dan init
    recalculate_stats(true);
    job.assign(_blueprint.job);
    _init_state_machine();

    show_debug_message("[HERO] Spawned: " + identity.name
        + " [" + identity.rarity + "]"
        + " | HP:" + string(stats.hp_max)
        + " | Job:" + job.current);
};

// ============================================================
// [21.0] STATE MACHINE
// ============================================================
_init_state_machine = function() {

    // ----------------------------------------------------------
    // [21.1] STATE: Idle
    // ----------------------------------------------------------
    var _state_idle = {
        owner      : id,
        name       : "idle",
        idle_timer : 0,

        on_enter : function() {
            idle_timer = room_speed * 2;
        },
        on_step : function() {
            idle_timer--;

            // [21.1.1] Flee check untuk non-combat jobs
            if (owner.should_flee_from_enemy()) {
                owner.ai.change_state("flee");
                return;
            }

            // [21.1.2] Evaluate target
            var _result = owner.decision.evaluate();
            if (!is_undefined(_result)) {
                owner.current_target      = _result.target;
                owner.current_target_type = _result.type;
                owner.ai.change_state("move_to_target");
                return;
            }

            // [21.1.3] Wander bila idle timer habis
            if (idle_timer <= 0) {
                owner.ai.change_state("wander");
            }
        },
        on_exit : function() { idle_timer = 0; },
    };

    // ----------------------------------------------------------
    // [21.2] STATE: Wander
    // ----------------------------------------------------------
    var _state_wander = {
        owner    : id,
        name     : "wander",
        wander_x : 0,
        wander_y : 0,

        on_enter : function() {
            var _map_max = 64 * 32;
            wander_x = clamp(owner.x + irandom_range(-150, 150), 32, _map_max - 32);
            wander_y = clamp(owner.y + irandom_range(-150, 150), 32, _map_max - 32);
        },
        on_step : function() {
            // [21.2.1] Flee check
            if (owner.should_flee_from_enemy()) {
                owner.ai.change_state("flee");
                return;
            }

            // [21.2.2] Evaluate target
            var _result = owner.decision.evaluate();
            if (!is_undefined(_result)) {
                owner.current_target      = _result.target;
                owner.current_target_type = _result.type;
                owner.ai.change_state("move_to_target");
                return;
            }

            // [21.2.3] Gerak ke wander point
            var _dist = point_distance(owner.x, owner.y, wander_x, wander_y);
            if (_dist > 4) {
                var _spd = owner.stats.move_speed / room_speed;
                owner.x += ((wander_x - owner.x) / _dist) * _spd;
                owner.y += ((wander_y - owner.y) / _dist) * _spd;
            } else {
                owner.ai.change_state("idle");
            }
        },
        on_exit : function() {},
    };

    // ----------------------------------------------------------
    // [21.3] STATE: Move To Target
    // ----------------------------------------------------------
    var _state_move = {
        owner : id,
        name  : "move_to_target",

        on_enter : function() {},
        on_step : function() {
            // [21.3.1] Retreat check untuk combat
            if (owner.current_target_type == "combat"
            &&  owner.decision.should_retreat()) {
                owner.ai.change_state("flee");
                return;
            }

            // [21.3.2] Dapatkan world position target
            var _target_valid = false;
            var _tx = 0;
            var _ty = 0;

            if (owner.current_target_type == "resource") {
                if (!is_undefined(owner.current_target)
                &&  !is_undefined(owner.current_target.resource)) {
                    if (owner.current_target.resource.is_depleted()) {
                        owner.current_target      = undefined;
                        owner.current_target_type = "";
                        owner.ai.change_state("idle");
                        return;
                    }
                    var _world = map_cell_to_world(
                        owner.current_target.col,
                        owner.current_target.row,
                        obj_map_manager.config
                    );
                    _tx           = _world.x;
                    _ty           = _world.y;
                    _target_valid = true;
                }
            } else if (owner.current_target_type == "combat") {
                if (instance_exists(owner.current_target)) {
                    _tx           = owner.current_target.x;
                    _ty           = owner.current_target.y;
                    _target_valid = true;
                }
            }

            // [21.3.3] Target tidak valid — balik idle
            if (!_target_valid) {
                owner.current_target      = undefined;
                owner.current_target_type = "";
                owner.ai.change_state("idle");
                return;
            }

            // [21.3.4] Gerak ke target
            var _dist = point_distance(owner.x, owner.y, _tx, _ty);
            var _spd  = owner.stats.move_speed / room_speed;

            var _engage_range = 35;
            if (owner.job.current == "Archer"
            ||  owner.job.current == "Wizard") {
                _engage_range = 200;
            }

            if (_dist > _engage_range) {
                owner.x += ((_tx - owner.x) / _dist) * _spd;
                owner.y += ((_ty - owner.y) / _dist) * _spd;
            } else {
                // [21.3.5] Sampai — tukar state
                if (owner.current_target_type == "combat") {
                    if (owner.job.current == "Archer"
                    ||  owner.job.current == "Wizard") {
                        owner.ai.change_state("attack_ranged");
                    } else {
                        owner.ai.change_state("attack");
                    }
                } else if (owner.current_target_type == "resource") {
                    owner.ai.change_state("gather");
                }
            }
        },
        on_exit : function() {},
    };

    // ----------------------------------------------------------
    // [21.4] STATE: Attack Melee
    // ----------------------------------------------------------
    var _state_attack = {
        owner        : id,
        name         : "attack",
        attack_timer : 0,

        on_enter : function() { attack_timer = 0; },
        on_step : function() {
            // [21.4.1] Target hilang
            if (!instance_exists(owner.current_target)) {
                owner.current_target      = noone;
                owner.current_target_type = "";
                owner.ai.change_state("idle");
                return;
            }
            // [21.4.2] Retreat check
            if (owner.decision.should_retreat()) {
                owner.ai.change_state("flee");
                return;
            }
            // [21.4.3] Semak jarak
            var _dist = point_distance(owner.x, owner.y,
                        owner.current_target.x, owner.current_target.y);
            if (_dist > 50) {
                owner.ai.change_state("move_to_target");
                return;
            }
            // [21.4.4] Attack tick
            attack_timer++;
            if (attack_timer >= owner.stats.attack_speed) {
                attack_timer = 0;
                owner.current_target.take_damage(owner.base_stats.strength * 0.8);
            }
        },
        on_exit : function() { attack_timer = 0; },
    };

    // ----------------------------------------------------------
    // [21.5] STATE: Attack Ranged
    // ----------------------------------------------------------
    var _state_attack_ranged = {
        owner        : id,
        name         : "attack_ranged",
        attack_timer : 0,
        safe_range   : 180,

        on_enter : function() { attack_timer = 0; },
        on_step : function() {
            // [21.5.1] Target hilang
            if (!instance_exists(owner.current_target)) {
                owner.current_target      = noone;
                owner.current_target_type = "";
                owner.ai.change_state("idle");
                return;
            }
            var _dist = point_distance(owner.x, owner.y,
                        owner.current_target.x, owner.current_target.y);

            // [21.5.2] Terlalu dekat — backpedal
            if (_dist < safe_range * 0.6) {
                var _angle = point_direction(
                    owner.current_target.x, owner.current_target.y,
                    owner.x, owner.y);
                var _spd = owner.stats.move_speed / room_speed;
                owner.x += lengthdir_x(_spd, _angle);
                owner.y += lengthdir_y(_spd, _angle);
                return;
            }
            // [21.5.3] Terlalu jauh — kejar
            if (_dist > safe_range * 1.4) {
                owner.ai.change_state("move_to_target");
                return;
            }
            // [21.5.4] Attack tick
            attack_timer++;
            if (attack_timer >= owner.stats.attack_speed) {
                attack_timer = 0;
                var _dmg = (owner.job.current == "Wizard")
                         ? owner.base_stats.intelligence * 0.9
                         : owner.base_stats.agility * 0.7;
                owner.current_target.take_damage(_dmg);
            }
        },
        on_exit : function() { attack_timer = 0; },
    };

    // ----------------------------------------------------------
    // [21.6] STATE: Gather
    // ----------------------------------------------------------
    var _state_gather = {
        owner        : id,
        name         : "gather",
        gather_timer : 0,
        gather_rate  : room_speed * 2,

        on_enter : function() { gather_timer = 0; },
        on_step : function() {
            // [21.6.1] Flee check
            if (owner.should_flee_from_enemy()) {
                owner.ai.change_state("flee");
                return;
            }
            // [21.6.2] Target tidak valid
            if (is_undefined(owner.current_target)
            ||  is_undefined(owner.current_target.resource)) {
                owner.ai.change_state("returning");
                return;
            }
            // [21.6.3] Inventory penuh
            if (owner.inventory.is_full()) {
                owner.ai.change_state("returning");
                return;
            }
            // [21.6.4] Gather tick
            gather_timer++;
            if (gather_timer >= gather_rate) {
                gather_timer = 0;
                var _cell    = owner.current_target;
                var _amount  = _cell.resource.harvest(5);
                if (_amount > 0) {
                    owner.inventory.add(_cell.resource.type, _amount);
                    show_debug_message("[HERO:" + owner.identity.name
                        + "] Gathered " + string(_amount)
                        + "x " + _cell.resource.type
                        + " | Inventory: "
                        + string(owner.inventory.total_items()) + " items");
                }
                if (_cell.resource.is_depleted()) {
                    owner.current_target      = undefined;
                    owner.current_target_type = "";
                    owner.ai.change_state("wander");
                }
            }
        },
        on_exit : function() { gather_timer = 0; },
    };

    // ----------------------------------------------------------
    // [21.7] STATE: Flee
    // ----------------------------------------------------------
    var _state_flee = {
        owner  : id,
        name   : "flee",
        flee_x : 0,
        flee_y : 0,

        on_enter : function() {
		    owner.history.retreats++;
		    owner._check_titles();

		    // [21.7.1] Lari ke townhall
		    flee_x = obj_townhall.x + irandom_range(-50, 50);
		    flee_y = obj_townhall.y + irandom_range(-50, 50);

		    show_debug_message("[HERO:" + owner.identity.name + "] FLEEING!");
		},						
		on_step : function() {
		    var _dist = point_distance(owner.x, owner.y, flee_x, flee_y);

		    // [21.7.2] Laju flee = 2x move speed
		    var _spd = (owner.stats.move_speed * 2.0) / room_speed;

		    if (_dist > 4) {
		        owner.x += ((flee_x - owner.x) / _dist) * _spd;
		        owner.y += ((flee_y - owner.y) / _dist) * _spd;
		    } else {
		        owner.ai.change_state("idle");
		    }
		},on_enter : function() {
			owner.history.retreats++;
			owner._check_titles();

			// [21.7.1] Lari ke townhall
			flee_x = obj_townhall.x + irandom_range(-50, 50);
			flee_y = obj_townhall.y + irandom_range(-50, 50);

			show_debug_message("[HERO:" + owner.identity.name + "] FLEEING!");
		},
		on_step : function() {
			var _dist = point_distance(owner.x, owner.y, flee_x, flee_y);

			// [21.7.2] Laju flee = 2x move speed
			var _spd = (owner.stats.move_speed * 2.0) / room_speed;

			if (_dist > 4) {
			    owner.x += ((flee_x - owner.x) / _dist) * _spd;
			    owner.y += ((flee_y - owner.y) / _dist) * _spd;
			} else {
			    owner.ai.change_state("idle");
			}
		},	
        on_exit : function() {},
    };

    // ----------------------------------------------------------
    // [21.8] STATE: Returning
    // ----------------------------------------------------------
    var _state_returning = {
        owner   : id,
        name    : "returning",
        target_x : 0,
        target_y : 0,

        on_enter : function() {
            // [21.8.1] Gerak ke warehouse kalau ada, townhall kalau tidak
            if (instance_exists(obj_warehouse)) {
                target_x = obj_warehouse.x;
                target_y = obj_warehouse.y;
            } else {
                target_x = obj_townhall.x;
                target_y = obj_townhall.y;
            }
            show_debug_message("[HERO:" + owner.identity.name
                + "] Returning to deposit at "
                + string(floor(target_x)) + ","
                + string(floor(target_y)));
        },
        on_step : function() {
            var _dist = point_distance(owner.x, owner.y, target_x, target_y);
            var _spd  = owner.stats.move_speed / room_speed;

            if (_dist > 48) {
                owner.x += ((target_x - owner.x) / _dist) * _spd;
                owner.y += ((target_y - owner.y) / _dist) * _spd;
            } else {
                // [21.8.2] Deposit dan balik idle
                owner.inventory.deposit_all();
                owner.ai.change_state("idle");
            }
        },
        on_exit : function() {},
    };

    // ----------------------------------------------------------
    // [21.9] STATE: Unconscious
    // ----------------------------------------------------------
    var _state_unconscious = {
        owner : id,
        name  : "unconscious",

        on_enter : function() {},
        on_step : function() {
            owner.status.unconscious_timer++;
            with (obj_hero) {
                if (id == other.owner.id) continue;
                if (!status.is_alive()) continue;
                var _dist = point_distance(x, y,
                            other.owner.x, other.owner.y);
                if (_dist <= other.owner.status.rescue_radius) {
                    other.owner.receive_rescue();
                    return;
                }
            }
            if (owner.status.unconscious_timer >= owner.status.unconscious_limit) {
                owner._trigger_death();
            }
        },
        on_exit : function() {},
    };
	
	// ----------------------------------------------------------
    // [21.9b] STATE: Move To Flag
    // ----------------------------------------------------------
    var _state_move_to_flag = {
        owner : id,
        name  : "move_to_flag",

        on_enter : function() {
            show_debug_message("[HERO:" + owner.identity.name + "] Moving to flag.");
        },
        on_step : function() {
            if (!instance_exists(owner.current_flag)) {
                owner.current_flag = noone;
                owner.ai.change_state("idle");
                return;
            }
            if (owner.should_flee_from_enemy()) {
                owner.current_flag = noone;
                owner.ai.change_state("flee");
                return;
            }
            var _flag = owner.current_flag;
            var _dist = point_distance(owner.x, owner.y, _flag.x, _flag.y);
            var _spd  = owner.stats.move_speed / room_speed;
            if (_dist <= 48) {
                if (_flag.is_active) {
                    _flag.is_active        = false;
                    _flag.completion_timer = 0;
                }
                return;
            }
            owner.x += ((_flag.x - owner.x) / _dist) * _spd;
            owner.y += ((_flag.y - owner.y) / _dist) * _spd;
        },
        on_exit : function() {},
    };

    // ----------------------------------------------------------
    // [21.10] ASSEMBLE STATE MACHINE
    // ----------------------------------------------------------
    ai = {
        owner         : id,
        current_state : undefined,
        states        : {},

        register : function(_name, _state_struct) {
            states[$ _name] = _state_struct;
        },
        change_state : function(_new_name) {
            if (!is_undefined(current_state)) current_state.on_exit();
            current_state = states[$ _new_name];
            if (!is_undefined(current_state)) {
                current_state.on_enter();
            } else {
                show_debug_message("State tidak wujud: " + _new_name);
            }
        },
        update : function() {
            if (!is_undefined(current_state)) current_state.on_step();
        },
    };

    // [21.11] Register semua states
    ai.register("idle",           _state_idle);
    ai.register("wander",         _state_wander);
    ai.register("move_to_target", _state_move);
    ai.register("attack",         _state_attack);
    ai.register("attack_ranged",  _state_attack_ranged);
    ai.register("gather",         _state_gather);
    ai.register("flee",           _state_flee);
    ai.register("returning",      _state_returning);
    ai.register("unconscious",    _state_unconscious);
	ai.register("move_to_flag", _state_move_to_flag);

    // [21.12] Mula dengan idle
    ai.change_state("idle");
};