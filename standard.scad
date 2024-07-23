
// height of the base
h_base = 5;
// lower base chamfer "radius"
r_c1 = 0.8;
// upper base chamfer "radius"
r_c2 = 2.4;
// bottom thiccness of bin
h_bot = 2.2;
// outside radii 1
r_fo1 = 7.5 / 2;
// outside radii 2
r_fo2 = 3.2 / 2;
// outside radii 3
r_fo3 = 1.6 / 2;
// length of a grid unit
l_grid = 42;


// Outside rounded radius of bin
// Per spec, matches radius of upper base section.
r_base = r_fo1;

// Tollerance to make sure cuts don't leave a sliver behind,
// and that items are properly connected to each other.
TOLLERANCE = 0.01;

// ****************************************
// Magnet / Screw Hole Constants
// ****************************************
LAYER_HEIGHT = 0.2;
MAGNET_HEIGHT = 2;

SCREW_HOLE_RADIUS = 3 / 2;
MAGNET_HOLE_RADIUS = 6.5 / 2;
MAGNET_HOLE_DEPTH = MAGNET_HEIGHT + (LAYER_HEIGHT * 2);

// center-to-center distance between holes
d_hole = 26;
// distance of hole from side of bin
d_hole_from_side=8;

// Meassured diameter in Fusion360.
// Smaller than the magnet to keep it squeezed.
REFINED_HOLE_RADIUS = 5.86 / 2;
REFINED_HOLE_HEIGHT = MAGNET_HEIGHT - 0.1;
// How many layers are between a Gridfinity Refined Hole and the bottom
REFINED_HOLE_BOTTOM_LAYERS = 2;

// Experimentally chosen for a press fit.
MAGNET_HOLE_CRUSH_RIB_INNER_RADIUS = 5.9 / 2;
// Mostly arbitrarily chosen.
// 30 ribs does not print with a 0.4mm nozzle.
// Anything 5 or under produces a hole that is not round.
MAGNET_HOLE_CRUSH_RIB_COUNT = 8;

// Radius to add when chamfering magnet and screw holes.
CHAMFER_ADDITIONAL_RADIUS = 0.8;
CHAMFER_ANGLE = 45;

// When countersinking the baseplate, how much to add to the screw radius.
BASEPLATE_SCREW_COUNTERSINK_ADDITIONAL_RADIUS = 5/2;
BASEPLATE_SCREW_COUNTERBORE_RADIUS = 5.5/2;
BASEPLATE_SCREW_COUNTERBORE_HEIGHT = 3;
// ****************************************

// top edge fillet radius
r_f1 = 0.6;
// internal fillet radius
r_f2 = 2.8;

// width of divider between compartments
d_div = 1.2;
// minimum wall thickness
d_wall = 0.95;
// tolerance fit factor
d_clear = 0.25;

// height of tab (yaxis, measured from inner wall)
d_tabh = 15.85;
// maximum width of tab
d_tabw = 42;
// angle of tab
a_tab = 36;
// lip height
h_lip = 3.548;

d_wall2 = r_base-r_c1-d_clear*sqrt(2);
d_magic = -2*d_clear-2*d_wall+d_div;

// Stacking Lip
// Based on https://gridfinity.xyz/specification/
stacking_lip_inner_slope_height_mm = 0.7;
stacking_lip_wall_height_mm = 1.8;
stacking_lip_outer_slope_height_mm = 1.9;
stacking_lip_depth =
    stacking_lip_inner_slope_height_mm +
    stacking_lip_outer_slope_height_mm;
stacking_lip_height =
    stacking_lip_inner_slope_height_mm +
    stacking_lip_wall_height_mm +
    stacking_lip_outer_slope_height_mm;

// Extracted from `profile_wall_sub_sub`.
stacking_lip_support_wall_height_mm = 1.2;
stacking_lip_support_height_mm =
    stacking_lip_support_wall_height_mm + d_wall2;


// Baseplate constants

// Baseplate bottom part height (part added with weigthed=true)
bp_h_bot = 6.4;
// Baseplate bottom cutout rectangle size
bp_cut_size = 21.4;
// Baseplate bottom cutout rectangle depth
bp_cut_depth = 4;
// Baseplate bottom cutout rounded thingy width
bp_rcut_width = 8.5;
// Baseplate bottom cutout rounded thingy left
bp_rcut_length = 4.25;
// Baseplate bottom cutout rounded thingy depth
bp_rcut_depth = 2;
// Baseplate clearance offset
bp_xy_clearance = 0.5;
// radius of cutout for skeletonized baseplate
r_skel = 2;
// minimum baseplate thickness (when skeletonized)
h_skel = 1;
