/**
 * @file gridfinity-rebuilt-holes.scad
 * @brief Functions to create different types of holes in an object.
 */

include <standard.scad>
use <generic-helpers.scad>

/**
 * @brief Make a magnet hole printable without suports.
 * @see https://www.youtube.com/watch?v=W8FbHTcB05w
 * @param screw_radius Radius of the screw hole.
 * @param magnet_radius Radius of the magnet hole.
 * @param magnet_depth Depth of the magnet hole.
 * @details This is the negative designed to be cut out of the magnet hole.
 *          Use it with `difference()`.
 */
module make_magnet_hole_printable(screw_radius, magnet_radius, magnet_depth) {
    copy_mirror([0,1,0]) {
        translate([-1.5*magnet_radius, screw_radius+0.1, magnet_depth - LAYER_HEIGHT])
        cube([magnet_radius*3, magnet_radius*3, 10]);
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
    assert(crush_ribs == false && chamfer == false, "crush_ribs and chamfer are not supported yet");

    screw_radius = SCREW_HOLE_RADIUS - (o/2);
    magnet_radius = MAGNET_HOLE_RADIUS - (o/2);
//    magnet_inner_radius =  // Not Implemented Yet
    screw_depth = h_base-o;
    // If using supportless / printable mode, need to add an additional layer, so it can be removed later
    magnet_depth = MAGNET_HOLE_DEPTH - o + (supportless ? LAYER_HEIGHT : 0);

    union() {
        if(refined_hole) {
            refined_hole();
        }

        if(magnet_hole) {
            difference() {
                if(crush_ribs) {
                    // Not Implemented Yet
                } else {
                    cylinder(h = magnet_depth, r=magnet_radius);
                }

                if(supportless) {
                    make_magnet_hole_printable(screw_radius, magnet_radius, magnet_depth);
                }
            }

            if(chamfer) {
                 // Not Implemented Yet
            }
        }

        if(screw_hole) {
            cylinder(h = screw_depth, r = screw_radius);
        }
    }
}

//$fa = 8;
//$fs = 0.25;
//block_base_hole(bundle_hole_options(
//    refined_hole=true,
//    magnet_hole=false,
//    screw_hole=false,
//    supportless=false,
//    crush_ribs=false,
//    chamfer=false
//));
