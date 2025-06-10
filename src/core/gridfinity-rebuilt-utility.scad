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
    let(lip_height = includeLipHeight ? STACKING_LIP_SIZE.y : 0)
    max(gridfinityUnit*7 + lip_height, BASE_HEIGHT);

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
 * @param style_lip as explained in gridfinity-rebuilt-bins.scad
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
        if (
            place_tab == 1 && (i != 1 || j != n_divy) // Top-Left Division
        ) {
            cut((i-1)*$gxx/n_divx,(j-1)*$gyy/n_divy, $gxx/n_divx, $gyy/n_divy, 5, scoop_weight);
        }
        else {
            cut((i-1)*$gxx/n_divx,(j-1)*$gyy/n_divy, $gxx/n_divx, $gyy/n_divy, style_tab, scoop_weight);
        }
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
            linear_extrude(coutout_depth * 2)
            rounded_square([cutout_x, cutout_y], BASE_TOP_RADIUS, true);

            pattern_grid([n_divx, n_divy], [(gridx_mm - padding) / n_divx, (gridy_mm - padding) / n_divy], true, true)
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
        color("royalblue")
        translate([0, 0, BASE_HEIGHT])
        sweep_rounded(foreach_add(grid_size_mm, -2*BASE_TOP_RADIUS))
        profile_wall(h);
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
