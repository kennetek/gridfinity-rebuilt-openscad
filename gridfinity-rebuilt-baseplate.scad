include <gridfinity-rebuilt-utility.scad>
include <standard.scad>
use <gridfinity-rebuilt-holes.scad>

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
gridx = 1;
// number of bases along y-axis
gridy = 1;

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
style_plate = 2; // [0: thin, 1:weighted, 2:skeletonized, 3: screw together, 4: screw together minimal]


// hole styles
style_hole = 0; // [0:none, 1:countersink, 2:counterbore]

/* [Magnet Hole] */
// Baseplate will have holes for 6mm Diameter x 2mm high magnets.
enable_magnet = true;
// Magnet holes will have crush ribs to hold the magnet.
crush_ribs = true;
// Magnet holes will have a chamfer to ease insertion.
chamfer_holes = true;

hole_options = bundle_hole_options(refined_hole=false, magnet_hole=enable_magnet, screw_hole=false, crush_ribs=crush_ribs, chamfer=chamfer_holes, supportless=false);

// ===== IMPLEMENTATION ===== //

color("tomato")
gridfinityBaseplate(gridx, gridy, l_grid, distancex, distancey, style_plate, hole_options, style_hole, fitx, fity);

// ===== CONSTRUCTION ===== //

module gridfinityBaseplate(gridx, gridy, length, dix, diy, sp, hole_options, sh, fitx, fity) {

    assert(gridx > 0 || dix > 0, "Must have positive x grid amount!");
    assert(gridy > 0 || diy > 0, "Must have positive y grid amount!");

    gx = gridx == 0 ? floor(dix/length) : gridx;
    gy = gridy == 0 ? floor(diy/length) : gridy;
    dx = max(gx*length-bp_xy_clearance, dix);
    dy = max(gy*length-bp_xy_clearance, diy);

    off = calculate_offset(sp, hole_options[1], sh);

    offsetx = dix < dx ? 0 : (gx*length-bp_xy_clearance-dix)/2*fitx*-1;
    offsety = diy < dy ? 0 : (gy*length-bp_xy_clearance-diy)/2*fity*-1;

    screw_together = sp == 3 || sp == 4;
    minimal = sp == 0 || sp == 4;

    difference() {
        pattern_linear(gx, gy, length) {
            difference() {
                if (minimal) {
                    square_baseplate_lip(off);
                } else {
                    solid_square_baseplate(off);
                }

                // Bottom/through pattern for the solid baseplates.
                if (sp == 1) {
                    cutter_weight();
                } else if (sp == 2 || sp == 3) {
                    translate([0,0,-TOLLERANCE])
                    linear_extrude(off+2*TOLLERANCE)
                    profile_skeleton();
                }

                // Add holes to the solid baseplates.
                hole_pattern(){
                    // Manget hole
                    translate([0, 0, off+TOLLERANCE])
                    mirror([0, 0, 1])
                    block_base_hole(hole_options);

                    translate([0,0,-TOLLERANCE])
                    if (sh == 1) {
                        cutter_countersink();
                    } else if (sh == 2) {
                        cutter_counterbore();
                    }
                }

            }
        }

        // Round the outside corners
        corner_center_distance = length/2;
        copy_mirror([0, 1, 0])
        copy_mirror([1, 0, 0])
        translate([
            (gx*length/2) - BASEPLATE_OUTSIDE_RADIUS,
            (gy*length/2) - BASEPLATE_OUTSIDE_RADIUS,
            -TOLLERANCE
        ])
        scale([1+TOLLERANCE, 1+TOLLERANCE, 1+2*TOLLERANCE])
        square_baseplate_corner(off);

        if (screw_together) {
            translate([0, 0, off])
            cutter_screw_together(gx, gy, off);
        }
    }
}

function calculate_offset(style_plate, enable_magnet, style_hole) =
    assert(style_plate >=0 && style_plate <=4)
    let (screw_together = style_plate == 3 || style_plate == 4)
    screw_together ? 6.75 :
    style_plate==0 ? 0 :
    style_plate==1 ? bp_h_bot :
    calculate_offset_skeletonized(enable_magnet, style_hole);

function calculate_offset_skeletonized(enable_magnet, style_hole) =
    h_skel + (enable_magnet ? MAGNET_HOLE_DEPTH : 0) +
    (
        style_hole==0 ? d_screw :
        style_hole==1 ? BASEPLATE_SCREW_COUNTERSINK_ADDITIONAL_RADIUS : // Only works because countersink is at 45 degree angle!
        BASEPLATE_SCREW_COUNTERBORE_HEIGHT
    );

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
    screw_hole(SCREW_HOLE_RADIUS + d_clear, 2*h_base,
        false, BASEPLATE_SCREW_COUNTERSINK_ADDITIONAL_RADIUS);
}

module cutter_counterbore(){
    screw_radius = SCREW_HOLE_RADIUS + d_clear;
    counterbore_height = BASEPLATE_SCREW_COUNTERBORE_HEIGHT + 2*LAYER_HEIGHT;
    union(){
        cylinder(h=2*h_base, r=screw_radius);
        difference() {
            cylinder(h = counterbore_height, r=BASEPLATE_SCREW_COUNTERBORE_RADIUS);
            make_hole_printable(screw_radius, BASEPLATE_SCREW_COUNTERBORE_RADIUS, counterbore_height);
        }
    }
}

/**
 * @brief Added or removed from the baseplate to square off or round the corners.
 * @param height Baseplate's height excluding lip and clearance height.
 */
module square_baseplate_corner(height=0) {
    assert(height >= 0);
    linear_extrude(height + BASEPLATE_LIP_MAX.y)
    difference() {
        square(BASEPLATE_OUTSIDE_RADIUS, center=false);
        circle(r=BASEPLATE_OUTSIDE_RADIUS-TOLLERANCE);
    }
}

/**
 * @brief Outer edge/lip of the baseplate.
 * @details Includes clearance to ensure the base touches the lip
 *          instead of the bottom.
 * @param height Baseplate's height excluding lip and clearance height.
 * @param width How wide a single baseplate is.  Only set if deviating from the standard!
 * @param length How long a single baseplate is.  Only set if deviating from the standard!
 */
module baseplate_lip(height=0, width=l_grid, length=l_grid) {
    assert(height >= 0);

    // How far, in the +x direction,
    // the lip needs to be from it's [0, 0] point
    // such that when swept by 90 degrees to produce a corner,
    // the outside edge has the desired radius.
    translation_x = BASEPLATE_OUTSIDE_RADIUS - BASEPLATE_LIP_MAX.x;

    additional_height = height + BASEPLATE_CLEARANCE_HEIGHT;

    sweep_rounded(width-2*BASEPLATE_OUTSIDE_RADIUS, length-2*BASEPLATE_OUTSIDE_RADIUS)
    translate([translation_x, additional_height, 0])
    polygon(concat(BASEPLATE_LIP, [
        [0, -additional_height],
        [BASEPLATE_LIP_MAX.x, -additional_height],
        [BASEPLATE_LIP_MAX.x, 0]
    ]));
}

/**
 * @brief Outer edge/lip of the baseplate, with square corners.
 * @details Needed to prevent gaps when joining multiples together.
 * @param height Baseplate's height excluding lip and clearance height.
 * @param size Width/Length of a single baseplate.  Only set if deviating from the standard!
 */
module square_baseplate_lip(height=0, size = l_grid) {
    assert(height >= 0 && size/2 >= BASEPLATE_OUTSIDE_RADIUS);
    corner_center_distance = size/2 - BASEPLATE_OUTSIDE_RADIUS;
    union() {
        baseplate_lip(height, size, size);
        pattern_circular(4)
        translate([corner_center_distance, corner_center_distance, 0])
        square_baseplate_corner(height);
    }
}

/**
 * @brief A single baseplate with square corners, a solid inner section, lip and the set clearance height.
 * @param height Baseplate's height excluding lip and clearance height.
 * @details A height of zero is the equivalent of just calling square_baseplate_lip()
 */
module solid_square_baseplate(height=0, length = l_grid) {
    assert(height >= 0);
    union() {
        square_baseplate_lip(height, length);
        if (height > 0) {
            linear_extrude(height)
            square(length - BASEPLATE_OUTSIDE_RADIUS, center=true);
        }
    }
}

/**
 * @brief 2d Cutter to skeletonize the baseplate.
 * @param size Width/Length of a single baseplate.  Only set if deviating from the standard!
 * @example difference(){
 *              cube(large_number);
 *              linear_extrude(large_number+TOLLERANCE)
 *              profile_skeleton();
 *          }
 */
module profile_skeleton(size=l_grid) {
    l = size - 2*BASEPLATE_LIP_MAX.x;

    offset(r_skel)
    difference() {
        square(l-2*r_skel, center = true);

        hole_pattern()
        offset(MAGNET_HOLE_RADIUS+r_skel+2)
        square([l,l]);
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
