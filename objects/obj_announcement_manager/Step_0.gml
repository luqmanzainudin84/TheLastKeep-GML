
// ============================================================
// obj_announcement_manager — STEP EVENT
// ============================================================

// [2.1] Check queue
if (current_announcement == undefined) {
    if (!ds_queue_empty(announcement_queue)) {
        current_announcement = ds_queue_dequeue(announcement_queue);
        current_announcement.state = "fade_in";
        current_announcement.timer = 0;
        current_announcement.alpha = 0;
        current_announcement.scale = 0.8;
    }
}

// [2.2] Update animation
if (current_announcement != undefined) {
    current_announcement.timer += (1/60);
    
    if (current_announcement.state == "fade_in") {
        var progress = current_announcement.timer / fade_in_time;
        current_announcement.alpha = clamp(progress, 0, 1);
        current_announcement.scale = lerp(0.8, 1.0, progress);
        
        if (current_announcement.timer >= fade_in_time) {
            current_announcement.state = "hold";
            current_announcement.timer = 0;
            current_announcement.alpha = 1.0;
            current_announcement.scale = 1.0;
        }
    } else if (current_announcement.state == "hold") {
        if (current_announcement.timer >= current_announcement.hold_time) {
            current_announcement.state = "fade_out";
            current_announcement.timer = 0;
        }
    } else if (current_announcement.state == "fade_out") {
        var progress = current_announcement.timer / fade_out_time;
        current_announcement.alpha = clamp(1 - progress, 0, 1);
        current_announcement.scale = lerp(1.0, 1.2, progress);
        
        if (current_announcement.timer >= fade_out_time) {
            current_announcement = undefined;
        }
    }
}
