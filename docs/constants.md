# gridfinity-rebuilt-constants

This file contains dimensions that are critical to the constructiuon of the other models, but are not values that often need to be changed. Thus, they were outsourced to this file such that the rest of the files would retain parity. All values here have the same range, this is positive real numbers. Some can be zero, but that may result in strange or invalid geometry, 

Parameter | Description
--- | ------
h_base | height of the base
r_base| outside rounded radius of bin
r_c1 | lower base chamfer "radius"
r_c2 | upper base chamfer "radius"
h_bot| bottom thiccness of bin
r_fo1| outside radii 1
r_fo2| outside radii 2
r_fo3 | outside radii 3
r_hole1| screw hole radius
r_hole2| magnet hole radius
d_hole| center-to-center distance between holes
h_hole| magnet hole depth
h_slit| slit depth (printer layer height)
r_f1| top edge fillet radius
r_f2 | internal fillet radius
d_div | width of divider between compartments 
d_wall| minimum wall thickness
d_clear| tolerance fit factor 
d_tabh| height of tab (yaxis, measured from inner wall)  
d_tabw| maximum width of tab 
a_tab| angle of tab   
bp_h_bot| Baseplate bottom part height (part added with weigthed=true)
bp_cut_size| Baseplate bottom cutout rectangle size
bp_cut_depth| Baseplate bottom cutout rectangle depth
bp_rcut_width| Baseplate bottom cutout finger gap width
bp_rcut_length| Baseplate bottom cutout finger gap left
bp_rcut_depth| Baseplate bottom cutout finger gap depth
d_cs | countersink diameter for baseplate
r_skel| radius of cutout for skeletonized baseplate
r_cb| baseplate counterbore radius
h_cb| baseplate counterbore depth
h_skel | minimum baseplate thickness (when skeletonized)