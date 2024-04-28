
// lower base chamfer "radius"
r_c1 = 0.8;
// bottom thiccness of bin
h_bot = 2.2;
// length of a grid unit
l_grid = 42;


// Outside rounded radius of bin
// Per spec, matches radius of upper base section.
r_base = 7.5 / 2;

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

// distance of hole from side of bin
d_hole_from_side=8;

// Based on https://gridfinity.xyz/specification/
HOLE_DISTANCE_FROM_BOTTOM_EDGE = 4.8;

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

// ****************************************
// Stacking Lip Constants
// Based on https://gridfinity.xyz/specification/
// ****************************************
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

// Height of the innermost section.
// Used to keep the innermost lip from just being a triangle.
// Spec implicitly expects wall width to equal stacking lip depth,
// so does not define this.
stacking_lip_support_wall_height_mm = 1.2;

// Support so the stacking lip is not floating in mid air
// when wall width is less than stacking lip depth.
stacking_lip_support_angle = 45;

stacking_lip_support_height_mm =
    stacking_lip_support_wall_height_mm
    + tan(90 - stacking_lip_support_angle) * stacking_lip_depth;

// ****************************************
// Base constants
// Based on https://gridfinity.xyz/specification/
// ****************************************
BASE_OUTSIDE_RADIUS = r_base;

BASE_PROFILE = [
    [0, 0], // Innermost bottom point
    [0.8, 0.8], // Up and out at a 45 degree angle
    [0.8, (0.8+1.8)], // Straight up
    [(0.8+2.15), (0.8+1.8+2.15)], // Up and out at a 45 degree angle
    [0, (0.8+1.8+2.15)], // Go in to form a solid polygon
    [0, 0] //Back to start
];

// Maximum [x,y] values/size of the base.
BASE_PROFILE_MAX = BASE_PROFILE[3];

// Each unit's base is 41.5mm x 41.5mm
// Leaving 0.5mm gap with an l_grid of 42
BASE_SIZE = 41.5;


/**
 * @summary Height of the raw base
 */
h_base = BASE_PROFILE_MAX.y;

// ****************************************
// Baseplate constants
// Based on https://gridfinity.xyz/specification/
// ****************************************
BASEPLATE_OUTSIDE_RADIUS = 8 / 2;

// Polygon describing the raw baseplate lip.
// Does NOT include clearance height.
BASEPLATE_LIP = [
    [0, 0], // Innermost bottom point
    [0.7, 0.7], // Up and out at a 45 degree angle
    [0.7, (0.7+1.8)], // Straight up
    [(0.7+2.15), (0.7+1.8+2.15)], // Up and out at a 45 degree angle
    [(0.7+2.15), 0], // Straight down
    [0, 0] //Back to start
];

// Height of the baseplate lip.
// This ads clearance height to the polygon
// that ensures the base makes contact with the baseplate lip.
BASEPLATE_LIP_HEIGHT = 5;

// The minimum height between the baseplate lip and anything below it.
// Needed to make sure the base always makes contact with the baseplate lip.
BASEPLATE_CLEARANCE_HEIGHT = BASEPLATE_LIP_HEIGHT - BASEPLATE_LIP[3].y;
assert(BASEPLATE_CLEARANCE_HEIGHT > 0, "Negative clearance doesn't make sense.");

// Maximum [x,y] values/size of the baseplate lip.
// Includes clearance height!
BASEPLATE_LIP_MAX = [BASEPLATE_LIP[3].x, BASEPLATE_LIP_HEIGHT];

// ****************************************
// Weighted Baseplate
// ****************************************

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

// ****************************************

// radius of cutout for skeletonized baseplate
r_skel = 2;
// minimum baseplate thickness (when skeletonized)
h_skel = 1;
