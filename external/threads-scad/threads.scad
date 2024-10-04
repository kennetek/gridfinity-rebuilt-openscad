// Created 2016-2017 by Ryan A. Colyer.
// This work is released with CC0 into the public domain.
// https://creativecommons.org/publicdomain/zero/1.0/
//
// https://www.thingiverse.com/thing:1686322
//
// v2.1


screw_resolution = 0.2;  // in mm


// Provides standard metric thread pitches.
function ThreadPitch(diameter) =
  (diameter <= 64) ?
    lookup(diameter, [
      [2, 0.4],
      [2.5, 0.45],
      [3, 0.5],
      [4, 0.7],
      [5, 0.8],
      [6, 1.0],
      [7, 1.0],
      [8, 1.25],
      [10, 1.5],
      [12, 1.75],
      [14, 2.0],
      [16, 2.0],
      [18, 2.5],
      [20, 2.5],
      [22, 2.5],
      [24, 3.0],
      [27, 3.0],
      [30, 3.5],
      [33, 3.5],
      [36, 4.0],
      [39, 4.0],
      [42, 4.5],
      [48, 5.0],
      [52, 5.0],
      [56, 5.5],
      [60, 5.5],
      [64, 6.0]
    ]) :
    diameter * 6.0 / 64;


// Provides standard metric hex head widths across the flats.
function HexAcrossFlats(diameter) =
  (diameter <= 64) ?
    lookup(diameter, [
      [2, 4],
      [2.5, 5],
      [3, 5.5],
      [3.5, 6],
      [4, 7],
      [5, 8],
      [6, 10],
      [7, 11],
      [8, 13],
      [10, 16],
      [12, 18],
      [14, 21],
      [16, 24],
      [18, 27],
      [20, 30],
      [22, 34],
      [24, 36],
      [27, 41],
      [30, 46],
      [33, 50],
      [36, 55],
      [39, 60],
      [42, 65],
      [48, 75],
      [52, 80],
      [56, 85],
      [60, 90],
      [64, 95]
    ]) :
    diameter * 95 / 64;

// Provides standard metric hex head widths across the corners.
function HexAcrossCorners(diameter) =
  HexAcrossFlats(diameter) / cos(30);


// Provides standard metric hex (Allen) drive widths across the flats.
function HexDriveAcrossFlats(diameter) =
  (diameter <= 64) ?
    lookup(diameter, [
      [2, 1.5],
      [2.5, 2],
      [3, 2.5],
      [3.5, 3],
      [4, 3],
      [5, 4],
      [6, 5],
      [7, 5],
      [8, 6],
      [10, 8],
      [12, 10],
      [14, 12],
      [16, 14],
      [18, 15],
      [20, 17],
      [22, 18],
      [24, 19],
      [27, 20],
      [30, 22],
      [33, 24],
      [36, 27],
      [39, 30],
      [42, 32],
      [48, 36],
      [52, 36],
      [56, 41],
      [60, 42],
      [64, 46]
    ]) :
    diameter * 46 / 64;

// Provides standard metric hex (Allen) drive widths across the corners.
function HexDriveAcrossCorners(diameter) =
  HexDriveAcrossFlats(diameter) / cos(30);

// Provides metric countersunk hex (Allen) drive widths across the flats.
function CountersunkDriveAcrossFlats(diameter) =
  (diameter <= 14) ?
    HexDriveAcrossFlats(HexDriveAcrossFlats(diameter)) :
    round(0.6*diameter);

// Provides metric countersunk hex (Allen) drive widths across the corners.
function CountersunkDriveAcrossCorners(diameter) =
  CountersunkDriveAcrossFlats(diameter) / cos(30);

// Provides standard metric nut thickness.
function NutThickness(diameter) =
  (diameter <= 64) ?
    lookup(diameter, [
      [2, 1.6],
      [2.5, 2],
      [3, 2.4],
      [3.5, 2.8],
      [4, 3.2],
      [5, 4.7],
      [6, 5.2],
      [7, 6.0],
      [8, 6.8],
      [10, 8.4],
      [12, 10.8],
      [14, 12.8],
      [16, 14.8],
      [18, 15.8],
      [20, 18.0],
      [22, 21.1],
      [24, 21.5],
      [27, 23.8],
      [30, 25.6],
      [33, 28.7],
      [36, 31.0],
      [42, 34],
      [48, 38],
      [56, 45],
      [64, 51]
    ]) :
    diameter * 51 / 64;


// This generates a closed polyhedron from an array of arrays of points,
// with each inner array tracing out one loop outlining the polyhedron.
// pointarrays should contain an array of N arrays each of size P outlining a
// closed manifold.  The points must obey the right-hand rule.  For example,
// looking down, the P points in the inner arrays are counter-clockwise in a
// loop, while the N point arrays increase in height.  Points in each inner
// array do not need to be equal height, but they usually should not meet or
// cross the line segments from the adjacent points in the other arrays.
// (N>=2, P>=3)
// Core triangles:
//   [j][i], [j+1][i], [j+1][(i+1)%P]
//   [j][i], [j+1][(i+1)%P], [j][(i+1)%P]
//   Then triangles are formed in a loop with the middle point of the first
//   and last array.
module ClosePoints(pointarrays) {
  function recurse_avg(arr, n=0, p=[0,0,0]) = (n>=len(arr)) ? p :
    recurse_avg(arr, n+1, p+(arr[n]-p)/(n+1));

  N = len(pointarrays);
  P = len(pointarrays[0]);
  NP = N*P;
  lastarr = pointarrays[N-1];
  midbot = recurse_avg(pointarrays[0]);
  midtop = recurse_avg(pointarrays[N-1]);

  faces_bot = [
    for (i=[0:P-1])
      [0,i+1,1+(i+1)%len(pointarrays[0])]
  ];

  loop_offset = 1;
  bot_len = loop_offset + P;

  faces_loop = [
    for (j=[0:N-2], i=[0:P-1], t=[0:1])
      [loop_offset, loop_offset, loop_offset] + (t==0 ?
      [j*P+i, (j+1)*P+i, (j+1)*P+(i+1)%P] :
      [j*P+i, (j+1)*P+(i+1)%P, j*P+(i+1)%P])
  ];

  top_offset = loop_offset + NP - P;
  midtop_offset = top_offset + P;

  faces_top = [
    for (i=[0:P-1])
      [midtop_offset,top_offset+(i+1)%P,top_offset+i]
  ];

  points = [
    for (i=[-1:NP])
      (i<0) ? midbot :
      ((i==NP) ? midtop :
      pointarrays[floor(i/P)][i%P])
  ];
  faces = concat(faces_bot, faces_loop, faces_top);

  polyhedron(points=points, faces=faces);
}



// This creates a vertical rod at the origin with external threads.  It uses
// metric standards by default.
module ScrewThread(outer_diam, height, pitch=0, tooth_angle=30, tolerance=0.4, tip_height=0, tooth_height=0, tip_min_fract=0) {

  pitch = (pitch==0) ? ThreadPitch(outer_diam) : pitch;
  tooth_height = (tooth_height==0) ? pitch : tooth_height;
  tip_min_fract = (tip_min_fract<0) ? 0 :
    ((tip_min_fract>0.9999) ? 0.9999 : tip_min_fract);

  outer_diam_cor = outer_diam + 0.25*tolerance; // Plastic shrinkage correction
  inner_diam = outer_diam - tooth_height/tan(tooth_angle);
  or = (outer_diam_cor < screw_resolution) ?
    screw_resolution/2 : outer_diam_cor / 2;
  ir = (inner_diam < screw_resolution) ? screw_resolution/2 : inner_diam / 2;
  height = (height < screw_resolution) ? screw_resolution : height;

  steps_per_loop_try = ceil(2*3.14159265359*or / screw_resolution);
  steps_per_loop = (steps_per_loop_try < 4) ? 4 : steps_per_loop_try;
  hs_ext = 3;
  hsteps = ceil(3 * height / pitch) + 2*hs_ext;

  extent = or - ir;

  tip_start = height-tip_height;
  tip_height_sc = tip_height / (1-tip_min_fract);

  tip_height_ir = (tip_height_sc > tooth_height/2) ?
    tip_height_sc - tooth_height/2 : tip_height_sc;

  tip_height_w = (tip_height_sc > tooth_height) ? tooth_height : tip_height_sc;
  tip_wstart = height + tip_height_sc - tip_height - tip_height_w;


  function tooth_width(a, h, pitch, tooth_height, extent) =
    let(
      ang_full = h*360.0/pitch-a,
      ang_pn = atan2(sin(ang_full), cos(ang_full)),
      ang = ang_pn < 0 ? ang_pn+360 : ang_pn,
      frac = ang/360,
      tfrac_half = tooth_height / (2*pitch),
      tfrac_cut = 2*tfrac_half
    )
    (frac > tfrac_cut) ? 0 : (
      (frac <= tfrac_half) ?
        ((frac / tfrac_half) * extent) :
        ((1 - (frac - tfrac_half)/tfrac_half) * extent)
    );


  pointarrays = [
    for (hs=[0:hsteps])
      [
        for (s=[0:steps_per_loop-1])
          let(
            ang_full = s*360.0/steps_per_loop,
            ang_pn = atan2(sin(ang_full), cos(ang_full)),
            ang = ang_pn < 0 ? ang_pn+360 : ang_pn,

            h_fudge = pitch*0.001,

            h_mod =
              (hs%3 == 2) ?
                ((s == steps_per_loop-1) ? tooth_height - h_fudge : (
                 (s == steps_per_loop-2) ? tooth_height/2 : 0)) : (
              (hs%3 == 0) ?
                ((s == steps_per_loop-1) ? pitch-tooth_height/2 : (
                 (s == steps_per_loop-2) ? pitch-tooth_height + h_fudge : 0)) :
                ((s == steps_per_loop-1) ? pitch-tooth_height/2 + h_fudge : (
                 (s == steps_per_loop-2) ? tooth_height/2 : 0))
              ),

            h_level =
              (hs%3 == 2) ? tooth_height - h_fudge : (
              (hs%3 == 0) ? 0 : tooth_height/2),

            h_ub = floor((hs-hs_ext)/3) * pitch
              + h_level + ang*pitch/360.0 - h_mod,
            h_max = height - (hsteps-hs) * h_fudge,
            h_min = hs * h_fudge,
            h = (h_ub < h_min) ? h_min : ((h_ub > h_max) ? h_max : h_ub),

            ht = h - tip_start,
            hf_ir = ht/tip_height_ir,
            ht_w = h - tip_wstart,
            hf_w_t = ht_w/tip_height_w,
            hf_w = (hf_w_t < 0) ? 0 : ((hf_w_t > 1) ? 1 : hf_w_t),

            ext_tip = (h <= tip_wstart) ? extent : (1-hf_w) * extent,
            wnormal = tooth_width(ang, h, pitch, tooth_height, ext_tip),
            w = (h <= tip_wstart) ? wnormal :
              (1-hf_w) * wnormal +
              hf_w * (0.1*screw_resolution + (wnormal * wnormal * wnormal /
                (ext_tip*ext_tip+0.1*screw_resolution))),
            r = (ht <= 0) ? ir + w :
              ( (ht < tip_height_ir ? ((2/(1+(hf_ir*hf_ir))-1) * ir) : 0) + w)
          )
          [r*cos(ang), r*sin(ang), h]
      ]
  ];


  ClosePoints(pointarrays);
}


// This creates a vertical rod at the origin with external auger-style
// threads.
module AugerThread(outer_diam, inner_diam, height, pitch, tooth_angle=30, tolerance=0.4, tip_height=0, tip_min_fract=0) {
  tooth_height = tan(tooth_angle)*(outer_diam-inner_diam);
  ScrewThread(outer_diam, height, pitch, tooth_angle, tolerance, tip_height,
    tooth_height, tip_min_fract);
}


// This creates a threaded hole in its children using metric standards by
// default.
module ScrewHole(outer_diam, height, position=[0,0,0], rotation=[0,0,0], pitch=0, tooth_angle=30, tolerance=0.4, tooth_height=0) {
  extra_height = 0.001 * height;

  difference() {
    children();
    translate(position)
      rotate(rotation)
      translate([0, 0, -extra_height/2])
      ScrewThread(1.01*outer_diam + 1.25*tolerance, height + extra_height,
        pitch, tooth_angle, tolerance, tooth_height=tooth_height);
  }
}


// This creates an auger-style threaded hole in its children.
module AugerHole(outer_diam, inner_diam, height, pitch, position=[0,0,0], rotation=[0,0,0], tooth_angle=30, tolerance=0.4) {
  tooth_height = tan(tooth_angle)*(outer_diam-inner_diam);
  ScrewHole(outer_diam, height, position, rotation, pitch, tooth_angle,
    tolerance, tooth_height=tooth_height) children();
}


// This inserts a ClearanceHole in its children.
// The rotation vector is applied first, then the position translation,
// starting from a position upward from the z-axis at z=0.
module ClearanceHole(diameter, height, position=[0,0,0], rotation=[0,0,0], tolerance=0.4) {
  extra_height = 0.001 * height;

  difference() {
    children();
    translate(position)
      rotate(rotation)
      translate([0, 0, -extra_height/2])
      cylinder(h=height + extra_height, r=(diameter/2+tolerance));
  }
}


// This inserts a ClearanceHole with a recessed bolt hole in its children.
// The rotation vector is applied first, then the position translation,
// starting from a position upward from the z-axis at z=0.  The default
// recessed parameters fit a standard metric bolt.
module RecessedClearanceHole(diameter, height, position=[0,0,0], rotation=[0,0,0], recessed_diam=-1, recessed_height=-1, tolerance=0.4) {
  recessed_diam = (recessed_diam < 0) ?
    HexAcrossCorners(diameter) : recessed_diam;
  recessed_height = (recessed_height < 0) ? diameter : recessed_height;
  extra_height = 0.001 * height;

  difference() {
    children();
    translate(position)
      rotate(rotation)
      translate([0, 0, -extra_height/2])
      cylinder(h=height + extra_height, r=(diameter/2+tolerance));
    translate(position)
      rotate(rotation)
      translate([0, 0, -extra_height/2])
      cylinder(h=recessed_height + extra_height/2,
        r=(recessed_diam/2+tolerance));
  }
}


// This inserts a countersunk ClearanceHole in its children.
// The rotation vector is applied first, then the position translation,
// starting from a position upward from the z-axis at z=0.
// The countersunk side is on the bottom by default.
module CountersunkClearanceHole(diameter, height, position=[0,0,0], rotation=[0,0,0], sinkdiam=0, sinkangle=45, tolerance=0.4) {
  extra_height = 0.001 * height;
  sinkdiam = (sinkdiam==0) ? 2*diameter : sinkdiam;
  sinkheight = ((sinkdiam-diameter)/2)/tan(sinkangle);

  difference() {
    children();
    translate(position)
      rotate(rotation)
      translate([0, 0, -extra_height/2])
      union() {
        cylinder(h=height + extra_height, r=(diameter/2+tolerance));
        cylinder(h=sinkheight + extra_height, r1=(sinkdiam/2+tolerance), r2=(diameter/2+tolerance), $fn=24*diameter);
      }
  }
}


// This inserts a Phillips tip shaped hole into its children.
// The rotation vector is applied first, then the position translation,
// starting from a position upward from the z-axis at z=0.
module PhillipsTip(width=7, thickness=0, straightdepth=0, position=[0,0,0], rotation=[0,0,0]) {
  thickness = (thickness <= 0) ? width*2.5/7 : thickness;
  straightdepth = (straightdepth <= 0) ? width*3.5/7 : straightdepth;
  angledepth = (width-thickness)/2;
  height = straightdepth + angledepth;
  extra_height = 0.001 * height;

  difference() {
    children();
    translate(position)
      rotate(rotation)
      union() {
        hull() {
          translate([-width/2, -thickness/2, -extra_height/2])
            cube([width, thickness, straightdepth+extra_height]);
          translate([-thickness/2, -thickness/2, height-extra_height])
            cube([thickness, thickness, extra_height]);
        }
        hull() {
          translate([-thickness/2, -width/2, -extra_height/2])
            cube([thickness, width, straightdepth+extra_height]);
          translate([-thickness/2, -thickness/2, height-extra_height])
            cube([thickness, thickness, extra_height]);
        }
      }
  }
}



// Create a standard sized metric bolt with hex head and hex key.
module MetricBolt(diameter, length, tolerance=0.4) {
  drive_tolerance = pow(3*tolerance/HexDriveAcrossCorners(diameter),2)
    + 0.75*tolerance;

  difference() {
    cylinder(h=diameter, r=(HexAcrossCorners(diameter)/2-0.5*tolerance), $fn=6);
    cylinder(h=diameter,
      r=(HexDriveAcrossCorners(diameter)+drive_tolerance)/2, $fn=6,
      center=true);
  }
  translate([0,0,diameter-0.01])
    ScrewThread(diameter, length+0.01, tolerance=tolerance,
      tip_height=ThreadPitch(diameter), tip_min_fract=0.75);
}


// Create a standard sized metric countersunk (flat) bolt with hex key drive.
// In compliance with convention, the length for this includes the head.
module MetricCountersunkBolt(diameter, length, tolerance=0.4) {
  drive_tolerance = pow(3*tolerance/CountersunkDriveAcrossCorners(diameter),2)
    + 0.75*tolerance;

  difference() {
    cylinder(h=diameter/2, r1=diameter, r2=diameter/2, $fn=24*diameter);
    cylinder(h=0.8*diameter,
      r=(CountersunkDriveAcrossCorners(diameter)+drive_tolerance)/2, $fn=6,
      center=true);
  }
  translate([0,0,diameter/2-0.01])
    ScrewThread(diameter, length-diameter/2+0.01, tolerance=tolerance,
      tip_height=ThreadPitch(diameter), tip_min_fract=0.75);
}


// Create a standard sized metric countersunk (flat) bolt with hex key drive.
// In compliance with convention, the length for this includes the head.
module MetricWoodScrew(diameter, length, tolerance=0.4) {
  drive_tolerance = pow(3*tolerance/CountersunkDriveAcrossCorners(diameter),2)
    + 0.75*tolerance;

  PhillipsTip(diameter-2)
    union() {
      cylinder(h=diameter/2, r1=diameter, r2=diameter/2, $fn=24*diameter);

      translate([0,0,diameter/2-0.01])
        ScrewThread(diameter, length-diameter/2+0.01, tolerance=tolerance,
          tip_height=diameter);
    }
}


// Create a standard sized metric hex nut.
module MetricNut(diameter, thickness=0, tolerance=0.4) {
  thickness = (thickness==0) ? NutThickness(diameter) : thickness;
  ScrewHole(diameter, thickness, tolerance=tolerance)
    cylinder(h=thickness, r=HexAcrossCorners(diameter)/2-0.5*tolerance, $fn=6);
}


// Create a convenient washer size for a metric nominal thread diameter.
module MetricWasher(diameter) {
  difference() {
    cylinder(h=diameter/5, r=1.15*diameter, $fn=24*diameter);
    cylinder(h=2*diameter, r=0.575*diameter, $fn=12*diameter, center=true);
  }
}


// Solid rod on the bottom, external threads on the top.
module RodStart(diameter, height, thread_len=0, thread_diam=0, thread_pitch=0) {
  // A reasonable default.
  thread_diam = (thread_diam==0) ? 0.75*diameter : thread_diam;
  thread_len = (thread_len==0) ? 0.5*diameter : thread_len;
  thread_pitch = (thread_pitch==0) ? ThreadPitch(thread_diam) : thread_pitch;

  cylinder(r=diameter/2, h=height, $fn=24*diameter);

  translate([0, 0, height])
    ScrewThread(thread_diam, thread_len, thread_pitch,
      tip_height=thread_pitch, tip_min_fract=0.75);
}


// Solid rod on the bottom, internal threads on the top.
// Flips around x-axis after printing to pair with RodStart.
module RodEnd(diameter, height, thread_len=0, thread_diam=0, thread_pitch=0) {
  // A reasonable default.
  thread_diam = (thread_diam==0) ? 0.75*diameter : thread_diam;
  thread_len = (thread_len==0) ? 0.5*diameter : thread_len;
  thread_pitch = (thread_pitch==0) ? ThreadPitch(thread_diam) : thread_pitch;

  ScrewHole(thread_diam, thread_len, [0, 0, height], [180,0,0], thread_pitch)
    cylinder(r=diameter/2, h=height, $fn=24*diameter);
}


// Internal threads on the bottom, external threads on the top.
module RodExtender(diameter, height, thread_len=0, thread_diam=0, thread_pitch=0) {
  // A reasonable default.
  thread_diam = (thread_diam==0) ? 0.75*diameter : thread_diam;
  thread_len = (thread_len==0) ? 0.5*diameter : thread_len;
  thread_pitch = (thread_pitch==0) ? ThreadPitch(thread_diam) : thread_pitch;

  max_bridge = height - thread_len;
  // Use 60 degree slope if it will fit.
  bridge_height = ((thread_diam/4) < max_bridge) ? thread_diam/4 : max_bridge;

  difference() {
    union() {
      ScrewHole(thread_diam, thread_len, pitch=thread_pitch)
        cylinder(r=diameter/2, h=height, $fn=24*diameter);

      translate([0,0,height])
        ScrewThread(thread_diam, thread_len, pitch=thread_pitch,
          tip_height=thread_pitch, tip_min_fract=0.75);
    }
    // Carve out a small conical area as a bridge.
    translate([0,0,thread_len])
      cylinder(h=bridge_height, r1=thread_diam/2, r2=0.1);
  }
}


// Produces a matching set of metric bolts, nuts, and washers.
module MetricBoltSet(diameter, length, quantity=1) {
  for (i=[0:quantity-1]) {
    translate([0, i*4*diameter, 0]) MetricBolt(diameter, length);
    translate([4*diameter, i*4*diameter, 0]) MetricNut(diameter);
    translate([8*diameter, i*4*diameter, 0]) MetricWasher(diameter);
  }
}


module Demo() {
  translate([0,-0,0]) MetricBoltSet(3, 8);
  translate([0,-20,0]) MetricBoltSet(4, 8);
  translate([0,-40,0]) MetricBoltSet(5, 8);
  translate([0,-60,0]) MetricBoltSet(6, 8);
  translate([0,-80,0]) MetricBoltSet(8, 8);

  translate([0,25,0]) MetricCountersunkBolt(5, 10);
  translate([23,18,5])
    scale([1,1,-1])
    CountersunkClearanceHole(5, 8, [7,7,0], [0,0,0])
    cube([14, 14, 5]);

  translate([70, -10, 0])
    RodStart(20, 30);
  translate([70, 20, 0])
    RodEnd(20, 30);

  translate([70, -45, 0])
    MetricWoodScrew(8, 20);

  translate([12, 50, 0])
    union() {
      translate([0, 0, 5.99])
        AugerThread(15, 3.5, 22, 7, tooth_angle=15, tip_height=7);
      translate([-4, -9, 0]) cube([8, 18, 6]);
    }
}


Demo();

//MetricBoltSet(6, 8, 10);

