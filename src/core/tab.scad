/**
 * @file
 * @brief Functions to create the tab for a gridfinity bin
 */

include <standard.scad>
use <../helpers/angles.scad>
use <../helpers/generic-helpers.scad>
use <../helpers/grid.scad>
use <../helpers/grid_element.scad>

/**
 * @brief Create a tab.
 * @details Exists half in Quadrant 1, and half in Quadrant 4.
 *          Aka +X axis.
 *          Angled so the base is touching the origin.
 * @param width How wide the tab is.
 */
module tab(width = TAB_WIDTH_NOMINAL){
    assert(is_num(width) && width > 0);

    translate([0, width / 2, 0])
    rotate([90, 0, 00])
    linear_extrude(width)
    polygon(TAB_POLYGON);
}

/*
 * @brief Given a centered bounding box and an angle, snap children to an edge of said box based on the angle.
 * @details Rotates children so they are inside the box.
 *          Children must be in Quadrants 1 & 4.  Aka +X axis.
 * @param box_size [x, y] Size of the box.
 * @param angle In degrees.
 * @param child_width Width of the child object(s).
 *                   If provided, the children will be adjusted to stay inside the bounding box.
 */
module snap_to_edge(box_size, angle, child_width = 0) {
    assert(is_list(box_size) && len(box_size) == 2 && box_size.x > 0 && box_size.y > 0);
    assert(is_num(angle));
    assert(is_num(child_width) && child_width >= 0);

    normalized_angle = normalize_angle(angle);
    corner_angle = atan2(box_size.y, box_size.x);

    // If the angle is pointing to one of the sides (+X or -X)
    is_right_side = abs(normalized_angle) <= corner_angle;
    is_left_side = abs(normalized_angle) >= (180 - corner_angle);
    is_top = normalized_angle >= corner_angle && normalized_angle <= (180-corner_angle);
    is_sides = is_right_side || is_left_side;

    // Snap rotation to edges
    rotate_angle = is_right_side ? 180 :
                   is_left_side ? 0:
                   is_top ? -90 : 90;

    translate_sides = [
        box_size.x/2 * signp(normalize_angle(angle + 90)),
        tan(angle) * box_size.x/2 * signp(normalize_angle(angle + 90)),
        0];
    translate_top_bottom = [
        tan(angle-90) * box_size.y/2 * -signp(normalized_angle),
        box_size.y/2 * signp(normalized_angle),
        0];
    translate_by = is_sides ? translate_sides : translate_top_bottom;

    child_max = foreach_add(box_size, -child_width) / 2;

    bounded_translation = [
        is_sides ? translate_by.x : max(min(translate_by.x, child_max.x), -child_max.x),
        !is_sides ? translate_by.y : max(min(translate_by.y, child_max.y), -child_max.y)
    ];

    translate(bounded_translation)
    rotate([0, 0, rotate_angle])
    children();

    if (!is_undef($debug_snap_to_edge) && $debug_snap_to_edge) {
        max_box_size = norm(box_size)/2;
        // Angle marker
        color([is_right_side?1:0, is_left_side?1:0, is_top?1:0, 1])
        rotate([0, 0, angle-90])
        translate([0, max_box_size/2, 0])
        rotate([90, 0, 0])
        cube([1, 1, max_box_size], center=true);

        color("red")
        translate([0,0,40])
        translate(translate_by)
        sphere(2);

        color("blue")
        translate([0,0,30])
        translate(bounded_translation)
        sphere(3);
    }
}

/**
 * @brief Normalize an angle so that 45 degrees points to the corner of a box.
 */
function normalize_to_box(box_size, angle) =
    assert(is_list(box_size) && len(box_size) == 2 && box_size.x > 0 && box_size.y > 0)
    assert(is_num(angle))
    let(na = normalize_angle(angle))
    let(ba = atan2(box_size.x, box_size.y))
    let(is_sides = abs(na) < 45 || abs(na) > 135)
    let(corner_consts = [0, 90 - ba, 90, 90 + ba, 180])
    sign(na) * corner_consts[floor(abs(na)/45)] + (na % 45) * (is_sides ? (90-ba) : ba)/45;

/**
 * @brief Internal variable. Do not use directly.
 * @details Must be a variable, so it can be used as part of a lookup table.
 */
_auto_tab_angle = function()
    let(element = grid_element_current())
    grid_element_is_first_col(element) ? 134 // Left
    : grid_element_is_last_col(element) ? 46 // Right
    : 90; // Center

/**
 * @brief Automatically calculate the tab angle.
 * @details Angle calculations rely on `grid_element_current`.
 *          First column has tabs on the left.
 *          Last column has tabs on the right.
 *          All others have centered tabs.
 */
function auto_tab_angle() = _auto_tab_angle();

/**
 * @brief Convert style_tab to the actual angle.
 * @param style_tab [0:Full,1:Auto,2:Left,3:Center,4:Right,5:None]
 * @warning Auto only works when `grid_element_current` is available.
 */
function get_tab_angle(style_tab) =
    assert(is_num(style_tab) && style_tab >=0 && style_tab <= 5)
    let(lookup = [90, _auto_tab_angle, 134, 90 , 46, undef])
    is_function(lookup[style_tab]) ? lookup[style_tab]()
    : lookup[style_tab];

$debug_snap_to_edge = false;
if (!is_undef($debug_snap_to_edge) && $debug_snap_to_edge) {
    b = [200, 100];
    color(c=[0.5, 0, 0, 0.1] ) {
        square(b, center=true);
    }
    raw_angle = $t*360;
    norm_a = normalize_angle(raw_angle);
    na = normalize_to_box(b, raw_angle);
    echo(raw_angle=raw_angle, norm_a=norm_a, na=na, quad=floor(na/90));
    snap_to_edge(b,  na){
        tab(TAB_WIDTH_MAX);
    }
}
