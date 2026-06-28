// ============================================================
// obj_announcement_manager — CREATE EVENT
// ============================================================

// [1.1] Queue
announcement_queue = ds_queue_create();
current_announcement = undefined;

// [1.2] Timing
fade_in_time = 0.3;
hold_time = 1.5;
fade_out_time = 0.3;

// [1.3] Display
announce_x = 640;
announce_y = 120;
announce_font = "fnt_announcement";

// [1.5] Helper function to get color value
function _get_color(color_enum) {
    switch(color_enum) {
        case global.ANNOUNCE_COLOR.RED:   return c_red;
        case global.ANNOUNCE_COLOR.GREEN: return c_lime;
        case global.ANNOUNCE_COLOR.GOLD:  return c_yellow;
        case global.ANNOUNCE_COLOR.BLUE:  return c_cyan;
        default: return c_white;
    }
}

// [1.6] Add announcement to queue
function add_announcement(text, color = global.ANNOUNCE_COLOR.BLUE, duration_hold = 1.5, sound_effect = undefined) {
    var ann_struct = {
        text: text,
        color: color,
        sound: sound_effect,
        hold_time: duration_hold,
        state: "idle",
        timer: 0,
        alpha: 0,
        scale: 0.8
    };
    ds_queue_enqueue(announcement_queue, ann_struct);
}

// [1.7] Remove all announcements
function remove_all() {
    while (!ds_queue_empty(announcement_queue)) {
        ds_queue_dequeue(announcement_queue);
    }
    current_announcement = undefined;
}

// [1.8] Remove current announcement
function remove_current() {
    current_announcement = undefined;
}
