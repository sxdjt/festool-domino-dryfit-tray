// Festool Domino Dry Fit Tray
// Parametric tray for holding Festool Domino dry fit tenons upright in a grid.
// Domino dimensions measured from verified 3D models.
//
// Usage: select a domino variant, set your desired grid size, and print.
// The tray holds tenons at 30% depth - secure but easy to remove.
//
// Optional Gridfinity base: adds a spec-compliant Gridfinity base.
// Optional expand-to-fit: when combined with a Gridfinity base, the tray body
// grows to fill the full Gridfinity footprint and hole spacing is redistributed
// evenly so all gaps (edge-to-hole and hole-to-hole) are equal.

/* [Domino Size] */
// Domino dry fit size to store in this tray
domino_variant = 0; // [0:4x20, 1:5x30, 2:6x40, 3:8x40, 4:8x50, 5:10x50]

/* [Grid] */
// Columns (along the long axis of the tenon)
cols = 5;
// Rows
rows = 4;

/* [Fit and Clearance] */
// Clearance added to each hole dimension for easy insertion/removal (mm)
clearance = 0.3;
// Gap between adjacent holes (mm) - used when not expanding to Gridfinity footprint
hole_gap = 3.0;

/* [Tray Structure] */
// Wall thickness (mm)
wall_thickness = 2.5;
// Floor thickness (mm)
floor_thickness = 2.0;
// Hole depth as a fraction of tenon length (0.30 = 30%)
hole_depth_ratio = 0.30;
// Top edge fillet radius (mm)
fillet_radius = 2.5;

/* [Label] */
// Deboss a size label on the front face of the tray
show_label = true;
// Label text size in mm (0 = auto-fit to available wall height)
// Note: the 4x20 tray is very short; auto size will be small (~1.8mm).
//       Increase this value or set Show Label = false if the label is not needed.
label_text_size = 0;

/* [Gridfinity] */
// Add a Gridfinity-compatible base to the tray
gridfinity_base = false;
// Expand tray to fill the Gridfinity footprint (requires Gridfinity Base = true)
gf_expand_to_fit = false;

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

// --- Gridfinity specification constants ---
GF_PITCH     = 42.0;   // grid unit size (mm)
GF_CLEARANCE =  0.5;   // bin-to-baseplate clearance (mm)
GF_CORNER_R  =  3.75;  // bin corner radius (mm)
GF_BASE_H    =  4.75;  // base profile height (mm) - measured from reference STL

// --- Derived tenon and hole dimensions ---
d_thickness = domino_data[domino_variant][1]; // short axis (Y direction)
d_width     = domino_data[domino_variant][2]; // long axis  (X direction)
d_length    = domino_data[domino_variant][3]; // tenon length

hole_short = d_thickness + clearance; // hole dimension along Y
hole_long  = d_width     + clearance; // hole dimension along X
hole_depth = d_length * hole_depth_ratio;

// Center-to-center pitch between holes (default, used when not expanding)
col_pitch = hole_long  + hole_gap;
row_pitch = hole_short + hole_gap;

// Tray body minimum dimensions (sized to the grid with wall_thickness margins)
tray_width  = 2*wall_thickness + cols*hole_long  + (cols-1)*hole_gap;
tray_depth  = 2*wall_thickness + rows*hole_short + (rows-1)*hole_gap;
tray_height = floor_thickness + hole_depth;

// --- Gridfinity base sizing ---
// Add GF_CLEARANCE before ceiling so the bin size (N*42 - 0.5) is always
// >= the tray body dimension.
_gf_x = max(1, ceil((tray_width + GF_CLEARANCE) / GF_PITCH));
_gf_y = max(1, ceil((tray_depth + GF_CLEARANCE) / GF_PITCH));
_gf_w = _gf_x * GF_PITCH - GF_CLEARANCE;  // full GF footprint width
_gf_d = _gf_y * GF_PITCH - GF_CLEARANCE;  // full GF footprint depth

// --- Expand-to-fit ---
// When active: tray body fills the GF footprint and hole spacing is recalculated
// so the gap between every pair of adjacent features is equal (edge-to-hole and
// hole-to-hole). This uses (cols+1) equal gaps across the inner width.
_do_expand = gridfinity_base && gf_expand_to_fit;

// Actual tray body outer dimensions
actual_w = _do_expand ? _gf_w : tray_width;
actual_d = _do_expand ? _gf_d : tray_depth;

// Inner space available for the hole grid (inside wall_thickness margins)
_inner_w = actual_w - 2*wall_thickness;
_inner_d = actual_d - 2*wall_thickness;

// Effective gap between holes (and between outermost holes and the inner wall face)
// When expanding: (cols+1) equal gaps share the space not taken by holes.
// When not expanding: use hole_gap as-is.
_eff_col_gap = _do_expand ? (_inner_w - cols*hole_long)  / (cols+1) : hole_gap;
_eff_row_gap = _do_expand ? (_inner_d - rows*hole_short) / (rows+1) : hole_gap;

// Effective center-to-center pitch
_eff_col_pitch = hole_long  + _eff_col_gap;
_eff_row_pitch = hole_short + _eff_row_gap;

// First hole center position within the tray body.
// When expanding: one gap separates the inner wall face from the first hole edge.
// When not expanding: first hole edge is flush with the inner wall face (no edge gap).
_hole_x0 = _do_expand
    ? wall_thickness + _eff_col_gap + hole_long/2
    : wall_thickness + hole_long/2;
_hole_y0 = _do_expand
    ? wall_thickness + _eff_row_gap + hole_short/2
    : wall_thickness + hole_short/2;

// GF base offset: centres the base under the tray body (0 when bodies are same size)
_gf_off_x = _do_expand ? 0 : (_gf_w - tray_width) / 2;
_gf_off_y = _do_expand ? 0 : (_gf_d - tray_depth) / 2;

// Z offset applied to the tray body and all features above it
z_base = gridfinity_base ? GF_BASE_H : 0;

// Bottom corner radius for tray body:
// matches GF_CORNER_R when the body fills the GF footprint for a seamless join
_body_bottom_r = _do_expand ? GF_CORNER_R : 0;

// --- Label geometry ---
// Panel on the front face (Y=0) of the tray body, centred on actual_w.
// Sized to the straight-wall zone: above the floor, below the top fillet.
_label_zone_h = tray_height - fillet_radius - floor_thickness - 1.0;
_auto_ts      = _label_zone_h * 0.72;
_text_size    = (label_text_size > 0) ? label_text_size : _auto_ts;
_label_name   = domino_data[domino_variant][0];

_panel_pad    = _text_size * 0.55;
_panel_h      = _text_size + 2*_panel_pad;
_panel_w      = _text_size * 4.5;
_panel_depth  = 0.15;
_text_recess  = 0.15;
_panel_cx     = actual_w / 2;   // centred on the actual tray body width
_panel_bz     = floor_thickness + (_label_zone_h - _panel_h) / 2;
_panel_cz     = _panel_bz + _panel_h / 2;

// --- Console output ---
echo(str("Domino: ", _label_name));
echo(str("Tray body (W x D x H): ", actual_w, " x ", actual_d, " x ", tray_height, " mm"));
echo(str("Hole depth: ", hole_depth, " mm  (", hole_depth_ratio*100, "% of tenon length)"));
echo(str("Grid: ", cols, " cols x ", rows, " rows  =  ", cols*rows, " tenons"));
if (gridfinity_base) {
    echo(str("Gridfinity base: ", _gf_x, " x ", _gf_y, " units  (", _gf_w, " x ", _gf_d, " mm)"));
    echo(str("Total height (base + tray): ", GF_BASE_H + tray_height, " mm"));
}
if (_do_expand) {
    echo(str("Expand-to-fit: col gap=", _eff_col_gap, "mm  row gap=", _eff_row_gap, "mm"));
}

// =============================================================================
// MODULES
// =============================================================================

// 2D rounded rectangle with outer extent (0,0) to (w,d), corner radius r.
module rounded_rect_2d(w, d, r) {
    offset(r=r, $fn=64)
        translate([r, r])
            square([w-2*r, d-2*r]);
}

// Single Gridfinity foot for one grid unit (41.5 x 41.5mm outer).
// Profile measured from a reference Gridfinity bin STL.
// Three sections from bottom to top:
//   z=0.00 to 0.80 : bottom 45-degree chamfer  (inset 2.95mm -> 2.15mm)
//   z=0.80 to 2.60 : vertical wall              (inset 2.15mm, height 1.80mm)
//   z=2.60 to 4.75 : upper 45-degree chamfer    (inset 2.15mm -> 0mm)
// The upper chamfer is the z-lock feature that clips into the baseplate socket.
module gf_foot() {
    outer = GF_PITCH - GF_CLEARANCE;  // 41.5mm outer size per unit
    r     = GF_CORNER_R;               // 3.75mm corner radius, constant throughout

    z0 = 0.00;  s0 = outer - 2*2.95;  // 35.60mm at base
    z1 = 0.80;  s1 = outer - 2*2.15;  // 37.20mm after bottom chamfer
    z2 = 2.60;                         // top of vertical wall
    z3 = 4.75;  s3 = outer;            // 41.50mm at top (full outer)

    o0 = (outer - s0) / 2;  // 2.95mm - inset offset for bottom shape
    o1 = (outer - s1) / 2;  // 2.15mm - inset offset for mid shape

    // Bottom 45-degree chamfer
    hull() {
        translate([o0, o0, z0])
            linear_extrude(0.01)
                rounded_rect_2d(s0, s0, r);
        translate([o1, o1, z1 - 0.01])
            linear_extrude(0.01)
                rounded_rect_2d(s1, s1, r);
    }

    // Vertical wall
    translate([o1, o1, z1])
        linear_extrude(z2 - z1)
            rounded_rect_2d(s1, s1, r);

    // Upper 45-degree chamfer (expands to full outer footprint = z-lock)
    hull() {
        translate([o1, o1, z2])
            linear_extrude(0.01)
                rounded_rect_2d(s1, s1, r);
        translate([0, 0, z3 - 0.01])
            linear_extrude(0.01)
                rounded_rect_2d(s3, s3, r);
    }
}

// Full Gridfinity base: one foot per grid unit in a gx x gy arrangement.
// Adjacent feet are separated by GF_CLEARANCE (0.5mm) gaps that align with
// the baseplate grid structure, allowing each foot to click into its socket.
module gf_base(gx, gy) {
    for (ix = [0:gx-1], iy = [0:gy-1]) {
        translate([ix * GF_PITCH, iy * GF_PITCH, 0])
            gf_foot();
    }
}

// Tray body: solid box with rounded top edges.
// bottom_r > 0: rounded bottom corners - use GF_CORNER_R when the body fills
//               the GF footprint so the join with the feet is seamless.
// bottom_r = 0: flat sharp-cornered bottom for printing directly on the bed.
module tray_body(w, d, h, top_r, bottom_r=0) {
    hull() {
        if (bottom_r > 0) {
            linear_extrude(0.01)
                rounded_rect_2d(w, d, bottom_r);
        } else {
            cube([w, d, 0.01]);
        }
        for (cx = [top_r, w-top_r], cy = [top_r, d-top_r]) {
            translate([cx, cy, h-top_r])
                sphere(r=top_r, $fn=64);
        }
    }
}

// Oval (oblong) hole: long axis along X, short axis along Y.
module oval_hole(long_axis, short_axis, depth) {
    r           = short_axis / 2;
    offset_dist = (long_axis - short_axis) / 2;
    hull() {
        translate([-offset_dist, 0, 0]) cylinder(h=depth, r=r, $fn=32);
        translate([ offset_dist, 0, 0]) cylinder(h=depth, r=r, $fn=32);
    }
}

// Debossed label panel on the front face (Y=0) of the tray body.
// z_offset: absolute Z of the tray body floor (= GF_BASE_H when Gridfinity is active).
module label_panel(z_offset=0) {
    translate([_panel_cx - _panel_w/2, -0.01, _panel_bz + z_offset])
        cube([_panel_w, _panel_depth + 0.01, _panel_h]);

    translate([_panel_cx, _panel_depth + _text_recess, _panel_cz + z_offset])
        rotate([90, 0, 0])
            linear_extrude(height = _text_recess + 0.01)
                text(_label_name,
                     size   = _text_size,
                     halign = "center",
                     valign = "center",
                     font   = "Liberation Sans:style=Bold");
}

// =============================================================================
// MAIN ASSEMBLY
// =============================================================================
difference() {
    union() {
        // Gridfinity base.
        // When not expanding: offset so it is centred under the (smaller) tray body.
        // When expanding: tray body fills the GF footprint, offset is zero.
        if (gridfinity_base) {
            translate([-_gf_off_x, -_gf_off_y, 0])
                gf_base(_gf_x, _gf_y);
        }

        // Tray body
        translate([0, 0, z_base])
            tray_body(actual_w, actual_d, tray_height, fillet_radius,
                      bottom_r = _body_bottom_r);
    }

    // Grid of oval holes using effective pitch and origin
    for (c = [0:cols-1], r = [0:rows-1]) {
        x = _hole_x0 + c * _eff_col_pitch;
        y = _hole_y0 + r * _eff_row_pitch;
        translate([x, y, z_base + floor_thickness])
            oval_hole(hole_long, hole_short, hole_depth + 0.01);
    }

    // Optional front-face label
    if (show_label) label_panel(z_offset = z_base);
}
