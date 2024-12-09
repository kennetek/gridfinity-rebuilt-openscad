/**
 * @file generic-helpers.scad
 * @brief Generic Helper Functions. Not gridfinity specific.
 */

function clp(x,a,b) = min(max(x,a),b);

function is_even(number) = (number%2)==0;

/**
 * @brief Create `square`, with rounded corners.
 * @param size Same as `square`.  See details for differences.
 * @param radius Radius of the corners. 0 is the same as just calling `square`
 * @param center Same as `square`.
 * @details "size" accepts both the standard number or a 2d vector the same as `square`.
 *          However, if passed a 3d vector, this will apply a `linear_extrude` to the resulting shape.
 */
module rounded_square(size, radius, center = false) {
    assert(is_num(size) ||
        (is_list(size) && (
            (len(size) == 2 && is_num(size.x) && is_num(size.y)) ||
            (len(size) == 3 && is_num(size.x) && is_num(size.y) && is_num(size.z))
        ))
    );
    assert(is_num(radius) && radius >= 0 && is_bool(center));

    // Make sure something is produced.
    if (is_num(size)) {
        assert((size/2) > radius);
    } else {
        assert((size.x/2) > radius && (size.y/2 > radius));
        if (len(size) == 3) {
            assert(size.z > 0);
        }
    }

    if (is_list(size) && len(size) == 3) {
        linear_extrude(size.z)
        _internal_rounded_square_2d(size, radius, center);
    } else {
        _internal_rounded_square_2d(size, radius, center);
    }
}

/**
 * @brief Internal module. Do not use. May be changed/removed at any time.
 */
module _internal_rounded_square_2d(size, radius, center) {
    diameter = 2*radius;
    if (is_list(size)) {
        offset(radius)
        square([size.x-diameter, size.y-diameter], center = center);
    } else {
        offset(radius)
        square(size-diameter, center = center);
    }
}

/**
 * @deprecated Use rounded_square(...)
 */
module rounded_rectangle(length, width, height, rad) {
    rounded_square([length, width, height], rad, center=true);
}

module copy_mirror(vec=[0,1,0]) {
    children();
    if (vec != [0,0,0])
    mirror(vec)
    children();
}

module pattern_linear(x = 1, y = 1, sx = 0, sy = 0) {
    yy = sy <= 0 ? sx : sy;
    translate([-(x-1)*sx/2,-(y-1)*yy/2,0])
    for (i = [1:ceil(x)])
    for (j = [1:ceil(y)]) {
      $is_odd_x = (i%2) == 1;
      $is_odd_y = (j%2) == 1;
      translate([(i-1)*sx,(j-1)*yy,0])
      children();
    }
}

module pattern_circular(n=2) {
    for (i = [1:n])
    rotate(i*360/n)
    children();
}

/**
 * @brief Unity (no change) affine transformation matrix.
 * @details For use with multmatrix transforms.
 */
unity_matrix = [
    [1, 0, 0, 0],
    [0, 1, 0, 0],
    [0, 0, 1, 0],
    [0, 0, 0, 1]
];

/**
 * @brief Get the magnitude of a 2d or 3d vector
 * @param vector A 2d or 3d vectorm
 * @returns Magnitude of the vector.
 */
function vector_magnitude(vector) =
    sqrt(vector.x^2 + vector.y^2 + (len(vector) == 3 ? vector.z^2 : 0));

/**
 * @brief Convert a 2d or 3d vector into a unit vector
 * @returns The unit vector.  Where total magnitude is 1.
 */
function vector_as_unit(vector) = vector / vector_magnitude(vector);

/**
 * @brief Convert a 2d vector into an angle.
 * @details Just a wrapper around atan2.
 * @param A 2d vectorm
 * @returns Angle of the vector.
 */
function atanv(vector) = atan2(vector.y, vector.x);

function _affine_rotate_x(angle_x) = [
    [1,  0, 0, 0],
    [0, cos(angle_x), -sin(angle_x), 0],
    [0, sin(angle_x), cos(angle_x), 0],
    [0, 0, 0, 1]
];

function _affine_rotate_y(angle_y) = [
    [cos(angle_y),  0, sin(angle_y), 0],
    [0, 1, 0, 0],
    [-sin(angle_y), 0, cos(angle_y), 0],
    [0, 0, 0, 1]
];

function _affine_rotate_z(angle_z) = [
    [cos(angle_z), -sin(angle_z), 0, 0],
    [sin(angle_z), cos(angle_z), 0, 0],
    [0, 0, 1, 0],
    [0, 0, 0, 1]
];


/**
 * @brief Affine transformation matrix equivalent of `rotate`
 * @param angle_vector @see `rotate`
 * @details Equivalent to `rotate([0, angle, 0])`
 * @returns An affine transformation matrix for use with `multmatrix()`
 */
function affine_rotate(angle_vector) =
    _affine_rotate_z(angle_vector.z) * _affine_rotate_y(angle_vector.y) * _affine_rotate_x(angle_vector.x);

/**
 * @brief Affine transformation matrix equivalent of `translate`
 * @param vector @see `translate`
 * @returns An affine transformation matrix for use with `multmatrix()`
 */
function affine_translate(vector) = [
    [1, 0, 0, vector.x],
    [0, 1, 0, vector.y],
    [0, 0, 1, vector.z],
    [0, 0, 0, 1]
];

/**
 * @brief Affine transformation matrix equivalent of `scale`
 * @param vector @see `scale`
 * @returns An affine transformation matrix for use with `multmatrix()`
 */
function affine_scale(vector) = [
    [vector.x, 0, 0, 0],
    [0, vector.y, 0, 0],
    [0, 0, vector.z, 0],
    [0, 0, 0, 1]
];

/**
 * @brief Add something to each element in a list.
 * @param list The list whos elements will be modified.
 * @param to_add
 * @returns a list with `to_add` added to each element in the list.
 */
function foreach_add(list, to_add) =
    assert(is_list(list))
    assert(!is_undef(to_add))
    [for (item = list) item + to_add];

/**
 * @brief Create a rectangle with rounded corners by sweeping a 2d object along a path.
 * @Details Centered on origin.
 *          Result is on the X,Y plane.
 *          Expects children to be a 2D shape in Quardrant 1 of the X,Y plane.
 * @param size Dimensions of the resulting object.
 *             Either a single number or [width, length]
 */
module sweep_rounded(size) {
    assert((is_num(size) && size > 0) || (
        is_list(size) && len(size) == 2 &&
        is_num(size.x) && size.x > 0 && is_num(size.y) && size.y > 0
        )
    );

    width = is_num(size) ? size : size.x;
    length = is_num(size) ? size : size.y;
    half_width = width/2;
    half_length = length/2;
    path_points = [
        [-half_width, half_length],  //Start
        [half_width, half_length], // Over
        [half_width, -half_length], //Down
        [-half_width, -half_length], // Back over
        [-half_width, half_length]  // Up to start
    ];
    path_vectors = [
        path_points[1] - path_points[0],
        path_points[2] - path_points[1],
        path_points[3] - path_points[2],
        path_points[4] - path_points[3],
    ];
    // These contain the translations, but not the rotations
    // OpenSCAD requires this hacky for loop to get accumulate to work!
    first_translation = affine_translate([path_points[0].y, 0,path_points[0].x]);
    affine_translations = concat([first_translation], [
        for (i = 0, a = first_translation;
            i < len(path_vectors);
            a=a * affine_translate([path_vectors[i].y, 0, path_vectors[i].x]), i=i+1)
        a * affine_translate([path_vectors[i].y, 0, path_vectors[i].x])
    ]);

    // Bring extrusion to the xy plane
    affine_matrix = affine_rotate([90, 0, 90]);

    walls = [
        for (i = [0 : len(path_vectors) - 1])
        affine_matrix * affine_translations[i]
        * affine_rotate([0, atanv(path_vectors[i]), 0])
    ];

    union()
    {
        for (i = [0 : len(walls) - 1]){
            multmatrix(walls[i])
            linear_extrude(vector_magnitude(path_vectors[i]))
            children();

            // Rounded Corners
            multmatrix(walls[i] * affine_rotate([-90, 0, 0]))
            rotate_extrude(angle = 90, convexity = 4)
            children();
        }
    }
}
