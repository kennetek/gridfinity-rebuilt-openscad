


/**
 * @brief Size of a single gridfinity unit. [Length, Width] In millimeters.
 */
GRID_DIMENSIONS_MM = [42, 42];

/**
 * @deprecated Use GRID_DIMENSIONS_MM instead.
 */
l_grid = GRID_DIMENSIONS_MM.x;

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
MAGNET_HOLE_CRUSH_RIB_INNER_RADIUS = 5.5 / 2;
// Mostly arbitrarily chosen.
// 30 ribs does not print with a 0.4mm nozzle.
// Anything 5 or under produces a hole that is not round.
MAGNET_HOLE_CRUSH_RIB_COUNT = 9;

// Radius to add when chamfering magnet and screw holes.
CHAMFER_ADDITIONAL_RADIUS = 0.5;
CHAMFER_ANGLE = 45;

// When countersinking the baseplate, how much to add to the screw radius.
BASEPLATE_SCREW_COUNTERSINK_ADDITIONAL_RADIUS = 5/2;
BASEPLATE_SCREW_COUNTERBORE_RADIUS = 5.5/2;
BASEPLATE_SCREW_COUNTERBORE_HEIGHT = 3;

// ****************************************

// internal fillet radius
r_f2 = 2.8;

// width of divider between compartments
d_div = 1.2;
// minimum wall thickness
d_wall = 0.95;
// ****************************************
// Tab Constants
// Arbitrarily chosen.
// ****************************************

/**
 * @brief Maximum width of a tab.
 */
TAB_WIDTH_NOMINAL = 42;

 /**
 * @brief How deep the tab protrudes into the bin.
 * @details External code should use `TAB_SIZE.x` instead.
 */
_tab_depth = 15.85;

/**
 * @brief Angle of the support holding up the tab
 */
 _tab_support_angle = 36;

 /**
 * @brief Additional support height, so the end isn't a sharp angle.
 */
 _tab_support_height = 1.2;

_tab_height = tan(_tab_support_angle) * _tab_depth + _tab_support_height;
TAB_POLYGON = [
    [0, 0], // Start
    [0, _tab_height], // Up
    [_tab_depth, _tab_height], //Out
    [_tab_depth, _tab_height - _tab_support_height] // Prevent a sharp angle
    //Implicit back to start
];

/**
 * @brief Size of the tab.
 * @Details "x": How deep the tab protrudes into the bin.
 *          "y": The height of the tab.
 */
TAB_SIZE = TAB_POLYGON[2];

// ****************************************
// Stacking Lip Constants
// Based on https://gridfinity.xyz/specification/
// Also includes a support base.
// ****************************************

/**
 * @Summary Fillet so the stacking lip does not come to a sharp point.
 */
STACKING_LIP_FILLET_RADIUS = 0.6;

/**
 * @Summary Height of the innermost section. In mm.
 * @Details Used to keep the innermost lip from just being a triangle.
 *          Spec implicitly expects wall width to equal stacking lip depth, so does not define this.
 */
STACKING_LIP_SUPPORT_HEIGHT = 1.2;

/**
 * @Summary Stacking lip as defined in the spec.  No support.
 * @Details This is just a line, and will not create a solid polygon.
 */
STACKING_LIP_LINE = [
    [0, 0], // Inner tip
    [0.7, 0.7], // Go out 45 degrees
    [0.7, (0.7+1.8)], // Vertical increase
    [(0.7+1.9), (0.7+1.8+1.9)], // Go out 45 degrees
];

/**
 * @Summary Size of the stacking lip.
 * @Details "x": How deep the stacking lip protrudes into the bin.
 *               Including wall thickness.
 *          "y": The height of the stacking lip.
 * @WARNING: Height does NOT include STACKING_LIP_SUPPORT_HEIGHT.
 */
STACKING_LIP_SIZE = STACKING_LIP_LINE[3];

/**
 * @brief Height of the stacking lip.
 * @details Height does **not** include STACKING_LIP_SUPPORT_HEIGHT.
 */
STACKING_LIP_HEIGHT = STACKING_LIP_SIZE.y;

_stacking_lip_support_angle = 45;

/**
 * @Summary Calculated value for the overall height of the stacking lip.
 *          Including support.
 */
_stacking_lip_support_height_mm =
    STACKING_LIP_SUPPORT_HEIGHT
    + tan(90 - _stacking_lip_support_angle) * STACKING_LIP_SIZE.x;

/**
 * @Summary Stacking lip with a support. Used to create a polygon.
 * @Details Support is so the stacking lip is not floating in mid air when wall width is less than stacking lip depth.
 */
STACKING_LIP = concat(STACKING_LIP_LINE, [
    [STACKING_LIP_SIZE.x, -_stacking_lip_support_height_mm], // Down to support bottom
    [0, -STACKING_LIP_SUPPORT_HEIGHT], // Up and in (to bottom inner support)
    //[0, 0] // Implicit back to start
]);

// ****************************************
// Base constants
// Based on https://gridfinity.xyz/specification/
// ****************************************

/**
 * @Summary Profile of a Gridfinity base as described in the spec.
 * @Details This is just a line, and will not create a solid polygon.
 */
BASE_PROFILE = [
    [0, 0], // Innermost bottom point
    [0.8, 0.8], // Up and out at a 45 degree angle
    [0.8, (0.8+1.8)], // Straight up
    [(0.8+2.15), (0.8+1.8+2.15)] // Up and out at a 45 degree angle
];

/**
 * @brief Maximum [x, y] values/size of the base.
 */
_base_profile_max_mm= BASE_PROFILE[3];

/**
 * @Summary Corner radius of the top of the base.
 */
BASE_TOP_RADIUS = 7.5 / 2;

/**
 * @Summary Size of the top of the base. [Length, Width]
 * @Details Each unit's base is 41.5mm x 41.5mm
 *          Leaving 0.5mm gap with an l_grid of 42
 */
BASE_TOP_DIMENSIONS = [41.5, 41.5];

/**
 * @Summary How much overhang is expected by the standard per base.
 * @Details There should be a 0.5mm gap between each base.
 *          This must be kept constant, even at half/quarter grid sizes.
 *          Otherwise, they won't fit in normal grids.
 */
BASE_GAP_MM = GRID_DIMENSIONS_MM - BASE_TOP_DIMENSIONS;

/**
 * @brief Height of the base profile.
 * @details Does **not** include the structure tying the bases together.
 */
BASE_PROFILE_HEIGHT = _base_profile_max_mm.y;

/**
 * @Summary Height of the base.
 * @details Includes the structure tying the bases together.
 */
BASE_HEIGHT = 7;

/**
 * @Summary Height of the structure tying the bases together.
 */
BASE_BRIDGE_HEIGHT = BASE_HEIGHT - BASE_PROFILE_HEIGHT;

/**
 * @Summary Corner radius of the bottom of the base.
 * @Details This is also how much BASE_PROFILE needs to be translated
 *          to use `sweep_rounded(...)`.
 */
BASE_BOTTOM_RADIUS = BASE_TOP_RADIUS - _base_profile_max_mm.x;

/**
 * @Summary Dimensions of the bottom of the base. [Length, Width]
 * @Details Supports arbitrary top sizes.
 * @param top_dimensions [Length, Width] of the top of the base.
 */
function base_bottom_dimensions(top_dimensions = BASE_TOP_DIMENSIONS) =
    assert(is_list(top_dimensions) && len(top_dimensions) == 2
        && is_num(top_dimensions.x) && is_num(top_dimensions.y))
    top_dimensions
    - 2*[_base_profile_max_mm.x, _base_profile_max_mm.x];

// ***************
// Gridfinity Refined Thumbscrew
// See https://www.printables.com/model/413761-gridfinity-refined
// ***************

BASE_THUMBSCREW_OUTER_DIAMETER=15;
BASE_THUMBSCREW_PITCH=1.5;


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


// ****************************************
// Deprecated Values
// Will be removed / re-named in the future.
// ****************************************

// height of tab (yaxis, measured from inner wall)
d_tabh = _tab_depth;

// angle of tab
a_tab = _tab_support_angle;
