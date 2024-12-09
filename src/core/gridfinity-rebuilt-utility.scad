/**
 * @file gridfinity-rebuilt-utility.scad
 * @brief UTILITY FILE, DO NOT EDIT
 *        EDIT OTHER FILES IN REPO FOR RESULTS
 */

include <standard.scad>
use <gridfinity-rebuilt-holes.scad>
use <../helpers/generic-helpers.scad>
use <../external/threads-scad/threads.scad>

// ===== User Modules ===== //

// functions to convert gridz values to mm values

/**
 * @Summary Convert a number from Gridfinity values to mm.
 * @details Also can include lip when working with height values.
 * @param gridfinityUnit Gridfinity is normally on a base 7 system.
 * @param includeLipHeight Include the lip height as well.
 * @returns The final value in mm.
 */
function fromGridfinityUnits(gridfinityUnit, includeLipHeight = false) =
    gridfinityUnit*7 + (includeLipHeight ? STACKING_LIP_SIZE.y : 0);

/**
 * @Summary Height in mm including fixed heights.
 * @details Also can include lip when working with height values.
 * @param mmHeight Height without other values.
 * @param includeLipHeight Include the lip height as well.
 * @returns The final value in mm.
 */
function includingFixedHeights(mmHeight, includeLipHeight = false) =
    mmHeight + h_bot + BASE_HEIGHT + (includeLipHeight ? STACKING_LIP_SIZE.y : 0);

/**
 * @brief Three Functions in One. For height calculations.
 * @param z Height value
 * @param gridz_define As explained in gridfinity-rebuilt-bins.scad
 * @param l style_lip as explained in gridfinity-rebuilt-bins.scad
 * @returns Height in mm
 */
function hf (z, gridz_define, style_lip) =
        gridz_define==0 ? fromGridfinityUnits(z, style_lip==2) :
        gridz_define==1 ? includingFixedHeights(z, style_lip==2) :
        gridz_define==2 ? z + (style_lip==2 ? STACKING_LIP_SIZE.y : 0)  :
        assert(false, "gridz_define must be 0, 1, or 2.")
    ;

/**
 * @brief Calculates the proper height for bins. Three Functions in One.
 * @Details Critically, this does not include the baseplate height.
 * @param z Height value
 * @param d gridz_define as explained in gridfinity-rebuilt-bins.scad
 * @param l style_lip as explained in gridfinity-rebuilt-bins.scad
 * @param enable_zsnap Automatically snap the bin size to the nearest 7mm increment.
 * @returns Height in mm
 */
function height (z,d=0,l=0,enable_zsnap=true) =
    (
    enable_zsnap ? (
        (abs(hf(z,d,l))%7==0) ? hf(z,d,l) :
        hf(z,d,l)+7-abs(hf(z,d,l))%7
    )
    :hf(z,d,l)
    ) - BASE_HEIGHT;

// Creates equally divided cutters for the bin
//
// n_divx:  number of x compartments (ideally, coprime w/ gridx)
// n_divy:  number of y compartments (ideally, coprime w/ gridy)
//          set n_div values to 0 for a solid bin
// style_tab:   tab style for all compartments. see cut()
// scoop_weight:    scoop toggle for all compartments. see cut()
// place_tab:   tab suppression for all compartments. see "gridfinity-rebuilt-bins.scad"
module cutEqual(n_divx=1, n_divy=1, style_tab=1, scoop_weight=1, place_tab=1) {
    for (i = [1:n_divx])
    for (j = [1:n_divy])
    {
        // disable style_tab if only Top-Left Division checked
        tab_style = place_tab == 1 && (i != 1 || j != n_divy) ? 5 : style_tab;

        // equally divide extra dimensions
        ex=(i - 1)*$extrax/n_divx;
        ey=(j - 1)*$extray/n_divy;

        cut(
          (i-1)*$gxx/n_divx,
          (j-1)*$gyy/n_divy,
          $gxx/n_divx,
          $gyy/n_divy,
          tab_style,
          scoop_weight,
          offsets=[
            $extrax < 0 ? $extrax-ex : ex,
            $extray < 0 ? $extray-ey : ey,
            abs($extrax)/n_divx,
            abs($extray)/n_divy
          ]
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
// coutout_depth: offset from top to solid part of container
// orientation: orientation of cylinder cutouts (0 = x direction, 1 = y direction, 2 = z direction)
// chamfer: chamfer around the top rim of the holes
module cutCylinders(n_divx=1, n_divy=1, cylinder_diameter=1, cylinder_height=1, coutout_depth=0, orientation=0, chamfer=0.5) {
    rotation = (orientation == 0)
            ? [0, 90, 0]
            : (orientation == 1)
                ? [90, 0, 0]
                : [0, 0, 0];

    // When oriented vertically along the z axis, half of the cutting cylinder is in the air
    // When oriented along the x or y axes, the entire height of the cylinder is cut out
    cylinder_height = (orientation == 2) ? cylinder_height * 2 : cylinder_height;

    // Chamfer is only enabled for vertical, since it doesn't make sense in other orientations
    chamfer = (orientation == 2) ? chamfer : 0;

    gridx_mm = $gxx * l_grid;
    gridy_mm = $gyy * l_grid;
    padding = 2;
    cutout_x = gridx_mm - d_wall * 2;
    cutout_y = gridy_mm - d_wall * 2;

    cut_move(x=0, y=0, w=$gxx, h=$gyy) {
        translate([0, 0, -coutout_depth]) {
            rounded_rectangle(cutout_x, cutout_y, coutout_depth * 2, r_base);

            pattern_linear(x=n_divx, y=n_divy, sx=(gridx_mm - padding) / n_divx, sy=(gridy_mm - padding) / n_divy)
                rotate(rotation)
                    union() {
                        cylinder(d=cylinder_diameter, h=cylinder_height, center=true);
                        if (chamfer > 0) {
                            translate([0, 0, -chamfer]) cylinder(d1=cylinder_diameter, d2=cylinder_diameter + 4 * chamfer, h=2 * chamfer);
                        }
                    };
        }
    }
}

// initialize gridfinity
// sl:  lip style of this bin.
//      0:Regular lip, 1:Remove lip subtractively, 2:Remove lip and retain height
module gridfinityInit(gx, gy, h, h0 = 0, l = l_grid, sl = 0, extra=[0,0]) {
    $gxx = gx;
    $gyy = gy;
    $dh = h;
    $dh0 = h0;
    $style_lip = sl;
    $extrax=extra[0];
    $extray=extra[1];
    difference() {
        color("firebrick")
        block_bottom(h0==0?$dh-0.1:h0, gx, gy, l, extra=extra);
        children();
    }
    color("royalblue")
    block_wall(gx, gy, l, extra=extra) {
        if ($style_lip == 0) profile_wall(h);
        else profile_wall2(h);
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
// offsets: the [x,y,w,h] offsets of the current cut to accomodate the extra x/y dimensions
module cut(x=0, y=0, w=1, h=1, t=1, s=1, tab_width=d_tabw, tab_height=d_tabh, offsets=[0,0,0,0]) {
    translate([0, 0, -$dh - BASE_HEIGHT])
    cut_move(x,y,w,h,offsets)
    block_cutter(
      clp(x,0,$gxx),
      clp(y,0,$gyy),
      clp(w,0,$gxx-x),
      clp(h,0,$gyy-y),
      t, s, tab_width, tab_height,
      offsets=offsets
    );
}


// cuts equally sized bins over a given length at a specified position
// bins_x:  number of bins along x-axis
// bins_y:  number of bins along y-axis
// len_x:   length (in gridfinity bases) along x-axis that the bins_x will fill
// len_y:   length (in gridfinity bases) along y-axis that the bins_y will fill
// pos_x:   start x position of the bins (left side)
// pos_y:   start y position of the bins (bottom side)
// style_tab:   Style of the tab used on the bins
// scoop:   Weight of the scoop on the bottom of the bins
// tab_width:   Width of the tab on the bins, in mm.
// tab_height:  How far the tab will stick out over the bin, in mm. Default tabs fit 12mm labels, but for narrow bins can take up too much space over the opening. This setting allows 'slimmer' tabs for use with thinner labels, so smaller/narrower bins can be labeled and still keep a reasonable opening at the top. NOTE: The measurement is not 1:1 in mm, so a '3.5' value does not guarantee a tab that fits 3.5mm label tape. Use the 'measure' tool after rendering to check the distance between faces to guarantee it fits your needs.
module cutEqualBins(bins_x=1, bins_y=1, len_x=1, len_y=1, pos_x=0, pos_y=0, style_tab=5, scoop=1, tab_width=d_tabw, tab_height=d_tabh) {
    // Calculate width and height of each bin based on total length and number of bins
    bin_width = len_x / bins_x;
    bin_height = len_y / bins_y;

    // Loop through each bin position in x and y direction
    for (i = [0:bins_x-1]) {
        for (j = [0:bins_y-1]) {
            // Calculate the starting position for each bin
            // Adjust position by adding pos_x and pos_y to shift the entire grid of bins as needed
            bin_start_x = pos_x + i * bin_width;
            bin_start_y = pos_y + j * bin_height;

            // Call the cut module to create each bin with calculated position and dimensions
            // Pass through the style_tab and scoop parameters
            cut(bin_start_x, bin_start_y, bin_width, bin_height, style_tab, scoop, tab_width=tab_width, tab_height=tab_height);
        }
    }
}

// Translates an object from the origin point to the center of the requested compartment block, can be used to add custom cuts in the bin
// See cut() module for parameter descriptions
module cut_move(x, y, w, h, offsets=[0,0,0,0]) {
    translate([0, 0, ($dh0==0 ? $dh : $dh0) + BASE_HEIGHT])
    cut_move_unsafe(
      clp(x,0,$gxx),
      clp(y,0,$gyy),
      clp(w,0,$gxx-x),
      clp(h,0,$gyy-y),
      offsets
    )
    children();
}

// ===== Modules ===== //

/**
 * @brief Create the base of a gridfinity bin, or use it for a custom object.
 * @param grid_size Number of bases in each dimension. [x, y]
 * @param grid_dimensions [length, width] of a single Gridfinity base.
 * @param thumbscrew Enable "gridfinity-refined" thumbscrew hole in the center of each base unit. This is a ISO Metric Profile, 15.0mm size, M15x1.5 designation.
 */
module gridfinityBase(grid_size, grid_dimensions=GRID_DIMENSIONS_MM, hole_options=bundle_hole_options(), off=0, final_cut=true, only_corners=false, thumbscrew=false, half_grid_hole_alignment=0, extra=[0,0]) {
    assert(is_list(grid_dimensions) && len(grid_dimensions) == 2 &&
        grid_dimensions.x > 0 && grid_dimensions.y > 0);
    assert(is_list(grid_size) && len(grid_size) == 2 &&
        grid_size.x > 0 && grid_size.y > 0);
    assert(
        is_bool(final_cut) &&
        is_bool(only_corners) &&
        is_bool(thumbscrew)
    );

    extrax=extra[0];
    extray=extra[1];

    // Per spec, there's a 0.5mm gap between each base.
    // This must be kept constant or half bins may not work correctly.
    gap_mm = GRID_DIMENSIONS_MM - BASE_TOP_DIMENSIONS;

    // Divisions per grid
    // Normal, half, or quarter grid sizes supported.
    // Automatically calculated using floating point comparisons.
    dbnxt = [for (i=[1,2,4]) if (abs(grid_size.x*i)%1 < 0.001 || abs(grid_size.x*i)%1 > 0.999) i];
    dbnyt = [for (i=[1,2,4]) if (abs(grid_size.y*i)%1 < 0.001 || abs(grid_size.y*i)%1 > 0.999) i];
    assert(len(dbnxt) > 0 && len(dbnyt) > 0, "Base only supports half and quarter grid spacing.");
    divisions_per_grid = [dbnxt[0], dbnyt[0]];

    // Final size in number of bases
    final_grid_size = [grid_size.x * divisions_per_grid.x, grid_size.y * divisions_per_grid.y];

    base_center_distance_mm = [grid_dimensions.x / divisions_per_grid.x, grid_dimensions.y / divisions_per_grid.y];
    individual_base_size_mm = base_center_distance_mm - gap_mm;

    // Final size of the base top. In mm.
    // subtracting gap_mm here to remove an outer lip along the peremiter.
    grid_size_mm = [
        base_center_distance_mm.x * final_grid_size.x,
        base_center_distance_mm.y * final_grid_size.y
    ] - gap_mm;

    // Top which ties all bases together
    if (final_cut) {
        translate([extrax/2, extray/2, BASE_HEIGHT])
        rounded_square([grid_size_mm.x+abs(extrax), grid_size_mm.y+abs(extray), h_bot], BASE_TOP_RADIUS, center=true);
    }

    if(only_corners) {
        difference(){
            pattern_linear(final_grid_size.x, final_grid_size.y, base_center_distance_mm.x, base_center_distance_mm.y) {
                base_solid(individual_base_size_mm);
            }

            if(thumbscrew) {
                thumbscrew_position = grid_size_mm - individual_base_size_mm;
                pattern_linear(2, 2, thumbscrew_position.x, thumbscrew_position.y) {
                    _base_thumbscrew();
                }
            }

            _base_holes(hole_options, off, grid_size_mm);
            _base_preview_fix();
        }
    }
    else {
        pattern_linear(final_grid_size.x, final_grid_size.y, base_center_distance_mm.x, base_center_distance_mm.y)
        block_base(
          hole_options, off, individual_base_size_mm, thumbscrew=thumbscrew,
          directions=[
            $is_odd_x || half_grid_hole_alignment != 2 ? 1 : -1,
            $is_odd_y || half_grid_hole_alignment == 0 ? 1 : -1]
        );
    }

    // check if we should extend the base to accomodate extra x/y
    add_to_x=extrax != 0 && abs(extrax) > BASE_TOP_RADIUS*2;
    add_to_y=extray != 0 && abs(extray) > BASE_TOP_RADIUS*2;

    if (!add_to_x && extrax != 0) {
      echo("WARNING: extrax should be at least 2*BASE_TOP_RADIUS to be able to add a bottom notch");
    }
    if (!add_to_y && extray != 0) {
      echo("WARNING: extray should be at least 2*BASE_TOP_RADIUS to be able to add a bottom notch");
    }

    // configure where to add extra bases
    extra_bases=[
      add_to_x ? [1,0] : undef,
      add_to_y ? [0,1] : undef,
      add_to_x && add_to_y ? [1,1] : undef,
    ];

    for(base=extra_bases) {
        if (base != undef) {
            assert(len(base) == 2, "extra_bases should have a length of 2");

            base_size_mm = [
              base[0] == 1 ? abs(extrax) : individual_base_size_mm[0],
              base[1] == 1 ? abs(extray) : individual_base_size_mm[1]
            ];

            translate([
              base[0] * (final_grid_size.x/2 * base_center_distance_mm.x * sign(extrax) + extrax/2),
              base[1] * (final_grid_size.y/2 * base_center_distance_mm.y * sign(extray) + extray/2)
            ])
            pattern_linear(
              base[0] == 1 ? 1 : final_grid_size.x,
              base[1] == 1 ? 1 : final_grid_size.y,
              base_center_distance_mm.x,
              base_center_distance_mm.y
            )
            block_base(hole_options, off, base_size_mm, thumbscrew=thumbscrew, directions=[sign(extrax),1]);
        }
    }
}

/**
 * @brief Create the base of a gridfinity bin, or use it for a custom object.
 * @param length X,Y size of a single Gridfinity base.
 * @param grid_size Size in number of bases. [x, y]
 * @param wall_thickness How thick the walls, and holes (if enabled) are.
 * @param top_bottom_thickness How thick the top and bottom is.
 * @param hole_options @see block_base_hole.hole_options
 * @param only_corners Only put holes on each corner.
 */
module gridfinity_base_lite(grid_size, wall_thickness, top_bottom_thickness, hole_options=bundle_hole_options(), only_corners = false) {
    assert(is_list(grid_size) && len(grid_size) == 2 && grid_size.x > 0 && grid_size.y > 0);
    assert(is_num(wall_thickness) && wall_thickness > 0);
    assert(is_num(top_bottom_thickness) && top_bottom_thickness > 0);
    assert(is_bool(only_corners));

    grid_dimensions = GRID_DIMENSIONS_MM;

    // Per spec, there's a 0.5mm gap between each base.
    // This must be kept constant or half bins may not work correctly.
    gap_mm = GRID_DIMENSIONS_MM - BASE_TOP_DIMENSIONS;

    // Final size of the base top. In mm.
    // Gap needs to be removed to prevent an unwanted overhang off the edges.
    grid_size_mm = [grid_dimensions.x * grid_size.x, grid_dimensions.y * grid_size.y] -gap_mm;

    //Bridging structure to tie the bases together
    difference() {
        translate([0, 0, BASE_HEIGHT-top_bottom_thickness])
        rounded_square([grid_size_mm.x, grid_size_mm.y, top_bottom_thickness], BASE_TOP_RADIUS, center=true);

        pattern_linear(grid_size.x, grid_size.y, grid_dimensions.x, grid_dimensions.y)
        translate([0, 0, top_bottom_thickness])
        base_solid();
    }

    render()
    if(only_corners) {
        difference() {
            union() {
                pattern_linear(grid_size.x, grid_size.y, grid_dimensions.x, grid_dimensions.y)
                base_outer_shell(wall_thickness, top_bottom_thickness);
                _base_holes(hole_options, -wall_thickness, grid_size_mm);
            }

            _base_holes(hole_options, 0, grid_size_mm);
            _base_preview_fix();
        }
    }
    else {
        pattern_linear(grid_size.x, grid_size.y, grid_dimensions.x, grid_dimensions.y) {
            difference() {
                union() {
                    base_outer_shell(wall_thickness, top_bottom_thickness);
                    _base_holes(hole_options, -wall_thickness);
                }
                _base_holes(hole_options, 0);
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
 * @param directions The directions into which the base/hole are added
 */
module _base_holes(hole_options, offset=0, top_dimensions=BASE_TOP_DIMENSIONS, directions=[1,1]) {
    hole_position = foreach_add(
        base_bottom_dimensions(top_dimensions)/2,
        -HOLE_DISTANCE_FROM_BOTTOM_EDGE
    );

    // calculate the minimum required dimensions that are needed to add a hole
    base_hole_pos = _base_hole_position(hole_options);
    has_min_x = top_dimensions.x >= 2*base_hole_pos[0] + base_hole_pos[2];
    has_min_y = top_dimensions.y >= 2*base_hole_pos[1] + base_hole_pos[3];

    is_full_x = top_dimensions.x == BASE_TOP_DIMENSIONS.x;
    is_full_y = top_dimensions.y == BASE_TOP_DIMENSIONS.y;

    // don't print any holes if the base is too small
    if (has_min_x && has_min_y) {
        angles = concat(
          is_full_x ? [0, 180] : [],
          is_full_y ? [90, 270] : [],
          has_min_x
            ? (directions[0] == 1 ? [0] : [270])
            : (directions[1] == 1 ? [180] : [90])
        );

        for(a=angles){
            // i and j represent the 4 quadrants.
            // The +1 is used to keep any values from being exactly 0.
            // Don't rotate each hole when base does not span full size,
            // to better fit refined holes
            j = is_full_y ? sign(sin(a+1)) : -sign(directions[1]);
            i = is_full_x ? sign(cos(a+1)) : -sign(directions[0]);
            x = i * hole_position.x;
            y = j * hole_position.y;

            translate([x, y, 0])
            rotate([0, 0, a])
            block_base_hole(hole_options, offset);
        }
    }
}

/**
 * @brief A single Gridfinity base.  With holes (if set).
 * @param hole_options @see block_base_hole.hole_options
 * @param offset Grows or shrinks the final shapes.  Similar to `scale`, but in mm.
 * @param top_dimensions [x, y] size of a single base.  Only set if deviating from the standard!
 * @param thumbscrew Enable "gridfinity-refined" thumbscrew hole in the center of each base unit. This is a ISO Metric Profile, 15.0mm size, M15x1.5 designation.
 * @param directions The directions into which the base/hole are added
 */
module block_base(hole_options, offset=0, top_dimensions=BASE_TOP_DIMENSIONS, thumbscrew=false, directions=[1,1]) {
    assert(is_list(top_dimensions) && len(top_dimensions) == 2);
    assert(is_bool(thumbscrew));

    base_bottom = base_bottom_dimensions(top_dimensions);

    difference() {
        base_solid(top_dimensions);

        if (thumbscrew) {
            _base_thumbscrew();
        }
        _base_holes(hole_options, offset, top_dimensions, directions);
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
 * @brief Internal code.  Calculate base hole position & dimension.
 * @param hole_options @see block_base_hole.hole_options
 * @details Position is from edge not center, used to position holes on partial bases
 */
function _base_hole_position(hole_options) =
  let(
    refined_hole = hole_options[0],
    magnet_hole = hole_options[1],
    chamfer = hole_options[4],
    magnet_hole_size = 2*(MAGNET_HOLE_RADIUS + (chamfer ? CHAMFER_ADDITIONAL_RADIUS : 0)),
  )
  // Treat magnet & refined holes the same (i.e. don't care about the poke through of refined holes)
  magnet_hole || refined_hole ? [
    HOLE_DISTANCE_FROM_BOTTOM_EDGE, // x
    HOLE_DISTANCE_FROM_BOTTOM_EDGE, // y
    magnet_hole_size, // w
    magnet_hole_size  // l
  ] : [0,0,0,0];

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

/**
 * @brief Stacking lip based on https://gridfinity.xyz/specification/
 * @details Also includes a support base.
 */
module stacking_lip() {
    polygon(STACKING_LIP);
}

/**
 * @brief Stacking lip with a with a filleted (rounded) top.
 * @details Based on https://gridfinity.xyz/specification/
 *          Also includes a support base.
 */
module stacking_lip_filleted() {
    // Replace 2D edge with a radius.
    // Method used: tangent, tangent, radius algorithm
    // See:  https://math.stackexchange.com/questions/797828/calculate-center-of-circle-tangent-to-two-lines-in-space
    before_fillet = STACKING_LIP[2];
    to_fillet = STACKING_LIP[3]; // tip, Point to Chamfer
    after_fillet = STACKING_LIP[4];

    fillet_vectors = [
        to_fillet - before_fillet,
        after_fillet - to_fillet,
        ];

    to_fillet_angle = 180 + atan2(
            cross(fillet_vectors[0], fillet_vectors[1]),
            fillet_vectors[0] * fillet_vectors[1]
        );
    half_angle = to_fillet_angle / 2;

    // Distance from tip to the center point of the circle.
    distance_from_edge = STACKING_LIP_FILLET_RADIUS / sin(half_angle);

    // Circle's center point
    fillet_center_vector = distance_from_edge * [sin(half_angle), cos(half_angle)];
    fillet_center_point = to_fillet - fillet_center_vector;

    // Exact point edges intersect the circle
    intersection_distance = fillet_center_vector.y;

//    echo(final_lip_height=fillet_center_point.y + STACKING_LIP_FILLET_RADIUS);

    union() {
        // Rounded top
        translate(concat(fillet_center_point, [0]))
        circle(r = STACKING_LIP_FILLET_RADIUS);

        // Stacking lip with cutout for circle to fit in
        difference(){
            polygon(STACKING_LIP);
            translate(concat(to_fillet, [0]))
            circle(r = intersection_distance);
        }
    }
}

/**
 * @brief External wall profile, with a stacking lip.
 * @details Translated so a 90 degree rotation produces the expected outside radius.
 */
module profile_wall(height_mm) {
    assert(is_num(height_mm))
    translate([r_base - STACKING_LIP_SIZE.x, 0, 0]){
        translate([0, height_mm, 0])
        stacking_lip_filleted();
        translate([STACKING_LIP_SIZE.x-d_wall/2, 0, 0])
        square([d_wall/2, height_mm]);
    }
}

// lipless profile
module profile_wall2(height_mm) {
    assert(is_num(height_mm))
    translate([r_base,0,0])
    mirror([1,0,0])
    square([d_wall, height_mm]);
}

module block_wall(gx, gy, l, extra=[0,0]) {
    extrax=extra[0];
    extray=extra[1];

    translate([extrax/2, extray/2, BASE_HEIGHT])
    sweep_rounded([
      gx*l-2*r_base-0.5-0.001+abs(extrax),
      gy*l-2*r_base-0.5-0.001+abs(extray)
    ])
    children();
}

module block_bottom(h = 2.2, gx, gy, l, extra=[0,0]) {
    extrax=extra[0];
    extray=extra[1];

    translate([extrax/2, extray/2, BASE_HEIGHT + 0.1])
    rounded_rectangle(
      gx*l-0.5-d_wall/4+abs(extrax),
      gy*l-0.5-d_wall/4+abs(extray),
      h,
      r_base+0.01
    );
}

module cut_move_unsafe(x, y, w, h, offsets=[0,0,0,0]) {
    xx = ($gxx*l_grid+d_magic);
    yy = ($gyy*l_grid+d_magic);
    translate([(x)*xx/$gxx,(y)*yy/$gyy,0])
    translate([(-xx+d_div)/2,(-yy+d_div)/2,0])
    translate([(w*xx/$gxx-d_div)/2+offsets[0],(h*yy/$gyy-d_div)/2+offsets[1],0])
    children();
}

module block_cutter(x,y,w,h,t,s,tab_width=d_tabw,tab_height=d_tabh, offsets=[0,0,0,0]) {
    v_len_tab = tab_height;
    v_len_lip = d_wall2-d_wall+1.2;
    v_cut_tab = tab_height - (2*STACKING_LIP_FILLET_RADIUS)/tan(a_tab);
    v_cut_lip = d_wall2-d_wall-d_clear;
    v_ang_tab = a_tab;
    v_ang_lip = 45;

    ycutfirst = y == 0 && $style_lip == 0;
    ycutlast = abs(y+h-$gyy)<0.001 && $style_lip == 0;
    xcutfirst = x == 0 && $style_lip == 0;
    xcutlast = abs(x+w-$gxx)<0.001 && $style_lip == 0;
    zsmall = ($dh+BASE_HEIGHT)/7 < 3;

    ylen = h*($gyy*l_grid+d_magic)/$gyy-d_div+offsets[3];
    xlen = w*($gxx*l_grid+d_magic)/$gxx-d_div+offsets[2];

    height = $dh;
    extent = (abs(s) > 0 && ycutfirst ? d_wall2-d_wall-d_clear : 0);
    tab = (zsmall || t == 5) ? (ycutlast?v_len_lip:0) : v_len_tab;
    ang = (zsmall || t == 5) ? (ycutlast?v_ang_lip:0) : v_ang_tab;
    cut = (zsmall || t == 5) ? (ycutlast?v_cut_lip:0) : v_cut_tab;
    style = (t > 1 && t < 5) ? t-3 : (x == 0 ? -1 : xcutlast ? 1 : 0);

    translate([offsets[2]/2, ylen/2+offsets[3]/2, BASE_HEIGHT+h_bot])
    rotate([90,0,-90]) {

    if (!zsmall && xlen - tab_width > 4*r_f2 && (t != 0 && t != 5)) {
        fillet_cutter(3,"bisque")
        difference() {
            transform_tab(style, xlen, ((xcutfirst&&style==-1)||(xcutlast&&style==1))?v_cut_lip:0, tab_width)
            translate([ycutlast?v_cut_lip:0,0])
            profile_cutter(height-h_bot, ylen/2, s);

            if (xcutfirst)
            translate([0,0,(xlen/2-r_f2)-v_cut_lip])
            cube([ylen,height,v_cut_lip*2]);

            if (xcutlast)
            translate([0,0,-(xlen/2-r_f2)-v_cut_lip])
            cube([ylen,height,v_cut_lip*2]);
        }

        if (t != 0 && t != 5)
        fillet_cutter(2,"indigo")
        difference() {
            transform_tab(style, xlen, ((xcutfirst&&style==-1)||(xcutlast&&style==1)?v_cut_lip:0), tab_width)
            difference() {
                intersection() {
                    profile_cutter(height-h_bot, ylen-extent, s);
                    profile_cutter_tab(height-h_bot, v_len_tab, v_ang_tab);
                }
                if (ycutlast) profile_cutter_tab(height-h_bot, v_len_lip, 45);
            }

            if (xcutfirst)
            translate([ylen/2,0,xlen/2])
            rotate([0,90,0])
            transform_main(2*ylen)
            profile_cutter_tab(height-h_bot, v_len_lip, v_ang_lip);

            if (xcutlast)
            translate([ylen/2,0,-xlen/2])
            rotate([0,-90,0])
            transform_main(2*ylen)
            profile_cutter_tab(height-h_bot, v_len_lip, v_ang_lip);
        }
    }

    fillet_cutter(1,"seagreen")
    translate([0,0,xcutlast?v_cut_lip/2:0])
    translate([0,0,xcutfirst?-v_cut_lip/2:0])
    transform_main(xlen-(xcutfirst?v_cut_lip:0)-(xcutlast?v_cut_lip:0))
    translate([cut,0])
    profile_cutter(height-h_bot, ylen-extent-cut-(!s&&ycutfirst?v_cut_lip:0), s);

    fillet_cutter(0,"hotpink")
    difference() {
        transform_main(xlen)
        difference() {
            profile_cutter(height-h_bot, ylen-extent, s);

            if (!((zsmall || t == 5) && !ycutlast))
            profile_cutter_tab(height-h_bot, tab, ang);

            if (!(abs(s) > 0)&& y == 0)
            translate([ylen-extent,0,0])
            mirror([1,0,0])
            profile_cutter_tab(height-h_bot, v_len_lip, v_ang_lip);
        }

        if (xcutfirst)
        color("indigo")
        translate([ylen/2+0.001,0,xlen/2+0.001])
        rotate([0,90,0])
        transform_main(2*ylen)
        profile_cutter_tab(height-h_bot, v_len_lip, v_ang_lip);

        if (xcutlast)
        color("indigo")
        translate([ylen/2+0.001,0,-xlen/2+0.001])
        rotate([0,-90,0])
        transform_main(2*ylen)
        profile_cutter_tab(height-h_bot, v_len_lip, v_ang_lip);
    }
  }
}

module transform_main(xlen) {
    translate([0,0,-(xlen-2*r_f2)/2])
    linear_extrude(xlen-2*r_f2)
    children();
}

module transform_tab(type, xlen, cut, tab_width=d_tabw) {
    mirror([0,0,type==1?1:0])
    copy_mirror([0,0,-(abs(type)-1)])
    translate([0,0,-(xlen)/2])
    translate([0,0,r_f2])
    linear_extrude((xlen-tab_width-abs(cut))/(1-(abs(type)-1))-2*r_f2)
    children();
}

module fillet_cutter(t = 0, c = "goldenrod") {
    color(c)
    minkowski() {
        children();
        sphere(r = r_f2-t/1000);
    }
}

/**
 * @brief Create the shape to cutout of the block.
 * @param h Height of cutout
 * @param l Length of cutout
 * @param s Scoop weight
 * @param yoffset Move cutout to accomodate extra dimensions
 */
module profile_cutter(h, l, s) {
    scoop = max(s*$dh/2-r_f2,0);
    translate([r_f2,r_f2])
    hull() {
        if (l-scoop-2*r_f2 > 0)
            square(0.1);
        if (scoop < h) {
            translate([l-2*r_f2,h-r_f2/2])
            mirror([1,1])
            square(0.1);

            translate([0,h-r_f2/2])
            mirror([0,1])
            square(0.1);
        }
        difference() {
            translate([l-scoop-2*r_f2, scoop])
            if (scoop != 0) {
                intersection() {
                    circle(scoop);
                    mirror([0,1]) square(2*scoop);
                }
            } else {
              mirror([1,0]) square(0.1);
            }
            translate([l-scoop-2*r_f2,-1])
            square([-(l-scoop-2*r_f2),2*h]);

            translate([0,h])
            square([2*l,scoop]);
        }
    }
}

module profile_cutter_tab(h, tab, ang) {
    if (tab > 0)
        color("blue")
        offset(delta = r_f2)
        polygon([[0,h],[tab,h],[0,h-tab*tan(ang)]]);

}
