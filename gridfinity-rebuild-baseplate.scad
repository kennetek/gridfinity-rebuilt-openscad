include <gridfinity-rebuilt-utility.scad>

// ===== Info ===== //
/*
 IMPORTANT: rendering will be better for analyzing the model if fast-csg is enabled. As of writing, this feature is only available in the development builds and not the official release of OpenSCAD, but it makes rendering only take a couple seconds, even for comically large bins. Enable it in Edit > Preferences > Features > fast-csg

https://github.com/kennetek/gridfinity-rebuilt-openscad

*/

/* [Setup Parameters] */
$fa = 8;
$fs = 0.25;

/* [General Settings] */
// number of bases along x-axis
gridx = 2;  
// number of bases along y-axis   
gridy = 2;  
// bin height. See bin height information and "gridz_define" below.  
gridz = 6;   
// base unit
length = 42;

/* [Base] */
style_hole = 1; // [0:no holes, 1:magnet holes only, 2: magnet and screw holes - no printable slit, 3: magnet and screw holes - printable slit, 4: magnet and countersunk screw holes]
// number of divisions per 1 unit of base along the X axis. (default 1, only use integers. 0 means automatically guess the right division)
div_base_x = 0;
// number of divisions per 1 unit of base along the Y axis. (default 1, only use integers. 0 means automatically guess the right division)
div_base_y = 0; 

/* [Togglles] */

// weigthed baseplate with possibility for magnet / screw holes
weigthed = true;

// cutout in the bottom for weigthed baseplate only
bottom_cutout = true;

// ===== Commands ===== //

color("tomato") {

    baseplate(gridx, gridy, length, div_base_x, div_base_y, style_hole, weigthed, bottom_cutout);

}