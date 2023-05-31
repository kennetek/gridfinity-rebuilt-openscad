
// height of the base
h_base = 5;     
// outside rounded radius of bin
r_base = 4;     
// lower base chamfer "radius"
r_c1 = 0.8;     
// upper base chamfer "radius"
r_c2 = 2.4;     
// bottom thiccness of bin
h_bot = 2.2;    
// outside radii 1
r_fo1 = 8.5;    
// outside radii 2
r_fo2 = 3.2;
// outside radii 3
r_fo3 = 1.6; 
// length of a grid unit
l_grid = 42;

// screw hole radius
r_hole1 = 1.5;  
// magnet hole radius
r_hole2 = 3.25; 
// center-to-center distance between holes
d_hole = 26;  
// distance of hole from side of bin
d_hole_from_side=8;
// magnet hole depth
h_hole = 2.4;   
// slit depth (printer layer height)
h_slit = 0.2; 

// top edge fillet radius
r_f1 = 0.6;     
// internal fillet radius
r_f2 = 2.8;     

// width of divider between compartments
d_div = 1.2;    
// minimum wall thickness
d_wall = 0.95;  
// tolerance fit factor 
d_clear = 0.25; 

// height of tab (yaxis, measured from inner wall)
d_tabh = 15.85;    
// maximum width of tab 
d_tabw = 42; 
// angle of tab   
a_tab = 36; 
// lip height
h_lip = 3.548;

d_wall2 = r_base-r_c1-d_clear*sqrt(2);
d_magic = -2*d_clear-2*d_wall+d_div; 

// Baseplate constants

// Baseplate bottom part height (part added with weigthed=true)
bp_h_bot = 6.4;
// Baseplate bottom cutout rectangle size
bp_cut_size = 21.4;
// Baseplate bottom cutout rectangle depth
bp_cut_depth = 4;
// Baseplate bottom cutout rounded thingy width
bp_rcut_width = 8.5;
// Baseplate bottom cutout rounded thingy left
bp_rcut_length = 4.25;
// Baseplate bottom cutout rounded thingy depth
bp_rcut_depth = 2;
// countersink diameter for baseplate
d_cs = 2.5; 
// radius of cutout for skeletonized baseplate
r_skel = 2; 
// baseplate counterbore radius
r_cb = 2.75;
// baseplate counterbore depth
h_cb = 3;
// minimum baseplate thickness (when skeletonized)
h_skel = 1; 