// UTILITY FILE, DO NOT EDIT
// EDIT OTHER FILES IN REPO FOR RESULTS

include <standard.scad>

// ===== User Modules ===== //

// functions to convert gridz values to mm values
function hf (z, d, l) = ((d==0)?z*7:(d==1)?h_bot+z+h_base:z-((l==1)?h_lip:0))+(l==2?h_lip:0);
function height (z,d=0,l=0,s=true) = (s?((abs(hf(z,d,l))%7==0)?hf(z,d,l):hf(z,d,l)+7-abs(hf(z,d,l))%7):hf(z,d,l))-h_base;

// Creates equally divided cutters for the bin
//
// n_divx:  number of x compartments (ideally, coprime w/ gridx)
// n_divy:  number of y compartments (ideally, coprime w/ gridy)
//          set n_div values to 0 for a solid bin
// style_tab:   tab style for all compartments. see cut()
// scoop_weight:    scoop toggle for all compartments. see cut()
module cutEqual(n_divx=1, n_divy=1, style_tab=1, scoop_weight=1) {
    for (i = [1:n_divx])
    for (j = [1:n_divy])
    cut((i-1)*$gxx/n_divx,(j-1)*$gyy/n_divy, $gxx/n_divx, $gyy/n_divy, style_tab, scoop_weight);
}


// Creates equally divided cylindrical cutouts
//
// n_divx: number of x cutouts
// n_divy: number of y cutouts
//         set n_div values to 0 for a solid bin
// cylinder_diameter: diameter of cutouts
// cylinder_height: height of cutouts
// coutout_depth: offset from top to solid part of container
// orientation: orientation of cylinder cutouts (0 = x direction, 1 = y direction, 2 = z direction)
// chamfer: chamfer around the top rim of the holes
module cutCylinders(n_divx=1, n_divy=1, cylinder_diameter=1, cylinder_height=1, coutout_depth=0, orientation=0, chamfer=0.5) {
    rotation = (orientation == 0)
            ? [0,90,0]
            : (orientation == 1)
                ? [90,0,0]
                : [0,0,0];

    gridx_mm = $gxx*l_grid;
    gridy_mm = $gyy*l_grid;
    padding = 2;
    cutout_x = gridx_mm - d_wall*2;
    cutout_y = gridy_mm - d_wall*2;

    cut_move(x=0, y=0, w=$gxx, h=$gyy) {
        translate([0,0,-coutout_depth]) {
            rounded_rectangle(cutout_x, cutout_y, coutout_depth*2, r_base);

            pattern_linear(x=n_divx, y=n_divy, sx=(gridx_mm - padding)/n_divx, sy=(gridy_mm - padding)/n_divy)
                rotate(rotation)
                    union() {
                        cylinder(d=cylinder_diameter, h=cylinder_height*2, center=true);
                        if (chamfer > 0) {
                            translate([0,0,-chamfer]) cylinder(d1=cylinder_diameter, d2=cylinder_diameter+4*chamfer, h=2*chamfer);
                        }
                    };
        }
    }
}

// initialize gridfinity
// sl:  lip style of this bin.
//      0:Regular lip, 1:Remove lip subtractively, 2:Remove lip and retain height
module gridfinityInit(gx, gy, h, h0 = 0, l = l_grid, sl = 0) {
    $gxx = gx;
    $gyy = gy;
    $dh = h;
    $dh0 = h0;
    $style_lip = sl;
    color("tomato") {
    difference() {
        color("firebrick")
        block_bottom(h0==0?$dh-0.1:h0, gx, gy, l);
        children();
    }
    color("royalblue")
    block_wall(gx, gy, l) {
        if ($style_lip == 0) profile_wall();
        else profile_wall2();
    }
    }
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

module cut(x=0, y=0, w=1, h=1, t=1, s=1, tab_width=d_tabw, tab_height=d_tabh) {
    translate([0,0,-$dh-h_base])
    cut_move(x,y,w,h)
    block_cutter(clp(x,0,$gxx), clp(y,0,$gyy), clp(w,0,$gxx-x), clp(h,0,$gyy-y), t, s, tab_width, tab_height);
}


// cuts equally sized bins over a given length at a specified position
// bins_x:  number of bins along x-axis
// bins_y:  number of bins along y-axis
// len_x:   length (in gridfinity bases) along x-axis that the bins_x will fill
// len_y:   length (in gridfinity bases) along y-axis that the bins_y will fill
// pos_x:   start x position of the bins (left side)
// pos_y:   start y position of the bins (bottom side)
// style_tab:   Style of the tab used on the bins
// scoop:   Weight of the scoop on the bottom of the bins
// tab_width:   Width of the tab on the bins, in mm.
// tab_height:  How far the tab will stick out over the bin, in mm. Default tabs fit 12mm labels, but for narrow bins can take up too much space over the opening. This setting allows 'slimmer' tabs for use with thinner labels, so smaller/narrower bins can be labeled and still keep a reasonable opening at the top. NOTE: The measurement is not 1:1 in mm, so a '3.5' value does not guarantee a tab that fits 3.5mm label tape. Use the 'measure' tool after rendering to check the distance between faces to guarantee it fits your needs.
module cutEqualBins(bins_x=1, bins_y=1, len_x=1, len_y=1, pos_x=0, pos_y=0, style_tab=5, scoop=1, tab_width=d_tabw, tab_height=d_tabh) {
    // Calculate width and height of each bin based on total length and number of bins
    bin_width = len_x / bins_x;
    bin_height = len_y / bins_y;

    // Loop through each bin position in x and y direction
    for (i = [0:bins_x-1]) {
        for (j = [0:bins_y-1]) {
            // Calculate the starting position for each bin
            // Adjust position by adding pos_x and pos_y to shift the entire grid of bins as needed
            bin_start_x = pos_x + i * bin_width;
            bin_start_y = pos_y + j * bin_height;

            // Call the cut module to create each bin with calculated position and dimensions
            // Pass through the style_tab and scoop parameters
            cut(bin_start_x, bin_start_y, bin_width, bin_height, style_tab, scoop, tab_width=tab_width, tab_height=tab_height);
        }
    }
}

// Translates an object from the origin point to the center of the requested compartment block, can be used to add custom cuts in the bin
// See cut() module for parameter descriptions
module cut_move(x, y, w, h) {
    translate([0,0,$dh0==0?$dh+h_base:$dh0+h_base])
    cut_move_unsafe(clp(x,0,$gxx), clp(y,0,$gyy), clp(w,0,$gxx-x), clp(h,0,$gyy-y))
    children();
}

// ===== Modules ===== //

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

module gridfinityBase(gx, gy, l, dx, dy, style_hole, off=0, final_cut=true, only_corners=false) {
    dbnxt = [for (i=[1:5]) if (abs(gx*i)%1 < 0.001 || abs(gx*i)%1 > 0.999) i];
    dbnyt = [for (i=[1:5]) if (abs(gy*i)%1 < 0.001 || abs(gy*i)%1 > 0.999) i];
    dbnx = 1/(dx==0 ? len(dbnxt) > 0 ? dbnxt[0] : 1 : round(dx));
    dbny = 1/(dy==0 ? len(dbnyt) > 0 ? dbnyt[0] : 1 : round(dy));
    xx = gx*l-0.5;
    yy = gy*l-0.5;

    if (final_cut)
    translate([0,0,h_base])
    rounded_rectangle(xx+0.002, yy+0.002, h_bot/1.5, r_fo1+0.001);

    intersection(){
        if (final_cut)
        translate([0,0,-1])
        rounded_rectangle(xx+0.005, yy+0.005, h_base+h_bot/2*10, r_fo1+0.001);

        if(only_corners) {
            difference(){
                pattern_linear(gx/dbnx, gy/dbny, dbnx*l, dbny*l)
                block_base(gx, gy, l, dbnx, dbny, 0, off);
                if (style_hole == 4) {
                    translate([(gx/2)*l_grid - d_hole_from_side, (gy/2) * l_grid - d_hole_from_side, h_slit*2])
                    refined_hole();
                    mirror([1, 0, 0])
                    translate([(gx/2)*l_grid - d_hole_from_side, (gy/2) * l_grid - d_hole_from_side, h_slit*2])
                    refined_hole();
                    mirror([0, 1, 0]) {
                        translate([(gx/2)*l_grid - d_hole_from_side, (gy/2) * l_grid - d_hole_from_side, h_slit*2])
                        refined_hole();
                        mirror([1, 0, 0])
                        translate([(gx/2)*l_grid - d_hole_from_side, (gy/2) * l_grid - d_hole_from_side, h_slit*2])
                        refined_hole();
                    }
                }
                else {
                    pattern_linear(2, 2, (gx-1)*l_grid+d_hole, (gy-1)*l_grid+d_hole)
                    block_base_hole(style_hole, off);
                }
            }
        }
        else {
            pattern_linear(gx/dbnx, gy/dbny, dbnx*l, dbny*l)
            block_base(gx, gy, l, dbnx, dbny, style_hole, off);
        }
    }
}

module block_base(gx, gy, l, dbnx, dbny, style_hole, off) {
    render(convexity = 2)
    difference() {
        block_base_solid(dbnx, dbny, l, off);

        if (style_hole > 0)
            pattern_circular(abs(l-d_hole_from_side/2)<0.001?1:4)
            if (style_hole == 4)
                translate([l/2-d_hole_from_side, l/2-d_hole_from_side, h_slit*2])
                refined_hole();
            else
                translate([l/2-d_hole_from_side, l/2-d_hole_from_side, 0])
                block_base_hole(style_hole, off);
        }
}

module block_base_solid(dbnx, dbny, l, o) {
    xx = dbnx*l-0.05;
    yy = dbny*l-0.05;
    oo = (o/2)*(sqrt(2)-1);
    translate([0,0,h_base])
    mirror([0,0,1])
    union() {
        hull() {
            rounded_rectangle(xx-2*r_c2-2*r_c1+o, yy-2*r_c2-2*r_c1+o, h_base+oo, r_fo3);
            rounded_rectangle(xx-2*r_c2+o, yy-2*r_c2+o, h_base-r_c1+oo, r_fo2);
        }
        translate([0,0,oo])
        hull() {
            rounded_rectangle(xx-2*r_c2+o, yy-2*r_c2+o, r_c2, r_fo2);
            mirror([0,0,1])
            rounded_rectangle(xx+o, yy+o, h_bot/2+abs(10*o), r_fo1);
        }
    }
}

module block_base_hole(style_hole, o=0) {
    r1 = r_hole1-o/2;
    r2 = r_hole2-o/2;
    union() {
        difference() {
            cylinder(h = 2*(h_hole-o+(style_hole==3?h_slit:0)), r=r2, center=true);

            if (style_hole==3)
            copy_mirror([0,1,0])
            translate([-1.5*r2,r1+0.1,h_hole-o])
            cube([r2*3,r2*3, 10]);
        }
        if (style_hole > 1)
        cylinder(h = 2*h_base-o, r = r1, center=true);
    }
}


module refined_hole() {
    /**
    * Refined hole based on Printables @grizzie17's Gridfinity Refined
    * https://www.printables.com/model/413761-gridfinity-refined
    */

    // Meassured magnet hole diameter to be 5.86mm (meassured in fusion360
    r = r_hole2-0.32;

    // Magnet height
    m = 2;
    mh = m-0.1;

    // Poke through - For removing a magnet using a toothpick
    ptl = h_slit*3; // Poke Through Layers
    pth = mh+ptl; // Poke Through Height
    ptr = 2.5; // Poke Through Radius

    union() {
        hull() {
            // Magnet hole - smaller than the magnet to keep it squeezed
            translate([10, -r, 0]) cube([1, r*2, mh]);
            cylinder(1.9, r=r);
        }
        hull() {
            // Poke hole
            translate([-9+5.60, -ptr/2, -ptl]) cube([1, ptr, pth]);
            translate([-12.53+5.60, 0, -ptl]) cylinder(pth, d=ptr);
        }
    }
}

module profile_wall_sub_sub() {
    polygon([
        [0,0],
        [d_wall/2,0],
        [d_wall/2,$dh-1.2-d_wall2+d_wall/2],
        [d_wall2-d_clear,$dh-1.2],
        [d_wall2-d_clear,$dh+h_base],
        [0,$dh+h_base]
    ]);
}

module profile_wall_sub() {
    difference() {
        profile_wall_sub_sub();
        color("red")
        offset(delta = d_clear)
        translate([r_base-d_clear,$dh,0])
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
            translate([0, $dh+h_base-d_clear*sqrt(2), 0])
            circle(r_base/2);
            offset(r = r_f1)
            offset(delta = -r_f1)
            profile_wall_sub();
        }
        // remove any negtive geometry in edge cases
        mirror([0,1,0])
        square(100*l_grid);
    }
}

// lipless profile
module profile_wall2() {
    translate([r_base,0,0])
    mirror([1,0,0])
    square([d_wall,$dh]);
}

module block_wall(gx, gy, l) {
    translate([0,0,h_base])
    sweep_rounded(gx*l-2*r_base-0.5-0.001, gy*l-2*r_base-0.5-0.001)
    children();
}

module block_bottom( h = 2.2, gx, gy, l ) {
    translate([0,0,h_base+0.1])
    rounded_rectangle(gx*l-0.5-d_wall/4, gy*l-0.5-d_wall/4, h, r_base+0.01);
}

module cut_move_unsafe(x, y, w, h) {
    xx = ($gxx*l_grid+d_magic);
    yy = ($gyy*l_grid+d_magic);
    translate([(x)*xx/$gxx,(y)*yy/$gyy,0])
    translate([(-xx+d_div)/2,(-yy+d_div)/2,0])
    translate([(w*xx/$gxx-d_div)/2,(h*yy/$gyy-d_div)/2,0])
    children();
}

module block_cutter(x,y,w,h,t,s,tab_width=d_tabw,tab_height=d_tabh) {

    v_len_tab = tab_height;
    v_len_lip = d_wall2-d_wall+1.2;
    v_cut_tab = tab_height - (2*r_f1)/tan(a_tab);
    v_cut_lip = d_wall2-d_wall-d_clear;
    v_ang_tab = a_tab;
    v_ang_lip = 45;

    ycutfirst = y == 0 && $style_lip == 0;
    ycutlast = abs(y+h-$gyy)<0.001 && $style_lip == 0;
    xcutfirst = x == 0 && $style_lip == 0;
    xcutlast = abs(x+w-$gxx)<0.001 && $style_lip == 0;
    zsmall = ($dh+h_base)/7 < 3;

    ylen = h*($gyy*l_grid+d_magic)/$gyy-d_div;
    xlen = w*($gxx*l_grid+d_magic)/$gxx-d_div;

    height = $dh;
    extent = (abs(s) > 0 && ycutfirst ? d_wall2-d_wall-d_clear : 0);
    tab = (zsmall || t == 5) ? (ycutlast?v_len_lip:0) : v_len_tab;
    ang = (zsmall || t == 5) ? (ycutlast?v_ang_lip:0) : v_ang_tab;
    cut = (zsmall || t == 5) ? (ycutlast?v_cut_lip:0) : v_cut_tab;
    style = (t > 1 && t < 5) ? t-3 : (x == 0 ? -1 : xcutlast ? 1 : 0);

    translate([0,ylen/2,h_base+h_bot])
    rotate([90,0,-90]) {

    if (!zsmall && xlen - tab_width > 4*r_f2 && (t != 0 && t != 5)) {
        fillet_cutter(3,"bisque")
        difference() {
            transform_tab(style, xlen, ((xcutfirst&&style==-1)||(xcutlast&&style==1))?v_cut_lip:0, tab_width)
            translate([ycutlast?v_cut_lip:0,0])
            profile_cutter(height-h_bot, ylen/2, s);

            if (xcutfirst)
            translate([0,0,(xlen/2-r_f2)-v_cut_lip])
            cube([ylen,height,v_cut_lip*2]);

            if (xcutlast)
            translate([0,0,-(xlen/2-r_f2)-v_cut_lip])
            cube([ylen,height,v_cut_lip*2]);
        }
        if (t != 0 && t != 5)
        fillet_cutter(2,"indigo")
        difference() {
            transform_tab(style, xlen, ((xcutfirst&&style==-1)||(xcutlast&&style==1)?v_cut_lip:0), tab_width)
            difference() {
                intersection() {
                    profile_cutter(height-h_bot, ylen-extent, s);
                    profile_cutter_tab(height-h_bot, v_len_tab, v_ang_tab);
                }
                if (ycutlast) profile_cutter_tab(height-h_bot, v_len_lip, 45);
            }

            if (xcutfirst)
            translate([ylen/2,0,xlen/2])
            rotate([0,90,0])
            transform_main(2*ylen)
            profile_cutter_tab(height-h_bot, v_len_lip, v_ang_lip);

            if (xcutlast)
            translate([ylen/2,0,-xlen/2])
            rotate([0,-90,0])
            transform_main(2*ylen)
            profile_cutter_tab(height-h_bot, v_len_lip, v_ang_lip);
        }
    }

    fillet_cutter(1,"seagreen")
    translate([0,0,xcutlast?v_cut_lip/2:0])
    translate([0,0,xcutfirst?-v_cut_lip/2:0])
    transform_main(xlen-(xcutfirst?v_cut_lip:0)-(xcutlast?v_cut_lip:0))
    translate([cut,0])
    profile_cutter(height-h_bot, ylen-extent-cut-(!s&&ycutfirst?v_cut_lip:0), s);

    fillet_cutter(0,"hotpink")
    difference() {
        transform_main(xlen)
        difference() {
            profile_cutter(height-h_bot, ylen-extent, s);

            if (!((zsmall || t == 5) && !ycutlast))
            profile_cutter_tab(height-h_bot, tab, ang);

            if (!(abs(s) > 0)&& y == 0)
            translate([ylen-extent,0,0])
            mirror([1,0,0])
            profile_cutter_tab(height-h_bot, v_len_lip, v_ang_lip);
        }

        if (xcutfirst)
        color("indigo")
        translate([ylen/2+0.001,0,xlen/2+0.001])
        rotate([0,90,0])
        transform_main(2*ylen)
        profile_cutter_tab(height-h_bot, v_len_lip, v_ang_lip);

        if (xcutlast)
        color("indigo")
        translate([ylen/2+0.001,0,-xlen/2+0.001])
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

module transform_tab(type, xlen, cut, tab_width=d_tabw) {
    mirror([0,0,type==1?1:0])
    copy_mirror([0,0,-(abs(type)-1)])
    translate([0,0,-(xlen)/2])
    translate([0,0,r_f2])
    linear_extrude((xlen-tab_width-abs(cut))/(1-(abs(type)-1))-2*r_f2)
    children();
}

module fillet_cutter(t = 0, c = "goldenrod") {
    color(c)
    minkowski() {
        children();
        sphere(r = r_f2-t/1000);
    }
}

module profile_cutter(h, l, s) {
    scoop = max(s*$dh/2-r_f2,0);
    translate([r_f2,r_f2])
    hull() {
        if (l-scoop-2*r_f2 > 0)
            square(0.1);
        if (scoop < h) {
            translate([l-2*r_f2,h-r_f2/2])
            mirror([1,1])
            square(0.1);

            translate([0,h-r_f2/2])
            mirror([0,1])
            square(0.1);
        }
        difference() {
            translate([l-scoop-2*r_f2, scoop])
            if (scoop != 0) {
                intersection() {
                    circle(scoop);
                    mirror([0,1]) square(2*scoop);
                }
            } else mirror([1,0]) square(0.1);
            translate([l-scoop-2*r_f2,-1])
            square([-(l-scoop-2*r_f2),2*h]);

            translate([0,h])
            square([2*l,scoop]);
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

module pattern_linear(x = 1, y = 1, sx = 0, sy = 0) {
    yy = sy <= 0 ? sx : sy;
    translate([-(x-1)*sx/2,-(y-1)*yy/2,0])
    for (i = [1:ceil(x)])
    for (j = [1:ceil(y)])
    translate([(i-1)*sx,(j-1)*yy,0])
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
