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
    poke_through_height = REFINED_HOLE_HEIGHT+ptl; // Poke Through Height
    poke_hole_radius = 2.5; // Poke Through Radius
    magic_constant = 5.60;
    poke_hole_center = [-12.53 + magic_constant, 0, -ptl];

    union() {
        hull() {
            // Magnet hole - smaller than the magnet to keep it squeezed
            translate([10, -REFINED_HOLE_RADIUS, 0]) cube([1, REFINED_HOLE_RADIUS*2, REFINED_HOLE_HEIGHT]);
            cylinder(1.9, r=REFINED_HOLE_RADIUS);
        }
        hull() {
            // Poke hole
            translate([-9+magic_constant, -poke_hole_radius/2, -ptl]) cube([1, poke_hole_radius, poke_through_height]);
            translate(poke_hole_center) cylinder(poke_through_height, d=poke_hole_radius);
        }
    }
}

module block_base_hole(style_hole, o=0) {
    r1 = SCREW_HOLE_RADIUS-o/2;
    r2 = MAGNET_HOLE_RADIUS-o/2;
    union() {
        difference() {
            cylinder(h = 2*(MAGNET_HOLE_DEPTH-o+(style_hole==3?h_slit:0)), r=r2, center=true);

            if (style_hole==3)
            copy_mirror([0,1,0])
            translate([-1.5*r2,r1+0.1,MAGNET_HOLE_DEPTH-o])
            cube([r2*3,r2*3, 10]);
        }
        if (style_hole > 1)
        cylinder(h = 2*h_base-o, r = r1, center=true);
    }
}

//$fa = 8;
//$fs = 0.25;
//block_base_hole(0);
//refined_hole();
