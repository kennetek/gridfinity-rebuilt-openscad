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
use <../helpers/list.scad>
use <../helpers/shapes.scad>

/*
 * @brief Initialize A Gridfinity Bin
 * @details Creates the top portion of a bin, and sets some gloal variables.
 * @param grid_size Size in number of bases. [x, y]
 * @param height_mm Bin height in mm.
 *                  Excludes STACKING_LIP_HEIGHT.
 *                  Includes BASE_HEIGHT.
 * @param fill_height_mm Height of the solid which fills a bin.  In mm.
          Set to 0 for automatic.
          Negative numbers are subtracted from the height.
          Set to -height_mm for no infill.
 * @param include_lip If the bin should have a stacking lip.
 * @param hole_options @see bundle_hole_options
 * @param only_corners If only the outer corners of the bin should have holes.
 * @param thumbscrew If the bin's base should have a thumbscrew hole.
 * @param grid_dimensions [length, width] of a single Gridfinity base.
 * @param base_thickness Lower this to create a "lite" bin with a hollow base.
 */
function new_bin(
        grid_size,
        height_mm,
        fill_height = 0,
        include_lip = true,
        hole_options=bundle_hole_options(),
        only_corners=false,
        thumbscrew=false,
        grid_dimensions = GRID_DIMENSIONS_MM,
        base_thickness = BASE_HEIGHT
    ) =
    assert(is_valid_2d(grid_size) && is_positive(grid_size))
    assert(is_num(height_mm) && height_mm >= BASE_HEIGHT)
    assert(is_num(fill_height))
    assert(is_bool(include_lip))
    assert(is_hole_options(hole_options))
    assert(is_bool(only_corners))
    assert(is_bool(thumbscrew))
    assert(is_valid_2d(grid_dimensions) && is_positive(grid_dimensions))
    assert(is_num(base_thickness)
        && base_thickness >= 0
        && base_thickness <= BASE_HEIGHT)
    assert(thumbscrew == false
        || base_thickness == BASE_HEIGHT,
        "Thumscrews are not compatible with custom base_thickness.")
    assert(!include_lip
        || fill_height <= 0
        || fill_height <= height_mm - STACKING_LIP_SUPPORT_HEIGHT,
        str("Maximum fill_height for this bin is", height_mm - STACKING_LIP_SUPPORT_HEIGHT))
    let(fill_height_calculated = include_lip ?
        height_mm - BASE_HEIGHT - STACKING_LIP_SUPPORT_HEIGHT
        : height_mm - BASE_HEIGHT)
    let(fill_height_real =
        fill_height > 0 ? fill_height
        : fill_height_calculated + fill_height
    )
    // Subtracting BASE_GAP_MM to remove the perimeter overhang.
    let(base_grid=new_grid(
        concat(as_2d(grid_size), 1),
        concat(as_2d(grid_dimensions), height_mm),
        true,
        _BIN_BASE_GAP_MM_PERIMETER)
    )
    [
        "gridfinity_bin_struct",
        base_grid,
        base_thickness,
        fill_height_real,
        include_lip,
        undef,
        undef,
        undef,
        hole_options,
        only_corners,
        thumbscrew
    ];

/*
 * @brief Render a solid bin.
 * @details Any children are subtracted from the bin.
 *          Automatically translated so [0, 0, 0] is the center of the bin, at the top of the fill.
 *     Stacking lip guards are always in place.
 * @warning Stacking lip guards may be removed in the future.
 * @param bin The bin to render.  Created by `new_bin`.
 * @param enable_guards Prevent infill from cutting into the base.
 *     In general, ajust `new_bin(base_thickness=...)` instead.
 */
module bin_render(bin, enable_guards=true) {
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    );
    assert(is_bool(enable_guards));
    fill_height = max(bin[3], 0);
    include_lip = bin[4];

    // If no lip is present, the outer wall is handled by the infill.
    if (include_lip) {
        bin_render_wall(bin);
    }

    // While not required, lite bases will not show correctly in preview without this.
    render()
    difference() {
        union() {
            bin_render_infill(bin);
            if(!enable_guards)
                bin_render_base(bin);
        }
        translate([0, 0, BASE_HEIGHT + fill_height + TOLLERANCE])
        children();
    }
    if(enable_guards)
        bin_render_base(bin);
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
    base_grid = bin[1];
    base_thickness = bin[2];
    fill_height = bin[3];  //May be negative.
    hole_options = bin[8];
    only_corners = bin[9];
    thumbscrew = bin[10];

    grid_size_mm = as_2d(grid_get_total_dimensions(base_grid));
    grid_size = bin_get_bases(bin);
    grid_dimensions = bin_get_grid_dimensions(bin);

    color("firebrick")
    translate([0, 0, BASE_HEIGHT])
    linear_extrude(max(fill_height, 0))
    rounded_square(
        grid_size_mm - [TOLLERANCE, TOLLERANCE],
        BASE_TOP_RADIUS,
        center=true);

    // "lite" bins can use the base as infill.
    if(base_thickness != BASE_HEIGHT) {
        total_fill_height = bin_get_infill_size_mm(bin).z;
        intersection() {
            translate([0, 0, base_thickness])
            linear_extrude(total_fill_height)
            square(grid_size_mm, center=true);

            color("firebrick")
            gridfinityBase(grid_size,
                grid_dimensions=grid_dimensions,
                hole_options=hole_options,
                only_corners=only_corners,
                thumbscrew=thumbscrew);
        }
    }
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
    let(base_grid = bin[1])
    let(wall_height = grid_get_total_dimensions(base_grid)
        - [0, 0, BASE_HEIGHT])

    translate([0, 0, BASE_HEIGHT])
    render_wall(wall_height);
}

/**
 * @brief Render the base of a bin.
 * @param bin The bin to render.  Created by `new_bin`.
 */
module bin_render_base(bin) {
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    );
    base_thickness = bin[2];
    hole_options = bin[8];
    only_corners = bin[9];
    thumbscrew = bin[10];

    grid_size = bin_get_bases(bin);
    grid_dimensions = bin_get_grid_dimensions(bin);

    if(base_thickness == BASE_HEIGHT) {
        gridfinityBase(grid_size,
            grid_dimensions=grid_dimensions,
            hole_options=hole_options,
            only_corners=only_corners,
            thumbscrew=thumbscrew);
    } else {
        gridfinity_base_lite(grid_size,
            grid_dimensions=grid_dimensions,
            wall_thickness=d_wall,
            bottom_thickness=base_thickness,
            hole_options=hole_options,
            only_corners=only_corners);
    }
}

/**
 * @brief Subdivide the bin.  Any children will be cut out from the center of each sub-division.
 * @details Supports `grid_element_current`.
 *          Takes wall thickness into account.
 *          Meaning `bin_subdivide(bin, bin_bin_get_bases(bin))` does **not** exactly correspond to the center of each base!
 *          Does nothing if there is no infill.
 * @param bin A bin created by the `new_bin` function.
 * @param subdivisions The number of sub bins/shapes to cut into the bin. [x, y]
 * @see bin_get_infill_size_mm For why wall thickness needs to be subtracted.
 */
module bin_subdivide(bin, subdivisions) {
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    );
    assert(is_valid_2d(subdivisions)
        && subdivisions.x >= 0
        && subdivisions.y >= 0
        );

    num_elements = concat(as_2d(subdivisions), 1);
    infill_size_mm = bin_get_infill_size_mm(bin);

    if(infill_size_mm.z > 0) {
        grid = grid_from_total(num_elements, infill_size_mm, true);
        grid_foreach(grid, true) {
            children();
        }
    }
}

/**
 * @brief Translate to the lower left of a particular grid element.
 * @details [0, 0] is the lower left corner.
 *          Since some functions expect all grid elements to be identical...
 * @param bin A bin created by the `new_bin` function.
 * @param index [x, y] Suppports fractional values.
 * @param exact If [0.5, 0.5] corresponds exactly to the center of a base.
 *        Do not enable this unless you are familiar with how grid_elements interact with perimiters.
 */
module bin_translate(bin, index, exact=false) {
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    );
    assert(is_valid_2d(index));

    index_3d = concat(as_2d(index), 0.5);
    infill_grid = _bin_get_infill_grid(bin, exact);

    grid_translate(infill_grid, index_3d, false)
    children();
}

/**
 * @brief Get the number of bases the bin is composed of.
 * @warning Total size **is not merely multiplying this by `bin_get_bases`.
 * @param bin A bin created by the `new_bin` function.
 * @returns [x, y] Number of bases.
 */
function bin_get_bases(bin) =
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    )
    let(base_grid = bin[1])
    as_2d(grid_get_num_elements(base_grid));

/**
 * @brief Get the dimensions of a single Gridfinity base.
 * @warning Total size **is not merely multiplying this by `bin_get_bases`.
 * @param bin A bin created by the `new_bin` function.
 * @returns [x, y] Size of a single base.
 */
 function bin_get_grid_dimensions(bin) =
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    )
    let(base_grid = bin[1])
    as_2d(grid_get_element_dimensions(base_grid));

/**
 * @brief Get the outer size of the bin.
 * @details Includes base and stacking lip (if enabled).
 * @param bin A bin created by the `new_bin` function.
 * @returns A 3d vector.
 */
function bin_get_bounding_box(bin) =
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    )
    let(base_grid = bin[1])
    let(include_lip = bin[4])
    grid_get_total_dimensions(base_grid)
        + [0, 0, include_lip ? stacking_lip_height() : 0];

/**
 * @brief Get infill dimensions that do not overlap with the walls.
 * @details Wall overlap handling is cricital for cutout chamfers to work correctly.
 * @param bin A bin created by the `new_bin` function.
 * @returns Infill [width, length, height]
 */
function bin_get_infill_size_mm(bin) =
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    )
    let(base_grid = bin[1])
    let(base_thickness=bin[2])
    let(fill_height=bin[3])  //May be negative.
    let(fill_height_total=max(
        fill_height + BASE_HEIGHT - base_thickness, 0))
    let(size_2d=as_2d(grid_get_total_dimensions(base_grid)))
    concat(size_2d-2*[d_wall,d_wall], fill_height_total);

/**
 * @brief Detailed information on bin's overall height.
 * @details Designed for use with `pprint`.
 * @returns A list of [key, value] pairs.
 */
function bin_get_height_breakdown(bin) =
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    )
    let(base_grid = bin[1])
    let(include_lip = bin[4])
    let(bin_height = grid_get_total_dimensions(base_grid).z)
    let(infill_height = bin_get_infill_size_mm(bin).z)
    let(total_height = bin_height + (include_lip ? stacking_lip_height() : 0))
    let(center_height = bin_height - BASE_HEIGHT)
    let(free_space = center_height - infill_height - (include_lip ? STACKING_LIP_SUPPORT_HEIGHT : 0))

    let(heights = [
        ["Total: ", total_height],
        ["* BASE_HEIGHT", BASE_HEIGHT],
        ["  -> BASE_PROFILE_HEIGHT", BASE_PROFILE_HEIGHT],
        ["  -> BASE_BRIDGE_HEIGHT", BASE_BRIDGE_HEIGHT],
        ["* Bin Height", center_height],
        ["  -> Infill", infill_height],
        ["  -> Free space", abs(free_space) > 0.01 ? free_space : 0],
        ["  -> Stacking Lip Support", STACKING_LIP_SUPPORT_HEIGHT],
        ["* Stacking Lip Height (Actual)", stacking_lip_height()],
        ["  -> Stacking Lip Height (Nominal)", STACKING_LIP_HEIGHT],
        ["  -> Stacking Lip Chamfer", stacking_lip_height()-STACKING_LIP_HEIGHT],
    ])

    assert(heights[1][1] == heights[2][1] + heights[3][1],
        "BASE_HEIGHT Calculation Error!")
    assert(heights[8][1] == heights[9][1] + heights[10][1],
        "Stacking Lip Height Calculation Error!")
    assert((heights[5][1] + heights[6][1]
            + (include_lip ? heights[7][1] : 0)
        ) - heights[4][1] < 0.01,
        str("Bin Height Calculation Error!\n",
        "  Expected: ", heights[4][1], "==", heights[5][1],
        "+", heights[6][1], "+", (include_lip ? heights[7][1] : 0),
        "\n"))
    assert(heights[0][1] == heights[1][1] + heights[4][1]
        + (include_lip ? heights[8][1] : 0),
        "Total Height Calculation Error!")
    assert(heights[0][1] == bin_get_bounding_box(bin).z,
        "Total Height Calculation Error!")
    include_lip ? heights: as_list(heights, 7);

/**
 * @brief If the object is a Gridfinity bin.
 * @param bin The object to check.
 */
function is_bin(bin) =
    is_list(bin) && bin[0] == "gridfinity_bin_struct";

/**
 * @brief Internal function. Do not use directly.
 * @param bin A bin created by the `new_bin` function.
 * @param exact If the element center of each element should exactly match the center of the corresponding Gridfinity base.
 * @details Setting exact to true. allows for perfect alignment, but at the cost of the outer elements being slightly smaller.
 */
function _bin_get_infill_grid(bin, exact) =
    assert(is_bin(bin),
        "Not a Gridfinity bin."
    )
    assert(is_bool(exact))
    let(base_grid = bin[1])

    let(infill_size_mm = bin_get_infill_size_mm(bin))
    let(base_perimeter = grid_get_perimeter(base_grid))
    let(infill_element_dimensions=concat(
        bin_get_grid_dimensions(bin),
        infill_size_mm.z))
    let(equal_grid = grid_from_total(
        concat(bin_get_bases(bin), 1), infill_size_mm, true))
    let(exact_grid = grid_from_other(base_grid,
        element_dimensions = infill_element_dimensions,
        perimeter = base_perimeter + _BIN_WALL_PERIMITER))
    // Ensure the calculations are correct.
    assert(grid_get_total_dimensions(equal_grid) == infill_size_mm)
    assert(grid_get_total_dimensions(exact_grid) == infill_size_mm)
    let(infill_grid = exact ? exact_grid : equal_grid)
    infill_grid;

/**
 * @brief Internal variable. Do not use directly.
 */
_BIN_BASE_GAP_MM_PERIMETER = [
    BASE_GAP_MM.x/2,
    BASE_GAP_MM.y/2,
    0,
    BASE_GAP_MM.x/2,
    BASE_GAP_MM.y/2,
    0
];

/**
 * @brief Internal variable. Do not use directly.
 */
 _BIN_WALL_PERIMITER = [
    d_wall,
    d_wall,
    0,
    d_wall,
    d_wall,
    0
 ];
