// ============================================================
// scr_save_system
// Save dan Load system untuk The Last Keep
// ============================================================

// ------------------------------------------------------------
// HELPER — Convert hero blueprint ke JSON-safe struct
// ------------------------------------------------------------
function hero_to_json(_hero) {
    return {
        name      : _hero.name,
        rarity    : _hero.rarity,
        is_legacy : _hero.is_legacy,
        gold      : _hero.gold,
        job       : _hero.job,

        base_stats : {
            strength     : _hero.base_stats.strength,
            intelligence : _hero.base_stats.intelligence,
            agility      : _hero.base_stats.agility,
        },

        stats : {
            hp             : _hero.stats.hp,
            hp_max         : _hero.stats.hp_max,
            mana           : _hero.stats.mana,
            mana_max       : _hero.stats.mana_max,
            hp_regen       : _hero.stats.hp_regen,
            mana_regen     : _hero.stats.mana_regen,
            hp_regen_acc   : _hero.stats.hp_regen_acc,
            mana_regen_acc : _hero.stats.mana_regen_acc,
            move_speed     : _hero.stats.move_speed,
            attack_speed   : _hero.stats.attack_speed,
        },

        personality : {
            iq              : _hero.personality.iq,
            braveness       : _hero.personality.braveness,
            greed           : _hero.personality.greed,
            iq_label        : _hero.personality.iq_label,
            braveness_label : _hero.personality.braveness_label,
            greed_label     : _hero.personality.greed_label,
        },

        history : {
            kills          : _hero.history.kills,
            deaths_avoided : _hero.history.deaths_avoided,
            gold_earned    : _hero.history.gold_earned,
            missions_done  : _hero.history.missions_done,
            waves_survived : _hero.history.waves_survived,
            retreats       : _hero.history.retreats,
        },

        titles : _hero.titles,
    };
}

// ------------------------------------------------------------
// HELPER — Convert JSON data balik ke hero blueprint
// ------------------------------------------------------------
function json_to_hero(_data) {
    return {
        name      : _data.name,
        rarity    : _data.rarity,
        is_legacy : _data.is_legacy,
        gold      : _data.gold,
        job       : _data.job,

        base_stats : {
            strength     : _data.base_stats.strength,
            intelligence : _data.base_stats.intelligence,
            agility      : _data.base_stats.agility,
        },

        stats : {
            hp             : _data.stats.hp,
            hp_max         : _data.stats.hp_max,
            mana           : _data.stats.mana,
            mana_max       : _data.stats.mana_max,
            hp_regen       : _data.stats.hp_regen,
            mana_regen     : _data.stats.mana_regen,
            hp_regen_acc   : 0,
            mana_regen_acc : 0,
            move_speed     : _data.stats.move_speed,
            attack_speed   : _data.stats.attack_speed,
        },

        personality : {
            iq              : _data.personality.iq,
            braveness       : _data.personality.braveness,
            greed           : _data.personality.greed,
            iq_label        : _data.personality.iq_label,
            braveness_label : _data.personality.braveness_label,
            greed_label     : _data.personality.greed_label,
        },

        history : {
            kills          : _data.history.kills,
            deaths_avoided : _data.history.deaths_avoided,
            gold_earned    : _data.history.gold_earned,
            missions_done  : _data.history.missions_done,
            waves_survived : _data.history.waves_survived,
            retreats       : _data.history.retreats ?? 0,
        },

        titles : _data.titles,
    };
}

// ------------------------------------------------------------
// SAVE RUN — simpan progress semasa
// ------------------------------------------------------------
function save_run() {
    var _gm = obj_game_manager;

    // Bina hero roster array untuk JSON
    var _roster_json = [];
    for (var i = 0; i < array_length(_gm.hero_roster); i++) {
        array_push(_roster_json, hero_to_json(_gm.hero_roster[i]));
    }

    // Bina warehouse storage
    var _wh_storage = {};
    if (instance_exists(obj_warehouse)) {
        var _keys = variable_struct_get_names(obj_warehouse.storage);
        for (var i = 0; i < array_length(_keys); i++) {
            var _key = _keys[i];
            _wh_storage[$ _key] = obj_warehouse.storage[$ _key];
        }
    }

    // Bina save struct
    var _save_data = {
        version  : "1.0",
        timestamp: string(current_year) + "-"
                 + string(current_month) + "-"
                 + string(current_day),

        kingdom : {
            th_level        : _gm.kingdom.th_level,
            hero_slots      : _gm.kingdom.hero_slots,
            treasury        : _gm.kingdom.treasury,
            salary_rate     : _gm.kingdom.salary_rate,
            total_days      : _gm.kingdom.total_days_survived,
            total_gold      : _gm.kingdom.total_gold_earned,
            total_heroes_lost: _gm.kingdom.total_heroes_lost,
        },

        calendar : {
            tick   : _gm.calendar.tick,
            day    : _gm.calendar.day,
            week   : _gm.calendar.week,
            month  : _gm.calendar.month,
        },

        wave : {
            current : _gm.wave.current,
            season  : _gm.wave.season,
        },

        hero_roster : _roster_json,
        warehouse   : _wh_storage,
    };

    // Convert ke JSON string dan simpan
    var _json   = json_stringify(_save_data, true);
    var _file   = file_text_open_write(working_directory + "thelastkeep_run.json");
    file_text_write_string(_file, _json);
    file_text_close(_file);

    show_debug_message("[SAVE] Run saved successfully.");
    return true;
}

// ------------------------------------------------------------
// LOAD RUN — load progress dari file
// ------------------------------------------------------------
function load_run() {
    var _path = working_directory + "thelastkeep_run.json";

    // Semak file wujud
    if (!file_exists(_path)) {
        show_debug_message("[SAVE] No run save found.");
        return false;
    }

    // Baca file
    var _file = file_text_open_read(_path);
    var _json = "";
    while (!file_text_eof(_file)) {
        _json += file_text_read_string(_file);
        file_text_readln(_file);
    }
    file_text_close(_file);

    // Parse JSON
    var _data = json_parse(_json);
    var _gm   = obj_game_manager;

    // Restore kingdom
    _gm.kingdom.th_level           = _data.kingdom.th_level;
    _gm.kingdom.hero_slots         = _data.kingdom.hero_slots;
    _gm.kingdom.treasury           = _data.kingdom.treasury;
    _gm.kingdom.salary_rate        = _data.kingdom.salary_rate;
    _gm.kingdom.total_days_survived= _data.kingdom.total_days;
    _gm.kingdom.total_gold_earned  = _data.kingdom.total_gold;
    _gm.kingdom.total_heroes_lost  = _data.kingdom.total_heroes_lost;

    // Restore calendar
    _gm.calendar.tick  = _data.calendar.tick;
    _gm.calendar.day   = _data.calendar.day;
    _gm.calendar.week  = _data.calendar.week;
    _gm.calendar.month = _data.calendar.month;

    // Restore wave
    _gm.wave.current = _data.wave.current;
    _gm.wave.season  = _data.wave.season;

    // Restore hero roster
    _gm.hero_roster = [];
    for (var i = 0; i < array_length(_data.hero_roster); i++) {
        var _hero = json_to_hero(_data.hero_roster[i]);
        array_push(_gm.hero_roster, _hero);

        // Spawn hero instance dalam world
        var _inst = instance_create_layer(
            obj_townhall.x + irandom_range(-60, 60),
            obj_townhall.y + irandom_range(-60, 60),
            "Heroes",
            obj_hero
        );
        _inst.init_from_blueprint(_hero);
    }

    // Restore warehouse
    if (instance_exists(obj_warehouse)) {
        var _keys = variable_struct_get_names(_data.warehouse);
        for (var i = 0; i < array_length(_keys); i++) {
            var _key = _keys[i];
            obj_warehouse.storage[$ _key] = _data.warehouse[$ _key];
        }
    }

    // Update townhall slots
    if (instance_exists(obj_townhall)) {
        obj_townhall.slot_layout.rebuild();
    }

    show_debug_message("[SAVE] Run loaded successfully."
        + " | Wave: " + string(_gm.wave.current)
        + " | TH: " + string(_gm.kingdom.th_level)
        + " | Heroes: " + string(array_length(_gm.hero_roster)));

    return true;
}

// ------------------------------------------------------------
// DELETE RUN SAVE — bila game over
// ------------------------------------------------------------
function delete_run_save() {
    var _path = working_directory + "thelastkeep_run.json";
    if (file_exists(_path)) {
        file_delete(_path);
        show_debug_message("[SAVE] Run save deleted.");
    }
}

// ------------------------------------------------------------
// SAVE LEGACY — simpan legacy hero dan leaderboard
// ------------------------------------------------------------
function save_legacy(_legacy_hero, _legacy_item, _score, _wave, _season) {
    var _path = working_directory + "thelastkeep_legacy.json";

    // Load existing legacy data dulu
    var _existing = load_legacy_raw();

    // Tambah entry baru ke leaderboard
    var _entry = {
        score        : _score,
        wave         : _wave,
        season       : _season,
        legacy_hero  : is_undefined(_legacy_hero)
                       ? undefined
                       : hero_to_json(_legacy_hero),
        timestamp    : string(current_year) + "-"
                     + string(current_month) + "-"
                     + string(current_day),
    };

    array_push(_existing.leaderboard, _entry);

    // Sort leaderboard by score (descending)
    array_sort(_existing.leaderboard, function(a, b) {
        return b.score - a.score;
    });

    // Keep top 10 sahaja
    while (array_length(_existing.leaderboard) > 10) {
        array_delete(_existing.leaderboard,
            array_length(_existing.leaderboard) - 1, 1);
    }

    // Update legacy hero
    if (!is_undefined(_legacy_hero)) {
        _existing.legacy_hero = hero_to_json(_legacy_hero);
        _existing.legacy_item = _legacy_item;
    }

    // Update hall of fallen
    var _gm = obj_game_manager;
    _existing.hall_of_fallen = _gm.hall_of_fallen;

    // Save
    var _json = json_stringify(_existing, true);
    var _file = file_text_open_write(_path);
    file_text_write_string(_file, _json);
    file_text_close(_file);

    show_debug_message("[SAVE] Legacy saved."
        + " | Score: " + string(_score));
}

// ------------------------------------------------------------
// LOAD LEGACY RAW — return struct (buat file baru kalau takde)
// ------------------------------------------------------------
function load_legacy_raw() {
    var _path = working_directory + "thelastkeep_legacy.json";

    if (!file_exists(_path)) {
        return {
            legacy_hero    : undefined,
            legacy_item    : undefined,
            leaderboard    : [],
            hall_of_fallen : [],
        };
    }

    var _file = file_text_open_read(_path);
    var _json = "";
    while (!file_text_eof(_file)) {
        _json += file_text_read_string(_file);
        file_text_readln(_file);
    }
    file_text_close(_file);

    return json_parse(_json);
}

// ------------------------------------------------------------
// LOAD LEGACY HERO — masukkan ke global untuk tavern
// ------------------------------------------------------------
function load_legacy_hero() {
    var _data = load_legacy_raw();

    if (is_undefined(_data.legacy_hero)
    ||  _data.legacy_hero == undefined) {
        show_debug_message("[SAVE] No legacy hero found.");
        return false;
    }

    global.legacy_hero = json_to_hero(_data.legacy_hero);
    global.legacy_item = _data.legacy_item ?? undefined;

    show_debug_message("[SAVE] Legacy hero loaded: "
        + global.legacy_hero.name);
    return true;
}

// ------------------------------------------------------------
// GET LEADERBOARD — untuk display
// ------------------------------------------------------------
function get_leaderboard() {
    var _data = load_legacy_raw();
    return _data.leaderboard;
}

// ------------------------------------------------------------
// AUTOSAVE — dipanggil setiap X minit
// ------------------------------------------------------------
function autosave() {
    save_run();
    show_debug_message("[SAVE] Autosaved.");
}