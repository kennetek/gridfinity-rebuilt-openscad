/**
 * @file
 * @brief Functions to make one or more Gridfinty base(s).
 */

include <standard.scad>
use <gridfinity-rebuilt-holes.scad>
use <../helpers/generic-helpers.scad>
use <../helpers/grid.scad>
use <../helpers/shapes.scad>
use <../external/threads-scad/threads.scad>


/**
 * @brief Create the base of a gridfinity bin, or use it for a custom object.
 * @param grid_size Number of bases in each dimension. [x, y]
 * @param grid_dimensions [length, width] of a single Gridfinity base.
 * @param thumbscrew Enable "gridfinity-refined" thumbscrew hole in the center of each base unit. This is a ISO Metric Profile, 15.0mm size, M15x1.5 designation.
 */
module gridfinityBase(grid_size, grid_dimensions=GRID_DIMENSIONS_MM, hole_options=bundle_hole_options(), off=0, final_cut=true, only_corners=false, thumbscrew=false) {
    assert(is_list(grid_dimensions) && len(grid_dimensions) == 2 &&
        grid_dimensions.x > 0 && grid_dimensions.y > 0);
    assert(is_list(grid_size) && len(grid_size) == 2 &&
        grid_size.x > 0 && grid_size.y > 0);
    assert(
        is_bool(final_cut) &&
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
    if (final_cut) {
        translate([0, 0, BASE_HEIGHT])
        linear_extrude(h_bot)
        rounded_square(grid_size_mm, BASE_TOP_RADIUS, center=true);
    }

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

            _base_holes(hole_options, off, grid_size_mm);
            _base_preview_fix();
        }
    }
    else {
        pattern_grid(grid_size, grid_dimensions, true, true)
        block_base(hole_options, off, individual_base_size_mm, thumbscrew=thumbscrew);
    }
}

/**
 * @brief Create the base of a gridfinity bin, or use it for a custom object.
 * @param grid_size Size in number of bases. [x, y]
 * @param grid_dimensions [length, width] of a single Gridfinity base.
 * @param wall_thickness How thick the walls, and holes (if enabled) are.
 * @param top_bottom_thickness How thick the top and bottom is.
 * @param hole_options @see block_base_hole.hole_options
 * @param only_corners Only put holes on each corner.
 */
module gridfinity_base_lite(grid_size, grid_dimensions=GRID_DIMENSIONS_MM, wall_thickness, top_bottom_thickness, hole_options=bundle_hole_options(), only_corners = false) {
    assert(is_list(grid_size) && len(grid_size) == 2 && grid_size.x > 0 && grid_size.y > 0);
    assert(is_num(wall_thickness) && wall_thickness > 0);
    assert(is_num(top_bottom_thickness) && top_bottom_thickness > 0);
    assert(is_bool(only_corners));

    individual_base_size_mm = grid_dimensions - BASE_GAP_MM;

    // Final size of the base top. In mm.
    // Subtracting BASE_GAP_MM to remove the perimeter overhang.
    grid_size_mm = [
        grid_dimensions.x * grid_size.x,
        grid_dimensions.y * grid_size.y
    ] - BASE_GAP_MM;


    //Bridging structure to tie the bases together
    difference() {
        translate([0, 0, BASE_HEIGHT-top_bottom_thickness])
        linear_extrude(top_bottom_thickness)
        rounded_square(grid_size_mm, BASE_TOP_RADIUS, center=true);

        pattern_grid(grid_size, grid_dimensions, true, true)
        translate([0, 0, top_bottom_thickness])
        base_solid(individual_base_size_mm);
    }

    render()
    if(only_corners) {
        difference() {
            union() {
                pattern_grid(grid_size, grid_dimensions, true, true)
                base_outer_shell(wall_thickness, top_bottom_thickness, individual_base_size_mm);
                _base_holes(hole_options, -wall_thickness, grid_size_mm);
            }

            _base_holes(hole_options, 0, grid_size_mm);
            _base_preview_fix();
        }
    }
    else {
        pattern_grid(grid_size, grid_dimensions, true, true) {
            difference() {
                union() {
                    base_outer_shell(wall_thickness, top_bottom_thickness, individual_base_size_mm);
                    _base_holes(hole_options, -wall_thickness, individual_base_size_mm);
                }
                _base_holes(hole_options, 0, individual_base_size_mm);
                _base_preview_fix();
            }
        }
    }
}

/**
 * @brief Solid polygon of a gridfinity base.
 * @details Ready for use with `sweep_rounded(...)`.
 */
module base_polygon() {
    translated_line = foreach_add(BASE_PROFILE, [BASE_BOTTOM_RADIUS, 0]);
    solid_profile = concat(translated_line,
        [
            [0, BASE_PROFILE_MAX.y],  // Go in to form a solid polygon
            [0, 0],  // Needed since start has been translated.
        ]
    );
    polygon(solid_profile);
}

/**
 * @brief A single solid Gridfinity base.
 * @param top_dimensions [x, y] size of a single base.  Only set if deviating from the standard!
 */
module base_solid(top_dimensions=BASE_TOP_DIMENSIONS) {
    assert(is_list(top_dimensions) && len(top_dimensions) == 2);

    base_bottom = base_bottom_dimensions(top_dimensions);
    sweep_inner = foreach_add(base_bottom, -2*BASE_BOTTOM_RADIUS);
    cube_size = foreach_add(base_bottom, -BASE_BOTTOM_RADIUS);

    assert(sweep_inner.x > 0 && sweep_inner.y > 0,
        str("Minimum size of a single base must be greater than ", 2*BASE_TOP_RADIUS)
    );

    union(){
        sweep_rounded(sweep_inner)
            base_polygon();

        translate([0, 0, BASE_HEIGHT/2])
        cube([cube_size.x, cube_size.y, BASE_HEIGHT], center=true);
    }
}

/**
 * @brief Internal function to create the negative for a Gridfinity Refined thumbscrew hole.
 * @details Magic constants are what the threads.ScrewHole function does.
 */
module _base_thumbscrew() {
    ScrewThread(
        1.01 * BASE_THUMBSCREW_OUTER_DIAMETER + 1.25 * 0.4,
        BASE_HEIGHT,
        BASE_THUMBSCREW_PITCH
    );
}

/**
 * @brief Internal Code. Generates the 4 holes for a single base.
 * @details Need this fancy code to support refined holes and non-square bases.
 * @param hole_options @see bundle_hole_options
 * @param offset @see block_base_hole.offset
 */
module _base_holes(hole_options, offset=0, top_dimensions=BASE_TOP_DIMENSIONS) {
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
 * @param hole_options @see block_base_hole.hole_options
 * @param offset Grows or shrinks the final shapes.  Similar to `scale`, but in mm.
 * @param top_dimensions [x, y] size of a single base.  Only set if deviating from the standard!
 * @param thumbscrew Enable "gridfinity-refined" thumbscrew hole in the center of each base unit. This is a ISO Metric Profile, 15.0mm size, M15x1.5 designation.
 */
module block_base(hole_options, offset=0, top_dimensions=BASE_TOP_DIMENSIONS, thumbscrew=false) {
    assert(is_list(top_dimensions) && len(top_dimensions) == 2);
    assert(is_bool(thumbscrew));

    base_bottom = base_bottom_dimensions(top_dimensions);

    difference() {
        base_solid(top_dimensions);

        if (thumbscrew) {
            _base_thumbscrew();
        }
        _base_holes(hole_options, offset, top_dimensions);
        _base_preview_fix();
    }
}

/**
 * @brief Outer shell of a Gridfinity base.
 * @param wall_thickness How thick the walls are.
 * @param bottom_thickness How thick the bottom is.
 * @param top_dimensions [x, y] size of a single base.  Only set if deviating from the standard!
 */
module base_outer_shell(wall_thickness, bottom_thickness, top_dimensions=BASE_TOP_DIMENSIONS) {
    assert(is_num(wall_thickness) && wall_thickness > 0);
    assert((is_num(bottom_thickness) && bottom_thickness > 0));

    union(){
        difference(){
            base_solid(top_dimensions=top_dimensions);
            base_solid(top_dimensions=foreach_add(top_dimensions, -2*wall_thickness));
            _base_preview_fix();
        }
        //Bottom
        intersection() {
            translate([0, 0, bottom_thickness/2])
            cube([top_dimensions.x, top_dimensions.y, bottom_thickness], center=true);
            base_solid(top_dimensions=top_dimensions);
        }
    }
}

/**
 * @brief Internal code.  Fix base preview rendering issues.
 * @details Preview does not like perfect top/bottoms.
 */
module _base_preview_fix() {
    if($preview){
        cube([10000, 10000, 0.01], center=true);
        translate([0, 0, BASE_HEIGHT])
        cube([10000, 10000, 0.01], center=true);
    }
}
