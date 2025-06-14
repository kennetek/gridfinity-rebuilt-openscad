/**
 * @file
 * @brief Functions to create the wall for a Gridfinity bin.
 * @details Has a stacking lip based on https://gridfinity.xyz/specification/
 */

include <standard.scad>
use <../helpers/generic-helpers.scad>

/*
 * @brief Render a wall of the given size, with a stacking lip.
 * @details Centered on x, y origin.  Bottom is at z == 0.
 *          Adds ~STACKING_LIP_HEIGHT to the height of the bin.
 *          Top is rounded, which reduces the height a bit.
 * @param size [x, y, z] Size of the stacking lip. In mm.
 */
module render_wall(size) {
    assert(
        is_valid_3d(size)
        && size.x > 0
        && size.y > 0
        && size.z >= 0
    );

    grid_size_mm = [size.x, size.y];

    // Prevent the stacking lip from protruding too far down.
    intersection() {
        sweep_rounded(foreach_add(grid_size_mm, -2*BASE_TOP_RADIUS))
        _profile_wall(size.z);

        linear_extrude(size.z + STACKING_LIP_HEIGHT)
        square(grid_size_mm, center=true);
    }
}

/**
 * @brief Stacking lip based on https://gridfinity.xyz/specification/
 * @details Also includes a support base.
 */
module _stacking_lip() {
    polygon(STACKING_LIP);
}

/**
 * @brief Stacking lip with a with a filleted (rounded) top.
 * @details Based on https://gridfinity.xyz/specification/
 *          Also includes a support base.
 */
module _stacking_lip_filleted() {
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
            _stacking_lip();
            translate(concat(to_fillet, [0]))
            circle(r = intersection_distance);
        }
    }
}

/**
 * @brief External wall profile, with a stacking lip.
 * @details Translated so a 90 degree rotation produces the expected outside radius.
 * @param height_mm Height of the wall.  Excludes STACKING_LIP_HEIGHT, but **includes** STACKING_LIP_SUPPORT_HEIGHT.
 */
module _profile_wall(height_mm) {
    assert(is_num(height_mm)  && height_mm >=0 )
    translate([BASE_TOP_RADIUS - STACKING_LIP_SIZE.x, 0, 0]){
        translate([0, height_mm, 0])
        _stacking_lip_filleted();

        if(height_mm > 0) {
            translate([STACKING_LIP_SIZE.x-d_wall, 0, 0])
            square([d_wall, height_mm]);
        }
    }
}
