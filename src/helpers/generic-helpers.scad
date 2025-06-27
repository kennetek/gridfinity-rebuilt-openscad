/**
 * @file generic-helpers.scad
 * @brief Generic Helper Functions. Not gridfinity specific.
 */

use <grid.scad>

function clp(x,a,b) = min(max(x,a),b);

function is_even(number) = (number%2)==0;

module copy_mirror(vec=[0,1,0]) {
    children();
    if (vec != [0,0,0])
    mirror(vec)
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
 * @brief Convert a vector into a unit vector.
 * @returns The unit vector.  Where total magnitude is 1.
 */
function vector_as_unit(vector) = vector / norm(vector);

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
    _affine_rotate_z(angle_vector.z) *
    _affine_rotate_y(angle_vector.y) *
    _affine_rotate_x(angle_vector.x);

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
 * @returns A list with `to_add` added to each element in the list.
 */
function foreach_add(list, to_add) =
    assert(is_list(list))
    assert(!is_undef(to_add))
    [for (item = list) item + to_add];

/**
 * @brief Scale each element in a vector by the corresponding element in another vector.
 * @param vector1
 * @param vector2
 * @returns The equivalent of `[vector1.x * vector2.x, vector1.y * vector2.y]`
 */
function vector_scale(vector1, vector2) = assert(len(vector1) == len(vector2))
    [for(i=[0:len(vector1)-1]) vector1[i] * vector2[i] ];


/*
 * @brief If the given vector is a valid 2d vector.
 * @details Only validates the first two elements.
 *          The list could have other things after those.
 */
function is_valid_2d(vector) =
    is_list(vector)
    && len(vector) >= 2
    && is_num(vector[0])
    && is_num(vector[1]);

/*
 * @brief If the given vector is a valid 3d vector.
 * @details This just validates the first three elements.
 *          The list could have other things after those.
 */
function is_valid_3d(vector) =
    is_valid_2d(vector)
    && len(vector) >= 3
    && is_num(vector[2]);

/*
 * @brief If all the elements in a vector are greater than zero.
 */
function is_positive(vector) =
    is_list(vector)
    && min(vector) > 0;

/**
 * @breif Simple helper to print affine matrices in an easier to read manner.
 * @details If a multidimensional matrix is provided, then each item is printed to a separate line.
 * @param object Object to print.
 */
module pprint(object) {
    if(is_list(object) && len(object) != len([for(i=object)each i])) {
        echo("[");
        for(i = object) {
            echo(i);
        };
        echo("]");
    } else {
        echo(object);
    }
}

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
        * affine_rotate([0, atan2(path_vectors[i].y, path_vectors[i].x), 0])
    ];

    union()
    {
        for (i = [0 : len(walls) - 1]){
            multmatrix(walls[i])
            linear_extrude(norm(path_vectors[i]))
            children();

            // Rounded Corners
            multmatrix(walls[i] * affine_rotate([-90, 0, 0]))
            rotate_extrude(angle = 90, convexity = 4)
            children();
        }
    }
}
