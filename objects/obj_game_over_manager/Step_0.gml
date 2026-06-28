// ============================================================
// obj_game_over_manager — Step Event
// ============================================================

// [1.1] Handle screen transitions
switch (screen_state) {

    // [1.1.1] Fade in — dari hitam ke screen
    case SCREEN.FADE_IN:
        fade_timer++;
        fade_alpha = 1.0 - (fade_timer / fade_duration);
        if (fade_timer >= fade_duration) {
            fade_alpha   = 0;
            screen_state = SCREEN.SCORE;
            fade_timer   = 0;
        }
    break;

    // [1.1.2] Score screen — tiada update diperlukan
    case SCREEN.SCORE:
    break;

    // [1.1.3] Legacy selection — tiada update diperlukan
    case SCREEN.LEGACY_SELECT:
    break;

    // [1.1.4] Hall of fallen — tiada update diperlukan
    case SCREEN.HALL:
    break;

    // [1.1.5] Fade out — dari screen ke hitam, lepas tu goto room baru
    case SCREEN.FADE_OUT:
        fade_timer++;
        fade_alpha = fade_timer / fade_duration;
        if (fade_timer >= fade_duration) {
            room_goto(rm_main);
        }
    break;
}