// ============================================================
// obj_townhall — Left Button Released
// Player klik TH untuk upgrade
// ============================================================
var _data = get_ui_data();

if (_data.is_upgrading) {
    show_debug_message("[TH] Upgrade in progress: "
        + string(floor(_data.upgrade_progress * 100)) + "%");
    // TODO: tunjuk progress panel dalam UI
    exit;
}

if (_data.is_max) {
    show_debug_message("[TH] Maximum level reached!");
    // TODO: tunjuk notification UI
    exit;
}

if (!_data.can_upgrade) {
    show_debug_message("[TH] Need " + string(_data.upgrade_cost)
        + "g | Have " + string(_data.treasury) + "g");
    // TODO: tunjuk "insufficient gold" UI
    exit;
}

// Tunjuk upgrade confirmation — player confirm dulu
// TODO: spawn upgrade confirmation panel
// Buat masa ni, terus upgrade untuk testing
start_upgrade();