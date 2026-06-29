// ============================================================
// obj_flag — Step Event
// ============================================================

// [1.1] Kalau dah tidak aktif — tunggu semua hero selesai
// lalu bahagi bounty dan destroy
if (!is_active) {

    // [1.1.1] Kira hero yang masih dalam radius flag
    var _heroes_nearby = 0;
    with (obj_hero) {
        if (!variable_instance_exists(id, "ai")) continue;
        if (!status.is_alive()) continue;
        if (is_undefined(ai.current_state)) continue;
        if (ai.current_state.name != "move_to_flag") continue;
        var _dist = point_distance(x, y, other.x, other.y);
        if (_dist <= 64) _heroes_nearby++;
    }

    // [1.1.2] Bila semua hero dah clear — bahagi bounty dan destroy
    if (_heroes_nearby == 0) {

        // Kira berapa hero yang berjaya sampai
        var _hero_count = 0;
        with (obj_hero) {
            if (!variable_instance_exists(id, "current_flag")) continue;
            if (current_flag == other.id) _hero_count++;
        }

        // Bahagi bounty
        if (_hero_count > 0 && bounty > 0) {
            var _share = floor(bounty / _hero_count);
            with (obj_hero) {
                if (!variable_instance_exists(id, "current_flag")) continue;
                if (current_flag != other.id) continue;
                wallet.gold += _share;
                history.gold_earned += _share;
                current_flag = noone;
                show_debug_message("[FLAG] " + identity.name
                    + " received " + string(_share) + "g bounty.");
            }
        }

        // Buang dari active_flags list
        var _idx = ds_list_find_index(global.active_flags, id);
        if (_idx >= 0) ds_list_delete(global.active_flags, _idx);

        instance_destroy();
    }
    exit;
}

// ============================================================
// [2.0] BROADCAST — hero dalam range boleh respond
// Dijalankan setiap 60 frame supaya tidak terlalu kerap
// ============================================================
completion_timer++;
if (completion_timer mod 60 != 0) exit;

// [2.1] Tentukan respond radius berdasarkan bounty
var _respond_radius = 200 + (bounty * 2);

// [2.2] Loop semua hero — decide sama ada nak respond
with (obj_hero) {
    // [2.2.1] Skip hero yang dah ada assignment atau tidak hidup
    if (!variable_instance_exists(id, "ai"))           continue;
    if (!variable_instance_exists(id, "current_flag")) continue;
    if (!status.is_alive())                            continue;
    if (current_flag != noone)                         continue;

    // [2.2.2] Semak dalam radius
    var _dist = point_distance(x, y, other.x, other.y);
    if (_dist > _respond_radius) continue;

    // [2.2.3] Hero decide — berdasarkan personality
    var _accept = _hero_will_respond(
        other.bounty,
        other.flag_type,
        _dist,
        _respond_radius,
        personality.braveness,
        personality.greed
    );

    if (_accept) {
        current_flag = other.id;
        ai.change_state("move_to_flag");
        show_debug_message("[FLAG] " + identity.name
            + " responding to " + other._get_flag_name(other.flag_type)
            + " flag | Bounty: " + string(other.bounty) + "g"
            + " | Dist: " + string(floor(_dist)));
    }
}

// ============================================================
// [3.0] HELPER — hero respond decision
// ============================================================
function _hero_will_respond(_bounty, _flag_type, _dist, _max_dist, _braveness, _greed) {

    // [3.1] Base score dari bounty dan jarak
    var _dist_factor  = 1 - (_dist / _max_dist);      // 1.0 = dekat, 0.0 = jauh
    var _bounty_score = _bounty * (_greed / 100);
    var _dist_score   = _dist_factor * 50;

    // [3.2] Flag type modifier berdasarkan braveness
    var _type_mod = 1.0;
    switch (_flag_type) {
        case 0: _type_mod = _braveness / 100;         break; // ATTACK — perlu berani
        case 1: _type_mod = _braveness / 100 * 0.8;  break; // DEFEND — sedikit berani
        case 2: _type_mod = 1.0;                      break; // GATHER — semua ok
        case 3: _type_mod = (_braveness + 50) / 150;  break; // EXPLORE — sederhana
        case 4: _type_mod = 1.0;                      break; // HEAL — semua ok
    }

    // [3.3] Final score
    var _total = (_bounty_score + _dist_score) * _type_mod;

    // [3.4] Random threshold — makin tinggi score makin besar chance respond
    var _threshold = irandom_range(20, 80);
    return (_total >= _threshold);
}