// ============================================================
// obj_flag — Draw GUI Event
// ============================================================

// [1.0] Convert world position ke GUI/screen position
var _cam_x    = camera_get_view_x(view_camera[0]);
var _cam_y    = camera_get_view_y(view_camera[0]);
var _cam_w    = camera_get_view_width(view_camera[0]);
var _cam_h    = camera_get_view_height(view_camera[0]);
var _gui_w    = display_get_gui_width();
var _gui_h    = display_get_gui_height();
var _scale_x  = _gui_w / _cam_w;
var _scale_y  = _gui_h / _cam_h;
var _sx       = (x - _cam_x) * _scale_x;
var _sy       = (y - _cam_y) * _scale_y;

var _col    = _get_flag_color(flag_type);
var _name   = _get_flag_name(flag_type);

// [2.0] Tiang flag
draw_set_color(c_white);
draw_set_alpha(0.9);
draw_line_width(_sx, _sy, _sx, _sy - 48, 3);

// [3.0] Flag kepala
draw_set_color(_col);
draw_set_alpha(1.0);
draw_triangle(_sx, _sy - 48, _sx + 24, _sy - 36, _sx, _sy - 24, false);

// [4.0] Border kepala
draw_set_color(c_white);
draw_set_alpha(0.6);
draw_triangle(_sx, _sy - 48, _sx + 24, _sy - 36, _sx, _sy - 24, true);

// [5.0] Label nama
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(fnt_small);

draw_set_color(c_black);
draw_set_alpha(0.8);
draw_text(_sx + 1, _sy - 58 + 1, _name);

draw_set_color(_col);
draw_set_alpha(1.0);
draw_text(_sx, _sy - 58, _name);

// [6.0] Bounty label
draw_set_color(c_yellow);
draw_set_alpha(1.0);
draw_text(_sx, _sy - 70, string(bounty) + "g");

// [7.0] Reset
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1.0);
draw_set_color(c_white);