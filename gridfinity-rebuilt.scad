// if F5 preview fails due to too many polygons or it is too slow to be usable, multiply both of these values by 10 and do an F6 render. Return back to normal for the final 3D print render. 
$fa = 5;
$fs = 0.25;


// ===== Parameters =====

gridx = 2;      // number of bases along x-axis
gridy = 2;      // number of bases along y-axis
gridz = 3;      // unit height along z-axis (2, 3, or 6, but can be anything)
n_divx = 2;     // number of x compartments (ideally, coprime w/ gridx)
n_divy = 2;     // number of y compartments (ideally, coprime w/ gridy) 
                // set n_div values to 0 for a solid bin (for custom bins)

length = 42;    // base unit (if you want to go rogue ig)

// type of tab style. alignment only matters if tabs are large enough
// 0:full, 1:automatic, 2:right, 3:center, 4:left, 5:none
style_tab = 0; 

enable_scoop    = true; // the rounded edge that allows for easy removal
enable_holes    = true; // holes on the base for magnet / screw
enable_holeslit = true; // extra cut within holes for better slicing

// ===== Info =====
// the red plane that is the top of the internal bin is d_height+h_base above z=0
// the tab cutter object causes serious lag in the preview, I think it has something to do with cutting the same surfaces as other cutting objects, but I cannot seem to fix it, apologies
// the magnet holes have an extra cut in them to make it easier to print without supports
// tabs will automatically be disabled when gridz is less than 3

// ===== Dimensions =====

// base
h_base = 5;     // height of the base
r_base = 4;     // outside rounded radius of bin
r_c1 = 0.8;     // lower base chamfer "radius"
r_c2 = 2.4;     // upper base chamfer "radius"
h_bot = 2.2;    // bottom thiccness of bin

// base holes
r_hole1 = 1.5;  // screw hole radius
r_hole2 = 3.25; // magnet hole radius
d_hole = 26;    // center-to-center distance between holes
h_hole = 2.4;   // magnet hole depth

// fillets
r_f1 = 0.6;     // top edge fillet radius
r_f2 = 2.8;     // internal fillet radius
r_f3 = 0.6;     // lip fillet radius

// misc
d_div = 1.2;    // width of divider between compartments
d_wall = 0.95;   // minimum wall thickness
d_clear = 0.25; // tolerance fit factor

// tabs
d_tabh = 15.85;   // height of tab (yaxis, measured from inner wall)
d_tabw = length; // maximum width of tab
a_tab = 32; 

// calculations
d_height = (gridz-1)*7 + 2;  
r_scoop = length*gridz/12;  // scoop radius
d_wall2 = r_base-r_c1-d_clear*sqrt(2);

d_pitchx = (gridx*length-2*d_wall-(n_divx-1)*d_div)/n_divx; 
d_pitchy = (gridy*length-2*d_wall-(n_divy-1)*d_div)/n_divy; 
b_notab = style_tab == 5 || gridz < 3; 

d_planey = d_pitchy/2 - d_div - d_tabh - 0.1;

// magic numbers (cutter parameters)
v_tab = [r_f2, r_f3, d_height-h_bot-(d_tabh-d_wall)*tan(a_tab), d_tabh-d_wall-r_f3/tan(a_tab/2), d_height-h_bot-r_f3, 179, a_tab, -d_planey];
v_edg = [r_f2, 0, d_height-h_bot-d_wall2, d_wall2-d_wall, d_height-h_bot-d_wall, 90, 45, -d_planey];
v_slo = [r_scoop, 0, 2*d_height, 0, 0, 30, 10, d_planey];
v_clr = [r_f2, 0, 2*d_height-h_bot-d_wall2, d_wall2-d_wall, 2*d_height-h_bot-d_wall, 90, 45, -d_planey];


gridfinity();


// ===== Modules =====

module gridfinity() {
    difference() {
        // solid bin
        block_bottom(d_height);
        
        // subtraction blocks
        block_cutter();
    }
    block_base();
    block_wall();
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
    color("orange")
    pattern_linear(gridx, gridy, length) 
    render() union() {
        sweep_rounded(length-2*r_base,length-2*r_base) profile_base();
        pattern_circular(4) difference() {
            linear_extrude(h_base) square(length/2-r_base);
            if (enable_holes)
            translate([d_hole/2, d_hole/2, 0]) union() {
                cylinder(h = 3*h_base, r = r_hole1, center=true);
                cylinder(h = 2*h_hole, r = r_hole2, center=true);
                if (enable_holeslit) intersection() {
                    cylinder(h = 2*(h_hole+0.2), r = r_hole2, center=true);
                    cube([r_hole1*2,r_hole2*3,2*(h_hole+0.4)], center=true);
                }
            }
        }
    }
}

module profile_wall_sub() {
    difference() {
        polygon([
            [0,0],
            [d_wall/2,0],
            [d_wall/2,d_height-d_wall2-d_wall/2],
            [d_wall2,d_height-d_wall],
            [d_wall2,d_height+h_base],
            [0,d_height+h_base]
        ]);
        offset(delta = 0.25) 
        translate([r_base,d_height,0]) 
        mirror([1,0,0]) 
        profile_base();
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
    color("royalblue")
    translate([0,0,h_base]) 
    sweep_rounded(gridx*length-2*r_base, gridy*length-2*r_base)
    profile_wall();
}

module block_bottom( h = 2.2 ) {
    color("firebrick")
    translate([0,0,h_base])
    hull()
    sweep_rounded(gridx*length-2*r_base, gridy*length-2*r_base)
    translate([r_base-0.1,0,0])
    mirror([1,0,0])
    square([d_wall, d_height]);
}

module profile_cutter(r = 0, width = 1, stretch = 0) {
    extent = width/2-r_f2+0.1;
    translate([r-r_f2,0,0]) 
    union() {
        difference() {
            union() {
                translate([0,extent,0]) circle(r=r_f2);
                square([r_f2,extent]);
            }
            translate([-r_f2,0,0]) square([r_f2,extent+r_f2]);
        }
        mirror([1,0,0]) square([stretch,extent+r_f2]);
    }
}

module part_bend(t=[0,0], rot, ang, rad, width, s = 0) {
    translate([t.x,t.y,0]) 
    rotate([0,0,rot]) 
    rotate_extrude(angle = ang, convexity = 4) 
    profile_cutter(rad,width,s);
}

module part_line(t=[0,0], rot, d, width, s = 0) {
    translate([t.x,t.y,0])
    rotate([90,0,rot])
    translate([r_f2,0,0])
    linear_extrude(d) 
    profile_cutter(0,width,s);
}

module cutter_main(arr, width, off_back = 0, off_front = 0) {
    
    r1 = arr[0]; 
    r2 = arr[1];
    a_end = arr[5];
    a_slo = arr[6];
    p_y3 = arr[2] - r1*tan((90-a_slo)/2);
    p_x4 = arr[3];
    p_y4 = arr[4];
    
    d_pitchx = width;
    d_extent = (gridy*length-2*d_wall-(n_divy-1)*d_div)/(2*n_divy)+0.1+off_front;

    assert(p_x4 < d_extent, "IMPOSSIBLE GEOMETRY: COMPARTMENT Y LENGTH IS TOO SMALL, TRY DISABLING TABS. OTHERWISE, DECREASE NUMBER OF Y COMPARTMENTS OR INCREASE Y BASE COUNT.");
    assert(r1 < d_extent, "IMPOSSIBLE GEOMETRY: COMPARTMENT Y LENGTH IS TOO SMALL, TRY DISABLING SCOOP. OTHERWISE, DECREASE NUMBER OF Y COMPARTMENTS OR INCREASE Y BASE COUNT.");
    
    l_angle = ([p_x4-r1,p_y4-p_y3] * [[cos(a_slo), -sin(a_slo)], [sin(a_slo), cos(a_slo)]])[0];
    
    difference() {
    translate([0,d_extent-0.1-off_front,h_base+h_bot])
    rotate([90,0,-90])
    union() 
    copy_mirror([0,0,1])
    translate([off_back,0,-0.1]) {
        // outside of hull because of its concave geometry
        if (p_x4 != 0 || p_y4 != 0) difference() 
            { 
            union() {
                render() part_bend([p_x4, p_y4], a_slo+90, a_end-a_slo, -r2, d_pitchx, 2*r_f2);
                part_line([p_x4, p_y4]+(r_f2+r2)*ta(a_end-90)-0.1*ta(a_end), a_end+90, d_extent, d_pitchx, 2*r_f2);
                part_line([r1, p_y3]+(r1-r_f2)*-ta(-a_slo)+l_angle*ta(a_slo), a_slo+90, l_angle, d_pitchx, 2*r_f2);
            }
            copy_mirror([0,1,0]) translate([0,-0.1,-0.1]) cube([d_extent+0.1,r_f2,d_pitchx]);
        }
        hull() 
        {
            // left bottom, angle, and scoop fillets
            part_bend([r1, r1], -180, 90, r1, d_pitchx);
            part_bend([r1, p_y3], 90+a_slo, 90-a_slo, r1, d_pitchx);
            
            // bottom, left, right, angle (thin), angle (thicc)
            part_line([d_extent, r_f2], -90, d_extent - r1, d_pitchx);
            part_line([r_f2, r1], 180, p_y3 - r1, d_pitchx);
            part_line([r1, p_y3]+(r1-r_f2)*-ta(-a_slo), a_slo+90, (d_extent-r1+(r1-r_f2)*cos(a_slo))/cos(a_slo), d_pitchx);
            
        }
    }
    mirror([0,1,0]) translate([-gridx*length/2, 0.1+off_front, h_base]) cube([2*gridx*length, 2*gridy*length, 10*d_height]); 
    }
}

module cutter_tab(s = 1, values=v_edg) {
    if ((d_pitchx > d_tabw && s != 0 && d_pitchx - d_tabw > 4*r_f2 ) || s == 5) {
        d_w = (d_pitchx - (s==5?0:length)) / (s==3?2:1);
        mirror([s==2?1:0, 0, 0])
        copy_mirror([s==3?1:0, 0, 0])
        translate([(d_pitchx-d_w)/2,0,0])
        cutter_main(values, d_w, 0, -d_planey);
    }
}

module block_cutter() {
    if (n_divx > 0) {
        for (j = [1:n_divy])
        translate(((j-1)-(n_divy-1)/2)*(d_pitchy + d_div)*[0,1,0])
        for (i = [1:n_divx]) 
        translate(((i-1)-(n_divx-1)/2)*(d_pitchx + d_div)*[1,0,0])
        cutter_main(b_notab ? j==n_divy ? v_edg : v_clr : v_tab, d_pitchx, 0, -d_planey);
        
        if (!b_notab)
        for (j = [1:n_divy])
        translate(((j-1)-(n_divy-1)/2)*(d_pitchy + d_div)*[0,1,0])
        for (i = [1:n_divx]) 
        translate(((i-1)-(n_divx-1)/2)*(d_pitchx + d_div)*[1,0,0])
        cutter_tab(style_tab==1?(i==1?4:(i==n_divx?2:3)):style_tab, j==n_divy ? v_edg : v_clr);
        
        for (j = [1:n_divy])
        translate(((j-1)-(n_divy-1)/2)*(d_pitchy + d_div)*[0,1,0])
        for (i = [1:n_divx]) 
        translate(((i-1)-(n_divx-1)/2)*(d_pitchx + d_div)*[1,0,0])
        mirror([0,1,0])
        cutter_main(enable_scoop?v_slo:j==1?v_edg:v_clr, d_pitchx, enable_scoop?j==1?d_wall2-d_wall:0:0, d_planey);
        
    }
}

// ==== Utilities =====

ta = function (a) [cos(a), sin(a)];

module copy_mirror(vec=[0,1,0]) {
    children();
    mirror(vec) children();
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

