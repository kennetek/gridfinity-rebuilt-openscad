/**
 * @File gridfinity-baseplate.scad
 * @Brief Functions and standards to make a SINGLE gridfinity baseplate.
 * @Copyright Arthur Moore 2025 MIT License
 * @WARNING: Where possible, `use` thise file. Constants may change between minor versions.
 */

use <../helpers/generic-helpers.scad>
use <../helpers/shapes.scad>

// ****************************************
// Baseplate constants
// Based on https://gridfinity.xyz/specification/
// ****************************************

/**
 * @Summary Length & Width of a single baseplate.
 */
BASEPLATE_DIMENSIONS = [42, 42];

/**
 * @Summary Minimum height of a baseplate.
 * @Details Ads clearance height to the polygon, and
 *          ensures the base makes contact with the baseplate lip.
 */
BASEPLATE_HEIGHT = 5;

/**
 * @Summary Corner diameter of the outside of the baseplate.
 */
BASEPLATE_OUTER_DIAMETER = 8;

/**
 * @Summary Profile of a Gridfinity baseplate as described in the spec.
 * @Details This is just a line, and will not create a solid polygon.
 *          Does NOT include the clearance height.
 */
_BASEPLATE_PROFILE = [
    [0, 0], // Innermost bottom point
    [0.7, 0.7], // Up and out at a 45 degree angle
    [0.7, (0.7+1.8)], // Straight up
    [(0.7+2.15), (0.7+1.8+2.15)], // Up and out at a 45 degree angle
];

// ****************************************
// Calculations
// ****************************************

/**
 * @Summary Corner radius of the outside of the baseplate.
 */
BASEPLATE_OUTER_RADIUS = BASEPLATE_OUTER_DIAMETER / 2;

///**
// * @Summary Corner radius of the inside of the baseplate.
// * @Details This is also how much _BASEPLATE_PROFILE needs to be translated
// *          to use `sweep_rounded(...)`.
// */
BASEPLATE_INNER_RADIUS = BASEPLATE_OUTER_RADIUS - _BASEPLATE_PROFILE[3].x;

/**
 * @Summary Corner diameter of the inside of the baseplate.
 */
BASEPLATE_INNER_DIAMETER = BASEPLATE_INNER_RADIUS * 2;

// ****************************************
// Implementation Functions
// ****************************************

/**
 * @Summary Polygon of the negative of a baseplate.
 * @Details Includes clearance height, as required by spec.
 *          Ready to use with to use `sweep_rounded(...)`.
 * @param height Height of the baseplate's hollow section.
                 Must be the same as or larger than BASEPLATE_HEIGHT.
 */
module _baseplate_cutter_polygon(height) {
    assert(height >= BASEPLATE_HEIGHT, "_baseplate_cutter_polygon: height may not be less than BASEPLATE_HEIGHT");
    // The minimum height between the baseplate lip and anything below it.
    // Needed to make sure the base always makes contact with the baseplate lip.
    _baseplate_clearance_height = height - _BASEPLATE_PROFILE[3].y;
    assert(_baseplate_clearance_height > 0, "Baseplate too short.");

    translated_line = foreach_add(_BASEPLATE_PROFILE,
        [BASEPLATE_INNER_RADIUS, _baseplate_clearance_height]);

    polygon(concat(translated_line, [
            [0, height],  // Go in to form a solid polygon
            [0, 0],  // Straight down
            [translated_line[0].x, 0] // Out to the translated start.
        ]));
}

// ****************************************
// Exported Functions
// ****************************************

/**
 * @Summary Inner size of the baseplate.
 * @param size [width, length] of a single baseplate.
 *             Only set if deviating from the standard!
 * @Details To be used with `rounded_square(...)` from generic-helpers.
 * @Example `rounded_square(baseplate_inner_size(), BASEPLATE_INNER_RADIUS, center=true);`
 */
function baseplate_inner_size(size=BASEPLATE_DIMENSIONS) = foreach_add(size, BASEPLATE_INNER_DIAMETER - BASEPLATE_OUTER_DIAMETER);

/**
 * @Summary The negative of a single baseplate.
 * @param size [width, length] of a single baseplate.
 *             Only set if deviating from the standard!
 * @param height Height of the baseplate's hollow section.
                 Must be the same as or larger than BASEPLATE_HEIGHT.
 * @Details Use with `difference()`.
 */
module baseplate_cutter(size=BASEPLATE_DIMENSIONS, height=BASEPLATE_HEIGHT) {
    assert(
        is_list(size) &&
        len(size) == 2 &&
        size.x > BASEPLATE_OUTER_DIAMETER &&
        size.y > BASEPLATE_OUTER_DIAMETER,
        "baseplate_cutter: argument 'dimensions' less than BASEPLATE_OUTER_DIAMETER.");
    assert(height >= BASEPLATE_HEIGHT, "baseplate_cutter: height may not be less than BASEPLATE_HEIGHT");

    inner_dimensions = foreach_add(size, -BASEPLATE_OUTER_DIAMETER);

    //Cube's dimensions are set to ensure overlap with `sweep_rounded(...)`
    //without using `rounded_square(...)`.
    inner_size = baseplate_inner_size(size);
    cube_dimensions = [
            inner_size.x - BASEPLATE_INNER_RADIUS,
            inner_size.y - BASEPLATE_INNER_RADIUS,
            height
        ];
    union(){
        sweep_rounded(inner_dimensions){
            _baseplate_cutter_polygon(height);
        }

        translate([0, 0, height/2])
        cube(cube_dimensions, center = true);
    }
}

/**
 * @Summary A single baseplate.
 * @Details Example of how to use `baseplate_cutter()`
 * @param size [width, length] of a single baseplate.
 *             Only set if deviating from the standard!
 * @param height Height of the baseplate's hollow section.
                 Must be the same as or larger than BASEPLATE_HEIGHT.
 */
module single_baseplate(size=BASEPLATE_DIMENSIONS, height=BASEPLATE_HEIGHT) {
    difference() {
        linear_extrude(height)
        rounded_square(size,
            radius = BASEPLATE_OUTER_RADIUS, center=true);

        baseplate_cutter(size, height);
    }
}
