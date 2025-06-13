/**
 * @file
 * @brief Functions to create the wall for a Gridfinity bin.
 * @details Has a stacking lip based on https://gridfinity.xyz/specification/
 */

include <standard.scad>
use <../helpers/generic-helpers.scad>

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
    translate([BASE_TOP_RADIUS - STACKING_LIP_SIZE.x, 0, 0]){
        translate([0, height_mm, 0])
        stacking_lip_filleted();
        translate([STACKING_LIP_SIZE.x-d_wall, 0, 0])
        square([d_wall, height_mm]);
    }
}
