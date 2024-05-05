include <gridfinity-rebuilt-utility.scad>
include <standard.scad>

// ===== INFORMATION ===== //
/*
 IMPORTANT: rendering will be better for analyzing the model if fast-csg is enabled. As of writing, this feature is only available in the development builds and not the official release of OpenSCAD, but it makes rendering only take a couple seconds, even for comically large bins. Enable it in Edit > Preferences > Features > fast-csg

https://github.com/kennetek/gridfinity-rebuilt-openscad

*/

// ===== PARAMETERS ===== //

/* [Setup Parameters] */
$fa = 8;
$fs = 0.25;

/* [General Settings] */
// number of bases along x-axis
gridx = 5;
// number of bases along y-axis
gridy = 5;

/* [Screw Together Settings - Defaults work for M3 and 4-40] */
// screw diameter
d_screw = 3.35;
// screw head diameter
d_screw_head = 5;
// screw spacing distance
screw_spacing = .5;
// number of screws per grid block
n_screws = 1; // [1:3]


/* [Fit to Drawer] */
// minimum length of baseplate along x (leave zero to ignore, will automatically fill area if gridx is zero)
distancex = 0;
// minimum length of baseplate along y (leave zero to ignore, will automatically fill area if gridy is zero)
distancey = 0;

// where to align extra space along x
fitx = 0; // [-1:0.1:1]
// where to align extra space along y
fity = 0; // [-1:0.1:1]


/* [Styles] */

// baseplate styles
style_plate = 0; // [0: thin, 1:weighted, 2:skeletonized, 3: screw together, 4: screw together minimal]

// enable magnet hole
enable_magnet = true;

// hole styles
style_hole = 2; // [0:none, 1:countersink, 2:counterbore]


/* [Snaps] */

// Print a snap to connect F-F
print_snap = 0; // [0: No, 1:Yes]
// East side
snap_east = 0; // [0: None, 1:F, 2:M]
// North side
snap_north = 0; // [0: None, 1:F, 2:M]
// West side
snap_west = 0; // [0: None, 1:F, 2:M]
// South side
snap_south = 0; // [0: None, 1:F, 2:M]


/* [Hidden] */
screw_together = (style_plate == 3 || style_plate == 4);
// order is: east, north, west, south
snaps = [snap_east, snap_north, snap_west, snap_south];

// ===== IMPLEMENTATION ===== //

color("tomato")
gridfinityBaseplate(gridx, gridy, l_grid, distancex, distancey, style_plate, enable_magnet, style_hole, fitx, fity, snaps);
if (print_snap){
    translate([((gridx+1)%2)*l_grid/2,((gridy+1)%2)*l_grid/2,0])
    snap(clearance=0);
}

// ===== CONSTRUCTION ===== //

module gridfinityBaseplate(gridx, gridy, length, dix, diy, sp, sm, sh, fitx, fity, snaps) {

    assert(gridx > 0 || dix > 0, "Must have positive x grid amount!");
    assert(gridy > 0 || diy > 0, "Must have positive y grid amount!");

    f_snaps = [snaps[0]==1, snaps[1]==1, snaps[2]==1, snaps[3]==1];
    m_snaps = [snaps[0]==2, snaps[1]==2, snaps[2]==2, snaps[3]==2];

    gx = gridx == 0 ? floor(dix/length) : gridx;
    gy = gridy == 0 ? floor(diy/length) : gridy;
    dx = max(gx*length-bp_xy_clearance, dix);
    dy = max(gy*length-bp_xy_clearance, diy);

    off = calculate_off(sp, sm, sh);

    offsetx = dix < dx ? 0 : (gx*length-bp_xy_clearance-dix)/2*fitx*-1;
    offsety = diy < dy ? 0 : (gy*length-bp_xy_clearance-diy)/2*fity*-1;

    difference() {
        translate([offsetx,offsety,h_base])
        mirror([0,0,1])
        rounded_rectangle(dx, dy, h_base+off, r_base);

        gridfinityBase(gx, gy, length, 1, 1, 0, 0.5, false);

        translate([offsetx,offsety,h_base-0.6])
        rounded_rectangle(dx*2, dy*2, h_base*2, r_base);

        pattern_linear(gx, gy, length) {
            render(convexity = 6) {

                if (sp == 1)
                    translate([0,0,-off])
                    cutter_weight();
                else if (sp == 2 || sp == 3)
                    linear_extrude(10*(h_base+off), center = true)
                    profile_skeleton();
                else if (sp == 4)
                    translate([0,0,-5*(h_base+off)])
                    rounded_square(length-2*r_c2-2*r_c1, 10*(h_base+off), r_fo3);


                hole_pattern(){
                    if (sm) block_base_hole(1);

                    translate([0,0,-off])
                    if (sh == 1) cutter_countersink();
                    else if (sh == 2) cutter_counterbore();
                }
            }
        }
        if (sp == 3 || sp ==4) cutter_screw_together(gx, gy, off);
        translate([0,0,-off])
        cutter_snaps(gx,gy, f_snaps);
    }
    translate([0,0,-off])
    adder_snaps(gx,gy, m_snaps);

}

function calculate_off(sp, sm, sh) =
    screw_together
        ? 6.75
        :sp==0
            ?0
            : sp==1
                ?bp_h_bot
                :h_skel + (sm
                    ?h_hole
                    : 0)+(sh==0
                        ? d_screw
                        : sh==1
                            ?d_cs
                            :h_cb);

module cutter_weight() {
    union() {
        linear_extrude(bp_cut_depth*2,center=true)
        square(bp_cut_size, center=true);
        pattern_circular(4)
        translate([0,10,0])
        linear_extrude(bp_rcut_depth*2,center=true)
        union() {
            square([bp_rcut_width, bp_rcut_length], center=true);
            translate([0,bp_rcut_length/2,0])
            circle(d=bp_rcut_width);
        }
    }
}
module hole_pattern(){
    pattern_circular(4)
    translate([l_grid/2-d_hole_from_side, l_grid/2-d_hole_from_side, 0]) {
        render();
        children();
    }
}

module cutter_countersink(){
    cylinder(r = r_hole1+d_clear, h = 100*h_base, center = true);
    translate([0,0,d_cs])
    mirror([0,0,1])
    hull() {
        cylinder(h = d_cs+10, r=r_hole1+d_clear);
        translate([0,0,d_cs])
        cylinder(h=d_cs+10, r=r_hole1+d_clear+d_cs);
    }
}

module cutter_counterbore(){
    cylinder(h=100*h_base, r=r_hole1+d_clear, center=true);
    difference() {
        cylinder(h = 2*(h_cb+0.2), r=r_cb, center=true);
        copy_mirror([0,1,0])
        translate([-1.5*r_cb,r_hole1+d_clear+0.1,h_cb-h_slit])
        cube([r_cb*3,r_cb*3, 10]);
    }
}

module profile_skeleton() {
    l = l_grid-2*r_c2-2*r_c1;
    minkowski() {
        difference() {
            square([l-2*r_skel+2*d_clear,l-2*r_skel+2*d_clear], center = true);
            pattern_circular(4)
            translate([l_grid/2-d_hole_from_side,l_grid/2-d_hole_from_side,0])
            minkowski() {
                square([l,l]);
                circle(r_hole2+r_skel+2);
           }
        }
        circle(r_skel);
    }
}

module cutter_screw_together(gx, gy, off) {

    screw(gx, gy);
    rotate([0,0,90])
    screw(gy, gx);

    module screw(a, b) {
        copy_mirror([1,0,0])
        translate([a*l_grid/2, 0, -off/2])
        pattern_linear(1, b, 1, l_grid)
        pattern_linear(1, n_screws, 1, d_screw_head + screw_spacing)
        rotate([0,90,0])
        cylinder(h=l_grid/2, d=d_screw, center = true);
    }
}

module cutter_snaps(gx, gy, snaps) {
    snaps_on_sides(gx, gy, snaps, clearance=0.2);
}

module adder_snaps(gx, gy, snaps) {
    snaps_on_sides(gx, gy, snaps, clearance=0);
}

module snaps_on_sides(gx, gy, sides = [false,false,false,false], clearance=0.2) {
    if (sides[0]){
        snaps_one_side(gx, gy, clearance=clearance);
    }
    if (sides[2]){
        mirror([1,0,0])
        snaps_one_side(gx, gy, clearance=clearance);
    }
    if (sides[1]){
        rotate([0,0,90])
        snaps_one_side(gy, gx, clearance=clearance);
    }
    if (sides[3]){
        rotate([0,0,90])
        mirror([1,0,0])
        snaps_one_side(gy, gx, clearance=clearance);
    }
}

module snaps_one_side(a, b, clearance=0.2) {
    translate([a*(l_grid)/2 - (bp_xy_clearance/2), 0])
    pattern_linear(1, b, l_grid/2, l_grid)
    snap(clearance=clearance);
}

module snap(r1=4,r2=5.2,l=1.5,h=1,clearance=0.2){
    r1c = r1+clearance;
    r2c = r2+clearance;
    hc = h+clearance;
    lc = l+clearance;
    mirror([1,0,0])
    hsnap();
    hsnap();
    module hsnap(){
        hull() {
            translate([0,-r1c/2,0]){
            cube([.0001,r1c,hc]); // 0.0001 ≈ 0
            }
            translate([lc,-r2c/2,0])
            cube([.0001,r2c,hc]);
        }
    }
}
