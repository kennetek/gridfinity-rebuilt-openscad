// ===== INFORMATION ===== //
/*
 IMPORTANT: rendering will be better in development builds and not the official release of OpenSCAD, but it makes rendering only take a couple seconds, even for comically large bins.

https://github.com/kennetek/gridfinity-rebuilt-openscad

*/

include <src/core/standard.scad>
use <src/core/gridfinity-rebuilt-utility.scad>
use <src/core/gridfinity-rebuilt-holes.scad>
use <src/core/base.scad>
use <src/helpers/generic-helpers.scad>
use <src/helpers/shapes.scad>

// ===== PARAMETERS ===== //

/* [Setup Parameters] */
$fa = 8;
$fs = 0.25;

/* [General Settings] */
// number of bases along x-axis
gridx = 3;
// number of bases along y-axis
gridy = 3;
// bin height. See bin height information and "gridz_define" below.
gridz = 6;
// Half grid sized bins.  Implies "only corners".
half_grid = false;

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
// scoop weight percentage. 0 disables scoop, 1 is regular scoop. Any real number will scale the scoop.
scoop = 0; //[0:0.1:1]

/* [Other] */
// determine what the variable "gridz" applies to based on your use case
gridz_define = 0; // [0:gridz is the height of bins in units of 7mm increments - Zack's method,1:gridz is the internal height in millimeters, 2:gridz is the overall external height of the bin in millimeters]
// the type of tabs
style_tab = 1; //[0:Full,1:Auto,2:Left,3:Center,4:Right,5:None]
// which divisions have tabs
place_tab = 1; // [0:Everywhere-Normal,1:Top-Left Division]

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
grid_dimensions = GRID_DIMENSIONS_MM / (half_grid ? 2 : 1);

// ===== IMPLEMENTATION ===== //

// Input all the cutter types in here
color("tomato")
render()
gridfinityLite(gridx, gridy, gridz, gridz_define, style_lip, enable_zsnap, grid_dimensions, hole_options, only_corners || half_grid) {
    cutEqual(n_divx = divx, n_divy = divy, style_tab = style_tab, scoop_weight = scoop, place_tab = place_tab);
}
// ===== CONSTRUCTION ===== //

module gridfinityLite(gridx, gridy, gridz, gridz_define, style_lip, enable_zsnap, grid_dimensions, style_hole, only_corners) {
    height_mm = height(gridz, gridz_define, style_lip, enable_zsnap);

    // Lower the bin start point by this amount.
    // Made up for in bin height.
    // Ensures divider walls smoothly transition to the bottom
    lower_by_mm = BASE_PROFILE_HEIGHT + bottom_layer;

    difference() {
        translate([0, 0, -lower_by_mm])
        gridfinityInit(gridx, gridy, height_mm+lower_by_mm, 0, grid_dimensions, sl=style_lip)
        children();

        // Underside of the base. Keep out zone.
        render()
        difference() {
            cube([gridx*grid_dimensions.x, gridy*grid_dimensions.y, BASE_PROFILE_HEIGHT*2], center=true);
            gridfinityBase([gridx, gridy], grid_dimensions, hole_options=style_hole, only_corners=only_corners);
        }
    }

    gridfinity_base_lite([gridx, gridy], grid_dimensions, d_wall, bottom_layer, hole_options=style_hole, only_corners=only_corners);
}
