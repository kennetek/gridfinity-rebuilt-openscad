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
// base unit
length = 42;

/* [Styles] */

// baseplate styles
style_plate = 2; // [0: thin, 1:weighted, 2:skeletonized]

// enable magnet hole
style_magnet = true; 

// hole styles
style_hole = 2; // [0:none, 1:contersink, 2:counterbore]


// ===== Commands ===== //

color("tomato") 
gridfinityBaseplate(gridx, gridy, length, style_plate, style_magnet, style_hole);

// Baseplate modules
module gridfinityBaseplate(gridx, gridy, length, sp, sm, sh) {
    
    off = (sp==0?0:sp==1?bp_h_bot:1+(sm?h_hole:0)+(sh==0?0:sh==1?d_cs:h_cb)); 

    difference() {
        translate([0,0,h_base])
        mirror([0,0,1])
        rounded_rectangle(gridx*length-0.5, gridy*length-0.5, h_base+off, r_base);
        
        gridfinityBase(gridx, gridy, length, 1, 1, 0, 0.5, false);
        
        translate([0,0,h_base-0.6])
        rounded_rectangle(gridx*length*2, gridy*length*2, h_base*2, r_base);
        
        pattern_linear(gridx, gridy, length) {
            if (sm)
            block_base_hole(1);

            if (sp == 1) {
                translate([0,0,-off])
                cutter_weight();
            } else if (sp == 2) {
                linear_extrude(10*(h_base+off), center = true)
                profile_skeleton();
            }
            
            if (sh == 1) {
                pattern_circular(4) 
                translate([d_hole/2, d_hole/2, 0]) {
                    cylinder(r = r_hole1+d_clear, h = 10*(h_base+off), center = true);
                    
                    translate([0,0,d_cs-off])
                    mirror([0,0,1])
                    hull() { 
                        cylinder(h = d_cs+10, r=r_hole1+d_clear);
                        translate([0,0,d_cs])
                        cylinder(h=d_cs+10, r=r_hole1+d_clear+d_cs);
                    }
                }
            } else if (sh == 2) {
                pattern_circular(4)
                translate([d_hole/2,d_hole/2,-off]) {
                    cylinder(h=10*(h_base+off), r=r_hole1+d_clear, center=true);
                    difference() {
                        cylinder(h = 2*(h_cb+0.2), r=r_cb, center=true);
                        copy_mirror([0,1,0])
                        translate([-1.5*r_cb,r_hole1+0.1,h_cb]) 
                        cube([r_cb*3,r_cb*3, 0.4]);
                    }
                }
            }
            
        }
    }       
}

module cutter_weight(){
    union() {
        linear_extrude(bp_cut_depth*2,center=true)
        square(bp_cut_size, center=true);
        pattern_circular(4)
        translate([0,10,0])
        linear_extrude(bp_rcut_depth*2,center=true)
        union() {
            square([bp_rcut_width, bp_rcut_length], center=true);
            translate([0,bp_rcut_length/2,0])
            circle(d=bp_rcut_width);
        }
    }
}

module profile_skeleton() {
    l = length-2*r_c2-2*r_c1; 
    minkowski() { 
        difference() {
            square([l-2*r_skel+2*d_clear,l-2*r_skel+2*d_clear], center = true);
            pattern_circular(4)
            translate([d_hole/2,d_hole/2,0])
            minkowski() {
                square([l,l]);
                circle(r_hole2+r_skel+2);
           } 
        }
        circle(r_skel);
    }
}