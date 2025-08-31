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
 * @param gridfinityUnit Gridfinity is normally on a base 7 system.
 * @returns The final value in mm. **Excluding** base height, and stacking lip height (if present).
 */
function fromGridfinityUnits(gridfinityUnit) =
    gridfinityUnit * 7;

/**
 * @brief Convert a raw mm height to a specific height format.
 * @param raw_mm Raw input value.
 * @param includes_base Raw input value includes the height of the base.
 * @param includes_lip Raw input value includes the (theoretical) lip height.
 * @returns Height value in mm.  Including base. Excluding lip.
 */
function calculate_bin_height(raw_mm, includes_base=false, includes_lip=false) =
    assert(is_num(raw_mm) && raw_mm >= 0)
    assert(is_bool(includes_base))
    assert(is_bool(includes_lip))
    raw_mm
    + (includes_base ? 0 : BASE_HEIGHT)
    - (includes_lip ? STACKING_LIP_HEIGHT : 0);

_gridz_functions = [
    function(h) fromGridfinityUnits(h),
    function(h) calculate_bin_height(h, false, false),
    function(h) calculate_bin_height(h, true, false),
    function(h) calculate_bin_height(h, true, true),
];

/**
 * @brief Ensure height is a multiple of 7 (Gridfinity Units).
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
 * @param gridz_define as explained in gridfinity-rebuilt-bins.scad
 * @param enable_zsnap Automatically snap the bin size to the nearest 7mm increment.
 * @returns Height in mm.  **Excluding** stacking lip height (if present).  **Possibly Excluding** base height.
 */
function height(z, gridz_define, enable_zsnap=true) =
    assert(is_num(z) && z >= 0)
    assert(is_num(gridz_define)
        && gridz_define >= 0
        && gridz_define <= 3)
    assert(is_bool(enable_zsnap))

    let(raw_mm = (_gridz_functions[gridz_define])(z))
    let(total_height = enable_zsnap ? z_snap(raw_mm) : raw_mm)
    max(total_height, BASE_HEIGHT);
