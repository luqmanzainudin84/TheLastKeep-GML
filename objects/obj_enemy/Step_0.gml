// ============================================================
// obj_enemy — Step Event
// ============================================================

// [1.1] Safety check — stats belum ready
if (!variable_instance_exists(id, "stats")) exit;

// [1.2] Handle death state — fade out sebelum destroy
if (estate == ESTATE.DIE) {
    die_timer++;
    if (die_timer >= die_duration) {
        instance_destroy();
    }
    exit;
}

// [1.3] Refresh target setiap 30 frame atau target hilang
if (current_time mod 30 == 0
||  current_target == noone
||  !instance_exists(current_target)) {
    current_target = find_target();
}

// [1.4] Kalau tiada target — diam
if (current_target == noone) exit;

// [1.5] Kira jarak ke target
var _tx   = current_target.x;
var _ty   = current_target.y;
var _dist = point_distance(x, y, _tx, _ty);
var _spd  = stats.move_speed / room_speed;

// [1.6] State: MOVE — gerak ke target
if (estate == ESTATE.MOVE) {
    if (_dist > stats.attack_range) {
        x += ((_tx - x) / _dist) * _spd;
        y += ((_ty - y) / _dist) * _spd;
    } else {
        estate       = ESTATE.ATTACK;
        attack_timer = 0;
    }
}

// [1.7] State: ATTACK — serang target
else if (estate == ESTATE.ATTACK) {

    // [1.7.1] Target keluar range — kejar semula
    if (_dist > stats.attack_range * 1.3) {
        estate = ESTATE.MOVE;
        exit;
    }

    // [1.7.2] Ranged enemy — maintain jarak selamat
    if (stats.is_ranged && _dist < stats.attack_range * 0.6) {
        var _angle = point_direction(_tx, _ty, x, y);
        x += lengthdir_x(_spd, _angle);
        y += lengthdir_y(_spd, _angle);
        exit;
    }

    // [1.7.3] Attack tick
    attack_timer++;
    if (attack_timer >= stats.attack_rate) {
        attack_timer = 0;

        // [1.7.4] Deal damage berdasarkan target type
        if (instance_exists(current_target)) {
            show_debug_message("[ENEMY] Attacking: "
                + object_get_name(current_target.object_index)
                + " | has take_damage: "
                + string(variable_instance_exists(current_target, "take_damage")));
            if (variable_instance_exists(current_target, "take_damage")) {
                current_target.take_damage(stats.damage);
            }
            else if (variable_instance_exists(current_target, "hp")) {
                current_target.hp -= stats.damage;
                if (current_target.hp <= 0) {
                    instance_destroy(current_target);
                    current_target = noone;
                    estate         = ESTATE.MOVE;
                }
            }
        }

    } // ← tutup if (attack_timer >= stats.attack_rate)

} // ← tutup else if (estate == ESTATE.ATTACK)