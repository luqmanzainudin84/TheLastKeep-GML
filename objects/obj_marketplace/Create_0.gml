// ============================================================
// obj_marketplace — Create Event
// Player set harga, hero beli/jual barang
// ============================================================

gm = obj_game_manager;

// ============================================================
// SHOP INVENTORY — apa yang ada untuk dijual kepada hero
// Diisi oleh crafting system (blacksmith, potion shop)
// ============================================================
shop_items = [];    // array of item structs

// Tambah item ke shop (dipanggil oleh crafting system)
add_item = function(_item) {
    array_push(shop_items, _item);
    show_debug_message("[MARKET] Added to shop: " + _item.name
        + " | Price: " + string(_item.price) + "g");
};

// Buang item dari shop (bila terjual)
remove_item = function(_index) {
    if (_index < 0 || _index >= array_length(shop_items)) return;
    array_delete(shop_items, _index, 1);
};

// ============================================================
// HERO PURCHASE LOGIC
// Hero datang ke marketplace untuk beli item
// Dipanggil oleh hero AI sebelum keluar untuk mission
// ============================================================
hero_purchase = function(_hero_instance) {
    var _hero = _hero_instance;
    var _iq   = _hero.personality.iq;

    // IQ Band 1 (Dull) — tak beli apa-apa
    if (_iq <= 25) {
        show_debug_message("[MARKET] " + _hero.identity.name
            + " (Dull) ignores the shop.");
        return;
    }

    // Tentukan apa yang hero nak beli berdasarkan IQ
    var _shopping_list = _build_shopping_list(_hero);

    for (var i = 0; i < array_length(_shopping_list); i++) {
        var _want      = _shopping_list[i];
        var _item_idx  = _find_item(_want.type);

        if (_item_idx == -1) continue; // item tak ada

        var _item = shop_items[_item_idx];

        // Semak hero ada cukup gold
        if (_hero.wallet.gold < _item.price) continue;

        // Beli!
        _hero.wallet.gold       -= _item.price;
        gm.kingdom.treasury     += _item.price; // revenue balik ke kingdom

        // Tambah ke hero inventory/equipment
        // TODO: implement equipment system
        show_debug_message("[MARKET] " + _hero.identity.name
            + " bought " + _item.name
            + " for " + string(_item.price) + "g"
            + " | Wallet: " + string(_hero.wallet.gold) + "g");

        remove_item(_item_idx);
    }
};

// Bina shopping list berdasarkan IQ dan keperluan
_build_shopping_list = function(_hero) {
    var _list = [];
    var _iq   = _hero.personality.iq;
    var _hp_pct = _hero.stats.hp / _hero.stats.hp_max;

    // IQ Band 2+ — beli potion kalau HP rendah
    if (_iq > 25 && _hp_pct < 0.7) {
        array_push(_list, { type: "potion_health", priority: 1 });
    }

    // IQ Band 3+ — beli spare weapon + potion sebelum mission
    if (_iq > 50) {
        array_push(_list, { type: "potion_health", priority: 1 });
        array_push(_list, { type: "weapon_basic",  priority: 2 });
    }

    // IQ Band 4 — beli berdasarkan destination danger
    if (_iq > 75) {
        array_push(_list, { type: "potion_health",  priority: 1 });
        array_push(_list, { type: "potion_mana",    priority: 1 });
        array_push(_list, { type: "weapon_basic",   priority: 2 });
        array_push(_list, { type: "armor_basic",    priority: 2 });
    }

    // Sort by priority
    array_sort(_list, function(a, b) {
        return a.priority - b.priority;
    });

    return _list;
};

// Cari item dalam shop mengikut type
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
        items        : shop_items,
        item_count   : array_length(shop_items),
        treasury     : gm.kingdom.treasury,
    };
};