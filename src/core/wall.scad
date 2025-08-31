/**
 * @file
 * @brief Functions to create the wall for a Gridfinity bin.
 * @details Has a stacking lip based on https://gridfinity.xyz/specification/
 */

include <standard.scad>
use <../helpers/generic-helpers.scad>
use <../helpers/angles.scad>
use <../helpers/list.scad>
use <../helpers/shapes.scad>

$debug = false;
$test_wall = true;
$fa = 1;
$fs = 0.1; // .01

/*
 * @brief Render a wall of the given size, with a stacking lip.
 * @details Centered on x, y origin.  Bottom is at z == 0.
 *          Adds ~STACKING_LIP_HEIGHT to the height of the bin.
 *          Top is rounded, which reduces the height a bit.
 * @param size [x, y, z] Size of the stacking lip. In mm.
 */
module render_wall(size) {
    assert(
        is_valid_3d(size)
        && size.x > 0
        && size.y > 0
        && size.z >= 0
    );

    grid_size_mm = as_2d(size);

    color("royalblue")
    sweep_rounded(foreach_add(grid_size_mm, -2*BASE_TOP_RADIUS))
    _profile_wall(size.z);

    // Wall below the stacking lip.
    color("orange")
    linear_extrude(size.z)
    difference() {
        rounded_square(grid_size_mm, BASE_TOP_RADIUS, center=true);
        rounded_square(grid_size_mm-2*as_2d(d_wall), BASE_TOP_RADIUS, center=true);
    }
}

/**
 * @brief Get the height of the stacking lip portion.
 * @details This takes the radius into account.
 * @returns The actual height, not nominal.
 */
function stacking_lip_height() =
    let(filleted_line = radius_line_edge(STACKING_LIP, 3, STACKING_LIP_FILLET_RADIUS))
    max([for(l=filleted_line) l.y]);

/**
 * @brief Internal function. Do not use directly.
 * @details If index is first or last element, wraps around.
 *          Also handles common case of first and last points being equal.
 * @param line A list of 2d points.
 * @param index Which point to determine the index of.
 * @returns 2d points before, at, and after.
 */
function _index_to_points(line, index) =
    assert(is_list(line) && len(line) >= 3)
    let(last_index = len(line) - 1)
    assert(is_num(index)
        && index >= 0
        && index <= len(line) - 1)
    let(first_point =
        line[0] != line[last_index] ? line[0]
        : line[1])
    let(last_point =
        line[0] != line[last_index] ? line[last_index]
        : line[last_index-1])
    [
        index==0 ? last_point : line[index-1],  // Before
        line[index], // At
        index==last_index ? first_point
            : line[index+1]  // After
    ];

module _test_index_to_points() {
    square_line = [
        [0, 0],
        [2, 0],
        [2, 2],
        [0, 2],
        [0, 0]
    ];
    assert(_index_to_points(square_line, 0) == [
        [0, 2],
        [0, 0],
        [2, 0],
    ]);
    assert(_index_to_points(square_line, 1) == [
        [0, 0],
        [2, 0],
        [2, 2],
    ]);
    assert(_index_to_points(square_line, 2) == [
        [2, 0],
        [2, 2],
        [0, 2],
    ]);
    assert(_index_to_points(square_line, 3) == [
        [2, 2],
        [0, 2],
        [0, 0]
    ]);
    assert(_index_to_points(square_line, 4) == [
        [0, 2],
        [0, 0],
        [2, 0],
    ]);
}

/**
 * @brief Determine the angle between two lines.
 * @param line A list of 2d points.
 * @param index Which point to determine the index of.
 * @returns -360 to +360.
 */
function point_angle(line, index) =
    let(points = _index_to_points(line, index))
    let(vectors = [
//        points[1] - points[0],  // at - before
        points[0] - points[1],  // before - at
        points[2] - points[1],  // after - at
//        points[1] - points[2],  // at - after
    ])
    atan2(
        cross(vectors[0], vectors[1]),
        vectors[0] * vectors[1]
    );

/**
 * @brief Radius a point along a line.
 * @details Replace 2D edge with a radius.
 *          Method used: tangent, tangent, radius algorithm.
 * @see https://math.stackexchange.com/questions/797828/calculate-center-of-circle-tangent-to-two-lines-in-space
 * @param line A list of points.
 * @param index The point within the line to have a radius applied to it.
 * @param radius The radius to apply.
 * @returns A line with the given point replaced by a semi-circle.
 */
function radius_line_edge(line, index, radius) =
    assert(is_list(line) && len(line) >= 3)
    assert(is_num(index)
        && index >= 0
        && index <= len(line) - 1)
    assert(is_num(radius) && radius > 0)
    let(points = _index_to_points(line, index))
    let(point = points[1])
    let(vectors = [
        points[1] - points[0],  // at - before
        [1, 0] // circle_fragment starts here.
    ])
    // Can be used to determine clockwise or counter clockwise line drawing direction.
    let(angle = point_angle(line, index))
    let(p_angle = positive_angle(angle))
    let(start_angle=atan2(
            cross(vectors[0], vectors[1]),
            vectors[1] * vectors[0]
        ))
    let(psa=positive_angle(start_angle))
    let(sweep_start=sign(angle)*90-psa)

    // Distance from tip to the center point of the circle.
    let(distance_from_edge = radius / sin(abs(angle)/2))
    // Standard line rotation function.
    // [x′,y′]=[x*cosθ-y*sinθ, x*sinθ+y*cosθ]
    let(v=vector_as_unit(vectors[0]))
    let(center_offset = [
        v.x*cos(angle/2) - v.y*sin(angle/2),
        v.x*sin(angle/2) + v.y*cos(angle/2)
    ])
    let(circle_center_point = point - distance_from_edge * center_offset)

//    let(_ = !$debug ? $debug :
//    echo("DEBUG: ---- radius_line_edge ----\n",
//        angle=angle, "\n",
//        p_angle=p_angle, "\n",
//        point=point, "\n",
//        distance_from_edge=distance_from_edge, "\n",
//        center_offset=center_offset, "\n",
//        circle_center_point=circle_center_point, "\n",
//        intersection_distance = center_offset.y, "\n",
//        v0 = vectors[0], "\n",
//        v1 = vectors[1], "\n",
//        start_angle=start_angle, "\n",
//        psa = psa, "\n",
//        sweep_start = sweep_start, "\n",
//    ) $debug)

    let(semicircle = circle_fragment(radius, sweep_start, -sign(angle)*abs(normalize_angle(3*angle))))
//    let(semicircle = [[0,0]])

    let(translated_semicircle = foreach_add(semicircle, circle_center_point))
    //Replace the point with multiple additional points
    concat(
        [for(i=[0:index-1]) line[i]],
        translated_semicircle,
        [for(i=[index+1:len(line)-1]) line[i]]
    );

/**
 * @brief Internal function. Do not use directly.
 * @details Stacking lip with a with a filleted (rounded) top.
 * @details Based on https://gridfinity.xyz/specification/
 *          Also includes a support base.
 */
module _stacking_lip_filleted() {
    filleted_line = radius_line_edge(STACKING_LIP, 3, STACKING_LIP_FILLET_RADIUS);
    polygon(filleted_line);
}

/**
 * @brief A line representing part of a circle.
 * @param radius
 * @param start_angle Where to start the line. In degrees.
 *        0: +X axis.
 *        90: +Y axis
 * @param sweep_by How many degrees the circle should be swept by.
 *        In degrees.  Examples:
 *        -90: Quarter Circle (clockwise)
 *        90: Quarter Circle (counter clockwise)
 *        360: Full Circle
 * @returns A list of points.
 */
function circle_fragment(radius, start_angle=0, sweep_by=360) =
    assert(is_num(radius) && radius > 0)
    assert(is_num(start_angle))
    assert(is_num(sweep_by)
        && sweep_by != 0
        && abs(sweep_by) <= 360)

    let(real_start_angle=start_angle%360)
    let(end_angle = real_start_angle + sweep_by)
    let(fragments = get_fragments_from_r(radius))
    let(degrees_per_fragment = 360/fragments * sign(sweep_by))
//    echo(str("\n",
//        "start_angle=", end_angle, "\n",
//        "real_start_angle=", real_start_angle, "\n",
//        "sweep_by=", sweep_by, "\n",
//        "end_angle=", end_angle, "\n",
//    ))
    [ for (i = [real_start_angle:degrees_per_fragment:end_angle])
        [cos(i), sin(i)] * radius
    ];

/**
 * @brief External wall profile, with a stacking lip.
 * @details Translated so a 90 degree rotation produces the expected outside radius.
 *          Limited to prevent protrusion at low heights.
 * @param height_mm Height of the wall.  Excludes STACKING_LIP_HEIGHT, but **includes** STACKING_LIP_SUPPORT_HEIGHT.
 */
module _profile_wall(height_mm) {
    assert(is_num(height_mm)  && height_mm >=0 );

    filleted_line = radius_line_edge(STACKING_LIP, 3, STACKING_LIP_FILLET_RADIUS);

    line = [
        for(l=filleted_line) [
            l.x + BASE_TOP_RADIUS - STACKING_LIP_SIZE.x,
            max(l.y+height_mm, 0)
        ]
    ];
    polygon(line);
}

module visualize_line(line, print=false) {
    assert(is_list(line) && len(line) > 0);
    assert(is_bool(print));
    seed=0;
    size = len(line)-1;
    new_line = [ for(i=[size:-1:0])
        line[i] + rands(-0.01, 0.01, 2, seed) ];
    final_points = concat(line, new_line);

    if(print) {
        for(i=[0:len(final_points)-1]) {
            echo(str(i, ":", final_points[i]));
        }
    }
    polygon(final_points);
}

if($test_wall) {
    t_square=true;
    t_diamond=true;

//    render_wall([42, 42, 7]);

    translate([2, 2.95147]){
    color("red", alpha=0.1)
    circle(r=0.6);
    circle(r=0.05);
    }

    _test_index_to_points();

    line = circle_fragment(1, 45, -20);
    t_line=[for(l=line) as_2d(concat(l,0,0) * affine_rotate([0, 0, 90]))];
    visualize_line(t_line);

    translate([0, 10, 0])
    _stacking_lip_filleted();

    translate([-10, 0, 0])
    _profile_wall(0);
    translate([-5, 0, 0])
    _profile_wall(10);

    color("blue")
    translate([0, 0, 0])
    visualize_line(STACKING_LIP);
    s_line = radius_line_edge(STACKING_LIP, 3, STACKING_LIP_FILLET_RADIUS);
    visualize_line(s_line);

    color("blue")
    translate([-5, 0, 0])
    visualize_line(reverse(STACKING_LIP));
    s_liner = radius_line_edge(reverse(STACKING_LIP), 2, STACKING_LIP_FILLET_RADIUS);
    translate([-5, 0, 0])
    visualize_line(s_liner);

    if(t_square) {
    square_line = [
        [0, 0],
        [2, 0],
        [2, 2],
        [0, 2],
        [0, 0]
    ];
    sll = len(square_line) - 1;

    translate([5, 0, 0]) {
        visualize_line(square_line);
        translate([0, -3, 0])
        visualize_line(reverse(square_line));
    }

    // Top Right
    translate([9, 0, 0]) {
        visualize_line(radius_line_edge(square_line, 2, 0.5), false);
        translate([0, -3, 0])
        visualize_line(radius_line_edge(reverse(square_line), sll-2, 0.5), false);
    }

    // Bottom Right
    translate([13, 0, 0]) {
        visualize_line(radius_line_edge(square_line, 1, 0.5), false);
        translate([0, -3, 0])
        visualize_line(radius_line_edge(reverse(square_line), sll-1, 0.5), false);
    }

    // Top Left
    translate([17, 0, 0]) {
        visualize_line(radius_line_edge(square_line, 3, 0.5), false);
        translate([0, -3, 0])
        visualize_line(radius_line_edge(reverse(square_line), sll-3, 0.5), false);
    }

    // Bottom Left
    translate([21, 0, 0]) {
        visualize_line(radius_line_edge(square_line, 0, 0.5), false);
        translate([0, -3, 0])
        visualize_line(radius_line_edge(reverse(square_line), sll-4, 0.5), false);
    }
    }

    if(t_diamond) {
    diamond_line = [
        [0, 0],
        [1, -1],
        [2, 0],
        [1, 1],
        [0, 0]
    ];
    dll = len(diamond_line) - 1;

    for(i=[0:4]) {
        color("blue")
        translate([5+i*4, 7.1, 0]) {
            visualize_line(diamond_line);
            translate([0, -3, 0])
            visualize_line(reverse(diamond_line));
        }
    }

    // Bottom Center
    translate([9, 7, 0]) {
        visualize_line(radius_line_edge(diamond_line, 1, 0.5));
        translate([0, -3, 0])
        visualize_line(radius_line_edge(reverse(diamond_line), dll-1, 0.5));
    }

    // Center Right
    translate([13, 7, 0]) {
        visualize_line(radius_line_edge(diamond_line, 2, 0.5));
        translate([0, -3, 0])
        visualize_line(radius_line_edge(reverse(diamond_line), dll-2, 0.5));
    }

    // Top Center
    translate([17, 7, 0]) {
        visualize_line(radius_line_edge(diamond_line, 3, 0.5));
        translate([0, -3, 0])
        visualize_line(radius_line_edge(reverse(diamond_line), dll-3, 0.5));
    }

    // Center Left
    translate([21, 7, 0]) {
        visualize_line(radius_line_edge(diamond_line, 4, 0.5));
        translate([0, -3, 0])
        visualize_line(radius_line_edge(reverse(diamond_line), dll-4, 0.5));
    }
    }
}
