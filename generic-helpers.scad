/**
 * @file generic-helpers.scad
 * @brief Generic Helper Functions. Not gridfinity specific.
 */

function clp(x,a,b) = min(max(x,a),b);

module rounded_rectangle(length, width, height, rad) {
    linear_extrude(height)
    offset(rad)
    offset(-rad)
    square([length,width], center = true);
}

module rounded_square(length, height, rad) {
    rounded_rectangle(length, length, height, rad);
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
    for (j = [1:ceil(y)])
    translate([(i-1)*sx,(j-1)*yy,0])
    children();
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
 * @brief Affine transformation matrix for 2d translation on the X,Y plane.
 * @param vector 2d Vector to translate by.
 * @returns an Affine transformation matrix for use with `multmatrix()`
 */
function affine_translation(vector) = [
    [1, 0, 0, vector.y],
    [0, 1, 0, 0],
    [0, 0, 1, vector.x],
    [0, 0, 0, 1]
];

/**
 * @brief Create a rectangle with rounded corners by sweeping a 2d object along a path.
 *        Centered on origin.
 */
module sweep_rounded(width=10, length=10) {
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
    first_translation = affine_translation(path_points[0]);
    affine_translations = concat([first_translation], [
        for (i = 0, a = first_translation;
            i < len(path_vectors);
            a=a * affine_translation(path_vectors[i]), i=i+1)
        a * affine_translation(path_vectors[i])
    ]);

    // Affine matrix to rotate around X axis
    rot_x = 90;
    x_matrix = [
        [1, 0, 0, 0],
        [0, cos(rot_x), -sin(rot_x), 0],
        [0, sin(rot_x), cos(rot_x), 0],
        [0, 0, 0, 1]
    ];

    // Affine matrix to rotate around Z axis
    z_rot = 90;
    z_matrix = [
        [cos(z_rot), -sin(z_rot), 0, 0],
        [sin(z_rot), cos(z_rot), 0, 0],
        [0, 0, 1, 0],
        [0, 0, 0, 1]
    ];

    // Bring extrusion to the xy plane
    affine_matrix = z_matrix * x_matrix;

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
            multmatrix(walls[i]
                *x_matrix*x_matrix*x_matrix *z_matrix*z_matrix*z_matrix*z_matrix)
            rotate_extrude(angle = 90, convexity = 4)
            children();
        }
    }
}
