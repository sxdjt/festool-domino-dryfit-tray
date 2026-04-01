// Festool Domino Dry Fit Tray
// Parametric tray for holding Festool Domino dry fit tenons upright in a grid.
// Domino dimensions measured from verified 3D models.
//
// Usage: select a domino variant, set your desired grid size, and print.
// The tray holds tenons at 30% depth - secure but easy to remove.

/* [Domino Size] */
// Domino dry fit size to store in this tray
domino_variant = 0; // [0:4x20, 1:5x30, 2:6x40, 3:8x40, 4:8x50, 5:10x50]

/* [Grid] */
// Number of columns (along the long axis of the tenon)
cols = 5;
// Number of rows
rows = 4;

/* [Fit and Clearance] */
// Extra clearance added to each hole dimension for easy insertion/removal (mm)
clearance = 0.3;
// Minimum wall thickness between adjacent holes (mm)
hole_gap = 3.0;

/* [Tray Structure] */
// Outer wall thickness (mm)
wall_thickness = 2.5;
// Solid floor thickness (mm)
floor_thickness = 2.0;
// Hole depth as a fraction of tenon length (0.30 = 30%)
hole_depth_ratio = 0.30;
// Top edge fillet radius (mm)
fillet_radius = 2.5;

/* [Label] */
// Deboss a size label panel on the front face of the tray
show_label = true;
// Label text size in mm (0 = auto-fit to available wall height)
// NOTE: for the 4x20 variant the tray is very short; auto size will be small (~1.8mm).
//       Increase this value or set show_label = false if the label is not needed.
label_text_size = 0;

// --- Domino data table ---
// Measured from verified 3D models.
// Format: [ label, thickness (short axis, Y), width (long axis, X), length (Z) ]
domino_data = [
    ["4x20",  3.95, 14.75, 20],
    ["5x30",  4.95, 17.90, 29],
    ["6x40",  5.95, 18.90, 40],
    ["8x40",  7.95, 20.90, 40],
    ["8x50",  7.95, 20.90, 50],
    ["10x50", 9.95, 22.90, 50]
];

// --- Derived dimensions ---
d_thickness = domino_data[domino_variant][1]; // short axis (Y direction)
d_width     = domino_data[domino_variant][2]; // long axis  (X direction)
d_length    = domino_data[domino_variant][3]; // length of tenon

hole_short = d_thickness + clearance; // hole dimension along Y
hole_long  = d_width     + clearance; // hole dimension along X
hole_depth = d_length * hole_depth_ratio;

// Center-to-center pitch between holes
col_pitch = hole_long  + hole_gap;
row_pitch = hole_short + hole_gap;

// Overall tray outer dimensions
tray_width  = 2*wall_thickness + cols*hole_long  + (cols-1)*hole_gap;
tray_depth  = 2*wall_thickness + rows*hole_short + (rows-1)*hole_gap;
tray_height = floor_thickness + hole_depth;

// --- Label geometry ---
// The label panel sits on the front face (Y=0), centred horizontally.
// Available straight-wall height: below the fillet, above the floor.
_label_zone_h = tray_height - fillet_radius - floor_thickness - 1.0;
_auto_ts      = _label_zone_h * 0.72;
_text_size    = (label_text_size > 0) ? label_text_size : _auto_ts;
_label_name   = domino_data[domino_variant][0];

// Panel is sized to frame the text with consistent padding.
// Width is based on the longest possible label ("10x50" = 5 chars) so all
// trays share the same badge proportions regardless of variant.
_panel_pad   = _text_size * 0.55;
_panel_h     = _text_size + 2*_panel_pad;
_panel_w     = _text_size * 4.5;      // wide enough for 5-char label with margins
_panel_depth = 1.0;                   // recess depth (mm)
_text_recess = 0.4;                   // text cut depth below panel floor (mm)

// Panel is centred horizontally and vertically within the straight-wall zone
_panel_cx = tray_width / 2;
_panel_bz  = floor_thickness + (_label_zone_h - _panel_h) / 2;
_panel_cz  = _panel_bz + _panel_h / 2;

echo(str("Domino: ", _label_name));
echo(str("Tray (W x D x H): ", tray_width, " x ", tray_depth, " x ", tray_height, " mm"));
echo(str("Hole depth: ", hole_depth, " mm  (", hole_depth_ratio*100, "% of tenon length)"));
echo(str("Grid: ", cols, " cols x ", rows, " rows  =  ", cols*rows, " tenons"));

// --- Modules ---

// Solid rectangular box with rounded top edges and sharp bottom edges.
// Uses hull() of a full-width bottom face and four corner spheres at the top.
module tray_body(w, d, h, r) {
    hull() {
        // Full-width bottom face keeps the bottom edges sharp and flat
        cube([w, d, 0.01]);
        // Corner spheres inset by r generate the rounded top edges
        for (cx = [r, w-r], cy = [r, d-r]) {
            translate([cx, cy, h-r])
                sphere(r=r, $fn=64);
        }
    }
}

// Oval (oblong) hole: long axis along X, short axis along Y.
// Built as hull() of two cylinders.
module oval_hole(long_axis, short_axis, depth) {
    r      = short_axis / 2;
    offset = (long_axis - short_axis) / 2;
    hull() {
        translate([-offset, 0, 0]) cylinder(h=depth, r=r, $fn=32);
        translate([ offset, 0, 0]) cylinder(h=depth, r=r, $fn=32);
    }
}

// Debossed label panel on the front face (Y=0).
// rotate([90,0,0]) maps the text XY plane so:
//   - baseline runs along +X (left-to-right when viewed from outside)
//   - height runs along +Z (upright)
//   - extrusion direction is -Y (cuts into the wall)
module label_panel() {
    // Outer panel recess - shallow rectangular pocket
    translate([_panel_cx - _panel_w/2, -0.01, _panel_bz])
        cube([_panel_w, _panel_depth + 0.01, _panel_h]);

    // Text debossed into the panel floor
    translate([_panel_cx, _panel_depth + _text_recess, _panel_cz])
        rotate([90, 0, 0])
            linear_extrude(height = _text_recess + 0.01)
                text(_label_name,
                     size   = _text_size,
                     halign = "center",
                     valign = "center",
                     font   = "Liberation Sans:style=Bold");
}

// --- Main tray ---
difference() {
    tray_body(tray_width, tray_depth, tray_height, fillet_radius);

    // Grid of oval holes - tenons stand upright, sticking up above the tray
    for (c = [0:cols-1], r = [0:rows-1]) {
        x = wall_thickness + hole_long/2  + c * col_pitch;
        y = wall_thickness + hole_short/2 + r * row_pitch;
        translate([x, y, floor_thickness])
            oval_hole(hole_long, hole_short, hole_depth + 0.01); // +0.01 avoids z-fighting at floor
    }

    // Optional front-face label panel
    if (show_label) label_panel();
}
