// ============================================================
// obj_game_over_manager — Left Button Released
// ============================================================

// [1.1] Mouse position
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);

// [1.2] Jangan process input semasa fade
if (screen_state == SCREEN.FADE_IN
||  screen_state == SCREEN.FADE_OUT) exit;

// ============================================================
// [2.0] SCORE SCREEN BUTTONS
// ============================================================
if (screen_state == SCREEN.SCORE) {

    var _btn_y = 90 + 320 + 20;

    // [2.1] Butang Choose Legacy
    if (point_in_rectangle(_mx, _my,
        SW/2 - 210, _btn_y,
        SW/2 - 10,  _btn_y + 40)) {
        if (array_length(surviving_heroes) > 0) {
            screen_state = SCREEN.LEGACY_SELECT;
        } else {
            screen_state = SCREEN.LEGACY_SELECT;
        }
    }

    // [2.2] Butang Hall of Fallen
    if (point_in_rectangle(_mx, _my,
        SW/2 + 10,  _btn_y,
        SW/2 + 210, _btn_y + 40)) {
        screen_state = SCREEN.HALL;
    }
}

// ============================================================
// [3.0] LEGACY SELECTION SCREEN BUTTONS
// ============================================================
else if (screen_state == SCREEN.LEGACY_SELECT) {

    var _card_w        = 160;
    var _card_h        = 340;
    var _card_gap      = 15;
    var _total_w       = min(array_length(surviving_heroes), 5)
                       * (_card_w + _card_gap) - _card_gap;
    var _start_x       = (SW - _total_w) / 2;
    var _card_y        = 80;
    var _confirm_y     = _card_y + _card_h + 20;

    // [3.1] Klik hero card — select legacy hero
    for (var i = 0; i < min(array_length(surviving_heroes), 5); i++) {
        var _cx    = _start_x + (i * (_card_w + _card_gap));
        var _btn_y = _card_y + _card_h - 35;

        if (point_in_rectangle(_mx, _my,
            _cx + 8, _btn_y,
            _cx + _card_w - 8, _btn_y + 28)) {
            selected_legacy = i;
        }
    }

    // [3.2] Butang Confirm Legacy
    if (selected_legacy >= 0
    &&  point_in_rectangle(_mx, _my,
        SW/2 - 210, _confirm_y,
        SW/2 - 20,  _confirm_y + 40)) {
        confirm_legacy();
    }

    // [3.3] Butang Start Fresh
    if (point_in_rectangle(_mx, _my,
        SW/2 + 20,  _confirm_y,
        SW/2 + 210, _confirm_y + 40)) {
        skip_legacy();
    }

    // [3.4] Start Fresh kalau tiada survivors
    if (array_length(surviving_heroes) == 0
    &&  point_in_rectangle(_mx, _my,
        SW/2 - 100, SH/2 + 40,
        SW/2 + 100, SH/2 + 80)) {
        skip_legacy();
    }
}

// ============================================================
// [4.0] HALL OF FALLEN SCREEN BUTTONS
// ============================================================
else if (screen_state == SCREEN.HALL) {

    // [4.1] Butang Back
    var _bx = SW/2 - 80;
    var _by = SH - 70;

    if (point_in_rectangle(_mx, _my,
        _bx, _by,
        _bx + 160, _by + 40)) {
        screen_state = SCREEN.SCORE;
    }
}

// ============================================================
// obj_game_over_manager — Left Button Released
// ============================================================

// [1.1] Mouse position
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);

// [1.2] Jangan process input semasa fade
if (screen_state == SCREEN.FADE_IN
||  screen_state == SCREEN.FADE_OUT) exit;

// ============================================================
// [2.0] SCORE SCREEN BUTTONS
// ============================================================
if (screen_state == SCREEN.SCORE) {

    var _btn_y = 90 + 320 + 20;

    // [2.1] Butang Choose Legacy
    if (point_in_rectangle(_mx, _my,
        SW/2 - 210, _btn_y,
        SW/2 - 10,  _btn_y + 40)) {
        if (array_length(surviving_heroes) > 0) {
            screen_state = SCREEN.LEGACY_SELECT;
        } else {
            screen_state = SCREEN.LEGACY_SELECT;
        }
    }

    // [2.2] Butang Hall of Fallen
    if (point_in_rectangle(_mx, _my,
        SW/2 + 10,  _btn_y,
        SW/2 + 210, _btn_y + 40)) {
        screen_state = SCREEN.HALL;
    }
}

// ============================================================
// [3.0] LEGACY SELECTION SCREEN BUTTONS
// ============================================================
else if (screen_state == SCREEN.LEGACY_SELECT) {

    var _card_w        = 160;
    var _card_h        = 340;
    var _card_gap      = 15;
    var _total_w       = min(array_length(surviving_heroes), 5)
                       * (_card_w + _card_gap) - _card_gap;
    var _start_x       = (SW - _total_w) / 2;
    var _card_y        = 80;
    var _confirm_y     = _card_y + _card_h + 20;

    // [3.1] Klik hero card — select legacy hero
    for (var i = 0; i < min(array_length(surviving_heroes), 5); i++) {
        var _cx    = _start_x + (i * (_card_w + _card_gap));
        var _btn_y = _card_y + _card_h - 35;

        if (point_in_rectangle(_mx, _my,
            _cx + 8, _btn_y,
            _cx + _card_w - 8, _btn_y + 28)) {
            selected_legacy = i;
        }
    }

    // [3.2] Butang Confirm Legacy
    if (selected_legacy >= 0
    &&  point_in_rectangle(_mx, _my,
        SW/2 - 210, _confirm_y,
        SW/2 - 20,  _confirm_y + 40)) {
        confirm_legacy();
    }

    // [3.3] Butang Start Fresh
    if (point_in_rectangle(_mx, _my,
        SW/2 + 20,  _confirm_y,
        SW/2 + 210, _confirm_y + 40)) {
        skip_legacy();
    }

    // [3.4] Start Fresh kalau tiada survivors
    if (array_length(surviving_heroes) == 0
    &&  point_in_rectangle(_mx, _my,
        SW/2 - 100, SH/2 + 40,
        SW/2 + 100, SH/2 + 80)) {
        skip_legacy();
    }
}

// ============================================================
// [4.0] HALL OF FALLEN SCREEN BUTTONS
// ============================================================
else if (screen_state == SCREEN.HALL) {

    // [4.1] Butang Back
    var _bx = SW/2 - 80;
    var _by = SH - 70;

    if (point_in_rectangle(_mx, _my,
        _bx, _by,
        _bx + 160, _by + 40)) {
        screen_state = SCREEN.SCORE;
    }
}
