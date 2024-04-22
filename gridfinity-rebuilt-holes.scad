/**
 * @file gridfinity-rebuilt-holes.scad
 * @brief Functions to create different types of holes in an object.
 */

include <standard.scad>
use <generic-helpers.scad>

module refined_hole() {
    /**
     * Refined hole based on Printables @grizzie17's Gridfinity Refined
     * https://www.printables.com/model/413761-gridfinity-refined
     */

    // Meassured magnet hole diameter to be 5.86mm (meassured in fusion360
    r = r_hole2-0.32;

    // Magnet height
    m = 2;
    mh = m-0.1;

    // Poke through - For removing a magnet using a toothpick
    ptl = h_slit*3; // Poke Through Layers
    pth = mh+ptl; // Poke Through Height
    ptr = 2.5; // Poke Through Radius

    union() {
        hull() {
            // Magnet hole - smaller than the magnet to keep it squeezed
            translate([10, -r, 0]) cube([1, r*2, mh]);
            cylinder(1.9, r=r);
        }
        hull() {
            // Poke hole
            translate([-9+5.60, -ptr/2, -ptl]) cube([1, ptr, pth]);
            translate([-12.53+5.60, 0, -ptl]) cylinder(pth, d=ptr);
        }
    }
}

module block_base_hole(style_hole, o=0) {
    r1 = r_hole1-o/2;
    r2 = r_hole2-o/2;
    union() {
        difference() {
            cylinder(h = 2*(h_hole-o+(style_hole==3?h_slit:0)), r=r2, center=true);

            if (style_hole==3)
            copy_mirror([0,1,0])
            translate([-1.5*r2,r1+0.1,h_hole-o])
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
