$fa = 8;
$fs = 0.25;

// number of bases along x-axis
gridx = 5; 

// number of bases along y-axis     
gridy = 3;      

// unit height along z-axis (2, 3, or 6, but can be any)
gridz = 6;

// number of x compartments (ideally, coprime w/ gridx)   
n_divx = 5;     

// number of y compartments (ideally, coprime w/ gridy) 
n_divy = 2;     
// set n_div values to 0 for a solid bin (for custom bins)                

// base unit (if you want to go rogue ig)
length = 42;    

// type of tab. alignment only matters if tabs are large enough
// tab style. 0:full, 1:automatic, 2:left, 3:center, 4:right, 5:none
style_tab = 1; 

// the rounded edge that allows for easy removal
enable_scoop    = true; 

// holes on the base for magnet / screw
enable_holes    = true; 

// extra cut within holes for better slicing
enable_hole_slit = true; 

// ===== Info =====

// rendering will be better for analyzing the model if fast-csg is enabled. This feature is only available in the nightly build and not the official release of OpenSCAD, but if makes rendering only take a couple seconds. Enable it in Edit > Preferences > Features > fast-csg
// the plane that is the top of the internal bin solid is d_height+h_base above z=0
// the magnet holes have an extra cut in them to make it easier to print without supports
// tabs will automatically be disabled when gridz is less than 3, as the tabs take up too much space

// ===== Dimensions =====

h_base = 5;     // height of the base
r_base = 4;     // outside rounded radius of bin
r_c1 = 0.8;     // lower base chamfer "radius"
r_c2 = 2.4;     // upper base chamfer "radius"
h_bot = 2.2;    // bottom thiccness of bin
r_fo1 = 7.5;    // outside radii
r_fo2 = 3.2;
r_fo3 = 1.6; 

r_hole1 = 1.5;  // screw hole radius
r_hole2 = 3.25; // magnet hole radius
d_hole = 26;    // center-to-center distance between holes
h_hole = 2.4;   // magnet hole depth

r_f1 = 0.6;     // top edge fillet radius
r_f2 = 1.5;     // internal fillet radius
r_f3 = 0.6;     // lip fillet radius

d_div = 1.2;    // width of divider between compartments
d_wall = 0.95;   // minimum wall thickness
d_clear = 0.25; // tolerance fit factor

d_tabh = 15.85;   // height of tab (yaxis, measured from inner wall)
d_tabw = length; // maximum width of tab
a_tab = 36; 

d_height = (gridz-1)*7 + 2;  
r_scoop = enable_scoop ? length*gridz/12 - r_f2 : 0;  // scoop radius
d_wall2 = r_base-r_c1-d_clear*sqrt(2);
d_pitchx = (gridx*length-0.5-2*d_wall-(n_divx-1)*d_div)/n_divx; 
d_pitchy = (gridy*length-0.5-2*d_wall-(n_divy-1)*d_div)/n_divy; 




color("tomato")
gridfinity();

// ===== Modules =====

module gridfinity() {
    difference() {
        // solid bin
        color("firebrick") block_bottom(d_height);
        
        // subtraction blocks
        color("sienna") block_cutter();
    }
    
    color("orange") block_base();
    color("royalblue") block_wall();
}

module profile_base() {
    polygon([
        [0,0],
        [0,h_base],
        [r_base,h_base],
        [r_base-r_c2,h_base-r_c2],
        [r_base-r_c2,r_c1],
        [r_base-r_c2-r_c1,0]
    ]);
}

module block_base() {
    translate([0,0,h_base])
    rounded_rectangle(gridx*length-0.5+0.002, gridy*length-0.5+0.002, h_bot/1.5, r_fo1/2+0.001);
    pattern_linear(gridx, gridy, length) 
    render()
    difference() {
        translate([0,0,h_base])
        mirror([0,0,1])
        union() {
            hull() {
                rounded_square(length-0.5-2*r_c2-2*r_c1, h_base, r_fo3/2);
                rounded_square(length-0.5-2*r_c2, h_base-r_c1, r_fo2/2);
            }
            hull() {
                rounded_square(length-0.5-2*r_c2, r_c2, r_fo2/2);
                mirror([0,0,1])
                rounded_square(length-0.5, h_bot/2, r_fo1/2);
            }
        }
        
        if (enable_holes)
        pattern_circular(4) 
        translate([d_hole/2, d_hole/2, 0]) {
            union() {
                difference() {
                    cylinder(h = 2*(h_hole+(enable_hole_slit?0.2:0)), r = r_hole2, center=true);
                    if (enable_hole_slit)
                    copy_mirror([0,1,0])
                    translate([-1.5*r_hole2,r_hole1+0.1,h_hole]) 
                    cube([r_hole2*3,r_hole2*3, 0.4]);
                }
                cylinder(h = 3*h_base, r = r_hole1, center=true);
            }
        }
    }
}

module profile_wall_sub() {
    difference() {
        polygon([
            [0,0],
            [d_wall/2,0],
            [d_wall/2,d_height-1.2-d_wall2+d_wall/2],
            [d_wall2,d_height-1.2],
            [d_wall2,d_height+h_base],
            [0,d_height+h_base]
        ]);
        color("red")
        offset(delta = 0.25) 
        translate([r_base,d_height,0]) 
        mirror([1,0,0]) 
        profile_base();
        square([d_wall,0.1]);
    }
}

module profile_wall() {
    translate([r_base,0,0])
    mirror([1,0,0])
    difference() {
        profile_wall_sub();
        difference() {
            translate([0, d_height+h_base-d_clear*sqrt(2), 0]) 
            circle(r_base/2);
            offset(r = r_f1) 
            offset(delta = -r_f1)
            profile_wall_sub();
        }
    }
}

module block_wall() {
    translate([0,0,h_base]) 
    sweep_rounded(gridx*length-2*r_base-0.5-0.001, gridy*length-2*r_base-0.5-0.001)
    profile_wall();
}

module block_bottom( h = 2.2 ) {
    translate([0,0,h_base+0.1])
    rounded_rectangle(gridx*length-0.5-d_wall/4, gridy*length-0.5-d_wall/4, d_height-0.1, r_base+0.01);
}

module block_cutter() {
    for (j = [1:n_divy])
    translate(-(j-1)*(d_pitchy + d_div)*[0,1,0])
    for (i = [1:n_divx]) 
    translate(((i-1)-(n_divx-1)/2)*(d_pitchx + d_div)*[1,0,0])
    translate([0,gridy*length/2-0.25-d_wall,h_base+h_bot])
    rotate([90,0,-90])
    cutter(i,j);
}

module cutter(i,j) {
    
    v_len_tab = d_tabh;
    v_len_lip = d_wall2-d_wall+1.2;
    v_cut_tab = d_tabh - (2*r_f1)/tan(a_tab); 
    v_cut_lip = d_wall2-d_wall;
    v_ang_tab = a_tab;
    v_ang_lip = 45; 
    
    enable_tab = style_tab != 5;
    height = d_height;
    extent = (enable_scoop && j==n_divy ? d_wall2-d_wall : 0); 
    tab = ((gridz < 3 || style_tab == 5) && j == 1) ? v_len_lip : v_len_tab; 
    ang = ((gridz < 3 || style_tab == 5) && j == 1) ? v_ang_lip : v_ang_tab;
    cut = ((gridz < 3 || style_tab == 5) && j == 1) ? v_cut_lip : v_cut_tab;
    style = (style_tab > 1 && style_tab < 5) ? style_tab-3 : (i == 1 ? -1 : i == n_divx ? 1 : 0);
    
    if (gridz >= 3 && d_pitchx - d_tabw > 4*r_f2) {
        if (style_tab != 0 && style_tab != 5 && j == 1)
        fillet_cutter(3,"bisque")
        transform_tab(style)
        translate([d_wall2-d_wall,0]) 
        profile_cutter(height-h_bot, d_pitchy/2);

        
        if (style_tab != 0 && style_tab != 5)
        fillet_cutter(2,"indigo")
        transform_tab(style)
        difference() {
            intersection() {
                profile_cutter(height-h_bot, d_pitchy-extent);
                profile_cutter_tab(height-h_bot, v_len_tab, v_ang_tab);
            }
            if (j==1) profile_cutter_tab(height-h_bot, v_len_lip, 45);
        } 
    }
    
    if (!(style_tab == 5 && j != 1))
    fillet_cutter(1,"seagreen")
    transform_main()
    translate([cut,0]) 
    profile_cutter(height-h_bot,d_pitchy/2);
    
    fillet_cutter(0,"hotpink")
    transform_main()
    difference() {
        profile_cutter(height-h_bot, d_pitchy-extent);
        
        if (!((gridz < 3 || style_tab == 5) && j != 1))
        profile_cutter_tab(height-h_bot, tab, ang);
        
        if (!enable_scoop && j == n_divy)
        translate([d_pitchy-extent,0,0])
        mirror([1,0,0])
        profile_cutter_tab(height-h_bot, v_len_lip, v_ang_lip);
    }
    
    if (!enable_scoop && j == n_divy) {
        fillet_cutter(5,"darkslategray")
        translate([d_pitchy-(d_wall2-d_wall+2*r_f2)-v_cut_lip,0,0])
        transform_main()
        profile_cutter(height-h_bot,d_wall2-d_wall+2*r_f2);
    }
}

module transform_main() {
    translate([0,0,-(d_pitchx-2*r_f2)/2])
    linear_extrude(d_pitchx-2*r_f2)
    children();
}

module transform_tab(type) {
    mirror([0,0,type==1?1:0])
    copy_mirror([0,0,-(abs(type)-1)])
    translate([0,0,-d_pitchx/2])
    translate([0,0,r_f2])
    linear_extrude((d_pitchx-length)/(1-(abs(type)-1))-2*r_f2)
    children();
}

module fillet_cutter(t = 0, c = "goldenrod") {
    color(c)
    minkowski() {
        children();
        sphere(r = r_f2-t/1000);
    }
}

module profile_cutter(h, length) {
    translate([r_f2,r_f2])
    hull() {
        if (length-r_scoop-2*r_f2 > 0)
            square(0.1);
        if (r_scoop < h) {
            translate([length-2*r_f2,h-r_f2/2]) 
            mirror([1,1]) 
            square(0.1);
            
            translate([0,h-r_f2/2]) 
            mirror([0,1]) 
            square(0.1);
        }
        difference() {
            translate([length-r_scoop-2*r_f2, r_scoop]) 
            if (r_scoop != 0) {
                intersection() {
                    circle(r_scoop);
                    mirror([0,1]) square(2*r_scoop);
                }
            } else mirror([1,0]) square(0.1);
            translate([length-r_scoop-2*r_f2,-1]) 
            square([-(length-r_scoop-2*r_f2),2*h]);
            
            translate([0,h]) 
            square([2*length,r_scoop]);
        }
    }
}

module profile_cutter_tab(h, tab, ang) {
    if (tab > 0)
        color("blue")
        offset(delta = r_f2)
        polygon([[0,h],[tab,h],[0,h-tab*tan(ang)]]);
    
}

// ==== Utilities =====

module rounded_rectangle(length, width, height, rad) {
    linear_extrude(height)
    offset(rad) 
    offset(-rad) 
    square([length,width], center = true);
}

module rounded_square(length, height, rad) {
    rounded_rectangle(length, length, height, rad);
}

module copy_mirror(vec=[0,1,0]) {
    children();
    if (vec != [0,0,0]) 
    mirror(vec) 
    children();
} 

module pattern_linear(x = 1, y = 1, spacing = 0) {
    translate([-(x-1)*spacing/2,-(y-1)*spacing/2,0])
    for (i = [1:x])
    for (j = [1:y])
    translate([(i-1)*spacing,(j-1)*spacing,0]) 
    children();
}

module pattern_circular(n=2) {
    for (i = [1:n]) 
    rotate(i*360/n) 
    children();
}

module sweep_rounded(w=10, h=10) {
    union() pattern_circular(2) {
        copy_mirror([1,0,0]) 
        translate([w/2,h/2,0])
        rotate_extrude(angle = 90, convexity = 4) 
        children();
        
        translate([w/2,0,0])
        rotate([90,0,0])
        linear_extrude(height = h, center = true)
        children();
        
        rotate([0,0,90])
        translate([h/2,0,0])
        rotate([90,0,0])
        linear_extrude(height = w, center = true)
        children();
    }
}

