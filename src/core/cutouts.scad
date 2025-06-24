/**
 * @file
 * @brief Modules to cut shapes out of a bin.
 */

include <standard.scad>
use <tab.scad>
use <../helpers/shapes.scad>
use <../helpers/list.scad>
use <../helpers/generic-helpers.scad>
use <../helpers/grid_element.scad>

/**
 * @brief A negative of a square compartment with rounded edges,
 *        a chamfered bottom, an optional scoop, and an optional tab.
 * @details Zero position is always the top, with the cutout extending down.
 * @param size_mm [x, y, z] Size of the compartment. In mm.
 * @param scoop_percent 0.0-1.0 How much of a scoop should be present.
 * @param tab_width How wide the tab should be.
 *                  Set to 0 to disable tab.
 * @param tab_angle Determines where the tab is placed.
 *        This will be normalized.
 *        Regardless of compartment dimensions, corners are always at 45 degree intervals.
 *        0: centered +x
 *        46: +y wall, right edge.
 *        90: centered +y
 *        134: +y wall, left edge.
 * @param center_top Default true, cutter [x, y] is centered on the current position.
 *        If false, cutter is in quadrant 1 [+x, +y].
 */
module compartment_cutter(size_mm, scoop_percent=0, tab_width=0, tab_angle=90, center_top=true) {
    assert(is_valid_3d(size_mm) && is_positive(size_mm));
    assert(is_num(scoop_percent));
    assert(is_num(tab_angle)
        || (is_undef(tab_angle) && tab_width == 0));
    assert(is_bool(center_top));

    translate_by = center_top ? [0, 0, 0]
        : [size_mm.x/2, size_mm.y/2, 0];

    color("olive")
    translate(translate_by)
    difference() {
        _half_rounded_square(size_mm);

        if (scoop_percent > 0) {
            _compartment_scoop(
                size_mm+as_3d(TOLLERANCE),
                scoop_percent);
        }

        if (tab_width > 0) {
            _compartment_tab(
                size_mm+as_3d(TOLLERANCE),
                tab_width+TOLLERANCE,
                tab_angle);
        }
    }
}

/**
 * @brief Internal module. Do not use directly.
 * @param size_mm [x, y, z] Size of the compartment. In mm.
 */
module _half_rounded_square(size_mm) {
    assert(is_valid_3d(size_mm)
        && is_positive(size_mm));

    difference(){
        rounded_cube([
            size_mm.x,
            size_mm.y,
            size_mm.z*2,
        ], r_f2, center=true);

        translate([0, 0, size_mm.z/2])
        cube(size_mm+as_3d(TOLLERANCE), center=true);
    }
}

/**
 * @brief Internal module. Do not use directly.
 * @details Add a tab to `cut_compartment`
 * @param size_mm [x, y, z] Size of the compartment. In mm.
 * @param tab_width How wide the tab should be.
 * @param tab_angle Determines where the tab is placed.
 *                  This will be normalized.
 *                  Regardless of compartment dimensions, corners are always at 45 degree intervals.
 */
module _compartment_tab(size_mm, tab_width, tab_angle) {
    assert(is_valid_2d(size_mm) && is_positive(size_mm));
    assert(is_num(tab_angle));
    assert(is_num(tab_width) && tab_width > 0);

    size_2d = as_2d(size_mm);
    normalized_angle = normalize_to_box(size_2d, tab_angle);

    snap_to_edge(size_2d, normalized_angle, tab_width)
    translate([0, 0, -TAB_SIZE.y])
    tab(tab_width);
}

/**
 * @brief Internal module. Do not use directly.
 * @details Add a scoop to `cut_compartment`
 * @param size_mm [x, y, z] Size of the compartment. In mm.
 * @param scoop_percent 0.0-1.0 how of a scoop should be present.
 */
module _compartment_scoop(size_mm, scoop_percent) {
    assert(is_list(size_mm) && len(size_mm) == 3 && size_mm.x >0 && size_mm.y > 0 && size_mm.z > 0);
    assert(is_num(scoop_percent) && scoop_percent > 0.0 && scoop_percent <= 1.0);

    scoop = scoop_percent * size_mm.z/2;

    translate([
        -size_mm.x/2,
        -size_mm.y/2,
        0
    ])
    rotate([0, 90, 0])
    linear_extrude(size_mm.x)
    intersection() {
        // Limit to the compartment's size.
        square([size_mm.z, size_mm.y]);

        difference() {
            translate([size_mm.z, 0])
            mirror([1, 0])
            square(scoop);

            translate([size_mm.z-scoop, scoop])
            circle(scoop);
        }
    }
}

/**
 * @brief Support legacy syntax and options.
 * @details See `compartment_cutter`
 * @param size_mm [x, y, z] Size of the compartment. In mm.
 * @param style_tab [0:Full,1:Auto,2:Left,3:Center,4:Right,5:None]
 *        Auto is not supported if `grid_element_current` is not available.
 * @param tab_top_left_only If the tab will only be on the top left compartment.
 *        Only false is supported when `grid_element_current` is not available.
 * @param scoop 0.0-1.0 How much of a scoop should be present.
 */
module cut_compartment_auto(size_mm, style_tab=5, tab_top_left_only=false, scoop_percent=0) {

    // Lambda so `grid_element_current()` is only called when needed.
    // It can throw!
    is_top_left = function()
        let(element = grid_element_current())
        grid_element_is_last_row(element)
        && grid_element_is_first_col(element);

    has_tab = style_tab != 5 && (!tab_top_left_only || is_top_left());
    tab_width = !has_tab ? 0
        : style_tab == 0 ? max(size_mm) : TAB_WIDTH_NOMINAL;
    tab_angle = has_tab ? get_tab_angle(style_tab) : 0;

    compartment_cutter(size_mm, scoop_percent, tab_width, tab_angle);
}

/**
 * @brief A negative of a chamfered cylinder.  Ready to be cut from solid bin.
 * @details Always a 45 degree chamfer.
 *          A cylinder of `radius+chamfer_radius` can be cut from the walls by default as well.
 * @param radius Radius of the cylinder.
 * @param depth How deep the cylinder goes.
 * @param chamfer_radius How far out from the cylinder, the chamfer should extend.
 * @param cut_lip Add an upper cylinder for cutting the stacking lip.
 *                NOTE: This does not bypass safety measures.
 */
module cut_chamfered_cylinder(radius, depth, chamfer_radius = 0, cut_lip=false) {
    assert(is_num(radius) && radius > 0);
    assert(is_num(depth) && depth > 0);
    assert(is_num(chamfer_radius) && chamfer_radius >= 0);
    outer_radius = radius + chamfer_radius;

    color("olive")
    union() {
        translate([0, 0, -depth])
        cylinder(h=depth, r=radius);

        if (cut_lip) {
            //Taller than tallest bin size.
            cylinder(h=10000, r=outer_radius);
        }

       if (chamfer_radius > 0) {
            mirror([0, 0, 1])
            cone(outer_radius, 45, depth);
        }
    }
}

$test_cutouts=true;
if($test_cutouts) {
    $fa = 4;
    $fs = 0.25;

    dim = [45, 20, 25];

    // Internal - Raw Functions
    translate([0, 50, 0]) {
        _half_rounded_square(dim);

        translate([100, 0, 0])
        _compartment_scoop(dim, 1);
        translate([50, 0, 0])
        difference() {
            _half_rounded_square(dim);
            _compartment_scoop(dim+as_3d(TOLLERANCE), 1);
        }
        translate([-100, 0, 0])
        _compartment_tab(dim, TAB_WIDTH_NOMINAL, 90);
        translate([-50, 0, 0])
        difference() {
            _half_rounded_square(dim);
            _compartment_tab(dim+as_3d(TOLLERANCE),
                TAB_WIDTH_NOMINAL, 90);
        }
    }

    // New Syntax
    compartment_cutter(dim);

    translate([50, 0, 0])
    compartment_cutter(dim, 1);
    translate([-50, 0, 0])
    compartment_cutter(dim, 0, TAB_WIDTH_NOMINAL);
    translate([-100, 0, 0])
    compartment_cutter(dim, 1, TAB_WIDTH_NOMINAL);

    // Support legacy syntax
    translate([0, -50, 0]) {
        cut_compartment_auto(dim);
        translate([50, 0, 0])
        cut_compartment_auto(dim, scoop_percent=1);
        translate([-50, 0, 0])
        cut_compartment_auto(dim, style_tab=3);
        translate([-100, 0, 0])
        cut_compartment_auto(dim, style_tab=3, scoop_percent=1);
    }
    // New Syntax - All tab styles (Except Auto)
    translate([0, -100, 0]) {
        compartment_cutter(dim, 0, 0, 0);
        //Right
        translate([50, 0, 0])
        compartment_cutter(dim, 0, TAB_WIDTH_NOMINAL, 46);
        //Left
        translate([-50, 0, 0])
        compartment_cutter(dim, 0, TAB_WIDTH_NOMINAL, 134);
        // Center
        translate([100, 0, 0])
        compartment_cutter(dim, 0, TAB_WIDTH_NOMINAL, 90);
        // Center (full width)
        translate([-100, 0, 0])
        compartment_cutter(dim, 0, max(dim), 90);
    }
    // Legacy Syntax - All tab styles (Except Auto)
    translate([0, -150, 0]) {
        cut_compartment_auto(dim, style_tab=5);
        //Right
        translate([50, 0, 0])
        cut_compartment_auto(dim, style_tab=4);
        //Left
        translate([-50, 0, 0])
        cut_compartment_auto(dim, style_tab=2);
        // Center
        translate([100, 0, 0])
        cut_compartment_auto(dim, style_tab=3);
        // Center (full width)
        translate([-100, 0, 0])
        cut_compartment_auto(dim, style_tab=0);
    }
    // New Syntax - Centered vs top bottom left
    translate([0, 100, 0]) {
        compartment_cutter(dim, 1, TAB_WIDTH_NOMINAL, 90,
            center_top=true);
        translate([0, 50, 0])
        compartment_cutter(dim, 1, TAB_WIDTH_NOMINAL, 90,
            center_top=false);
    }
    //Chamfered hole
    translate([0, 200, 0]) {
        cut_chamfered_cylinder(5, 15);

        translate([20, 0, 0])
        cut_chamfered_cylinder(5, 15, 5);

        translate([40, 0, 0])
        cut_chamfered_cylinder(5, 15, 5, true);
    }
}
