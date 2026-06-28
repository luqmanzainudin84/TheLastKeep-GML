// ============================================================
// obj_blacksmith — Create Event
// Player-driven crafting untuk weapon dan armor
// ============================================================

gm = obj_game_manager;

// ============================================================
// RECIPE BOOK
// ============================================================
RECIPES = {
    // Format: { name, item_type, ingredients[], output_price, craft_time }
    // craft_time dalam ticks

    sword_basic : {
        name         : "Basic Sword",
        item_type    : "weapon_basic",
        ingredients  : [
            { type: "iron", amount: 3 },
            { type: "wood", amount: 1 },
        ],
        output_price : 45,
        craft_time   : room_speed * 10,  // 10 saat
        stat_bonus   : { attack: 8 },
    },

    sword_iron : {
        name         : "Iron Sword",
        item_type    : "weapon_iron",
        ingredients  : [
            { type: "iron",   amount: 6 },
            { type: "wood",   amount: 2 },
            { type: "stone",  amount: 1 },
        ],
        output_price : 90,
        craft_time   : room_speed * 20,
        stat_bonus   : { attack: 18 },
    },

    armor_basic : {
        name         : "Leather Armor",
        item_type    : "armor_basic",
        ingredients  : [
            { type: "hide_common", amount: 4 },
            { type: "wood",        amount: 1 },
        ],
        output_price : 55,
        craft_time   : room_speed * 12,
        stat_bonus   : { hp_max: 30 },
    },

    armor_iron : {
        name         : "Iron Armor",
        item_type    : "armor_iron",
        ingredients  : [
            { type: "iron",       amount: 5 },
            { type: "hide_thick", amount: 2 },
        ],
        output_price : 110,
        craft_time   : room_speed * 25,
        stat_bonus   : { hp_max: 70 },
    },
};

// ============================================================
// CRAFTING QUEUE
// ============================================================
craft_queue  = [];      // array of { recipe_key, timer }
is_crafting  = false;
craft_timer  = 0;

// ============================================================
// CRAFT — player request craft item
// ============================================================
craft = function(_recipe_key) {
    var _recipe = RECIPES[$ _recipe_key];

    if (is_undefined(_recipe)) {
        show_debug_message("[BLACKSMITH] Unknown recipe: " + _recipe_key);
        return false;
    }

    // Semak ingredients ada dalam warehouse
    var _wh = obj_warehouse;
    for (var i = 0; i < array_length(_recipe.ingredients); i++) {
        var _ing = _recipe.ingredients[i];
        if (!_wh.has_enough(_ing.type, _ing.amount)) {
            show_debug_message("[BLACKSMITH] Missing ingredient: "
                + _ing.type + " (need " + string(_ing.amount) + ")");
            return false;
        }
    }

    // Withdraw ingredients
    for (var i = 0; i < array_length(_recipe.ingredients); i++) {
        var _ing = _recipe.ingredients[i];
        _wh.withdraw(_ing.type, _ing.amount);
    }

    // Tambah ke queue
    array_push(craft_queue, {
        recipe_key : _recipe_key,
        timer      : 0,
    });

    show_debug_message("[BLACKSMITH] Crafting queued: " + _recipe.name);
    return true;
};

// ============================================================
// UPDATE — process craft queue
// ============================================================
update_crafting = function() {
    if (array_length(craft_queue) == 0) {
        is_crafting = false;
        return;
    }

    is_crafting = true;
    var _current = craft_queue[0];
    var _recipe  = RECIPES[$ _current.recipe_key];

    _current.timer++;

    if (_current.timer >= _recipe.craft_time) {
        // Siap! Hantar ke marketplace
        _complete_craft(_current.recipe_key);
        array_delete(craft_queue, 0, 1);
    }
};

_complete_craft = function(_recipe_key) {
    var _recipe = RECIPES[$ _recipe_key];

    var _item = {
        name       : _recipe.name,
        item_type  : _recipe.item_type,
        price      : _recipe.output_price,
        stat_bonus : _recipe.stat_bonus,
    };

    // Hantar ke marketplace
    if (instance_exists(obj_marketplace)) {
        obj_marketplace.add_item(_item);
    }

    show_debug_message("[BLACKSMITH] Crafted: " + _recipe.name
        + " | Sent to marketplace.");
};

// ============================================================
// GET UI DATA
// ============================================================
get_ui_data = function() {
    var _recipes_list = [];
    var _keys = variable_struct_get_names(RECIPES);

    for (var i = 0; i < array_length(_keys); i++) {
        var _key    = _keys[i];
        var _recipe = RECIPES[$ _key];
        var _wh     = obj_warehouse;

        // Semak boleh craft atau tidak
        var _can_craft = true;
        for (var j = 0; j < array_length(_recipe.ingredients); j++) {
            var _ing = _recipe.ingredients[j];
            if (!_wh.has_enough(_ing.type, _ing.amount)) {
                _can_craft = false;
                break;
            }
        }

        array_push(_recipes_list, {
            key         : _key,
            name        : _recipe.name,
            ingredients : _recipe.ingredients,
            price       : _recipe.output_price,
            craft_time  : _recipe.craft_time,
            can_craft   : _can_craft,
        });
    }

    return {
        recipes     : _recipes_list,
        queue       : craft_queue,
        is_crafting : is_crafting,
    };
};