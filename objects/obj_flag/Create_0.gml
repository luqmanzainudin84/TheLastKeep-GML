// ============================================================
// obj_flag — CREATE EVENT
// ============================================================

// [1.1] Flag properties
flag_type = 0; // 0=ATTACK, 1=DEFEND, 2=GATHER, 3=EXPLORE, 4=HEAL
flag_x = x;
flag_y = y;
bounty = 0;
is_active = true;
completion_timer = 0;

// [1.2] Color by type
_get_flag_color = function(_type) {
    switch(_type) {
        case 0: return c_red;
        case 1: return c_blue;
        case 2: return c_lime;
        case 3: return c_aqua;
        case 4: return c_purple;
        default: return c_white;
    }
};

_get_flag_name = function(_type) {
    switch(_type) {
        case 0: return "ATTACK";
        case 1: return "DEFEND";
        case 2: return "GATHER";
        case 3: return "EXPLORE";
        case 4: return "HEAL";
        default: return "UNKNOWN";
    }
};