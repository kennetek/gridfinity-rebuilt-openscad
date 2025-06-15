/**
 * @file gridfinity-rebuilt-utility.scad
 * @brief UTILITY FILE, DO NOT EDIT
 *        EDIT OTHER FILES IN REPO FOR RESULTS
 */

include <standard.scad>
use <wall.scad>
use <cutouts.scad>
use <../helpers/generic-helpers.scad>
use <../helpers/grid.scad>
use <../helpers/shapes.scad>
use <../helpers/grid.scad>
use <../external/threads-scad/threads.scad>

// ===== User Modules ===== //

// functions to convert gridz values to mm values

/**
 * @Summary Convert a number from Gridfinity values to mm.
 * @details Also can include lip when working with height values.
 * @param gridfinityUnit Gridfinity is normally on a base 7 system.
 * @param includeLipHeight Include the lip height as well.
 * @returns The final value in mm. Including base height.
 */
function fromGridfinityUnits(gridfinityUnit, includeLipHeight = false) =
    let(lip_height = includeLipHeight ? STACKING_LIP_HEIGHT : 0)
    max(gridfinityUnit*7 + lip_height, BASE_HEIGHT);

/**
 * @Summary Height in mm including fixed heights.
 * @details Also can include lip when working with height values.
 * @param mmHeight Height without other values.
 * @param includeLipHeight Include the lip height as well.
 * @returns The final value in mm.
 */
function includingFixedHeights(mmHeight, includeLipHeight = false) =
    mmHeight + BASE_HEIGHT + (includeLipHeight ? STACKING_LIP_HEIGHT : 0);

/**
 * @brief Three Functions in One. For height calculations.
 * @param z Height value
 * @param gridz_define As explained in gridfinity-rebuilt-bins.scad
 * @param style_lip as explained in gridfinity-rebuilt-bins.scad
 * @returns Height in mm
 */
function hf (z, gridz_define, style_lip) =
        gridz_define==0 ? fromGridfinityUnits(z, style_lip==2) :
        gridz_define==1 ? includingFixedHeights(z, style_lip==2) :
        gridz_define==2 ? z + (style_lip==2 ? STACKING_LIP_HEIGHT : 0)  :
        assert(false, "gridz_define must be 0, 1, or 2.")
    ;

/**
 * @brief Ensure height is a multiple of 7.
 * @param height_mm The Overall bin's height.
 *                  Including the base!
 * @returns height_mm, if it is a multiple of 7.
 *          Otherwise, the next multiple of 7 from height_mm.
 */
function z_snap(height_mm) =
    height_mm % 7 == 0 ? height_mm
    : height_mm + 7 - height_mm % 7;

/**
 * @brief Calculates the proper height for bins. Three Functions in One.
 * @details This does **not** include the baseplate height.
 * @param z Height value
 * @param d gridz_define as explained in gridfinity-rebuilt-bins.scad
 * @param l style_lip as explained in gridfinity-rebuilt-bins.scad
 * @param enable_zsnap Automatically snap the bin size to the nearest 7mm increment.
 * @returns Height in mm
 */
function height (z,d=0,l=0,enable_zsnap=true) =
    let(total_height = enable_zsnap ? z_snap(hf(z,d,l)) : hf(z,d,l))
    max(total_height - BASE_HEIGHT, 0);

// Creates equally divided cutters for the bin
//
// n_divx:  number of x compartments (ideally, coprime w/ gridx)
// n_divy:  number of y compartments (ideally, coprime w/ gridy)
//          set n_div values to 0 for a solid bin
// style_tab:   tab style for all compartments. see cut()
// scoop_weight:    scoop toggle for all compartments. see cut()
// place_tab:   tab suppression for all compartments. see "gridfinity-rebuilt-bins.scad"
module cutEqual(n_divx=1, n_divy=1, style_tab=1, scoop_weight=1, place_tab=1) {

    element_dimensions = [
        GRID_DIMENSIONS_MM.x * $gxx/n_divx ,
        GRID_DIMENSIONS_MM.y * $gyy/n_divy
    ];

    compartment_size = [
        element_dimensions.x - 2 * d_div,
        element_dimensions.y - 2 * d_div,
        $dh
    ];

    translate([0, 0, $dh + BASE_HEIGHT])
    pattern_grid([n_divx, n_divy], element_dimensions, true, true) {
        cut_compartment_auto(
            compartment_size,
            style_tab,
            place_tab != 0,
            scoop_weight
        );
    }
}


// Creates equally divided cylindrical cutouts
//
// n_divx: number of x cutouts
// n_divy: number of y cutouts
//         set n_div values to 0 for a solid bin
// cylinder_diameter: diameter of cutouts
// cylinder_height: height of cutouts
// chamfer: chamfer around the top rim of the holes
module cutCylinders(n_divx=1, n_divy=1, cylinder_diameter=1, cylinder_height=1, chamfer=0.5) {

    element_dimensions = [
        GRID_DIMENSIONS_MM.x * $gxx/n_divx ,
        GRID_DIMENSIONS_MM.y * $gyy/n_divy
    ];

    translate([0, 0, $dh + BASE_HEIGHT])
    pattern_grid([n_divx, n_divy], element_dimensions, true, true) {
        cut_chamfered_cylinder(cylinder_diameter/2, cylinder_height, chamfer);
    }
}

/**
 * @Summary Initialize A Gridfinity Bin
 * @Details Creates the top portion of a bin, and sets some gloal variables.
 * @TODO: Remove dependence on global variables.
 * @param sl Lip style of this bin.
 *        0:Regular lip,
 *        1:Remove lip subtractively,
 *        2:Remove lip and retain height
 * @param fill_height Height of the solid which fills a bin.  Set to 0 for automatic.
 * @param grid_dimensions [length, width] of a single Gridfinity base.
 */
module gridfinityInit(gx, gy, h, fill_height = 0, grid_dimensions = GRID_DIMENSIONS_MM, sl = 0) {
    $gxx = gx;
    $gyy = gy;
    $dh = h;
    $dh0 = fill_height;
    $style_lip = sl;

    fill_height_real = fill_height != 0 ? fill_height : h - STACKING_LIP_SUPPORT_HEIGHT;

    // Subtracting BASE_GAP_MM to remove the perimeter overhang.
    grid_size_mm = [gx * grid_dimensions.x, gy * grid_dimensions.y] - BASE_GAP_MM;

    // Inner Fill
    difference() {
        color("firebrick")
        translate([0, 0, BASE_HEIGHT])
        linear_extrude(fill_height_real)
        rounded_square(grid_size_mm, BASE_TOP_RADIUS, center=true);
        children();
    }

    // Outer Wall
    // If no lip is present, the outer wall is handled by the inner fill.
    if ($style_lip == 0) {
        translate([0, 0, BASE_HEIGHT])
        render_wall(concat(grid_size_mm, h));
    }
}

// Function to include in the custom() module to individually slice bins
// Will try to clamp values to fit inside the provided base size
//
// x:   start coord. x=1 is the left side of the bin.
// y:   start coord. y=1 is the bottom side of the bin.
// w:   width of compartment, in # of bases covered
// h:   height of compartment, in # of basese covered
// t:   tab style of this specific compartment.
//      alignment only matters if the compartment size is larger than d_tabw
//      0:full, 1:auto, 2:left, 3:center, 4:right, 5:none
//      Automatic alignment will use left tabs for bins on the left edge, right tabs for bins on the right edge, and center tabs everywhere else.
// s:   toggle the rounded back corner that allows for easy removal

module cut(x=0, y=0, w=1, h=1, t=1, s=1) {
    size_mm = [
        GRID_DIMENSIONS_MM.x * clp(w,0,$gxx-x) - d_div,
        GRID_DIMENSIONS_MM.y * clp(h,0,$gyy-y) - d_div,
        $dh
        ];

    cut_move(x,y,w,h)
    cut_compartment_auto(size_mm, t, false, s);
}

// Translates an object from the origin point to the center of the requested compartment block, can be used to add custom cuts in the bin
// See cut() module for parameter descriptions
module cut_move(x, y, w, h) {
    assert(is_num(x));
    assert(is_num(y));
    assert(is_num(w));
    assert(is_num(h));

    corner_mm = [
        GRID_DIMENSIONS_MM.x * x,
        GRID_DIMENSIONS_MM.y * y
    ];
    grid_size_mm = [
        $gxx * GRID_DIMENSIONS_MM.x,
        $gyy * GRID_DIMENSIONS_MM.y
    ];
    size_mm = [
        GRID_DIMENSIONS_MM.x * w,
        GRID_DIMENSIONS_MM.y * h
    ];
    translate_mm = corner_mm - grid_size_mm/2 + size_mm/2;

    translate(concat(translate_mm, $dh + BASE_HEIGHT))
    children();
}
