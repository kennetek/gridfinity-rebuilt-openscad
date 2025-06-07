/**
 * @file
 * @brief Modules to cut shapes out of a bin.
 */

include <standard.scad>
use <tab.scad>
use <../helpers/shapes.scad>
use <../helpers/generic-helpers.scad>
use <../helpers/grid.scad>
use <../helpers/grid_element.scad>

/**
 * @brief A negative of a square compartment with rounded edges and a chamfered bottom.
 * @param size_mm [x, y, z] Size of the compartment. In mm.
 * @param children Anything which should be removed from the negative.
 *                 Like tabs or a scoop.
 */
module cut_compartment(size_mm) {
    assert(is_list(size_mm) && len(size_mm) == 3 && size_mm.x > 0 && size_mm.y > 0 && size_mm.z > 0);
    bottom_chamfer_mm = [size_mm.x - 2*r_f2, size_mm.y - 2*r_f2];

    translate([0, 0, -size_mm.z + TOLLERANCE])
    difference() {
        linear_extrude(size_mm.z)
        rounded_square([size_mm.x, size_mm.y], r_f2, center=true);

        // Chamfer the bottom edge
        sweep_rounded(bottom_chamfer_mm)
        difference() {
            square([r_f2+TOLLERANCE, r_f2+TOLLERANCE]);
            translate([0, r_f2+TOLLERANCE])
            circle(r=r_f2+TOLLERANCE);
        }
        translate([0, 0, size_mm.z])
        children();
    }
}

/**
 * @brief Add a tab to `cut_compartment`
 * @param size_mm [x, y, z] Size of the compartment. In mm.
 * @param tab_angle Determines where the tab is placed.
 *                  This will be normalized.
 *                  Regardless of compartment dimensions, corners are always at 45 degree intervals.
 * @param full_tab If the tab should always span the entire compartment.
 *                 Otherwise, it is limited to `TAB_WIDTH_NOMINAL`.
 */
module with_tab(size_mm, tab_angle, full_tab = false) {
    assert(is_list(size_mm) && len(size_mm) >= 2 && size_mm.x >0 && size_mm.y > 0);
    assert(is_num(tab_angle));
    assert(is_bool(full_tab));

    size_2d = [size_mm.x, size_mm.y];
    tab_width = full_tab ? max(size_2d) : TAB_WIDTH_NOMINAL;
    normalized_angle = normalize_to_box(size_2d, tab_angle);

    snap_to_edge(size_2d, normalized_angle, tab_width)
    translate([0, 0, -TAB_SIZE.y])
    tab(tab_width);
}

/**
 * @brief Add a scoop to `cut_compartment`
 * @param size_mm [x, y, z] Size of the compartment. In mm.
 * @param scoop_percent 0.0-1.0 how of a scoop should be present.
 */
module with_scoop(size_mm, scoop_percent) {
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
 * @brief Helper to support common compartment options with minimal user code.
 * @details See `cut_compartment`
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

    cut_compartment(size_mm) {
        if (style_tab != 5 && (!tab_top_left_only || is_top_left())) {
            with_tab(
                size_mm,
                get_tab_angle(style_tab),
                style_tab == 0
            );
        }
        if (scoop_percent) {
            with_scoop(size_mm, scoop_percent);
        }
    }
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
module cut_chamfered_cylinder(radius, depth, chamfer_radius = 0, cut_lip=false ) {
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
