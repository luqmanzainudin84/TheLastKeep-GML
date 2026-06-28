// ============================================================
// obj_ui_manager — Step Event
// ============================================================

// [1.1] Safety check
if (!instance_exists(obj_game_manager)) exit;

// [1.2] Mouse position dalam GUI coords
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);

// [1.3] World mouse position
var _world_mx = _mx + obj_game_manager.cam.x;
var _world_my = _my + obj_game_manager.cam.y;

// [1.4] Semak sama ada mouse dalam UI area
var _in_top_bar    = (_my < HUD.top_h);
var _in_bottom_bar = (_my > SH - HUD.bottom_h);
var _in_ui         = _in_top_bar || _in_bottom_bar
                  || (active_panel != PANEL.NONE);

// [1.5] World click detection — klik hero dalam world
if (mouse_check_button_released(mb_left) && !_in_ui) {
    with (obj_hero) {
        if (!variable_instance_exists(id, "identity")) continue;
        var _dist = point_distance(_world_mx, _world_my, x, y);
        if (_dist < 24) {
            for (var i = 0; i < array_length(obj_game_manager.hero_roster); i++) {
                if (obj_game_manager.hero_roster[i].name == identity.name) {
                    obj_ui_manager.selected_hero_idx = i;
                    obj_ui_manager.open_panel(obj_ui_manager.PANEL.HERO_INFO);
                    break;
                }
            }
            break;
        }
    }
}

// [1.6] Button clicks dalam UI
if (mouse_check_button_released(mb_left)) {

    // [DEBUG] — padam bila dah fix
    debug_click(_mx, _my, show_job_panel, job_panel_hero_idx);

    // [1.6.1] Butang TAVERN dalam bottom bar
    var _btn_tavern_x = SW - HUD.padding - 100;
    var _btn_tavern_y = SH - HUD.bottom_h + 8;

    if (point_in_rectangle(_mx, _my,
        _btn_tavern_x, _btn_tavern_y,
        _btn_tavern_x + 90, _btn_tavern_y + 32)) {
        toggle_panel(PANEL.TAVERN);
        if (active_panel == PANEL.TAVERN) {
            if (instance_exists(obj_tavern)) {
                obj_tavern.open_tavern();
            }
        }
    }

    // [1.6.2] Klik dalam Tavern Panel
    if (active_panel == PANEL.TAVERN && instance_exists(obj_tavern)) {
        var _data = obj_tavern.get_ui_data();
        var _pw   = 620;
        var _ph   = 420;
        var _px   = (SW - _pw) / 2;
        var _py   = (SH - _ph) / 2;

        // [1.6.2.1] Klik X — close tavern panel
        if (point_in_rectangle(_mx, _my,
            _px + _pw - 22, _py + 4,
            _px + _pw, _py + 22)) {
            close_panel();
            obj_tavern.close_tavern();
        }

        // [1.6.2.2] Klik Refresh
        var _rbtn_x = _px + _pw - 110;
        var _rbtn_y = _py + _ph - 45;
        if (point_in_rectangle(_mx, _my,
            _rbtn_x, _rbtn_y,
            _rbtn_x + 90, _rbtn_y + 32)) {
            if (obj_tavern.refresh_heroes()) {
                add_notification("Tavern refreshed!", COL.text_gold);
            } else {
                add_notification("Not enough gold!", COL.text_red);
            }
        }

        // [1.6.2.3] Klik Recruit button pada hero card
        var _card_w        = 180;
        var _card_h        = 310;
        var _card_gap      = 15;
        var _cards_total_w = (_card_w * 3) + (_card_gap * 2);
        var _card_start_x  = _px + (_pw - _cards_total_w) / 2;
        var _card_y        = _py + 45;

        for (var i = 0; i < array_length(_data.heroes); i++) {
            var _cx      = _card_start_x + (i * (_card_w + _card_gap));
            var _rbtn_cy = _card_y + _card_h - 40;

            if (point_in_rectangle(_mx, _my,
                _cx + 10, _rbtn_cy,
                _cx + _card_w - 10, _rbtn_cy + 30)) {
                if (obj_tavern.recruit_hero(i)) {
                    var _hero_name = _data.heroes[i].name;
                    add_notification(_hero_name + " joined the kingdom!",
                                     COL.text_green);
                } else {
                    add_notification("Cannot recruit!", COL.text_red);
                }
                break;
            }
        }
    }

    // [1.6.3] Klik Hero Slot dalam bottom bar
    var _slot_start_x = HUD.padding + 55;
    var _slot_y       = SH - HUD.bottom_h + 10;

    for (var i = 0; i < obj_game_manager.kingdom.hero_slots; i++) {
        var _sx = _slot_start_x + (i * 35);
        if (point_in_rectangle(_mx, _my,
            _sx, _slot_y,
            _sx + 30, _slot_y + 30)) {
            if (i < array_length(obj_game_manager.hero_roster)) {
                selected_hero_idx = i;
                open_panel(PANEL.HERO_INFO);
            }
            break;
        }
    }

    // [1.6.4] Klik X pada Hero Info Panel
    if (active_panel == PANEL.HERO_INFO) {
        var _pw = 260;
        var _px = SW - _pw - 10;
        var _py = HUD.top_h + 10;
        if (point_in_rectangle(_mx, _my,
            _px + _pw - 22, _py + 4,
            _px + _pw, _py + 22)) {
            close_panel();
            show_job_panel = false;
        }
    }

    // [1.6.5] Klik Change Job button
    if (active_panel == PANEL.HERO_INFO
    &&  selected_hero_idx >= 0
    &&  !show_job_panel) {
        var _pw = 260;
        var _px = SW - _pw - 10;
        var _py = HUD.top_h + 10;
        var _job_btn_y = _py + 280;  // CALCULATE DARI PANEL POSITION

        if (point_in_rectangle(_mx, _my,
            _px + 10, _job_btn_y,
            _px + _pw - 10, _job_btn_y + 24)) {
            show_job_panel     = true;
            job_panel_hero_idx = selected_hero_idx;
            show_debug_message("[UI] Job panel opened for: "
                + obj_game_manager.hero_roster[selected_hero_idx].name);
        }
    }

    // [1.6.6] Klik job dalam job panel
    if (show_job_panel && job_panel_hero_idx >= 0) {
        var _jobs = [
            "Gatherer", "Warrior", "Archer", "Explorer",
            "Miner", "Guard", "Healer", "Wizard", "Rogue", "Paladin"
        ];
        var _pw = 200;
        var _px = SW - 270 - _pw - 10;
        var _py = HUD.top_h + 10;

        for (var i = 0; i < array_length(_jobs); i++) {
            var _jy = _py + 24 + (i * 28);
            if (point_in_rectangle(_mx, _my,
                _px + 5,       _jy - 2,
                _px + _pw - 5, _jy + 22)) {

                var _raw     = obj_game_manager.hero_roster[job_panel_hero_idx];
                var _new_job = _jobs[i];
                _raw.job     = _new_job;

                with (obj_hero) {
                    if (!variable_instance_exists(id, "identity")) continue;
                    if (identity.name == _raw.name) {
                        job.assign(_new_job);
                        if (variable_instance_exists(id, "ai")) {
                            ai.change_state("idle");
                        }
                        show_debug_message("[UI] Job changed: "
                            + identity.name + " to " + _new_job);
                        break;
                    }
                }

                add_notification(_raw.name + " is now a " + _new_job + "!",
                                 COL.text_gold);
                show_job_panel = false;
                break;
            }
        }
    }

// [1.6.7] Klik Warehouse button
    var _btn_wh_x = SW - HUD.padding - 340;
    var _btn_wh_y = SH - HUD.bottom_h + 8;

    if (point_in_rectangle(_mx, _my,
        _btn_wh_x, _btn_wh_y,
        _btn_wh_x + 100, _btn_wh_y + 32)) {
        toggle_panel(PANEL.WAREHOUSE);
    }

    // [1.6.8] Klik Blacksmith button
    var _btn_bs_x = SW - HUD.padding - 450;
    var _btn_bs_y = SH - HUD.bottom_h + 8;

    if (point_in_rectangle(_mx, _my,
        _btn_bs_x, _btn_bs_y,
        _btn_bs_x + 100, _btn_bs_y + 32)) {
        toggle_panel(PANEL.BLACKSMITH);
    }

    // [1.6.8.1] Klik Craft button dalam blacksmith panel
    if (active_panel == PANEL.BLACKSMITH
    &&  instance_exists(obj_blacksmith)) {
        var _pw    = 360;
        var _ph    = 580;
        var _px    = 10;
        var _py    = HUD.top_h + 10;
        var _data  = obj_blacksmith.get_ui_data();
        var _ty    = _py + 38;
        var _row_h = 18;
        var _ing_h = 16;
        var _btn_h = 30;
        var _div_h = 12;
        var _pad   = 8;
        var _limit = _py + _ph - 65;

        for (var i = 0; i < array_length(_data.recipes); i++) {
            var _r       = _data.recipes[i];
            var _num_ing = array_length(_r.ingredients);
            var _entry_h = _row_h + (_num_ing * _ing_h) + _pad + _btn_h + _div_h;

            if (_ty + _entry_h > _limit) break;

            _ty += _row_h;
            _ty += _num_ing * _ing_h;
            _ty += _pad;

            if (point_in_rectangle(_mx, _my,
                _px + 10, _ty,
                _px + _pw - 10, _ty + 22)) {
                if (_r.can_craft) {
                    if (obj_blacksmith.craft(_r.key)) {
                        add_notification("Crafting: " + _r.name + "!",
                                         COL.text_gold);
                    }
                } else {
                    add_notification("Not enough materials!", COL.text_red);
                }
                break;
            }

            _ty += _btn_h;
            _ty += _div_h;
        }
    }

    // [1.6.9] Klik Potion Shop button
    var _btn_ps_x = SW - HUD.padding - 560;
    var _btn_ps_y = SH - HUD.bottom_h + 8;

    if (point_in_rectangle(_mx, _my,
        _btn_ps_x, _btn_ps_y,
        _btn_ps_x + 110, _btn_ps_y + 32)) {
        toggle_panel(PANEL.POTION_SHOP);
    }

    // [1.6.9.1] Klik Buy button dalam potion shop panel
    if (active_panel == PANEL.POTION_SHOP
    &&  instance_exists(obj_potion_shop)) {
        var _pw   = 280;
        var _ph   = 280;
        var _px   = 10;
        var _py   = HUD.top_h + 10;
        var _data = obj_potion_shop.get_ui_data();
        var _ty   = _py + 60;

        for (var i = 0; i < array_length(_data.potions); i++) {
            var _p = _data.potions[i];
            _ty += 16 + 14;

            if (point_in_rectangle(_mx, _my,
                _px + 10, _ty,
                _px + _pw - 10, _ty + 24)) {

                if (selected_hero_idx >= 0
                &&  selected_hero_idx < array_length(obj_game_manager.hero_roster)) {
                    var _hero = obj_game_manager.hero_roster[selected_hero_idx];
                    
                    var _hero_id = noone;
                    with (obj_hero) {
                        if (identity.name == _hero.name) {
                            _hero_id = id;
                            break;
                        }
                    }

                    if (_hero_id != noone) {
                        if (obj_potion_shop.buy_potion(_p.key, _hero_id)) {
                            add_notification(_hero.name + " drank "
                                + _p.name + "!", COL.text_green);
                        } else {
                            add_notification("Cannot buy!", COL.text_red);
                        }
                    } else {
                        add_notification("Hero not in battle!", COL.text_red);
                    }
                } else {
                    add_notification("Select a hero first!", COL.text_red);
                }
                break;
            }
            _ty += 32;
        }
    }

    // [1.6.10] Butang TH UPGRADE
    var _btn_th_x = SW - HUD.padding - 210;
    var _btn_th_y = SH - HUD.bottom_h + 8;

    if (point_in_rectangle(_mx, _my,
        _btn_th_x, _btn_th_y,
        _btn_th_x + 100, _btn_th_y + 32)) {
        if (instance_exists(obj_townhall)) {
            var _result = obj_townhall.start_upgrade();
            if (_result) {
                add_notification("Townhall upgrading!", COL.text_gold);
            } else {
                var _th = obj_townhall.get_ui_data();
                if (_th.is_upgrading) {
                    add_notification("Already upgrading!", COL.text_red);
                } else if (_th.th_level >= 10) {
                    add_notification("Townhall is max level!", COL.text_grey);
                } else {
                    add_notification("Not enough gold! Need "
                        + string(_th.upgrade_cost) + "g", COL.text_red);
                }
            }
        }
    }

} // ← TUTUP mouse_check_button_released BLOCK