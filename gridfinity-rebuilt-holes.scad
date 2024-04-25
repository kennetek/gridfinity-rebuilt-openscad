/**
 * @file gridfinity-rebuilt-holes.scad
 * @brief Functions to create different types of holes in an object.
 */

include <standard.scad>
use <generic-helpers.scad>

/**
 * @brief Wave generation function for wrapping a circle.
 * @param t An angle of the circle.  Between 0 and 360 degrees.
 * @param count The number of **full** waves in a 360 degree circle.
 * @param range **Half** the difference between minimum and maximum values.
 * @param vertical_offset A simple offset.
 * @details
 *    If plotted on an x/y graph this produces a standard sin wave.
 *    Range only seems weird because it describes half a wave.
 *    Mapped by doing [sin(t), cost(t)] * wave_function(...).
 *    When wrapping a circle:
 *      Final Outer radius is (wave_vertical_offset + wave_range).
 *      Final Inner radius is (wave_vertical_offset - wave_range).
 */
function wave_function(t, count, range, vertical_offset) =
    (sin(t * count) * range) + vertical_offset;

/**
 * @brief A circle with crush ribs to give a tighter press fit.
 * @details Extrude and use as a negative modifier.
 *          Idea based on Slant3D's video at 5:20 https://youtu.be/Bd7Yyn61XWQ?t=320
 *          Implementaiton is completely different.
 *          Important: Lower ribs numbers just result in a deformed circle.
 * @param outer_radius Final outer radius.
 * @param inner_radius Final inner radius.
 * @param ribs Number of crush ribs the circle has.
**/
module ribbed_circle(outer_radius, inner_radius, ribs) {
    assert(outer_radius > 0, "outer_radius must be positive");
    assert(inner_radius > 0, "inner_radius must be positive");
    assert(ribs > 0, "ribs must be positive");
    assert(outer_radius > inner_radius, "outer_radius must be larger than inner_radius");

    wave_range = (outer_radius - inner_radius) / 2;
    wave_vertical_offset = inner_radius + wave_range;

    // Circe with a wave wrapped around it
    wrapped_circle = [ for (i = [0:360])
        [sin(i), cos(i)] * wave_function(i, ribs, wave_range, wave_vertical_offset)
    ];

    polygon(wrapped_circle);
}


/**
 * @brief A cylinder with crush ribs to give a tighter press fit.
 * @details To be used as the negative for a hole.
 * @see ribbed_circle
 * @param outer_radius Outer Radius of the crush ribs.
 * @param inner_radius Inner Radius of the crush ribs.
 * @param height Cylinder's height.
 * @param ribs Number of crush ribs.
 */
module ribbed_cylinder(outer_radius, inner_radius, height, ribs) {
    assert(height > 0, "height must be positive");
    linear_extrude(height)
    ribbed_circle(
        outer_radius,
        inner_radius,
        ribs
    );
}


/**
 * @brief Make a hole printable without suports.
 * @see https://www.youtube.com/watch?v=W8FbHTcB05w
 * @param inner_radius Radius of the inner hole.
 * @param outer_radius Radius of the outer hole.
 * @param outer_depth Depth of the magnet hole.
 * @details This is the negative designed to be cut out of the magnet hole.
 *          Use it with `difference()`.
 */
module make_hole_printable(inner_radius, outer_radius, outer_depth) {
    assert(inner_radius > 0, "inner_radius must be positive");
    assert(outer_radius > 0, "outer_radius must be positive");
    assert(outer_depth > 2*LAYER_HEIGHT, str("outer_depth must be at least ", 2*LAYER_HEIGHT));
    tollerance = 0.001;  // To make sure the top layer is fully removed

    translation_matrix = affine_translate([
        -outer_radius,
        inner_radius,
        outer_depth - 2*LAYER_HEIGHT
    ]);
    second_translation_matrix = translation_matrix * affine_translate([0, 0, LAYER_HEIGHT]);

    cube_dimensions = [
        outer_radius*2,
        outer_radius - inner_radius,
        LAYER_HEIGHT + tollerance
    ];

    union(){
        union() {
            multmatrix(translation_matrix)
            cube(cube_dimensions);
            multmatrix(affine_rotate([0, 0, 180]) * translation_matrix)
            cube(cube_dimensions);
        }
        // 2nd level
        union() {
            multmatrix(second_translation_matrix)
            cube(cube_dimensions);
            multmatrix(affine_rotate([0, 0, 90]) * second_translation_matrix)
            cube(cube_dimensions);
            multmatrix(affine_rotate([0, 0, 180]) * second_translation_matrix)
            cube(cube_dimensions);
            multmatrix(affine_rotate([0, 0, 270]) * second_translation_matrix)
            cube(cube_dimensions);
        }
    }
}

/**
* @brief Refined hole based on Printables @grizzie17's Gridfinity Refined
* @details Magnet is pushed in from +X direction, and held in by friction.
*          Small slit on the bottom allows removing the magnet.
* @see https://www.printables.com/model/413761-gridfinity-refined
*/
module refined_hole() {
    refined_offset = LAYER_HEIGHT * REFINED_HOLE_BOTTOM_LAYERS;

    // Poke through - For removing a magnet using a toothpick
    ptl = refined_offset + LAYER_HEIGHT; // Additional layer just in case
    poke_through_height = REFINED_HOLE_HEIGHT + ptl;
    poke_hole_radius = 2.5;
    magic_constant = 5.60;
    poke_hole_center = [-12.53 + magic_constant, 0, -ptl];

    translate([0, 0, refined_offset])
    union() {
        // Magnet hole
        translate([0, -REFINED_HOLE_RADIUS, 0])
        cube([11, REFINED_HOLE_RADIUS*2, REFINED_HOLE_HEIGHT]);
        cylinder(REFINED_HOLE_HEIGHT, r=REFINED_HOLE_RADIUS);

        // Poke hole
        translate([poke_hole_center.x, -poke_hole_radius/2, poke_hole_center.z])
        cube([10 - magic_constant, poke_hole_radius, poke_through_height]);
        translate(poke_hole_center)
        cylinder(poke_through_height, d=poke_hole_radius);
    }
}

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
 * @brief Create an options list used to configure bin holes.
 * @param refined_hole Use gridfinity refined hole type.  Not compatible with "magnet_hole".
 * @param magnet_hole Create a hole for a 6mm magnet.
 * @param screw_hole Create a hole for a M3 screw.
 * @param crush_ribs If the magnet hole should have crush ribs for a press fit.
 * @param chamfer Add a chamfer to the magnet hole.
 * @param supportless If the magnet hole should be printed in such a way that the screw hole does not require supports.
 */
function bundle_hole_options(refined_hole=true, magnet_hole=false, screw_hole=false, crush_ribs=false, chamfer=false, supportless=false) =
    [refined_hole, magnet_hole, screw_hole, crush_ribs, chamfer, supportless];

/**
 * @brief A single magnet/screw hole.  To be cut out of the base.
 * @details Supports multiple options that can be mixed and matched.
 * @pram hole_options @see bundle_hole_options
 * @param o Offset
 */
module block_base_hole(hole_options, o=0) {
    // Destructure the options
    refined_hole = hole_options[0];
    magnet_hole = hole_options[1];
    screw_hole = hole_options[2];
    crush_ribs = hole_options[3];
    chamfer = hole_options[4];
    supportless = hole_options[5];

    // Validate said options
    if(refined_hole) {
        assert(!magnet_hole, "magnet_hole is not compatible with refined_hole");
    }

    screw_radius = SCREW_HOLE_RADIUS - (o/2);
    magnet_radius = MAGNET_HOLE_RADIUS - (o/2);
    magnet_inner_radius = MAGNET_HOLE_CRUSH_RIB_INNER_RADIUS - (o/2);
    screw_depth = h_base-o;
    // If using supportless / printable mode, need to add two additional layers, so they can be removed later.
    supportless_additional_depth = 2* LAYER_HEIGHT;
    magnet_depth = MAGNET_HOLE_DEPTH - o +
        (supportless ? supportless_additional_depth : 0);

    union() {
        if(refined_hole) {
            refined_hole();
        }

        if(magnet_hole) {
            difference() {
                if(crush_ribs) {
                    ribbed_cylinder(magnet_radius, magnet_inner_radius, magnet_depth, MAGNET_HOLE_CRUSH_RIB_COUNT);
                } else {
                    cylinder(h = magnet_depth, r=magnet_radius);
                }

                if(supportless) {
                    make_hole_printable(screw_radius, magnet_radius, magnet_depth);
                }
            }

            if(chamfer) {
                 cone(magnet_radius + MAGNET_HOLE_CHAMFER_ADDITIONAL_RADIUS, MAGNET_HOLE_CHAMFER_ANGLE, magnet_depth);
            }
        }

        if(screw_hole) {
            difference() {
                cylinder(h = screw_depth, r = screw_radius);
                if(supportless) {
                    rotate([0, 0, 90])
                    make_hole_printable(screw_radius/2, screw_radius, screw_depth);
                }
            }
        }
    }
}

//$fa = 8;
//$fs = 0.25;
//block_base_hole(bundle_hole_options(
//    refined_hole=false,
//    magnet_hole=true,
//    screw_hole=true,
//    supportless=true,
//    crush_ribs=true,
//    chamfer=true
//));
