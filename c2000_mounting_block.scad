// ============================================================
//  Surface mounting block for C2000-style wall plates
//  (Clipsal 2000 series / AU-NZ standard, 84 mm screw centres)
//  Designed for an HDMI wallplate: maximum internal volume,
//  thin walls, plate-screw bosses merged into the end walls.
//
//  Print open-face UP (base on the bed). No supports needed.
//  All dimensions in mm. Measure your plate and adjust!
// ============================================================

/* [Footprint - match your plate] */
// Outer height (vertical, along screw axis). C2000 plate ~115
outer_h = 115;
// Outer width (horizontal). C2000 plate ~73
outer_w = 73;
// Shrink the block this much per side so the plate overhangs slightly (0 = flush)
plate_overhang = 0.5;
// Outer corner radius
corner_r = 3;

/* [Depth] */
// Total depth off the wall (incl. base)
depth = 35;

/* [Shell] */
// Side wall thickness
wall = 2.0;
// Base (back) thickness
base = 2.0;

/* [Plate screws] */
// Plate mounting screw centres (AU standard = 84)
screw_centres = 84;
// Pilot hole: ~2.9 for 3.5 mm self-tapper, ~4.0-4.6 for M3.5 heat-set insert
screw_pilot_d = 2.9;
// Boss outer diameter
boss_d = 7.5;
// Pilot depth from top face
screw_pilot_depth = 14;
// Small lead-in chamfer on pilot hole
pilot_chamfer = 0.6;

/* [Wall fixing (into solid wood)] */
// Wood screw shank clearance (4.5 suits #8 / 4 mm screws)
fix_d = 4.5;
// Countersink head diameter (0 = no countersink)
fix_head_d = 8.5;
// Leave this much flat under the countersink (stops a knife edge on a thin base)
fix_cs_land = 0.4;
// Gap between screw head and the side/end walls (room for the driver bit)
fix_wall_clear = 1.5;

/* [Cable entries] */
// Cable entry on bottom wall
entry_bottom = false;
// Cable entry on top wall
entry_top = false;
// Cable entry on left wall
entry_left = false;
// Cable entry on right wall
entry_right = false;
// Hole through the back (cable coming out of the wall)
entry_back = true;
// Wall entry slot width
entry_w = 24;
// Wall entry slot height (from base, open-top slot if >= depth)
entry_h = 14;
// Sideways offset of top/bottom slots (keeps them clear of the screw boss)
entry_tb_offset = -18;
// Back hole size [w, h]. Max height is limited by the plate-screw bosses
back_hole = [58, 70];
// Back hole corner radius
back_hole_r = 4;

/* [Hidden] */
$fn = 48;
eps = 0.01;
H = outer_h - 2 * plate_overhang;
W = outer_w - 2 * plate_overhang;

// Fixing holes go in the four inside corners, clear of the bosses and cable hole
fix_r  = max(fix_d, fix_head_d) / 2;
fix_x  = (W / 2 - wall) - fix_r - fix_wall_clear;
fix_y  = (H / 2 - wall) - fix_r - fix_wall_clear;
fix_holes = [[-fix_x, -fix_y], [fix_x, fix_y], [fix_x, -fix_y], [-fix_x, fix_y]];

// Sanity checks
boss_inner_y = screw_centres / 2 - boss_d / 2;
assert(back_hole[1] / 2 <= boss_inner_y - 0.5,
       str("back_hole height too big - it would undercut the screw bosses. Max ~", 2 * (boss_inner_y - 0.5)));
assert(back_hole[0] / 2 <= W / 2 - wall - 2,
       str("back_hole width too big - leave a rim. Max ~", W - 2 * wall - 4));
assert(!entry_back || (fix_y - fix_r >= back_hole[1] / 2 + 1) || (fix_x - fix_r >= back_hole[0] / 2 + 1),
       "Fixing holes collide with back_hole");

module rrect(w, h, r, z) {
    linear_extrude(z)
        offset(r = r) offset(delta = -r) square([w, h], center = true);
}

module shell() {
    difference() {
        rrect(W, H, corner_r, depth);
        translate([0, 0, base])
            rrect(W - 2 * wall, H - 2 * wall, max(corner_r - wall, 0.5), depth);
    }
}

// Boss + web joining it to the end wall (keeps the cavity clear)
module boss(y) {
    s = sign(y);
    wall_inner = H / 2 - wall;
    hull() {
        translate([0, y, 0]) cylinder(d = boss_d, h = depth);
        translate([-boss_d / 2, s > 0 ? wall_inner - eps : -wall_inner - 0.5 + eps, 0])
            cube([boss_d, 0.5, depth]);
    }
}

module pilot(y) {
    translate([0, y, depth - screw_pilot_depth])
        cylinder(d = screw_pilot_d, h = screw_pilot_depth + eps);
    translate([0, y, depth - pilot_chamfer])
        cylinder(d1 = screw_pilot_d, d2 = screw_pilot_d + 2 * pilot_chamfer, h = pilot_chamfer + eps);
}

module fixing(p) {
    translate([p[0], p[1], -eps]) {
        cylinder(d = fix_d, h = base + 2 * eps);
        if (fix_head_d > 0) {
            // 90 deg countersink, depth capped so a thin base keeps a small land
            ch = min((fix_head_d - fix_d) / 2, base - fix_cs_land);
            translate([0, 0, base - ch + eps])
                cylinder(d1 = fix_head_d - 2 * ch, d2 = fix_head_d, h = ch + eps);
        }
    }
}

module entries() {
    // slot open at the front face if entry_h >= depth
    zh = (entry_h >= depth) ? depth + 1 : entry_h;
    // top/bottom walls (y = +/-)
    for (e = [[entry_top, 1], [entry_bottom, -1]]) if (e[0])
        translate([entry_tb_offset, e[1] * (H / 2 - wall / 2), base])
            slot(entry_w, wall * 3, zh, [1, 0, 0]);
    // left/right walls (x = +/-)
    for (e = [[entry_right, 1], [entry_left, -1]]) if (e[0])
        translate([e[1] * (W / 2 - wall / 2), 0, base])
            slot(wall * 3, entry_w, zh, [0, 1, 0]);
    if (entry_back)
        translate([0, 0, -eps]) rrect(back_hole[0], back_hole[1], back_hole_r, base + 2 * eps);
}

// Rounded-bottom slot sitting on z=0 (relative), extending up by zh
module slot(sx, sy, zh, along) {
    span = along[0] == 1 ? sx : sy;
    r = min(4, span / 2);
    hull() {
        for (o = [-1, 1])
            translate(along * o * (span / 2 - r) + [0, 0, r])
                rotate(along[0] == 1 ? [90, 0, 0] : [0, 90, 0])
                    cylinder(r = r, h = (along[0] == 1 ? sy : sx), center = true);
        translate([-sx / 2, -sy / 2, r]) cube([sx, sy, max(zh - r, eps)]);
    }
}

difference() {
    union() {
        shell();
        boss( screw_centres / 2);
        boss(-screw_centres / 2);
    }
    pilot( screw_centres / 2);
    pilot(-screw_centres / 2);
    for (p = fix_holes) fixing(p);
    entries();
}

// Info
echo(str("Internal cavity approx: ", W - 2 * wall, " x ", H - 2 * wall,
         " x ", depth - base, " mm (bosses take ~", boss_d, " mm at each end)"));
