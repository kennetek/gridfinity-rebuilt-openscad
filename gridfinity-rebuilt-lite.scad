include <gridfinity-rebuilt-utility.scad>

// ===== INFORMATION ===== //
/*
 IMPORTANT: rendering will be better for analyzing the model if fast-csg is enabled. As of writing, this feature is only available in the development builds and not the official release of OpenSCAD, but it makes rendering only take a couple seconds, even for comically large bins. Enable it in Edit > Preferences > Features > fast-csg

https://github.com/kennetek/gridfinity-rebuilt-openscad

*/

// ===== PARAMETERS ===== //

/* [Setup Parameters] */
$fa = 8;
$fs = 0.25;

/* [General Settings] */
// number of bases along x-axis
gridx = 3; //.5
// number of bases along y-axis
gridy = 3; //.5
// bin height. See bin height information and "gridz_define" below.
gridz = 6;

/* [Compartments] */
// number of X Divisions
divx = 2;
// number of y Divisions
divy = 2;

/* [Toggles] */
// snap gridz height to nearest 7mm increment
enable_zsnap = false;
// how should the top lip act
style_lip = 0; //[0: Regular lip, 1:remove lip subtractively, 2: remove lip and retain height]

/* [Other] */
// determine what the variable "gridz" applies to based on your use case
gridz_define = 0; // [0:gridz is the height of bins in units of 7mm increments - Zack's method,1:gridz is the internal height in millimeters, 2:gridz is the overall external height of the bin in millimeters]
// the type of tabs
style_tab = 1; //[0:Full,1:Auto,2:Left,3:Center,4:Right,5:None]

/* [Base] */
// thickness of bottom layer
bottom_layer = 1;

/* [Base Hole Options] */
// only cut magnet/screw holes at the corners of the bin to save uneccesary print time
only_corners = false;
//Use gridfinity refined hole style. Not compatible with magnet_holes!
refined_holes = false;
// Base will have holes for 6mm Diameter x 2mm high magnets.
magnet_holes = true;
// Base will have holes for M3 screws.
screw_holes = true;
// Magnet holes will have crush ribs to hold the magnet.
crush_ribs = true;
// Magnet/Screw holes will have a chamfer to ease insertion.
chamfer_holes = true;
// Magnet/Screw holes will be printed so supports are not needed.
printable_hole_top = true;

hole_options = bundle_hole_options(refined_holes, magnet_holes, screw_holes, crush_ribs, chamfer_holes, printable_hole_top);

// ===== IMPLEMENTATION ===== //

// Input all the cutter types in here
color("tomato")
gridfinityLite(gridx, gridy, gridz, gridz_define, style_lip, enable_zsnap, l_grid, hole_options, only_corners) {
    cutEqual(n_divx = divx, n_divy = divy, style_tab = style_tab, scoop_weight = 0);
}

// ===== CONSTRUCTION ===== //

module gridfinityLite(gridx, gridy, gridz, gridz_define, style_lip, enable_zsnap, length, style_hole, only_corners) {
    height_mm = height(gridz, gridz_define, style_lip, enable_zsnap);
    union() {
        difference() {
            union() {
                gridfinityInit(gridx, gridy, height_mm, 0, length, sl=style_lip)
                children();
                gridfinityBase([gridx, gridy], [length, length], hole_options=style_hole, only_corners=only_corners);
            }

            difference() {
                union() {
                    intersection() {
                        difference() {
                            gridfinityBase([gridx, gridy], [length, length], hole_options=style_hole, -d_wall*2, false, only_corners=only_corners);
                            translate([-gridx*length/2,-gridy*length/2,2*h_base])
                            cube([gridx*length,gridy*length,1000]);
                        }
                        translate([0,0,-1])
                        rounded_rectangle(gridx*length-0.5005-d_wall*2, gridy*length-0.5005-d_wall*2, 1000, r_f2);
                        translate([0,0,bottom_layer])
                        rounded_rectangle(gridx*1000, gridy*1000, 1000, r_f2);
                    }
                    translate([0,0,h_base+d_clear])
                    rounded_rectangle(gridx*length-0.5005-d_wall*2, gridy*length-0.5005-d_wall*2, h_base, r_f2);
                }

                translate([0,0,-4*h_base])
                gridfinityInit(gridx, gridy, height(20,0), 0, length, sl=style_lip)
                children();
            }

        }
        difference() {
            translate([0,0,-1.6])
                difference() {
                    difference() {
                        union() {

                            gridfinityInit(gridx, gridy, height_mm, 0, length, sl=style_lip)
                            children();
                        }

                        difference() {

                                intersection() {
                                    difference() {
                                        gridfinityBase([gridx, gridy], [length, length], hole_options=style_hole, -d_wall*2, false, only_corners=only_corners);
                                        translate([-gridx*length/2,-gridy*length/2,2*h_base])
                                        cube([gridx*length,gridy*length,1000]);
                                    }
                                    translate([0,0,-1])
                                    rounded_rectangle(gridx*length-0.5005-d_wall*2, gridy*length-0.5005-d_wall*2, 1000, r_f2);
                                    translate([0,0,bottom_layer])
                                    rounded_rectangle(gridx*1000, gridy*1000, 1000, r_f2);
                                }


                            translate([0,0,-4*h_base])
                            gridfinityInit(gridx, gridy, height(20,0), 0, length, sl=style_lip)
                            children();
                        }

                    }
                    translate([0,0,9])
                    rounded_rectangle(gridx*1000, gridy*1000, gridz*1000, gridz);
                }
                    translate([0,0,0])
                    rounded_rectangle(gridx*1000, gridy*1000, 5, r_f2);
            }

    }
}
