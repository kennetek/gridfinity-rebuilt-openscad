/**
 * @file shapes.scad
 * @brief Generic shape modules. Not gridfinity specific.
 */

$debug_shapes=false;

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

/**
 * @brief Create `square`, with rounded corners.
 * @param size Same as `square`.
 * @param radius Radius of the corners. 0 is the same as just calling `square`
 * @param center Same as `square`.
 */
module rounded_square(size, radius, center = false) {
    assert(is_num(size) ||
        (is_list(size) && (
            (len(size) == 2 && is_num(size.x) && is_num(size.y))
        ))
    );
    assert(is_num(radius) && radius >= 0);
    assert(is_bool(center));

    // Make sure something is produced.
    if (is_num(size)) {
        assert((size/2) > radius);
    } else {
        assert((size.x/2) > radius && (size.y/2 > radius),
            str("Cannot create a rounded_square smaller than the corner radius (", radius,").")
        );
    }
    size_l = is_num(size) ? [size, size] : size;
    diameter_2d = 2 * [radius, radius];

    offset(radius)
    square(size_l - diameter_2d, center = center);
}

/**
 * @brief Create `cube`, with rounded corners.
 * @param size A positive 3d vector.
 * @param radius Radius of the corners. 0 is the same as just calling `cube`
 * @param center Same as `cube`.
 */
module rounded_cube(size, radius, center=false) {
    assert(is_list(size)
        && len(size) == 3
        && min(size) > 0);
    assert(is_num(radius) && radius >= 0);

    adjusted = size/2 - [radius, radius, radius];
    assert(min(adjusted) >= 0,
        str("All dimensions must be at least 2*radius (",
            2 * radius ,").\n", "  size: ", size, "\n"));

    translate(center ? [0, 0, 0] : size/2)
    if(radius == 0) {
        cube(size, center=true);
    } else {
        // 8 corners
        for(i=[0:1], j=[0:1], k=[0:1])
        mirror([i, 0, 0])
        mirror([0, j, 0])
        mirror([0, 0, k])
        translate(adjusted)
        {
            sphere(r=radius);

            if(adjusted.x > 0)
            color("orange")
            rotate([0, -90, 0])
            cylinder(r=radius, h=adjusted.x);

            if(adjusted.y > 0)
            color("blue")
            rotate([90, 0, 0])
            cylinder(r=radius, h=adjusted.y);

            if(adjusted.z > 0)
            color("green")
            rotate([0, 180, 0])
            cylinder(r=radius, h=adjusted.z);
        }
        //Center Fill
        if(adjusted.y > 0 && adjusted.z > 0)
        cube(size - 2*[0, radius, radius], center=true);
        if(adjusted.x > 0 && adjusted.z > 0)
        cube(size - 2*[radius, 0, radius], center=true);
        if(adjusted.x > 0 && adjusted.y > 0)
        cube(size - 2*[radius, radius, 0], center=true);

//        if($preview && $debug_shapes)
//        color("grey", 0.1)
//        cube(size, center=true);
    }
}

/**
 * @brief Simple donut shape.
 * @details When inner_r=0, called a "horn torus".
 * @param inner_r Inner radius.
 * @param outer_r Outer radius.
 * @param inner_fill Make the inside solid.
 *                   Equivalent to `rounded_cylinder` with height equal to diameter.
 */
module torus(inner_r, outer_r, inner_fill=false) {
    assert(is_num(inner_r) && inner_r >= 0);
    assert(is_num(outer_r) && outer_r > 0);
    assert(outer_r > inner_r);
    radius = (outer_r - inner_r)/2;

    rotate_extrude(360)
    translate([outer_r-radius, 0, 0])
    circle(r=radius);

    if(inner_fill) {
        cylinder(h=2*radius, r=outer_r-radius, center=true);
    }
//    color("blue", 0.5)
//    circle(r=inner_r);
//    color("red", 0.1)
//    circle(r=outer_r);
}

/**
 * @brief
 * @details This is what (wolframcloud)[https://resources.wolframcloud.com/FunctionRepository/resources/RoundedCylinder] calls it.
 * @param height
 * @param radius
 * @param edge_r Radius of the top/bottom edges.
 *               0 is the same as calling `cylinder`.
 * @param center Same as `cylinder(center)`.
 */
module rounded_cylinder(height, radius, edge_r, center=false) {
    assert(is_num(height) && height>0);
    assert(is_num(radius) && radius>0);
    assert(is_num(edge_r) && edge_r>=0);
    assert(is_bool(center));
    assert(height >= 2*edge_r);
    assert(radius >= 2*edge_r);

    inner_radius = radius-2*edge_r;
    inner_height = height-2*edge_r;

    translate([0, 0, edge_r + (center?-height/2:0)]) {
        if(inner_height > 0) {
            cylinder(h=inner_height, r=radius);
        }
        if(edge_r > 0) {
            torus(inner_radius, radius, true);
            translate([0, 0, inner_height])
            torus(inner_radius, radius, true);
        }
    }
//    color("blue", 0.1)
//    cylinder(h=5, r=5);
}

$test_shapes = true;
if(!is_undef($test_shapes) && $test_shapes){
    $fa = 4;
    $fs = 0.1;

    rounded_cube([3, 4, 5], 1, true);
    translate([5, 0, 0])
    rounded_cube([3, 4, 5], 1, false);

    translate([0, 10, 0])
    torus(4, 5);
    translate([0, 10, 0])
    torus(0, 2);
    translate([0, 20, 0])
    torus(4, 5, true);
    translate([0, 30, 0])
    rounded_cylinder(5, 5, 0.25);
    translate([0, 40, 0])
    rounded_cylinder(5, 5, 2.5);
    translate([0, 50, 0])
    rounded_cylinder(5, 5, 0);
    translate([0, 60, 0])
    rounded_cylinder(5, 5, 0.25, center=true);
    translate([0, 70, 0])
    color("blue")
    cylinder(h=5, r=5, center=true);
}
