/**
 * @file grid.scad
 * @brief 2d grid object.  Used to either create a pattern or to subdivide a larger object.
 */

use <grid_element.scad>

_is_valid_perimeter = function(element_dimensions, perimeter)
    assert(is_list(element_dimensions))
    let(rank=len(element_dimensions))
    is_undef(perimeter) || (
    is_list(perimeter)
    && len(perimeter) == 2 * rank
    // None match the condition.
    && min([for(i=[0:rank-1])
        perimeter[i] + perimeter[i+rank] < element_dimensions[i]
        || (element_dimensions[i] ==0
            && perimeter[i] + perimeter[i+rank] == 0
        ) ? 1 : 0]) != 0
    );

/**
 * @brief Create a pattern of 2d elements.
 * @description Each element is the given size.
 *     The total size is the sum of all elements minus the perimiter.
 *     Perimeter exists to allow a specific spacing between elements, while reducing the overall size.
 *     When perimeter is set, the outer elements dimensions are reduced.
 * @param num_elements [x, y] Number of elements to create.
 * @param @param element_dimensions [length, width] of a single element.
 * @param center Center the entire grid.
 *               Otherwise grid starts at bottom left corner.
 *               Determines the [0, 0] position grid_elements use.
 * @param perimeter [-x, -y, +x, +y, ...]
 *     **Subtracted** from the outer element edges.
 *     Each item represents a side.
 *     Always 2 * len(element_dimensions) items..
 *     Bottom left position is always **outside** the perimeter.
 * @returns An opaque "grid" object.
 */
function new_grid(
    num_elements,
    element_dimensions,
    center=false,
    perimeter=undef
    ) =
    assert(is_list(num_elements)
        && len(num_elements) >= 2
        && min(num_elements) >= 0)
    assert(is_list(element_dimensions)
        && len(element_dimensions) == len(num_elements)
        && min(element_dimensions) >= 0)
    assert(is_bool(center))
    assert(_is_valid_perimeter(element_dimensions, perimeter),
    str("perimeter must have ", len(element_dimensions) * 2," items, and must be smaller than an element."))
    [
        "grid_struct",
        num_elements,
        element_dimensions,
        center,
        !is_undef(perimeter) ? perimeter
            : [for(i=[0:2*len(element_dimensions)-1]) 0]
    ];

/**
 * @brief Subdivide a 2d square into grid of child elements.
 * @param total_dimensions [length, width] of the entire grid.
 * @see new_grid for all other parameters.
 * @returns An opaque "grid" object.
*/
function grid_from_total(
    num_elements,
    total_dimensions,
    center=false,
    perimeter=undef
    ) =
    assert(is_list(num_elements)
        && len(num_elements) >= 2
        && min(num_elements) >= 0)
    assert(is_list(total_dimensions)
        && len(total_dimensions) == len(num_elements)
        && min(total_dimensions) >= 0)
    let(element_dimensions = [
        for(d=[0:len(num_elements)-1])
        num_elements[d] == 0 ? 1
        : total_dimensions[d] / num_elements[d]
    ])
    new_grid(num_elements, element_dimensions, center, perimeter);

/**
 * @brief Create a new grid from an existing one.  Overriding parameters if set.
 * @copydoc new_grid
 */
function grid_from_other(
    grid,
    num_elements=undef,
    element_dimensions=undef,
    center=undef,
    perimeter=undef
    ) =
    assert(is_grid(grid))
    new_grid(
        !is_undef(num_elements) ? num_elements : grid[1],
        !is_undef(element_dimensions) ? element_dimensions : grid[2],
        !is_undef(center) ? center : grid[3],
        !is_undef(perimeter) ? perimeter : grid[4]
    );

function grid_get_num_elements(grid) =
    assert(is_grid(grid), "Not a grid.")
    let(num_elements = grid[1])
    num_elements;

/**
 * @brief Get the total number of elements.
 * @param grid An opaque "grid" data object.
 * @returns A positive integer.
 */
function grid_get_element_count(grid) =
    assert(is_grid(grid), "Not a grid.")
    let(num_elements = grid[1])
    let(rank=len(num_elements))
    [for(i=0,a=1;i<rank;a=a*num_elements[i],i=i+1)
        a*num_elements[i]
    ][rank-1];

/**
 * @brief Theoretical element dimensions.
 * @details Does **NOT** take perimeter into account.
 * @param grid An opaque "grid" data object.
 */
function grid_get_element_dimensions(grid) =
    assert(is_grid(grid), "Not a grid.")
    let(element_dimensions = grid[2])
    element_dimensions;

function grid_is_centered(grid) =
    assert(is_grid(grid), "Not a grid.")
    let(centered = grid[3])
    centered;

/**
 * @brief The grid's perimeter.
 * @details This is **subtracted** from the outermost elements.
 * @param grid An opaque "grid" data object.
 * @returns A valid perimeter object.
 */
function grid_get_perimeter(grid) =
    assert(is_grid(grid), "Not a grid.")
    let(perimeter=grid[4])
    perimeter;

 /**
 * @brief **Not reccomended for most use cases.** Get raw grid size.
 * @details Does **NOT** take perimeter into account.
 * @see grid_get_total_dimensions for the correct function.
 * @param grid An opaque "grid" data object.
 * @returns The raw [length, width, height, ...] of the entire grid.
 */
function grid_get_raw_dimensions(grid) =
    assert(is_grid(grid), "Not a grid.")
    let(num_elements = grid[1])
    let(element_dimensions = grid[2])
    let(rank=len(num_elements))
    [ for(i=[0:rank-1])
        num_elements[i] * element_dimensions[i]
    ];

/**
 * @brief Get the [length, width] of the entire grid.
 * @details Takes perimeter into account.
 * @param grid An opaque "grid" data object.
 * @returns A vector with the same rank as element_dimensions.
 */
function grid_get_total_dimensions(grid) =
    assert(is_grid(grid), "Not a grid.")
    let(perimeter=grid[4])
    let(raw_dimensions=grid_get_raw_dimensions(grid))
    let(rank=len(raw_dimensions))
    raw_dimensions
    - [ for(i=[0:rank-1]) perimeter[i] + perimeter[i+rank] ];

/**
 * @brief The amount to translate by in order to be at the bottom left position of the grid.
 * @details **This is always outside perimeter**, if one exists.
 *    This is the bottom left position of the first element **only** if there is no perimeter.
 * @param grid An opaque "grid" data object.
 * @returns A 3d vector. Ready for use with `translate`.
 */
function grid_get_position_bottom_left(grid) =
    assert(is_grid(grid), "Not a grid.")
    let(centered = grid[3])
    let(half_raw_dimensions=grid_get_raw_dimensions(grid)/2)
    let(rank=len(half_raw_dimensions))
    !centered ? [0, 0, 0]
        : -[
            half_raw_dimensions.x,
            half_raw_dimensions.y,
            rank>=3 ? half_raw_dimensions.z : 0
        ];

/*
 * @brief The amount to translate by in order to be at the center position of the grid.
 * @details Zero point if `is_centered(grid)==true`.
 *     Otherwise assumes zero point is **outside** the perimeter.
 * @param grid An opaque "grid" data object.
 * @returns A 3d vector. Ready for use with `translate`.
 */
function grid_get_position_center(grid) =
    assert(is_grid(grid), "Not a grid.")
    let(centered = grid[3])
    let(half_raw_dimensions=grid_get_raw_dimensions(grid)/2)
    let(rank=len(half_raw_dimensions))
    centered ? [0, 0, 0]
        : [
            half_raw_dimensions.x,
            half_raw_dimensions.y,
            rank>=3 ? half_raw_dimensions.z : 0
        ];

/**
 * @brief If the object is a grid.
 * @param grid The object to check.
 */
function is_grid(grid) =
    is_list(grid) && len(grid) == 5
    && grid[0] == "grid_struct";

/**
 * @brief Get the element at a particular index.
 * @details Uses `floor` to insure all indexes are integers.
 * @param grid An opaque "grid" data object.
 * @param index The multidimensional index of the element.
 * @param center If the element's position should be at the center of the element.  Otherwise, bottom left.
 * @returns An opaque "grid_element" data object.
 */
function grid_get_element(grid, index, center=false) =
    assert(is_grid(grid), "Not a grid.")
    let(num_elements = grid[1])

    assert(is_list(index) && len(index) == len(num_elements),
        str("index must be a list with ", len(num_elements), " items."))
    assert(min(index) >= 0, "index may not contain negative values.")
    assert(min([
            for(d=[0:len(index)-1])
            index[d] < num_elements[d] ? 1 : 0
        ]) == 1,
        str("index must be below ", num_elements))
    assert(is_bool(center))
    let(index_real = [for(i=index) floor(i)])
    [
        "grid_element_struct",
        grid,
        index_real,
        center // Return position as center of the element or not.
    ];

/**
 * @brief Move to a particular element's position within the grid.
 * @details Supports floating point index values.
 *     Children may use `grid_element_current` to obtain the element at the index passed in.
 * @param grid An opaque "grid" data object.
 * @param index The multidimensional index of the element to move to.
 *              If passed a float, final position is translated by the formula `(index-floor(index))*element_dimensions`.
 * @param center Move to the center point of the element.
 *                       Otherwise moves to the bottom left corner.
 */
module grid_translate(grid, index, center=false) {
    element = grid_get_element(grid, index, center);
    $_grid_element = element;

    index_real = grid_element_get_index(element);
    partial_index = index - index_real;
    element_dimensions = grid_get_element_dimensions(grid);
    offset = [for(i=[0:len(index)-1])
        partial_index[i] * element_dimensions[i]
    ];

    translate(grid_element_get_position(element) + offset)
    children();
}

/**
 * @brief Call `grid_translate` on each element in the grid.
 * @details Children may use `grid_element_current` to obtain the current element.
            Creates a grid pattern of elements.
 * @see grid_translate
 * @param grid An opaque "grid" data object.
 */
module grid_foreach(grid, center_elements=false) {
    assert(is_grid(grid), "Not a grid.");
    num_elements = grid[1];

    count = grid_get_element_count(grid);
    rank = len(num_elements);

    for(sequence_number = [0:count-1]) {
        //Goes x -> y -> z
        index = [
            for(d=0,i=sequence_number;
                d<rank;
                i=floor(i/num_elements[d]), d=d+1
            )
            i % num_elements[d]
        ];

//        echo(sequence_number=sequence_number, index=index);
        grid_translate(grid, index, center_elements)
        children();
    }
}

/**
 * @brief Create one child per grid element.
 * @details For use inside `grid_foreach`
 * @WARNING: BETA FEATURE direction and ordering is not guaranteed.
 * @see https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/User-Defined_Functions_and_Modules#Children
 * > Note that children(), echo() and empty block statements (including ifs) count as $children objects, even if no geometry is present (as of v2017.12.23).
 */
module child_per_element() {
    element = grid_element_current();
    sequence_number = grid_element_get_sequence_number(element);
    children(sequence_number);
}

/**
  * @brief Subdivide a 2d square into grid of child elements.
  * @details Use `grid_element_current` in child elements to obtain details about the current position within the grid.
  *          Use `center_elements=false` for squares and other things in quadrant 1.
  *          Use `center_elements=true` for circles and anything centered.
  * @param num_elements Number of elements to create. [x, y]
  * @param total_dimensions [length, width] of the entire grid.
  * @param center Center the entire grid.
  *               Otherwise grid starts at bottom left corner.
  * @param center_elements Center each element.
  *                        Otherwise each element starts at the bottom left corner.
 */
module subdivide_grid(num_elements, total_dimensions, center=false, center_elements=false) {

    grid = grid_from_total(num_elements, total_dimensions, center);
    grid_foreach(grid, center_elements) {
        children();
    }
}

/**
  * @brief Create a 2d grid pattern of child items.
  * @details Use `grid_element_current` in child elements to obtain details about the current position within the grid.
  *          Use `center_elements=false` for squares and other things in quadrant 1.
  *          Use `center_elements=true` for circles and anything centered.
  * @param num_elements Number of elements to create. [x, y]
  * @param element_dimensions [length, width] of a single element.
  * @param center Center the entire grid.
  *               Otherwise grid starts at bottom left corner.
  * @param center_elements Center each element.
  *                        Otherwise each element starts at the bottom left corner.
 */
module pattern_grid(num_elements, element_dimensions, center=false, center_elements=false) {

    grid = new_grid(num_elements, element_dimensions, center);
    grid_foreach(grid, center_elements) {
        children();
    }
}

/**
 * @brief Print information about the given grid.
 * @param grid An opaque "grid" data object.
 */
module print_grid(grid) {
    assert(is_grid(grid));

    raw_mm = grid_get_raw_dimensions(grid);
    total_mm = grid_get_total_dimensions(grid);
    centered = grid_is_centered(grid);
    position_bottom_left = grid_get_position_bottom_left(grid);
    position_center = grid_get_position_center(grid);

    echo("Grid:");
    echo(str("  element_count:\t     ", grid_get_element_count(grid)));
    echo(str("  num_elements:\t     ", grid_get_num_elements(grid)));
    echo(str("  element_dimensions:  ", grid_get_element_dimensions(grid)));
    echo(str("  raw_dimensions:\t     ", raw_mm));
    echo(str("  total_dimensions:\t     ", total_mm));
    echo(str("  is_centered:\t     ", centered));
    echo(str("  position_bottom_left: ", position_bottom_left));
    echo(str("  position_center:\t     ", position_center));
    echo(str("  perimeter:\t     ", grid_get_perimeter(grid)));
}

/**
 * @brief Show the grid's perimeter.
 * @param grid An opaque "grid" data object.
 * @param min_per_side Minimum width per side.
 *                     Ensures the grid can always be visualized.
 *                     0 means do nothing if no perimeter.
 * @returns A 2d object representing the perimeter.
 */
module grid_visualize_perimeter(grid, min_per_side=0.1) {
    assert(is_grid(grid));
    assert(is_num(min_per_side) && min_per_side >= 0);

    raw_mm = grid_get_raw_dimensions(grid);
    rank = len(raw_mm);
    perimeter = grid_get_perimeter(grid);
    position_bottom_left = grid_get_position_bottom_left(grid);

    if(len(raw_mm) < 3) {
        _grid_visualize_perimeter_2d(grid, min_per_side);
    } else {
        translate([0, 0, position_bottom_left.z])
        linear_extrude(max(perimeter[2], min_per_side))
        _grid_visualize_perimeter_2d(grid, min_per_side);

        translate([0, 0, position_bottom_left.z + raw_mm.z])
        mirror([0, 0, 1])
        linear_extrude(max(perimeter[2+rank], min_per_side))
        _grid_visualize_perimeter_2d(grid, min_per_side);
    }
}

/**
 * @brief Internal function.  Do not use directly
 */
module _grid_visualize_perimeter_2d(grid, min_per_side) {
    assert(is_grid(grid));
    assert(is_num(min_per_side) && min_per_side >= 0);

    position_bottom_left = grid_get_position_bottom_left(grid);
    raw_mm = grid_get_raw_dimensions(grid);
    raw_mm_2d = [raw_mm.x, raw_mm.y];
    total_mm = grid_get_total_dimensions(grid);
    perimeter = grid_get_perimeter(grid);

    perimiter_offset = [
        max(perimeter[0], min_per_side),
        max(perimeter[1], min_per_side)
    ];
    inner_size = raw_mm_2d - [
        max(raw_mm.x - total_mm.x, 2 * min_per_side),
        max(raw_mm.y - total_mm.y, 2 * min_per_side)
    ];
    // Ensure logic is correct.
    assert(inner_size.x <= total_mm.x
        && inner_size.y <= total_mm.y);

    // Perimeter
    if(raw_mm != total_mm || min_per_side > 0) {
        translate(position_bottom_left)
        difference() {
            square(raw_mm_2d);

            translate(concat(perimiter_offset, 0))
            square(inner_size);
        }
    }
}

/**
 * @brief Color and label a grid.
 * @param grid An opaque "grid" data object.
 * @param gap Spacing between grid elements.
 * @param alpha 0-1 How transparent the colors are.
 * @param layer_spacing Height difference between elements.
 *                      Helps fix rendering issues.
 * @param print Print data about the current grid/element.
 *     0: Nothing.
 *     1: Grid information.
 *     2: Grid and Element information.
 */
module debug_grid(
    grid,
    gap=1.0,
    alpha=1.0,
    layer_spacing=0.01,
    print=0,
    _center_elements=true
    ) {
    assert(is_num(print)
        && print >= 0
        && print < 3);

    if(print > 0) {
        print_grid(grid);
    }
    grid_foreach(grid, _center_elements) {
        element = grid_element_current();
        debug_grid_element(element, gap=gap, alpha=alpha, layer_spacing=layer_spacing);
        if(print == 2) {
            print_grid_element(element);
        }
    }

    translate([0, 0, 3 * layer_spacing])
    grid_visualize_perimeter(grid);

    //Grid Center
    position_center = grid_get_position_center(grid);
    translate(position_center + [0, 0, 3 * layer_spacing])
    if (len(position_center) == 2) {
        circle(r=0.75);
    } else {
        sphere(r=0.75);
    }
}

$test_grid = true;
//NOTE: The seeming offset between the circles and the squares is because the squares are not centered per element.
if(!is_undef($test_grid) && $test_grid){
    pattern_grid([3, 5], [20, 10], true, false){
        element = grid_element_current();
//        print_grid_element(element);
        debug_grid_element(element, alpha = 0.5);
    }

    translate([0, 0, 2])
    pattern_grid([3, 5], [20, 10], true, true){
        element = grid_element_current();
//        print_grid_element(element);
        color(_element_color(element), alpha=0.3)
        circle(r=4.5);
    }

    translate([0, 0, 3])
    subdivide_grid([3, 5], [60, 50], true, true) {
        circle(1);
    }

    //****************************************//
    // Testing Perimeter

    grid_34 = new_grid([3, 4], [20, 10], false, [1, 2, 3, 4]);
    grid_34_copy = grid_from_other(grid_34);
    grid_34_centered = grid_from_other(grid_34, center=true);
    translate([100, 0, 0])
    debug_grid(grid_34, print=1);
    translate([200, 0, 0])
    debug_grid(grid_34_copy, _center_elements=false);
    translate([300, 0, 0])
    debug_grid(grid_34_centered);

    grid_11 = new_grid([1, 1], [20, 10], false, [4, 3, 2, 1]);
    translate([400, 0, 0])
    debug_grid(grid_11, print=2, _center_elements=false);

    //****************************************//
    grid_341 = new_grid([3, 4, 1], [20, 10, 5], true);
    translate([0, -50, 0])
    debug_grid(grid_341, print=1);

    grid_342 = new_grid([3, 4, 2], [20, 10, 5], true);
    translate([0, -100, 0])
    debug_grid(grid_342, print=1);

    grid_3d2 = grid_from_other(grid_342, center=false);
    translate([0, -175, 0])
    debug_grid(grid_3d2, print=1);

    translate([0, -225, 0])
    debug_grid(grid_3d2, print=0, _center_elements=false);

    grid_3dp = grid_from_other(grid_3d2,
        perimeter=[0, 0, 3, 0, 0, 1]);
    translate([0, -275, 0])
    debug_grid(grid_3dp, print=1);
    //****************************************//

    grid_13 = new_grid([1, 3], [10, 20], true);
    translate([-50, 0, 0]) {
        grid_foreach(grid_13, true)
        child_per_element() {
            circle(r=3);
            square(4, center=true);
            text("text", halign="center");
        }
        //Perimeter should not show
        grid_visualize_perimeter(grid_13, 0);

        //Should create a red circle between text and the square.
        grid_translate(grid_13, [0, 1.5], true){
            element = grid_element_current();
            print_grid_element(element);
            color("red")
            circle(r=1);
        }
    }

    // These should produce nothing.
    translate([0, 0, 10]) {
        pattern_grid([0, 0], [10, 10], true, true) {
            circle(100);
        }
        subdivide_grid([0, 0], [1, 1], true, true) {
            circle(100);
        }
    }
}
