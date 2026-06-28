// ============================================================
// obj_potion_shop — Create Event
// Jual health dan mana potion
// ============================================================

gm = obj_game_manager;

// ============================================================
// [1.0] POTION CATALOG
// ============================================================
POTIONS = {
    health_potion : {
        name        : "Health Potion",
        type        : "health",
        amount      : 50,
        cost        : 30,
        description : "Restores 50 HP",
    },
    mana_potion : {
        name        : "Mana Potion",
        type        : "mana",
        amount      : 50,
        cost        : 30,
        description : "Restores 50 MP",
    },
};

// ============================================================
// [2.0] BUY POTION — player beli potion
// ============================================================
buy_potion = function(_potion_key, _hero_id) {
    var _potion = POTIONS[$ _potion_key];

    if (is_undefined(_potion)) {
        show_debug_message("[POTION_SHOP] Unknown potion: " + _potion_key);
        return false;
    }

    // [2.1] Semak gold cukup
    if (gm.kingdom.treasury < _potion.cost) {
        show_debug_message("[POTION_SHOP] Not enough gold. Need "
            + string(_potion.cost) + "g");
        return false;
    }

    // [2.2] Semak hero ada
    if (!instance_exists(_hero_id)) {
        show_debug_message("[POTION_SHOP] Hero not found: " + string(_hero_id));
        return false;
    }

    // [2.3] Withdraw gold dari treasury
    gm.kingdom.treasury -= _potion.cost;

    // [2.4] Apply potion effect kepada hero
    with (_hero_id) {
        if (_potion.type == "health") {
            stats.hp = min(stats.hp + _potion.amount, stats.hp_max);
        } else if (_potion.type == "mana") {
            stats.mp = min(stats.mp + _potion.amount, stats.mp_max);
        }
    }

    show_debug_message("[POTION_SHOP] Hero drank " + _potion.name
        + " | Treasury now: " + string(gm.kingdom.treasury) + "g");
    return true;
};

// ============================================================
// [3.0] GET UI DATA
// ============================================================
get_ui_data = function() {
    var _potions_list = [];
    var _keys = variable_struct_get_names(POTIONS);

    for (var i = 0; i < array_length(_keys); i++) {
        var _key     = _keys[i];
        var _potion  = POTIONS[$ _key];
        var _can_buy = (gm.kingdom.treasury >= _potion.cost);

        array_push(_potions_list, {
            key         : _key,
            name        : _potion.name,
            type        : _potion.type,
            amount      : _potion.amount,
            cost        : _potion.cost,
            description : _potion.description,
            can_buy     : _can_buy,
        });
    }

    return {
        potions : _potions_list,
        gold    : gm.kingdom.treasury,
    };
};