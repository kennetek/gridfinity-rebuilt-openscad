// ===== Info =====
// IMPORTANT: rendering will be better for analyzing the model if fast-csg is enabled. As of writing, this feature is only available in the development builds and not the official release of OpenSCAD, but it makes rendering only take a couple seconds, even for comically large bins. Enable it in Edit > Preferences > Features > fast-csg
// the plane that is the top of the internal bin solid is d_height+h_base above z=0
// the magnet holes can have an extra cut in them to make it easier to print without supports
// tabs will automatically be disabled when gridz is less than 3, as the tabs take up too much space
// examples are at the end of the file
// ===============


$fa = 8;
$fs = 0.25;

gridx = 3;  // number of bases along x-axis   
gridy = 3;  // number of bases along y-axis  
gridz = 6;  // unit height along z-axis (2, 3, or 6, but can be any)  
length = 42;// base unit (if you want to go rogue ig)

enable_holes = true; // holes on the base for magnet / screw
enable_hole_slit = true; // extra cut within holes for better slicing

color("tomato")
gridfinityEqual(n_divx = 2, n_divy = 2, style_tab = 1, enable_scoop = true);







// ===== User Modules =====

// Creates an equally divided gridfinity bin.  
//
// n_divx:  number of x compartments (ideally, coprime w/ gridx)    
// n_divy:  number of y compartments (ideally, coprime w/ gridy) 
//          set n_div values to 0 for a solid bin 
// style_tab:   tab style for all compartments. see cut()
// enable_scoop:    scoop toggle for all compartments. see cut()
module gridfinityEqual(n_divx=1, n_divy=1, style_tab=1, enable_scoop=true) {
    gridfinityCustom()
    for (i = [1:n_divx]) 
    for (j = [1:n_divy])
    cut((i-1)*gridx/n_divx,(j-1)*gridy/n_divy, gridx/n_divx, gridy/n_divy, style_tab, enable_scoop);
}

// wrapper module
// DOES NOT CHECK FOR VALID COMPARTMENT STRUCTURE
module gridfinityCustom() {
    difference() {
        color("firebrick") block_bottom(d_height);
        children();
    }
    color("orange") block_base();
    color("royalblue") block_wall();
}

// Function to include in the custom() module to individually slice bins
// Will try to clamp values to fit inside the provided base size
//
// x:   start coord. x=1 is the left side of the bin.
// y:   start coord. y=1 is the bottom side of the bin. 
// w:   width of compartment, in # of bases covered
// h:   height of compartment, in # of basese covered
// t:   tab style of this specific compartment.
//      alignment only matters if the compartment size is larger than d_tabw
//      0:full, 1:auto, 2:left, 3:center, 4:right, 5:none
//      Automatic alignment will use left tabs for bins on the left edge, right tabs for bins on the right edge, and center tabs everywhere else. 
// s:   toggle the rounded back corner that allows for easy removal
module cut(x=0, y=0, w=1, h=1, t=1, s=true) {
    cut_move(x,y,w,h)
    block_cutter(clp(x,0,gridx), clp(y,0,gridy), clp(w,0,gridx-x), clp(h,0,gridy-y), t, s);
}

// Translates an object from the origin point to the center of the requested compartment block, can be used to add custom cuts in the bin
// See cut() module for parameter descriptions
module cut_move(x, y, w, h) {
    cut_move_unsafe(clp(x,0,gridx), clp(y,0,gridy), clp(w,0,gridx-x), clp(h,0,gridy-y))
    children();
}



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
r_f2 = 2.8;     // internal fillet radius

d_div = 1.2;    // width of divider between compartments
d_wall = 0.95;   // minimum wall thickness
d_clear = 0.25; // tolerance fit factor

d_tabh = 15.85;     // height of tab (yaxis, measured from inner wall)
d_tabw = length;    // maximum width of tab
a_tab = 36; 

d_height = (gridz-1)*7 + 2;  
r_scoop = length*gridz/12 - r_f2;  // scoop radius
d_wall2 = r_base-r_c1-d_clear*sqrt(2);

xl = gridx*length-0.5-2*d_wall+d_div; 
yl = gridy*length-0.5-2*d_wall+d_div; 



// ===== Modules =====

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

module cut_move_unsafe(x, y, w, h) {
    translate([(x)*xl/gridx,(y)*yl/gridy,0])
    translate([(-xl+d_div)/2,(-yl+d_div)/2,0])
    translate([(w*xl/gridx-d_div)/2,(h*yl/gridy-d_div)/2,0])
    children();
}

module block_cutter(x,y,w,h,t,s) {
    
    v_len_tab = d_tabh;
    v_len_lip = d_wall2-d_wall+1.2;
    v_cut_tab = d_tabh - (2*r_f1)/tan(a_tab); 
    v_cut_lip = d_wall2-d_wall;
    v_ang_tab = a_tab;
    v_ang_lip = 45;
    
    ylast = abs(y+h-gridy)<0.001; 
    xlast = abs(x+w-gridx)<0.001;
    ylen = h*yl/gridy-d_div; 
    xlen = w*xl/gridx-d_div; 
    
    height = d_height;
    extent = (s && y==0 ? d_wall2-d_wall : 0); 
    tab = (gridz < 3 || t == 5) ? (ylast?v_len_lip:0) : v_len_tab; 
    ang = (gridz < 3 || t == 5) ? (ylast?v_ang_lip:0) : v_ang_tab;
    cut = (gridz < 3 || t == 5) ? (ylast?v_cut_lip:0) : v_cut_tab;
    style = (t > 1 && t < 5) ? t-3 : (x == 0 ? -1 : xlast ? 1 : 0);
    
    translate([0,ylen/2,h_base+h_bot])
    rotate([90,0,-90]) {
    
    if (gridz >= 3 && xlen - d_tabw > 4*r_f2 && t != 0) {
        fillet_cutter(3,"bisque")
        difference() {
            transform_tab(style, xlen, ((x==0&&style==-1)||(xlast&&style==1))?v_cut_lip:0)
            translate([ylast?d_wall2-d_wall:0,0]) 
            profile_cutter(height-h_bot, ylen/2, s);

            if (x==0)
            translate([0,0,(xlen/2-r_f2)-v_cut_lip]) 
            cube([ylen,height,v_cut_lip*2]);
            
            if (xlast)
            translate([0,0,-(xlen/2-r_f2)-v_cut_lip])
            cube([ylen,height,v_cut_lip*2]);
        }
        if (t != 0 && t != 5)
        fillet_cutter(2,"indigo")
        difference() {
            transform_tab(style, xlen, ((x==0&&style==-1)||(xlast&&style==1))?v_cut_lip:0)
            difference() {
                intersection() {
                    profile_cutter(height-h_bot, ylen-extent, s);
                    profile_cutter_tab(height-h_bot, v_len_tab, v_ang_tab);
                }
                if (ylast) profile_cutter_tab(height-h_bot, v_len_lip, 45);
            } 
            
            if (x == 0)
            translate([ylen/2,0,xlen/2])
            rotate([0,90,0])
            transform_main(2*ylen)
            profile_cutter_tab(height-h_bot, v_len_lip, v_ang_lip);
            
            if (xlast)
            translate([ylen/2,0,-xlen/2])
            rotate([0,-90,0])
            transform_main(2*ylen)
            profile_cutter_tab(height-h_bot, v_len_lip, v_ang_lip);
        }
    }
    
    fillet_cutter(1,"seagreen")
    translate([0,0,xlast?v_cut_lip/2:0])
    translate([0,0,x==0?-v_cut_lip/2:0])
    transform_main(xlen-(x==0?v_cut_lip:0)-(xlast?v_cut_lip:0))
    translate([cut,0]) 
    profile_cutter(height-h_bot, ylen-extent-cut-(!s&&y==0?v_cut_lip:0), s);
    
    fillet_cutter(0,"hotpink")
    difference() {
        transform_main(xlen)
        difference() {
            profile_cutter(height-h_bot, ylen-extent, s);
            
            if (!((gridz < 3 || t == 5) && !ylast))
            profile_cutter_tab(height-h_bot, tab, ang);
            
            if (!s && y == 0)
            translate([ylen-extent,0,0])
            mirror([1,0,0])
            profile_cutter_tab(height-h_bot, v_len_lip, v_ang_lip);
        }
        
        if (x == 0)
        color("indigo")
        translate([ylen/2,0,xlen/2])
        rotate([0,90,0])
        transform_main(2*ylen)
        profile_cutter_tab(height-h_bot, v_len_lip, v_ang_lip);
        
        if (xlast)
        color("indigo")
        translate([ylen/2,0,-xlen/2])
        rotate([0,-90,0])
        transform_main(2*ylen)
        profile_cutter_tab(height-h_bot, v_len_lip, v_ang_lip);
    }

    }
}

module transform_main(xlen) {
    translate([0,0,-(xlen-2*r_f2)/2])
    linear_extrude(xlen-2*r_f2)
    children();
}

module transform_tab(type, xlen, cut) {
    mirror([0,0,type==1?1:0])
    copy_mirror([0,0,-(abs(type)-1)])
    translate([0,0,-(xlen)/2])
    translate([0,0,r_f2])
    linear_extrude((xlen-d_tabw-abs(cut))/(1-(abs(type)-1))-2*r_f2)
    children();
}

module fillet_cutter(t = 0, c = "goldenrod") {
    color(c)
    minkowski() {
        children();
        sphere(r = r_f2-t/1000);
    }
}

module profile_cutter(h, length, s) {
    scoop = s ? r_scoop : 0; 
    translate([r_f2,r_f2])
    hull() {
        if (length-scoop-2*r_f2 > 0)
            square(0.1);
        if (scoop < h) {
            translate([length-2*r_f2,h-r_f2/2]) 
            mirror([1,1]) 
            square(0.1);
            
            translate([0,h-r_f2/2]) 
            mirror([0,1]) 
            square(0.1);
        }
        difference() {
            translate([length-scoop-2*r_f2, scoop]) 
            if (scoop != 0) {
                intersection() {
                    circle(scoop);
                    mirror([0,1]) square(2*scoop);
                }
            } else mirror([1,0]) square(0.1);
            translate([length-scoop-2*r_f2,-1]) 
            square([-(length-scoop-2*r_f2),2*h]);
            
            translate([0,h]) 
            square([2*length,scoop]);
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

function clp(x,a,b) = min(max(x,a),b);

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


// ===== Examples =====

// All examples assume gridx == 3, gridy == 3, and gridz == 6, but some may work with other settings

// 3x3 even spaced grid
//gridfinityEqual(3, 3, 0, true);

// Compartments can be placed anywhere (this includes non-integer positions like 1/2 or 1/3). The grid is defined as (0,0) being the bottom left corner of the bin, with each unit being 1 base long. Each cut() module is a compartment, with the first four values defining the area that should be made into a compartment (X coord, Y coord, width, and height). These values should all be positive. t is the tab style of the compartment (0:full, 1:auto, 2:left, 3:center, 4:right, 5:none). s is a toggle for the bottom scoop. 
/*
gridfinityCustom() {
    cut(x=0, y=0, w=1.5, h=0.5, t=5, s=false);
    cut(0, 0.5, 1.5, 0.5, 5, false);
    cut(0, 1, 1.5, 0.5, 5, false);
    
    cut(0,1.5,0.5,1.5,5,false);
    cut(0.5,1.5,0.5,1.5,5,false);
    cut(1,1.5,0.5,1.5,5,false);
    
    cut(1.5, 0, 1.5, 5/3, 2);
    cut(1.5, 5/3, 1.5, 4/3, 4);
}*/

// Compartments can overlap! This allows for weirdly shaped compartments, such as this "2" bin. 
/*
gridfinityCustom() {
    cut(0,2,2,1,5,false);
    cut(1,0,1,3,5);
    cut(1,0,2,1,5);
    cut(0,0,1,2);
    cut(2,1,1,2);
}*/

// Areas without a compartment are solid material, where you can put your own cutout shapes. using the cut_move() function, you can select an area, and any child shapes will be moved from the origin to the center of that area, and subtracted from the block. For example, a pattern of three cylinderical holes.
/*
gridfinityCustom() {
    cut(x=0, y=0, w=2, h=3);
    cut(x=0, y=0, w=3, h=1, t=5);
    cut_move(x=2, y=1, w=1, h=2) 
        pattern_linear(x=1, y=3, spacing=length/2) 
            cylinder(r=5, h=10*d_height, center=true);
}*/

// You can use loops as well as the bin dimensions to make different parametric functions, such as this one, which divides the box into columns, with a small 1x1 top compartment and a long vertical compartment below

/*gridfinityCustom() {
    for(i=[0:gridx-1]) {
        cut(i,0,1,gridx-1);
        cut(i,gridx-1,1,1);
    }
}*/

// Pyramid scheme bin
/*
gridfinityCustom() {
    for (i = [0:gridx-1]) 
    for (j = [0:i])
    cut(j*gridx/(i+1),gridy-i-1,gridx/(i+1),1,0);
}*/

