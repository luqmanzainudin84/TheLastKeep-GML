
// ============================================================
// obj_announcement_manager — DRAW GUI EVENT
// ============================================================

if (current_announcement != undefined) {
    var prev_halign = draw_get_halign();
    var prev_valign = draw_get_valign();
    var prev_color = draw_get_color();
    var prev_alpha = draw_get_alpha();
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_font(fnt_announcement);
    draw_set_color(_get_color(current_announcement.color));
    draw_set_alpha(current_announcement.alpha);
    
    var draw_scale = current_announcement.scale;
    draw_text_transformed(announce_x, announce_y, current_announcement.text, draw_scale, draw_scale, 0);
    
    draw_set_halign(prev_halign);
    draw_set_valign(prev_valign);
    draw_set_color(prev_color);
    draw_set_alpha(prev_alpha);
    draw_set_font(-1);
}