/**
 * @file
 * @brief Functions to create a Gridfinty bin, and cutouts in said bin.
 * @details Uses a struct like syntax to avoid globals.
 * @example ```
 *     bin1 = new_bin(...)
 *     bin_render(bin1) {
 *       equal_bins(bin1, [x_bins, y_bins])
 *     }
 * ```
 */

include <standard.scad>
use <base.scad>
use <gridfinity-rebuilt-holes.scad>
use <wall.scad>
use <../helpers/grid.scad>
use <../helpers/grid_element.scad>
use <../helpers/generic-helpers.scad>
use <../helpers/shapes.scad>

/*
 * @brief Initialize A Gridfinity Bin
 * @details Creates the top portion of a bin, and sets some gloal variables.
 * @param grid_size Size in number of bases. [x, y]
 * @param height_mm Bin height in mm.
 *                  Excludes both STACKING_LIP_HEIGHT and BASE_HEIGHT.
 * @param fill_height_mm Height of the solid which fills a bin.  In mm.
          Set to 0 for automatic.
          Negative numbers are subtracted from the height.
          Set to -height_mm for no infill.
 * @param include_lip If the bin should have a stacking lip.
 * @param hole_options @see bundle_hole_options
 * @param only_corners If only the outer corners of the bin should have holes.
 * @param thumbscrew If the bin's base should have a thumbscrew hole.
 * @param grid_dimensions [length, width] of a single Gridfinity base.
 */
function new_bin(
        grid_size,
        height_mm,
        fill_height = 0,
        include_lip = true,
        hole_options=bundle_hole_options(),
        only_corners=false,
        thumbscrew=false,
        grid_dimensions = GRID_DIMENSIONS_MM
    ) =
    assert(is_valid_2d(grid_size) && is_positive(grid_size))
    assert(is_num(height_mm) && height_mm >= 0)
    assert(is_num(fill_height))
    assert(is_bool(include_lip))
    assert(is_valid_2d(grid_dimensions) && is_positive(grid_dimensions))
    assert(!include_lip || fill_height <= 0 || fill_height <= height_mm - STACKING_LIP_SUPPORT_HEIGHT,
        str("Maximum fill_height for this bin is", height_mm - STACKING_LIP_SUPPORT_HEIGHT))
    let(fill_height_calculated = include_lip ?
        max(height_mm - STACKING_LIP_SUPPORT_HEIGHT, 0)
        : max(height_mm, 0))
    let(fill_height_real =
        fill_height > 0 ? fill_height
        : max(fill_height_calculated + fill_height, 0)
    )
    // Subtracting BASE_GAP_MM to remove the perimeter overhang.
    let(grid_size_mm = vector_scale(grid_size, grid_dimensions) - BASE_GAP_MM)
    [
        "gridfinity_bin_struct",
        grid_size,
        height_mm,
        fill_height_real,
        include_lip,
        grid_dimensions,
        grid_size_mm,
        undef,
        hole_options,
        only_corners,
        thumbscrew
    ];

/*
 * @brief Render a solid bin.
 * @details Any children are subtracted from the bin.
 *          Automatically translated so [0, 0, 0] is the center of the bin, at the top of the fill.
 * @warning Excluding stacking lip, there are deliberately no guards.  Too large of a cutout can damage structural integrety.
 * @warning Stacking lip guards may be removed in the future.
 * @see `bin_render_lite` for a version with additional guards.
 * @param bin The bin to render.  Created by `new_bin`.
 */
module bin_render(bin) {
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    );
    grid_size = bin[1];
    height_mm = bin[2];
    fill_height_real = bin[3];
    include_lip = bin[4];
    grid_dimensions = bin[5];
    grid_size_mm = bin[6];
    hole_options = bin[8];
    only_corners = bin[9];
    thumbscrew = bin[10];

    // If no lip is present, the outer wall is handled by the infill.
    if (include_lip) {
        bin_render_wall(bin);
    }

    difference() {
        union() {
            bin_render_infill(bin);
            bin_render_base(bin);
        }
        translate([0, 0, BASE_HEIGHT + fill_height_real + TOLLERANCE])
        children();
    }
}

/**
 * @brief Render the inner solid part of a bin.
 * @details The resulting solid intersects with the walls.
 *          Allowing a bin without a stacking lip to have a wall.
 * @param bin The bin to render.  Created by `new_bin`.
 */
module bin_render_infill(bin) {
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    );
    fill_height_real = bin[3];
    grid_size_mm = bin[6];

    color("firebrick")
    translate([0, 0, BASE_HEIGHT])
    linear_extrude(fill_height_real)
    rounded_square(grid_size_mm-[TOLLERANCE, TOLLERANCE], BASE_TOP_RADIUS, center=true);
}

/**
 * @brief Render the wall of a bin.  With a stacking lip.
 * @param bin The bin to render.  Created by `new_bin`.
 * @see bin_render_infill if you do not want a stacking lip.
 */
module bin_render_wall(bin) {
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    );
    height_mm = bin[2];
    grid_size_mm = bin[6];

    color("royalblue")
    translate([0, 0, BASE_HEIGHT])
    render_wall(concat(grid_size_mm, height_mm));
}

/**
 * @brief Render the base a bin.
 * @param bin The bin to render.  Created by `new_bin`.
 */
module bin_render_base(bin) {
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    );
    grid_size = bin[1];
    height_mm = bin[2];
    fill_height_real = bin[3];
    include_lip = bin[4];
    grid_dimensions = bin[5];
    grid_size_mm = bin[6];
    hole_options = bin[8];
    only_corners = bin[9];
    thumbscrew = bin[10];

    gridfinityBase(grid_size, grid_dimensions=grid_dimensions, hole_options=hole_options,only_corners=only_corners, thumbscrew=thumbscrew);
}

/**
 * @brief Render a "lite" bin.
 * @details Has safety features allowing cutters to hollow out the base.
 *          Any children are subtracted from the bin.
 *          Automatically translated so [0, 0, 0] is the center of the bin, at the top of the fill.
 * @see `bin_get_infill_size_mm` for obtaining the extra infill height.
 * @param bin The bin to render.  Created by `new_bin`.
 * @param bottom_thickness Thickness of the bottom and bridging structures.
 *        Regular bins have this as BASE_HEIGHT.
 * @warning This could be used as a regular bin, but can cause performance issues.
 */
module bin_render_lite(bin, bottom_thickness) {
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    );
    assert(is_num(bottom_thickness) && bottom_thickness >= 0);
    grid_size = bin[1];
    height_mm = bin[2];
    fill_height_real = bin[3];
    include_lip = bin[4];
    grid_dimensions = bin[5];
    grid_size_mm = bin[6];
    hole_options = bin[8];
    only_corners = bin[9];
    thumbscrew = bin[10];

    // Deliberately overlapping with the bridging structure.
    // Lite bases use a thinner structure.
    // h_bot makes up for said overlap.
    translate([0, 0, BASE_PROFILE_HEIGHT])
    render_wall(concat(grid_size_mm, height_mm + h_bot));

    // While not required, the base cutout will not show correctly in preview without this.
    render()
    difference() {
        // Infill
        union() {
            bin_render_infill(bin);

            // Much easier to just treat an extra base as infill than trying to make a negative.
            color("firebrick")
            bin_render_base(bin);
        }

        translate([0, 0, BASE_HEIGHT + fill_height_real + TOLLERANCE])
        children();
    }

    gridfinity_base_lite(grid_size, grid_dimensions, d_wall, bottom_thickness, hole_options=hole_options, only_corners=only_corners);
}

/**
 * @brief Subdivide the bin.  Any children will be cut out from the center of each sub-division.
 * @details Supports `grid_element_current`.
 *          Takes wall thickness into account.
 *          Meaning `bin_subdivide(bin, bin_bin_get_bases(bin))` does **not** exactly correspond to the center of each base!
 * @param bin A bin created by the `new_bin` function.
 * @param subdivisions The number of sub bins/shapes to cut into the bin. [x, y]
 * @see bin_get_infill_size_mm For why wall thickness needs to be subtracted.
 */
module bin_subdivide(bin, subdivisions) {
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    );
    assert(is_valid_2d(subdivisions)
        && subdivisions.x >=0 && subdivisions.y >=0);
    grid_size = bin[1];
    height_mm = bin[2];
    fill_height_real = bin[3];
    include_lip = bin[4];
    grid_dimensions = bin[5];
    grid_size_mm = bin[6];
    hole_options = bin[8];
    only_corners = bin[9];
    thumbscrew = bin[10];

    infill_size_mm = bin_get_infill_size_mm(bin);
    grid = grid_from_total(
        [subdivisions.x, subdivisions.y, 1],
        infill_size_mm,
        true);

    grid_foreach(grid, true) {
        children();
    }
}

/**
 * @brief Get the number of bases the bin is composed of.
 * @returns [x, y] Number of bases.
 */
function bin_get_bases(bin) =
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    )
    let(grid_size = bin[1])
    grid_size;

/**
 * @brief Get the outer size of the bin.
 * @details Includes the stacking lip, if it is enabled, but excludes BASE_HEIGHT.
 * @returns A 3d vector.
 */
function bin_get_size_mm(bin) =
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    )
    let(height_mm = bin[2])
    let(grid_size_mm = bin[6])
    concat(grid_size_mm, height_mm);

/**
 * @brief Get the infill dimensions.
 * @details Wall overlap handling is cricital for cutout chamfers to work correctly.
 * @param is_lite If the bin is meant to be rendered using `bin_render_light`.
 * @returns Infill dimensions that do not overlap with the walls.
 */
function bin_get_infill_size_mm(bin, is_lite = false) =
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    )
    let(fill_height_real = bin[3])
    let(grid_size_mm = bin[6])
    let(extra_height = is_lite ? BASE_HEIGHT : 0)
    let(total_inner_mm = foreach_add(grid_size_mm, - 2*d_wall))
    concat(total_inner_mm, fill_height_real + extra_height);

/**
 * @brief If the object is a Gridfinity bin.
 * @param bin The object to check.
 */
function is_bin(bin) =
    is_list(bin) && bin[0] == "gridfinity_bin_struct";
