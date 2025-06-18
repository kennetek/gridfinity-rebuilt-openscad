/**
 * @file grid.scad
 * @brief 2d grid object.  Used to either create a pattern or to subdivide a larger object.
 */

use <grid_element.scad>

_assert_grid_parameters = function(
    num_elements,
    element_dimensions,
    center,
    perimeter
    )
    assert(is_list(num_elements)
        && len(num_elements) == 2
        && num_elements.x >= 0
        && num_elements.y >= 0)
    assert(is_list(element_dimensions)
        && len(element_dimensions) == 2
        && element_dimensions.x > 0
        && element_dimensions.y > 0)
    assert(is_bool(center))
    assert(is_list(perimeter)
        && len(perimeter) == 4
        && perimeter[0] >= 0
        && perimeter[1] >= 0
        && perimeter[2] >= 0
        && perimeter[3] >= 0,
        "perimeter must be in the form [0, 0, 0, 0], and no item may be negative.")
    true;

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
  * @param perimeter [-x, -y, +x, +y] **Subtracted** from the outer element edges.
  *        Each item represents a side.
  *        Bottom left position is always **outside** the perimeter.
  * @returns An opaque "grid" object.
 */
function new_grid(
    num_elements,
    element_dimensions,
    center=false,
    perimeter=[0,0,0,0]
    ) =
    assert(_assert_grid_parameters(
        num_elements,
        element_dimensions,
        center,
        perimeter
    ))
    [
        "grid_struct",
        num_elements,
        element_dimensions,
        center,
        perimeter
    ];

 /**
  * @brief Subdivide a 2d square into grid of child elements.
  * @param num_elements Number of elements to create. [x, y]
  * @param total_dimensions [length, width] of the entire grid.
  * @param center Center the entire grid.
  *               Otherwise grid starts at bottom left corner.
  *               Also determines the [0, 0] position.
  * @param perimeter [-x, -y, +x, +y] **Subtracted** from the outer element edges.
  *        Each item represents a side.
  * @returns An opaque "grid" object.
 */
function grid_from_total(
    num_elements,
    total_dimensions,
    center=false,
    perimeter=[0,0,0,0]
    ) =
    assert(_assert_grid_parameters(
        num_elements,
        [1, 1],
        center,
        perimeter
    ))
    assert(is_list(total_dimensions)
        && len(total_dimensions) >= 2
        && total_dimensions.x > 0
        && total_dimensions.y > 0)
    let(element_dimensions = [
        num_elements.x == 0 ? 1
        : total_dimensions.x / num_elements.x,
        num_elements.y == 0 ? 1
        : total_dimensions.y / num_elements.y
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
 * @returns [length, width]
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
 * @returns The [length, width] of the entire grid.
 */
function grid_get_raw_dimensions(grid) =
    assert(is_grid(grid), "Not a grid.")
    let(num_elements = grid[1])
    let(element_dimensions = grid[2])
    [
        num_elements.x * element_dimensions.x,
        num_elements.y * element_dimensions.y
    ];

/**
 * @brief Get the [length, width] of the entire grid.
 * @details Takes perimeter into account.
 * @param grid An opaque "grid" data object.
 * @returns A 2d vector.
 */
function grid_get_total_dimensions(grid) =
    assert(is_grid(grid), "Not a grid.")
    let(perimeter=grid[4])
    grid_get_raw_dimensions(grid) - [
        perimeter[0] + perimeter[2],
        perimeter[1] + perimeter[3]
    ];

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
    let(perimeter=grid[4])
    !centered ? [0, 0, 0]
        : concat(-grid_get_raw_dimensions(grid)/2, 0);

/*
 * @brief The amount to translate by in order to be at the center position of the grid.
 * @details [0, 0] if `is_centered(grid)==true`.
 *     Otherwise assumes [0, 0] is **outside** the perimeter.
 * @param grid An opaque "grid" data object.
 * @returns A 3d vector. Ready for use with `translate`.
 */
function grid_get_position_center(grid) =
    assert(is_grid(grid), "Not a grid.")
    let(centered = grid[3])
    centered ? [0, 0, 0]
        : concat(grid_get_raw_dimensions(grid)/2, 0);

/**
 * @brief If the object is a grid.
 * @param grid The object to check.
 */
function is_grid(grid) =
    is_list(grid) && len(grid) == 5
    && grid[0] == "grid_struct";

/**
 * @brief Get the element at a particular index.
 * @param grid An opaque "grid" data object.
 * @param index The multidimensional index of the element.
 * @param center If the element's position should be at the center of the element.  Otherwise, bottom left.
 * @returns An opaque "grid_element" data object.
 */
function grid_get_element(grid, index, center=false) =
    assert(is_grid(grid), "Not a grid.")
    let(num_elements = grid[1])
    let(element_dimensions = grid[2])

    assert(is_list(index)
        && len(index) == 2
        && index.x >= 0
        && index.y >= 0)
    assert(index.x < num_elements.x && index.y < num_elements.y,
        str("index must be below ", num_elements))
    assert(is_bool(center))
    [
        "grid_element_struct",
        grid,
        index,
        center // Return position as center of the element or not.
    ];

/**
 * @brief Move to a particular element's position within the grid.
 * @details Children may use `grid_element_current` to obtain the element at the index passed in.
 * @param grid An opaque "grid" data object.
 * @param index The multidimensional index of the element to move to.
 * @param center Move to the center point of the element.
 *                       Otherwise moves to the bottom left corner.
 */
module grid_translate(grid, index, center=false) {
    element = grid_get_element(grid, index, center);
    $_grid_element = element;
    translate(grid_element_get_position(element))
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
    element_dimensions = grid[2];

    for(sequence_number = [0 : num_elements.x * num_elements.y - 1]) {
        index = [
            floor(sequence_number / num_elements.y),
            sequence_number % num_elements.y
        ];
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
    assert(min_per_side >= 0);

    position_bottom_left = grid_get_position_bottom_left(grid);
    raw_mm = grid_get_raw_dimensions(grid);
    total_mm = grid_get_total_dimensions(grid);
    perimeter = grid_get_perimeter(grid);

    perimiter_offset = [
        max(perimeter[0], min_per_side),
        max(perimeter[1], min_per_side)
    ];
    inner_size = raw_mm - perimiter_offset - [
        max(perimeter[2], min_per_side),
        max(perimeter[3], min_per_side)
    ];
    // Ensure logic is correct.
    assert(inner_size.x <= total_mm.x
        && inner_size.y <= total_mm.y);

    // Perimeter
    if (raw_mm != total_mm || min_per_side > 0) {
        difference() {
            translate(position_bottom_left)
            square(raw_mm);

            translate(position_bottom_left + concat(perimiter_offset, 0))
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
    translate(grid_get_position_center(grid) + [0, 0, 3 * layer_spacing])
    circle(r=0.75);
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
    translate([0, -100, 0])
    debug_grid(grid_11, print=2, _center_elements=false);

    grid_13 = new_grid([1, 3], [10, 20], true);
    translate([-50, 0, 0]) {
        grid_foreach(grid_13, true)
        child_per_element() {
            circle(r=3);
            square(4, center=true);
            text("text", halign="center");
        }
        grid_visualize_perimeter(grid_13, 0);
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
