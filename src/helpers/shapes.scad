/**
 * @file shapes.scad
 * @brief Generic shape modules. Not gridfinity specific.
 */

/**
 * @brief Create a cone given a radius and an angle.
 * @param bottom_radius Radius of the bottom of the cone.
 * @param angle Angle as measured from the bottom of the cone.
 * @param max_height Optional maximum height.  Cone will be cut off if higher.
 */
module cone(bottom_radius, angle, max_height=0) {
    assert(bottom_radius > 0);
    assert(angle > 0 && angle <= 90);
    assert(max_height >=0);

    height = tan(angle) * bottom_radius;
    if(max_height == 0 || height < max_height) {
        // Normal Cone
        cylinder(h = height, r1 = bottom_radius, r2 = 0, center = false);
    } else {
        top_angle = 90 - angle;
        top_radius = bottom_radius - tan(top_angle) * max_height;
        cylinder(h = max_height, r1 = bottom_radius, r2 = top_radius, center = false);
    }
}
