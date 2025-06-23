/**
 * @file
 * @brief Functions to make one or more Gridfinty base(s).
 */

include <standard.scad>
use <gridfinity-rebuilt-holes.scad>
use <../helpers/generic-helpers.scad>
use <../helpers/grid.scad>
use <../helpers/list.scad>
use <../helpers/shapes.scad>
use <../external/threads-scad/threads.scad>

_debug = false;
//$fa = 8;
//$fs = 0.25;

/**
 * @brief Create the base of a gridfinity bin, or use it for a custom object.
 * @param grid_size Number of bases in each dimension. [x, y]
 * @param grid_dimensions [length, width] of a single Gridfinity base.
 * @param thumbscrew Enable "gridfinity-refined" thumbscrew hole in the center of each base unit. This is a ISO Metric Profile, 15.0mm size, M15x1.5 designation.
 */
module gridfinityBase(grid_size, grid_dimensions=GRID_DIMENSIONS_MM, hole_options=bundle_hole_options(), only_corners=false, thumbscrew=false) {
    assert(is_list(grid_dimensions) && len(grid_dimensions) == 2 &&
        grid_dimensions.x > 0 && grid_dimensions.y > 0);
    assert(is_list(grid_size) && len(grid_size) == 2 &&
        grid_size.x > 0 && grid_size.y > 0);
    assert(
        is_bool(only_corners) &&
        is_bool(thumbscrew)
    );

    individual_base_size_mm = grid_dimensions - BASE_GAP_MM;

    // Final size of the base top. In mm.
    // Subtracting BASE_GAP_MM to remove the perimeter overhang.
    grid_size_mm = [
        grid_dimensions.x * grid_size.x,
        grid_dimensions.y * grid_size.y
    ] - BASE_GAP_MM;

    // Top which ties all bases together
    _base_bridge_solid(grid_size_mm);

    if(only_corners) {
        difference(){
            pattern_grid(grid_size, grid_dimensions, true, true) {
                base_solid(individual_base_size_mm);
            }

            if(thumbscrew) {
                thumbscrew_position = grid_size_mm - individual_base_size_mm;
                pattern_grid([2, 2], thumbscrew_position, true, true) {
                    _base_thumbscrew();
                }
            }

            _base_holes(hole_options, grid_size_mm);
            _base_preview_fix();
        }
    }
    else {
        pattern_grid(grid_size, grid_dimensions, true, true)
        block_base(hole_options, individual_base_size_mm, thumbscrew=thumbscrew);
    }
}

/**
 * @brief Create the base of a gridfinity bin, or use it for a custom object.
 * @param grid_size Size in number of bases. [x, y]
 * @param grid_dimensions [length, width] of a single Gridfinity base.
 * @param wall_thickness How thick the walls, and holes (if enabled) are.
 * @param bottom_thickness Height of the solid bottom.
 * @param hole_options @see block_base_hole.hole_options
 * @param only_corners Only put holes on each corner.
 */
module gridfinity_base_lite(grid_size, grid_dimensions=GRID_DIMENSIONS_MM, wall_thickness, bottom_thickness, hole_options=bundle_hole_options(), only_corners = false) {
    assert(is_list(grid_size) && len(grid_size) == 2 && grid_size.x > 0 && grid_size.y > 0);
    assert(is_num(wall_thickness) && wall_thickness > 0);
    assert(is_num(bottom_thickness)
        && bottom_thickness >= 0
        && bottom_thickness <= BASE_HEIGHT);
    assert(is_bool(only_corners));

    wall_thickness_2d = [wall_thickness, wall_thickness];

    solid_bridge_height = bottom_thickness - BASE_PROFILE_HEIGHT;
    profile_height = min(bottom_thickness, BASE_PROFILE_HEIGHT);

    individual_base_size_mm = grid_dimensions - BASE_GAP_MM;
    // Final size of the base top. In mm.
    // Subtracting BASE_GAP_MM to remove the perimeter overhang.
    grid_size_mm = [
        grid_dimensions.x * grid_size.x,
        grid_dimensions.y * grid_size.y
    ] - BASE_GAP_MM;

    //Hollow bridging structure to tie the bases together
    color("RosyBrown")
    difference() {
        _base_bridge_solid(grid_size_mm);

        //Creates a square bridging structure.
        translate([0, 0, BASE_PROFILE_HEIGHT-TOLLERANCE])
        pattern_grid(grid_size, grid_dimensions, true, true)
        linear_extrude(BASE_BRIDGE_HEIGHT+2*TOLLERANCE)
        rounded_square(
            individual_base_size_mm - 2 * wall_thickness_2d,
            BASE_TOP_RADIUS-wall_thickness,
            center=true);

        // Chamfer the inner edges
        translate([0, 0, BASE_PROFILE_HEIGHT-TOLLERANCE])
        intersection() {
            pattern_grid(grid_size, grid_dimensions, true, true)
            _lite_bridge_chamfer(
                individual_base_size_mm,
                wall_thickness);

            // Don't touch the exterior.
            linear_extrude(BASE_BRIDGE_HEIGHT+2*TOLLERANCE)
            rounded_square(
                grid_size_mm- 2 * wall_thickness_2d,
                BASE_TOP_RADIUS-wall_thickness,
                center=true);
        }
    }

    //Solid bridging structure
    if (solid_bridge_height > 0) {
        _base_bridge_solid(grid_size_mm, solid_bridge_height);
    }

    render()
    if(only_corners) {
        difference() {
            union() {
                pattern_grid(grid_size, grid_dimensions, true, true)
                base_outer_shell(wall_thickness, profile_height, individual_base_size_mm);
                _base_holes(hole_options, grid_size_mm, -2*wall_thickness);
            }

            _base_holes(hole_options, grid_size_mm);
            _base_preview_fix();
        }
    }
    else {
        pattern_grid(grid_size, grid_dimensions, true, true) {
            difference() {
                union() {
                    base_outer_shell(wall_thickness, profile_height, individual_base_size_mm);
                    _base_holes(hole_options, individual_base_size_mm, -2*wall_thickness);
                }
                _base_holes(hole_options, individual_base_size_mm);
                _base_preview_fix();
            }
        }
    }
}

/**
 * @brief The solid bridging structure for bases.
 * @details Already translated to the correct height. Per the standard.
 * @param grid_size_mm Total grid size.
 *        Taking BASE_GAP_MM into account.
 * @param height
 */
module _base_bridge_solid(grid_size_mm, height=BASE_BRIDGE_HEIGHT) {
    assert(is_valid_2d(grid_size_mm)
        && is_positive(grid_size_mm));
    assert(is_num(height)
        && height >= 0
        && height <= BASE_BRIDGE_HEIGHT);

    color("RosyBrown")
    translate([0, 0, BASE_PROFILE_HEIGHT])
    linear_extrude(height)
    rounded_square(grid_size_mm, BASE_TOP_RADIUS, center=true);
}

/**
 * @brief Negative to chamfer the bridge structure for lite bases.
 * @param individual_base_size_mm Size of a single base.
 *        Taking BASE_GAP_MM into account.
 * @param wall_thickness
 */
module _lite_bridge_chamfer(individual_base_size_mm, wall_thickness) {
    assert(is_valid_2d(individual_base_size_mm)
        && is_positive(individual_base_size_mm));
    assert(is_num(wall_thickness)
        && wall_thickness > 0);

    chamfer_polygon = [
        [0, 0], // Inside of bin
        [wall_thickness, BASE_BRIDGE_HEIGHT],
        [0, BASE_BRIDGE_HEIGHT],
    ];
    translated_polygon = foreach_add(
        chamfer_polygon, [
            BASE_TOP_RADIUS-wall_thickness-TOLLERANCE,
            2*TOLLERANCE
        ]);
    sweep_inner = individual_base_size_mm
        - 2 * [BASE_TOP_RADIUS, BASE_TOP_RADIUS];

    sweep_rounded(sweep_inner)
    polygon(translated_polygon);
}

/**
 * @brief Solid polygon of a gridfinity base.
 * @details Ready for use with `sweep_rounded(...)`.
 *          Square internals allow for `cube` to fill the center.
 */
module _base_polygon() {
    translated_line = foreach_add(BASE_PROFILE, [BASE_BOTTOM_RADIUS, 0]);
    solid_profile = concat(translated_line,
        [
            [0, BASE_PROFILE_HEIGHT],  // Go in to form a solid polygon
            [0, 0],  // Needed since start has been translated.
        ]
    );
    polygon(solid_profile);
}

/**
 * @brief A single solid Gridfinity base.
 * @details Height is BASE_PROFILE_HEIGHT.
 * @warning Does not include the structure tying the bases together.
 * @param top_dimensions [x, y] size of a single base.  Only set if deviating from the standard!
 */
module base_solid(top_dimensions=BASE_TOP_DIMENSIONS) {
    assert(is_valid_2d(top_dimensions)
           && min(top_dimensions) > 2 * BASE_TOP_RADIUS,
        str("Minimum size of a single base must be greater than ", 2 * BASE_TOP_RADIUS)
    );

    base_bottom = base_bottom_dimensions(top_dimensions);
    sweep_inner = foreach_add(base_bottom, -2*BASE_BOTTOM_RADIUS);
    cube_size = foreach_add(base_bottom, -BASE_BOTTOM_RADIUS);

    union(){
        sweep_rounded(sweep_inner)
        _base_polygon();

        //Inner fill
        translate([0, 0, BASE_PROFILE_HEIGHT/2])
        cube([cube_size.x, cube_size.y, BASE_PROFILE_HEIGHT], center=true);
    }
}

/**
 * @brief Internal function to create the negative for a Gridfinity Refined thumbscrew hole.
 * @details Magic constants are what the threads.ScrewHole function does.
 */
module _base_thumbscrew() {
    ScrewThread(
        1.01 * BASE_THUMBSCREW_OUTER_DIAMETER + 1.25 * 0.4,
        BASE_PROFILE_HEIGHT,
        BASE_THUMBSCREW_PITCH
    );
}

/**
 * @brief Internal Code. Generates the 4 holes for a single base.
 * @details Need this fancy code to support refined holes and non-square bases.
 * @param top_dimensions [length, width] of a single Gridfinity base.
 * @param hole_options @see bundle_hole_options
 * @param offset @see block_base_hole.offset
 */
module _base_holes(hole_options, top_dimensions=BASE_TOP_DIMENSIONS, offset=0) {
    hole_position = foreach_add(
        base_bottom_dimensions(top_dimensions)/2,
        -HOLE_DISTANCE_FROM_BOTTOM_EDGE
    );

    for(a=[0:90:270]){
        // i and j represent the 4 quadrants.
        // The +1 is used to keep any values from being exactly 0.
        j = sign(sin(a+1));
        i = sign(cos(a+1));
        translate([i * hole_position.x, j * hole_position.y, 0])
        rotate([0, 0, a])
        block_base_hole(hole_options, offset);
    }
}

/**
 * @brief A single Gridfinity base.  With holes (if set).
 * @details Height is BASE_PROFILE_HEIGHT.
 * @param hole_options @see block_base_hole.hole_options
 * @param top_dimensions [x, y] size of a single base.  Only set if deviating from the standard!
 * @param thumbscrew Enable "gridfinity-refined" thumbscrew hole in the center of each base unit. This is a ISO Metric Profile, 15.0mm size, M15x1.5 designation.
 */
module block_base(hole_options, top_dimensions=BASE_TOP_DIMENSIONS, thumbscrew=false) {
    assert(is_valid_2d(top_dimensions) && is_positive(top_dimensions));
    assert(is_bool(thumbscrew));

    base_bottom = base_bottom_dimensions(top_dimensions);

    difference() {
        base_solid(top_dimensions);

        if (thumbscrew) {
            _base_thumbscrew();
        }
        _base_holes(hole_options, top_dimensions);
        _base_preview_fix();
    }
}

/**
 * @brief Outer shell of a Gridfinity base.
 * @details Height is BASE_PROFILE_HEIGHT.
 * @param wall_thickness How thick the walls are.
 *                       Capped at BASE_TOP_RADIUS.
 * @param bottom_thickness How thick the bottom is.
 * @param top_dimensions [x, y] size of a single base.  Only set if deviating from the standard!
 * @IMPORTANT: This is highly optimized to reduce the amount of geometry generated.
 */
module base_outer_shell(wall_thickness, bottom_thickness, top_dimensions=BASE_TOP_DIMENSIONS) {
    assert(is_num(wall_thickness) && wall_thickness > 0);
    assert(is_num(bottom_thickness)
        && bottom_thickness >= 0
        && bottom_thickness <= BASE_PROFILE_HEIGHT);
    assert(is_valid_2d(top_dimensions)
           && min(top_dimensions) > 2 * BASE_TOP_RADIUS,
        str("Minimum size of a single base must be greater than ", 2 * BASE_TOP_RADIUS)
    );

    base_bottom = base_bottom_dimensions(top_dimensions);
    sweep_inner = foreach_add(base_bottom, -2*BASE_BOTTOM_RADIUS);
    cube_size = foreach_add(base_bottom, -BASE_BOTTOM_RADIUS);

    optimized_wall = wall_thickness <= BASE_BOTTOM_RADIUS;
    optimized_bottom = optimized_wall
        || bottom_thickness < (wall_thickness - BASE_BOTTOM_RADIUS);

    if(_debug)
        echo(
            optimized_wall=optimized_wall,
            optimized_bottom=optimized_bottom
        );

    union(){
        //Sides
        if(optimized_wall) {
            sweep_rounded(sweep_inner)
            _base_polygon_lite(wall_thickness, bottom_thickness);
        } else {
            sweep_rounded(sweep_inner)
            difference() {
                _base_polygon();

                translate([-wall_thickness, 0, 0])
                _base_polygon();
            }
        }

        //Bottom
        if (bottom_thickness > 0)
        if(optimized_bottom){
            translate([0, 0, bottom_thickness/2])
            cube(concat(cube_size, bottom_thickness), center=true);
        } else {
            intersection() {
                translate([0, 0, bottom_thickness/2])
                cube(concat(top_dimensions, bottom_thickness), center=true);
                base_solid(top_dimensions=top_dimensions);
            }
        }
    }
}

/**
 * @brief Optimized lite version of `_base_polygon`.
 * @details Ready for use with `sweep_rounded(...)`.
 *          Produces a shape with a specific thickness.
 *          Bottom internals are squared for use with `cube`.
 * @param wall_thickness How thick the resulting walls are.
 *        Max allowed is BASE_BOTTOM_RADIUS.
 * @param bottom_thickness How thick the bottom is.
 *        Max allowed is BASE_PROFILE_HEIGHT.
 * @warning: Walls may be slightly thicker than expected as they slope to the appropriate bottom_thickness.
 */
module _base_polygon_lite(wall_thickness, bottom_thickness) {
    assert(is_num(wall_thickness)
        && wall_thickness > 0
        && wall_thickness <= BASE_BOTTOM_RADIUS);
    assert(is_num(bottom_thickness)
        && bottom_thickness >= 0
        && bottom_thickness <= BASE_PROFILE_HEIGHT);

    translated_line = foreach_add(BASE_PROFILE, [BASE_BOTTOM_RADIUS, 0]);
    inner_line = reverse(
        foreach_add(translated_line, [-wall_thickness, 0])
    );

    first_point = inner_line[0];
    last_point = inner_line[len(inner_line) -1];

    // Ensures the end is squared off.
    capped_inner_line = [
        for(p = inner_line)
            [p.x, max(p.y, bottom_thickness)]
    ];

    solid_profile = concat(
        translated_line,
        capped_inner_line,
        [last_point] // Go back to start.
    );
    polygon(solid_profile);
}

/**
 * @brief Internal code.  Fix base preview rendering issues.
 * @details Preview does not like perfect top/bottoms.
 */
module _base_preview_fix() {
    if($preview){
        cube([10000, 10000, 0.01], center=true);
        translate([0, 0, BASE_PROFILE_HEIGHT])
        cube([10000, 10000, 0.01], center=true);
    }
}
