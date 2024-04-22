/**
 * @file gridfinity-rebuilt-holes.scad
 * @brief Functions to create different types of holes in an object.
 */

include <standard.scad>
use <generic-helpers.scad>

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
 * @brief A single magnet/screw hole.  To be cut out of the base.
 * @pram style_hole Determines the type of hole that will be generated.
 * @param o Offset
 * @details
 *      - 0: No holes. Does nothing.
 *      - 1: Magnet holes only
 *      - 2: Magnet and screw holes - no printable slit.
 *      - 3: Magnet and screw holes - printable slit.
 *      - 4: Gridfinity Refined hole - no glue needed.
 */
module block_base_hole(style_hole, o=0) {
    assert(style_hole >= 0 && style_hole <= 4, "Unhandled Hole Style");

    refined_hole = style_hole == 4;
    magnet_hole = style_hole == 1 || style_hole == 2 || style_hole == 3;
    screw_hole = style_hole == 2 || style_hole == 3;
    crush_ribs = false; // Not Implemented Yet
    chamfer = false;  // Not Implemented Yet
    supportless = style_hole==3;

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
                if(crush_ribs){
                    // Not Implemented Yet
                } else {
                    cylinder(h = magnet_depth, r=magnet_radius);
                }

                if(supportless) {
                    copy_mirror([0,1,0])
                    translate([-1.5*magnet_radius, screw_radius+0.1,magnet_depth])
                    cube([magnet_radius*3,magnet_radius*3, 10]);
                }
                if(chamfer) {
                    // Not Implemented Yet
                }
            }
        }

        if(screw_hole) {
            cylinder(h = screw_depth, r = screw_radius);
        }
    }
}

//$fa = 8;
//$fs = 0.25;
//block_base_hole(4);
