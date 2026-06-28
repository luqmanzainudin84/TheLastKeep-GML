// ============================================================
// obj_game_over_manager — Draw GUI Event
// ============================================================

// [1.1] Reset draw state
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1.0);

// [1.2] Background gelap penuh
draw_set_color(COL.bg_dark);
draw_rectangle(0, 0, SW, SH, false);

// ============================================================
// [2.0] DRAW SCREEN BERDASARKAN STATE
// ============================================================

// [2.1] Pilih screen untuk dirender
switch (screen_state) {
    case SCREEN.SCORE         : _draw_score_screen();   break;
    case SCREEN.LEGACY_SELECT : _draw_legacy_screen();  break;
    case SCREEN.HALL          : _draw_hall_screen();    break;
}

// ============================================================
// [3.0] FADE OVERLAY
// ============================================================

// [3.1] Draw fade overlay kalau alpha > 0
if (fade_alpha > 0) {
    draw_set_color(c_black);
    draw_set_alpha(fade_alpha);
    draw_rectangle(0, 0, SW, SH, false);
    draw_set_alpha(1.0);
}

// ============================================================
// [4.0] RESET DRAW STATE
// ============================================================
draw_set_color(c_white);
draw_set_alpha(1.0);
draw_set_halign(fa_left);
draw_set_valign(fa_top);