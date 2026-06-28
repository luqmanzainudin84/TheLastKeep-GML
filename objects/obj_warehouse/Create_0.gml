// ============================================================
// obj_warehouse — Create Event
// Resource storage dan supply tracking untuk The Last Keep
// ============================================================

// [1.0] Rujukan ke game manager
gm = obj_game_manager;

// ============================================================
// [2.0] RESOURCE REGISTRY
// ============================================================
RESOURCE = {
    // [2.1] Tier 1
    WOOD         : "wood",
    STONE        : "stone",
    FOOD         : "food",
    HIDE_COMMON  : "hide_common",

    // [2.2] Tier 2
    IRON         : "iron",
    COPPER       : "copper",
    HIDE_THICK   : "hide_thick",

    // [2.3] Tier 3
    CRYSTAL      : "crystal",
    MITHRIL      : "mithril",
    HIDE_RARE    : "hide_rare",
};

// ============================================================
// [3.0] STORAGE
// ============================================================

// [3.1] Cap setiap resource — naik dari 500 ke 2000
storage_cap = 2000;

storage = {};

// [3.2] Init semua resource ke 0
var _resource_keys = variable_struct_get_names(RESOURCE);
for (var i = 0; i < array_length(_resource_keys); i++) {
    var _key = RESOURCE[$ _resource_keys[i]];
    storage[$ _key] = 0;
}

// ============================================================
// [4.0] BASE PRICES
// ============================================================

base_prices = {};
base_prices[$ RESOURCE.WOOD]        = 1;
base_prices[$ RESOURCE.STONE]       = 1;
base_prices[$ RESOURCE.FOOD]        = 2;
base_prices[$ RESOURCE.HIDE_COMMON] = 3;
base_prices[$ RESOURCE.IRON]        = 5;
base_prices[$ RESOURCE.COPPER]      = 4;
base_prices[$ RESOURCE.HIDE_THICK]  = 10;
base_prices[$ RESOURCE.CRYSTAL]     = 20;
base_prices[$ RESOURCE.MITHRIL]     = 35;
base_prices[$ RESOURCE.HIDE_RARE]   = 40;

// ============================================================
// [5.0] SUPPLY & DEMAND
// ============================================================

// [5.1] Kira supply modifier berdasarkan ratio simpanan
get_supply_modifier = function(_resource_type) {
    var _amount = storage[$ _resource_type] ?? 0;
    var _ratio  = _amount / storage_cap;

    if (_ratio > 0.80) return 0.5;
    if (_ratio > 0.50) return 0.8;
    if (_ratio > 0.20) return 1.0;
    if (_ratio > 0.05) return 1.3;
    return 1.8;
};

// [5.2] Dapatkan harga semasa
get_current_price = function(_resource_type) {
    var _base     = base_prices[$ _resource_type] ?? 1;
    var _modifier = get_supply_modifier(_resource_type);
    return max(1, floor(_base * _modifier));
};

// ============================================================
// [6.0] DEPOSIT
// Hero hantar resource ke warehouse
// Return: gold yang hero dapat
// ============================================================
deposit = function(_resource_type, _amount) {
    if (_amount <= 0) return 0;

    // [6.1] Semak space
    var _current = storage[$ _resource_type] ?? 0;
    var _space   = storage_cap - _current;
    var _actual  = min(_amount, _space);

    if (_actual <= 0) {
        show_debug_message("[WAREHOUSE] Full! Cannot deposit "
            + _resource_type);
        return 0;
    }

    // [6.2] Kira gold berdasarkan harga semasa
    var _price       = get_current_price(_resource_type);
    var _gold_earned = _actual * _price;

    // [6.3] Simpan resource
    storage[$ _resource_type] += _actual;

    // [6.4] Bayar hero dari treasury
    gm.kingdom.treasury -= _gold_earned;
    gm.kingdom.treasury  = max(0, gm.kingdom.treasury);

    show_debug_message("[WAREHOUSE] Deposited " + string(_actual)
        + "x " + _resource_type
        + " | Price: " + string(_price) + "g each"
        + " | Total: " + string(_gold_earned) + "g"
        + " | Storage: " + string(storage[$ _resource_type])
        + "/" + string(storage_cap));

    return _gold_earned;
};

// ============================================================
// [7.0] WITHDRAW
// Untuk crafting system keluarkan resource
// ============================================================
withdraw = function(_resource_type, _amount) {
    var _current = storage[$ _resource_type] ?? 0;
    var _actual  = min(_amount, _current);

    if (_actual <= 0) {
        show_debug_message("[WAREHOUSE] Insufficient " + _resource_type
            + ". Have: " + string(_current)
            + " Need: " + string(_amount));
        return 0;
    }

    storage[$ _resource_type] -= _actual;
    return _actual;
};

// [7.1] Semak ada cukup resource
has_enough = function(_resource_type, _amount) {
    return (storage[$ _resource_type] ?? 0) >= _amount;
};

// ============================================================
// [8.0] STORAGE STATUS — untuk UI
// ============================================================

// [8.1] Status satu resource
get_storage_status = function(_resource_type) {
    var _amount   = storage[$ _resource_type] ?? 0;
    var _ratio    = _amount / storage_cap;
    var _price    = get_current_price(_resource_type);
    var _modifier = get_supply_modifier(_resource_type);

    return {
        resource  : _resource_type,
        amount    : _amount,
        cap       : storage_cap,
        ratio     : _ratio,
        price     : _price,
        modifier  : _modifier,
        is_full   : (_amount >= storage_cap),
        is_scarce : (_ratio < 0.05),
    };
};

// [8.2] Status semua resource
get_all_status = function() {
    var _result = [];
    var _keys   = variable_struct_get_names(RESOURCE);
    for (var i = 0; i < array_length(_keys); i++) {
        var _type = RESOURCE[$ _keys[i]];
        array_push(_result, get_storage_status(_type));
    }
    return _result;
};

// ============================================================
// [9.0] UPGRADE STORAGE
// ============================================================
upgrade_cap_cost = 300;

upgrade_storage = function() {
    // [9.1] Semak treasury cukup
    if (gm.kingdom.treasury < upgrade_cap_cost) {
        show_debug_message("[WAREHOUSE] Cannot upgrade. Need "
            + string(upgrade_cap_cost) + "g");
        return false;
    }

    // [9.2] Proses upgrade
    gm.kingdom.treasury -= upgrade_cap_cost;
    storage_cap         += 250;
    upgrade_cap_cost     = floor(upgrade_cap_cost * 1.5);

    show_debug_message("[WAREHOUSE] Upgraded! New cap: "
        + string(storage_cap));
    return true;
};