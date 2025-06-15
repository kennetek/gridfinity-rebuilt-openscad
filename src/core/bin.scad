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
use <gridfinity-base.scad>
use <gridfinity-rebuilt-holes.scad>
use <wall.scad>
use <../helpers/grid.scad>
use <../helpers/generic-helpers.scad>

/*
 * @brief Initialize A Gridfinity Bin
 * @details Creates the top portion of a bin, and sets some gloal variables.
 * @param grid_size Size in number of bases. [x, y]
 * @param height_mm Bin height in mm.
 *                  Excludes both STACKING_LIP_HEIGHT and BASE_HEIGHT.
 * @param fill_height_mm Height of the solid which fills a bin.  In mm.
          Set to -1 for automatic.
 * @param include_lip If the bin should have a stacking lip.
 * @param hole_options @see bundle_hole_options
 * @param only_corners If only the outer corners of the bin should have holes.
 * @param thumbscrew If the bin's base should have a thumbscrew hole.
 * @param grid_dimensions [length, width] of a single Gridfinity base.
 */
function new_bin(
        grid_size,
        height_mm,
        fill_height = -1,
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
    let(fill_height_real =
        fill_height >= 0 ? fill_height
        : include_lip ? max(height_mm - STACKING_LIP_SUPPORT_HEIGHT, 0)
        : max(height_mm, 0)
    )
    // Subtracting BASE_GAP_MM to remove the perimeter overhang.
    let(grid_size_mm = vector_scale(grid_size, grid_dimensions) - BASE_GAP_MM)
    // Need to take wall thickness into account, or things like bin's bottom chamfer won't work correctly.
    let(total_inner_mm = foreach_add(grid_size_mm, - 2*d_wall))
    [
        "gridfinity_bin_struct",
        grid_size,
        height_mm,
        fill_height_real,
        include_lip,
        grid_dimensions,
        grid_size_mm,
        total_inner_mm,
        hole_options,
        only_corners,
        thumbscrew
    ];

/*
 * @brief Render a solid bin.
 * @details Any children are subtracted from the bin.
 *          Automatically translated so [0, 0, 0] is the center of the bin, at the top of the fill.
 * @warning When not using stacking lip, there are deliberately no guards.  Too large of a cutout can damage structural integrety.
 * @warning Stacking lip guards may be removed in the future.
 * @param bin The bin to render.  Created by `new_bin`.
 */
module bin_render(bin) {
    assert(_is_bin(bin),
        "Not a Gridfinity bin."
    );
    grid_size = bin[1];
    height_mm = bin[2];
    fill_height_real = bin[3];
    include_lip = bin[4];
    grid_dimensions = bin[5];
    grid_size_mm = bin[6];
    total_inner_mm = bin[7];
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
 * @param bin The bin to render.  Created by `new_bin`.
 */
module bin_render_infill(bin) {
    assert(_is_bin(bin),
        "Not a Gridfinity bin."
    );
    fill_height_real = bin[3];
    grid_size_mm = bin[6];

    color("firebrick")
    translate([0, 0, BASE_HEIGHT])
    linear_extrude(fill_height_real)
    rounded_square(grid_size_mm, BASE_TOP_RADIUS, center=true);
}

/**
 * @brief Render the wall of a bin.  With a stacking lip.
 * @param bin The bin to render.  Created by `new_bin`.
 */
module bin_render_wall(bin) {
    assert(_is_bin(bin),
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
    assert(_is_bin(bin),
        "Not a Gridfinity bin."
    );
    grid_size = bin[1];
    height_mm = bin[2];
    fill_height_real = bin[3];
    include_lip = bin[4];
    grid_dimensions = bin[5];
    grid_size_mm = bin[6];
    total_inner_mm = bin[7];
    hole_options = bin[8];
    only_corners = bin[9];
    thumbscrew = bin[10];

    gridfinityBase(grid_size, grid_dimensions=grid_dimensions, hole_options=hole_options,only_corners=only_corners, thumbscrew=thumbscrew);
}

/**
 * @brief Get the maximum size of each sub-division.
 * @details Does **not** take `d_div` into account.
 * @param bin A bin created by the `new_bin` function.
 * @param subdivisions The number of sub bins/shapes to cut into the bin. [x, y]
 * @returns [x, y, z] size of each subdivision.  In mm.
 */
function bin_get_subdivision_size(bin, subdivisions) =
    assert(_is_bin(bin),
        "Not a Gridfinity bin."
    )
    assert(is_valid_2d(subdivisions) && is_positive(subdivisions))
    let(fill_height_real = bin[3])
    let(total_inner_mm = bin[7])
    let(subdivision_spacing_mm = vector_scale(total_inner_mm, 1/subdivisions))
    concat(subdivision_spacing_mm, fill_height_real);

/**
 * @brief Subdivide the bin.  Any children will be cut out from the center of each sub-division.
 * @details Allows arbitrary shapes to be cut from the bin.
 * @param bin A bin created by the `new_bin` function.
 * @param subdivisions The number of sub bins/shapes to cut into the bin. [x, y]
 */
module subdivide_bin(bin, subdivisions) {
    assert(_is_bin(bin),
        "Not a Gridfinity bin."
    );
    assert(is_list(subdivisions) && len(subdivisions) == 2 && subdivisions.x >0 && subdivisions.y > 0);
    grid_size = bin[1];
    height_mm = bin[2];
    fill_height_real = bin[3];
    include_lip = bin[4];
    grid_dimensions = bin[5];
    grid_size_mm = bin[6];
    total_inner_mm = bin[7];
    hole_options = bin[8];
    only_corners = bin[9];
    thumbscrew = bin[10];

    subdivision_spacing_mm = vector_scale(total_inner_mm, 1/subdivisions);
    pattern_grid(subdivisions, subdivision_spacing_mm, true, true) {
        children();
    }
}

/**
 * @brief Get the outer size of the bin.
 * @details Includes the stacking lip, if it is enabled.
 */
function bin_get_size_mm(bin) =
    assert(_is_bin(bin),
        "Not a Gridfinity bin."
    )
    let(height_mm = bin[2])
    let(grid_size_mm = bin[6])
    concat(grid_size_mm, height_mm);

/**
 * @brief Get the infill dimensions.
 * @returns Infill dimensions that do not overlap with the walls.
 */
function bin_get_infill_size_mm(bin) =
    assert(_is_bin(bin),
        "Not a Gridfinity bin."
    )
    let(fill_height_real = bin[3])
    let(total_inner_mm = bin[7])
    concat(total_inner_mm, fill_height_real);

/**
 * @brief Internal function. Do not use directly.
 */
function _is_bin(bin) =
    is_list(bin) && bin[0] == "gridfinity_bin_struct";
