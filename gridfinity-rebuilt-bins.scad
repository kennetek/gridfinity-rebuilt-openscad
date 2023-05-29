include <gridfinity-rebuilt-utility.scad>

// ===== INFORMATION ===== //
/*
 IMPORTANT: rendering will be better for analyzing the model if fast-csg is enabled. As of writing, this feature is only available in the development builds and not the official release of OpenSCAD, but it makes rendering only take a couple seconds, even for comically large bins. Enable it in Edit > Preferences > Features > fast-csg
 the magnet holes can have an extra cut in them to make it easier to print without supports
 tabs will automatically be disabled when gridz is less than 3, as the tabs take up too much space
 base functions can be found in "gridfinity-rebuilt-utility.scad"
 examples at end of file

 BIN HEIGHT
 the original gridfinity bins had the overall height defined by 7mm increments
 a bin would be 7*u millimeters tall
 the lip at the top of the bin (3.8mm) added onto this height
 The stock bins have unit heights of 2, 3, and 6:
 Z unit 2 -> 7*2 + 3.8 -> 17.8mm
 Z unit 3 -> 7*3 + 3.8 -> 24.8mm
 Z unit 6 -> 7*6 + 3.8 -> 45.8mm

https://github.com/kennetek/gridfinity-rebuilt-openscad

*/

// ===== PARAMETERS ===== //

/* [Setup Parameters] */
$fa = 8;
$fs = 0.25;

/* [General Settings] */
// number of bases along x-axis
gridx = 5;  
// number of bases along y-axis   
gridy = 5;  
// bin height. See bin height information and "gridz_define" below.  
gridz = 6;   
// base unit
length = 42;

/* [Compartments] */
// number of X Divisions (set to zero to have solid bin)
divx = 1;
// number of y Divisions (set to zero to have solid bin)
divy = 1;

/* [Open ends (do not check both)] */
// Open top side of bin on x-axis
open_end_x_top = false;
// Open bottom side of bin on x-axis
open_end_x_bottom = false;
// Open top side of bin on y-axis
open_end_y_top = false;
// Open bottom side of bin on y-axis
open_end_y_bottom = false;

/* [Height] */
// determine what the variable "gridz" applies to based on your use case
gridz_define = 0; // [0:gridz is the height of bins in units of 7mm increments - Zack's method,1:gridz is the internal height in millimeters, 2:gridz is the overall external height of the bin in millimeters]
// overrides internal block height of bin (for solid containers). Leave zero for default height. Units: mm
height_internal = 0; 
// snap gridz height to nearest 7mm increment
enable_zsnap = false;

/* [Features] */
// the type of tabs
style_tab = 1; //[0:Full,1:Auto,2:Left,3:Center,4:Right,5:None]
// how should the top lip act
style_lip = 0; //[0: Regular lip, 1:remove lip subtractively, 2: remove lip and retain height]
// scoop weight percentage. 0 disables scoop, 1 is regular scoop. Any real number will scale the scoop. 
scoop = 1; //[0:0.1:1]
// only cut magnet/screw holes at the corners of the bin to save uneccesary print time
style_corners = false;

/* [Base] */
style_hole = 3; // [0:no holes, 1:magnet holes only, 2: magnet and screw holes - no printable slit, 3: magnet and screw holes - printable slit]
// number of divisions per 1 unit of base along the X axis. (default 1, only use integers. 0 means automatically guess the right division)
div_base_x = 0;
// number of divisions per 1 unit of base along the Y axis. (default 1, only use integers. 0 means automatically guess the right division)
div_base_y = 0; 


// ===== IMPLEMENTATION ===== //

color("tomato") {
    
    difference() {
        
        // Since we chop off the top and/or bottom of the bin, we need to add 1 or 2 to the gridx and gridy
        gridx = gridx + (open_end_x_top ? 1 : 0) + (open_end_x_bottom ? 1 : 0);
        gridy = gridy + (open_end_y_top ? 1 : 0) + (open_end_y_bottom ? 1 : 0);

        // Only translate off center if the bin is open on ONE side of the x axis
        // when both sides are open, the bin is still centered
        off_center_x = 
        
            open_end_x_top 
                ? open_end_x_bottom 
                    ? 0                       // both sides open 
                    : 0.5                     // only top open
                : open_end_x_bottom 
                    ? -0.5                    // only bottom open
                    : 0;                      // both sides closed

        // Only translate off center if the bin is open on ONE side of the y axis
        // when both sides are open, the bin is still centered
        off_center_y = 
        
            open_end_y_top 
                ? open_end_y_bottom 
                    ? 0                       // both sides open 
                    : 0.5                     // only top open
                : open_end_y_bottom 
                    ? -0.5                    // only bottom open
                    : 0;                      // both sides closed


        // Only translate off center if the bin is open on ONE side of the y axis
        translate([ off_center_x * length, off_center_y * length, 0])

            union() {
                
                gridfinityInit(gridx, gridy, height(gridz, gridz_define, style_lip, enable_zsnap), height_internal, length) {

                    if (divx > 0 && divy > 0)
                    cutEqual(n_divx = divx, n_divy = divy, style_tab = style_tab, scoop_weight = scoop);
                }
                gridfinityBase(gridx, gridy, length, div_base_x, div_base_y, style_hole*(style_corners?p_corn:1));
            }


            largest_grid_side = max(gridx, gridy);


            // OPEN SIDES ON X AXIS ////////////////////////////
            x_offset = open_end_x_top && open_end_x_bottom 
                ? (gridx/2 -1) * length               // both sides open
                : length/2 + (gridx/2 -1) * length;   // only one side open


            if (open_end_x_top)
                translate([x_offset, -((largest_grid_side * length)/2), -10])
                    cube([length, largest_grid_side * length, 20 + height(gridz, gridz_define, style_lip, enable_zsnap)]);

            if (open_end_x_bottom)
                // We need to do -length because the x axis is flipped and we need to subtract the cube thickness
                translate([-x_offset - length, -((largest_grid_side * length)/2), -10])
                    cube([length, largest_grid_side * length, 20 + height(gridz, gridz_define, style_lip, enable_zsnap)]);


            // OPEN SIDES ON Y AXIS ////////////////////////////
            y_offset = open_end_y_top && open_end_y_bottom 
                ? (gridy/2 -1) * length               // both sides open
                : length/2 + (gridy/2 -1) * length;   // only one side open

            if (open_end_y_top)
                translate([-((largest_grid_side * length)/2), y_offset, -10])
                    cube([largest_grid_side * length, length, 20 + height(gridz, gridz_define, style_lip, enable_zsnap)]);

            if (open_end_y_bottom)
                // We need to do -length because the y axis is flipped and we need to subtract the cube thickness
                translate([-((largest_grid_side * length)/2), -y_offset - length, -10])
                    cube([largest_grid_side * length, length, 20 + height(gridz, gridz_define, style_lip, enable_zsnap)]);

    }

}


// ===== EXAMPLES ===== //

// 3x3 even spaced grid
/*
gridfinityInit(3, 3, height(6), 0, 42) {
	cutEqual(n_divx = 3, n_divy = 3, style_tab = 0, scoop_weight = 0);
}
gridfinityBase(3, 3, 42, 0, 0, 1);
*/

// Compartments can be placed anywhere (this includes non-integer positions like 1/2 or 1/3). The grid is defined as (0,0) being the bottom left corner of the bin, with each unit being 1 base long. Each cut() module is a compartment, with the first four values defining the area that should be made into a compartment (X coord, Y coord, width, and height). These values should all be positive. t is the tab style of the compartment (0:full, 1:auto, 2:left, 3:center, 4:right, 5:none). s is a toggle for the bottom scoop. 
/*
gridfinityInit(3, 3, height(6), 0, 42) {
    cut(x=0, y=0, w=1.5, h=0.5, t=5, s=0);
    cut(0, 0.5, 1.5, 0.5, 5, 0);
    cut(0, 1, 1.5, 0.5, 5, 0);
    
    cut(0,1.5,0.5,1.5,5,0);
    cut(0.5,1.5,0.5,1.5,5,0);
    cut(1,1.5,0.5,1.5,5,0);
    
    cut(1.5, 0, 1.5, 5/3, 2);
    cut(1.5, 5/3, 1.5, 4/3, 4);
}
gridfinityBase(3, 3, 42, 0, 0, 1);
*/

// Compartments can overlap! This allows for weirdly shaped compartments, such as this "2" bin. 
/*
gridfinityInit(3, 3, height(6), 0, 42)  {
    cut(0,2,2,1,5,0);
    cut(1,0,1,3,5);
    cut(1,0,2,1,5);
    cut(0,0,1,2);
    cut(2,1,1,2);
}
gridfinityBase(3, 3, 42, 0, 0, 1);
*/

// Areas without a compartment are solid material, where you can put your own cutout shapes. using the cut_move() function, you can select an area, and any child shapes will be moved from the origin to the center of that area, and subtracted from the block. For example, a pattern of three cylinderical holes.
/*
gridfinityInit(3, 3, height(6), 0, 42) {
    cut(x=0, y=0, w=2, h=3);
    cut(x=0, y=0, w=3, h=1, t=5);
    cut_move(x=2, y=1, w=1, h=2) 
        pattern_linear(x=1, y=3, sx=42/2) 
            cylinder(r=5, h=1000, center=true);
}
gridfinityBase(3, 3, 42, 0, 0, 1);
*/

// You can use loops as well as the bin dimensions to make different parametric functions, such as this one, which divides the box into columns, with a small 1x1 top compartment and a long vertical compartment below
/*
gx = 3;
gy = 3;
gridfinityInit(gx, gy, height(6), 0, 42) {
    for(i=[0:gx-1]) {
        cut(i,0,1,gx-1);
        cut(i,gx-1,1,1);
    }
}
gridfinityBase(gx, gy, 42, 0, 0, 1);
*/

// Pyramid scheme bin
/*
gx = 4.5;
gy = 4;
gridfinityInit(gx, gy, height(6), 0, 42) {
    for (i = [0:gx-1]) 
    for (j = [0:i])
    cut(j*gx/(i+1),gy-i-1,gx/(i+1),1,0);
}
gridfinityBase(gx, gy, 42, 0, 0, 1);
*/