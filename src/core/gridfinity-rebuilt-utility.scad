/**
 * @file gridfinity-rebuilt-utility.scad
 * @brief UTILITY FILE, DO NOT EDIT
 *        EDIT OTHER FILES IN REPO FOR RESULTS
 */

include <standard.scad>
use <bin.scad>
use <cutouts.scad>
use <../helpers/generic-helpers.scad>
use <../helpers/grid.scad>
use <../helpers/grid_element.scad>
use <../helpers/list.scad>

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

// Function to include in the custom() module to individually slice bins
// x:   start coord. x=1 is the left side of the bin.
// y:   start coord. y=1 is the bottom side of the bin.
// w:   width of compartment, in # of bases covered
// h:   height of compartment, in # of basese covered
// t:   tab style of this specific compartment.
//      alignment only matters if the compartment size is larger than d_tabw
//      0:full, 1:auto, 2:left, 3:center, 4:right, 5:none
//      Automatic alignment will use left tabs for bins on the left edge, right tabs for bins on the right edge, and center tabs everywhere else.
// s:   toggle the rounded back corner that allows for easy removal

module cut(x=0, y=0, w=1, h=1, t=5, s=1) {
    assert(w > 0 && h > 0);
    bin = $_current_bin;
    assert(is_bin(bin),
        "No active Gridfinity bin."
    );

    infill_size_mm = bin_get_infill_size_mm(bin);

    cut_move(x,y,w,h) {
        element = grid_element_current();
        element_dimensions = grid_element_get_dimensions(element);
        size_mm = [
            element_dimensions.x * w - d_div/2,
            element_dimensions.x * h - d_div/2,
            infill_size_mm.z + TOLLERANCE
        ];
        cut_compartment_auto(size_mm, t, false, s);
    }
}

// Translates an object from the origin point to the center of the requested compartment block, can be used to add custom cuts in the bin
// See cut() module for parameter descriptions
module cut_move(x, y, w, h) {
    assert(is_num(x));
    assert(is_num(y));
    assert(is_num(w));
    assert(is_num(h));

    bin = $_current_bin;
    assert(is_bin(bin),
        "No active Gridfinity bin."
    );

    infill_grid = grid_from_total(
        bin_get_bases(bin),
        as_2d(bin_get_infill_size_mm(bin)),
        true
    );

    element_dimensions = grid_get_element_dimensions(infill_grid);
    size_mm = [
        element_dimensions.x * w - d_div/2,
        element_dimensions.x * h - d_div/2,
        0
    ];

    translate(size_mm/2)
    grid_translate(infill_grid, [x, y], false)
    children();
}
