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
gridx = 5;  
// number of bases along y-axis   
gridy = 5;  
// base unit
length = 42;

/* [Screw Together Settings - Defaults work for M3 and 4-40] */
// screw diameter
d_screw = 3.35;
// screw head diameter
d_screw_head = 5;
// screw spacing distance
screw_spacing = .5;
// number of screws per grid block
n_screws = 1; // [1:3]


/* [Fit to Drawer] */
// minimum length of baseplate along x (leave zero to ignore, will automatically fill area if gridx is zero)
distancex = 0;
// minimum length of baseplate along y (leave zero to ignore, will automatically fill area if gridy is zero)
distancey = 0;

// where to align extra space along x
fitx = 0; // [-1:0.1:1]
// where to align extra space along y
fity = 0; // [-1:0.1:1]


/* [Styles] */

// baseplate styles
style_plate = 0; // [0: thin, 1:weighted, 2:skeletonized, 3: screw together, 4: screw together minimal]

// enable magnet hole
enable_magnet = true; 

// hole styles
style_hole = 2; // [0:none, 1:contersink, 2:counterbore]


// ===== IMPLEMENTATION ===== //
screw_together = (style_plate == 3 || style_plate == 4);

color("tomato") 
gridfinityBaseplate(gridx, gridy, length, distancex, distancey, style_plate, enable_magnet, style_hole, fitx, fity);


// ===== CONSTRUCTION ===== //

module gridfinityBaseplate(gridx, gridy, length, dix, diy, sp, sm, sh, fitx, fity) {
    
    assert(gridx > 0 || dix > 0, "Must have positive x grid amount!");
    assert(gridy > 0 || diy > 0, "Must have positive y grid amount!");

    gx = gridx == 0 ? floor(dix/length) : gridx; 
    gy = gridy == 0 ? floor(diy/length) : gridy; 
    dx = max(gx*length-0.5, dix);
    dy = max(gy*length-0.5, diy);

    off = calculate_off(sp, sm, sh);

    offsetx = dix < dx ? 0 : (gx*length-0.5-dix)/2*fitx*-1;
    offsety = diy < dy ? 0 : (gy*length-0.5-diy)/2*fity*-1;
    
    difference() {
        translate([offsetx,offsety,h_base])
        mirror([0,0,1])
        rounded_rectangle(dx, dy, h_base+off, r_base);
        
        gridfinityBase(gx, gy, length, 1, 1, 0, 0.5, false);
        
        translate([offsetx,offsety,h_base-0.6])
        rounded_rectangle(dx*2, dy*2, h_base*2, r_base);
        
        pattern_linear(gx, gy, length) {
            render(convexity = 6) {
                if (sm) block_base_hole(1);

                if (sp == 1)
                    translate([0,0,-off])
                    cutter_weight();
                else if (sp == 2 || sp == 3) 
                    linear_extrude(10*(h_base+off), center = true)
                    profile_skeleton();
                else if (sp == 4) 
                    translate([0,0,-5*(h_base+off)])
                    rounded_square(length-2*r_c2-2*r_c1, 10*(h_base+off), r_fo3);


                hole_pattern(){
                    if (sm) block_base_hole(1);

                    translate([0,0,-off])
                    if (sh == 1) cutter_countersink();
                    else if (sh == 2) cutter_counterbore();
                }
            }
        }
        if (sp == 3 || sp ==4) cutter_screw_together(gx, gy, off);    
    }

}

function calculate_off(sp, sm, sh) = 
    screw_together
        ? 6.75
        :sp==0
            ?0
            : sp==1
                ?bp_h_bot
                :h_skel + (sm
                    ?h_hole
                    : 0)+(sh==0
                        ? d_screw
                        : sh==1
                            ?d_cs
                            :h_cb);

module cutter_weight() {
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
module hole_pattern(){
    pattern_circular(4)
    translate([d_hole/2, d_hole/2, 0]) {
        render();
        children();
    }
}

module cutter_countersink(){
    cylinder(r = r_hole1+d_clear, h = 100*h_base, center = true);     
    translate([0,0,d_cs])
    mirror([0,0,1])
    hull() { 
        cylinder(h = d_cs+10, r=r_hole1+d_clear);
        translate([0,0,d_cs])
        cylinder(h=d_cs+10, r=r_hole1+d_clear+d_cs);
    }
}

module cutter_counterbore(){
    cylinder(h=100*h_base, r=r_hole1+d_clear, center=true);
    difference() {
        cylinder(h = 2*(h_cb+0.2), r=r_cb, center=true);
        copy_mirror([0,1,0])
        translate([-1.5*r_cb,r_hole1+d_clear+0.1,h_cb-h_slit]) 
        cube([r_cb*3,r_cb*3, 10]);
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

module cutter_screw_together(gx, gy, off) {

    screw(gx, gy);
    rotate([0,0,90])
    screw(gy, gx);
    
    module screw(a, b) {
        copy_mirror([1,0,0])
        translate([a*length/2, 0, -off/2])
        pattern_linear(1, b, 1, length)
        pattern_linear(1, n_screws, 1, d_screw_head + screw_spacing)
        rotate([0,90,0])
        cylinder(h=length/2, d=d_screw, center = true);
    }
}
