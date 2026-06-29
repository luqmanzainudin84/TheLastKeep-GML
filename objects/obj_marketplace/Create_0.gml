// ============================================================
// obj_marketplace — Create Event
// Player set harga, hero beli/jual barang
// ============================================================

gm = obj_game_manager;

// ============================================================
// SHOP INVENTORY
// ============================================================
shop_items = [];

add_item = function(_item) {
    array_push(shop_items, _item);
    show_debug_message("[MARKET] Added to shop: " + _item.name
        + " | Price: " + string(_item.price) + "g");
};

remove_item = function(_index) {
    if (_index < 0 || _index >= array_length(shop_items)) return;
    array_delete(shop_items, _index, 1);
};

// ============================================================
// HERO PURCHASE LOGIC
// ============================================================
hero_purchase = function(_hero_instance) {
    var _hero = _hero_instance;
    var _iq   = _hero.personality.iq;

    if (_iq <= 25) {
        show_debug_message("[MARKET] " + _hero.identity.name
            + " (Dull) ignores the shop.");
        return;
    }

    var _shopping_list = _build_shopping_list(_hero);

    for (var i = 0; i < array_length(_shopping_list); i++) {
        var _want     = _shopping_list[i];
        var _item_idx = _find_item(_want.type);

        if (_item_idx == -1) continue;

        var _item = shop_items[_item_idx];

        if (_hero.wallet.gold < _item.price) continue;

        // Beli
        _hero.wallet.gold   -= _item.price;
        gm.kingdom.treasury += _item.price;

        // [BARU] Apply equipment ke hero instance
        _apply_item_to_hero(_hero, _item);

        show_debug_message("[MARKET] " + _hero.identity.name
            + " bought " + _item.name
            + " for " + string(_item.price) + "g"
            + " | Wallet: " + string(_hero.wallet.gold) + "g");

        remove_item(_item_idx);
    }
};

// [BARU] Apply item ke hero — cari live instance dan equip
_apply_item_to_hero = function(_hero_blueprint, _item) {
    // Potion — apply terus ke stats
    if (string_pos("potion", _item.item_type) > 0) {
        with (obj_hero) {
            if (!variable_instance_exists(id, "identity")) continue;
            if (identity.name != _hero_blueprint.identity.name) continue;
            if (_item.item_type == "potion_health") {
                stats.hp = min(stats.hp + 50, stats.hp_max);
                show_debug_message("[MARKET] " + identity.name
                    + " drank health potion.");
            }
            else if (_item.item_type == "potion_mana") {
                stats.mana = min(stats.mana + 50, stats.mana_max);
                show_debug_message("[MARKET] " + identity.name
                    + " drank mana potion.");
            }
            break;
        }
        return;
    }

    // Weapon / Armor — equip pada live instance
    with (obj_hero) {
        if (!variable_instance_exists(id, "identity")) continue;
        if (identity.name != _hero_blueprint.identity.name) continue;
        if (!variable_instance_exists(id, "equipment")) continue;
        equipment.equip(_item);
        break;
    }
};

// ============================================================
// SHOPPING LIST
// ============================================================
_build_shopping_list = function(_hero) {
    var _list   = [];
    var _iq     = _hero.personality.iq;
    var _hp_pct = _hero.stats.hp / _hero.stats.hp_max;

    if (_iq > 25 && _hp_pct < 0.7) {
        array_push(_list, { type: "potion_health", priority: 1 });
    }

    if (_iq > 50) {
        array_push(_list, { type: "potion_health", priority: 1 });
        array_push(_list, { type: "weapon_basic",  priority: 2 });
    }

    if (_iq > 75) {
        array_push(_list, { type: "potion_health",  priority: 1 });
        array_push(_list, { type: "potion_mana",    priority: 1 });
        array_push(_list, { type: "weapon_basic",   priority: 2 });
        array_push(_list, { type: "armor_basic",    priority: 2 });
    }

    array_sort(_list, function(a, b) {
        return a.priority - b.priority;
    });

    return _list;
};

_find_item = function(_type) {
    for (var i = 0; i < array_length(shop_items); i++) {
        if (shop_items[i].item_type == _type) return i;
    }
    return -1;
};

// ============================================================
// GET UI DATA
// ============================================================
get_ui_data = function() {
    return {
        items      : shop_items,
        item_count : array_length(shop_items),
        treasury   : gm.kingdom.treasury,
    };
};