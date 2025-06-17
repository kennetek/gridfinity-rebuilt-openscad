/**
 * @file grid.scad
 * @brief pattern_grid, and helpers to change child behavior based on position within the grid.
 */

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
    assert(is_list(num_elements) && len(num_elements) >= 2 && num_elements.x >= 0 && num_elements.y >= 0);

    if (num_elements.x != 0 && num_elements.y != 0) {
        element_dimensions = [
            total_dimensions.x / num_elements.x,
            total_dimensions.y / num_elements.y
        ];
        pattern_grid(num_elements, element_dimensions, center, center_elements){
            children();
        }
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
    assert(is_list(num_elements) && len(num_elements) >= 2 && num_elements.x >= 0 && num_elements.y >= 0);
    assert(is_list(element_dimensions) && len(element_dimensions) >= 2 && element_dimensions.x > 0 && element_dimensions.y > 0);

    total_dimensions = [
        num_elements.x * element_dimensions.x,
        num_elements.y * element_dimensions.y,
        0
    ];
    element_center = element_dimensions / 2;

    // Local coordinates
    position_start = center ? -total_dimensions/2 : [0, 0, 0];

    for(sequence_number = [0 : num_elements.x * num_elements.y - 1]) {
        i = floor(sequence_number / num_elements.y);
        j = sequence_number % num_elements.y;
        position_offset = [
            i * element_dimensions.x,
            j * element_dimensions.y,
            0
        ] + (center_elements ? element_center : [0, 0, 0]);
        position = position_start + position_offset;
        $_grid_element = [
            "grid_element_struct",
            [i, j],  // index
            position, // position
            num_elements,
            element_dimensions,
            sequence_number
        ];
        translate(position)
        children();
    }
}

/**
 * @brief Create one child per grid element.
 * @details For use inside `pattern_grid` or `subdivide_grid`
 * @WARNING: BETA FEATURE direction and ordering is not guaranteed.
 * @see https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/User-Defined_Functions_and_Modules#Children
 * > Note that children(), echo() and empty block statements (including ifs) count as $children objects, even if no geometry is present (as of v2017.12.23).
 */
module child_per_element() {
    element = grid_element_current();
    sequence_number = grid_element_get_sequence_number(element);
    //echo(sequence_number=sequence_number);
    children(sequence_number);
}

/**
 * @brief Internal variable.  Do not use!
 */
$_grid_element = undef;

/**
 * @brief Information about the given element from `subdivide_grid` or `pattern_grid`.
 * @details To be used by a child element.
 * @param allow_default If true, returns an empty element.
 *                      False triggers an assert.
 * @returns An opaque data type to be passed to accessor functions.
 */
function grid_element_current(allow_default = false) =
    _is_grid_element($_grid_element) ? $_grid_element
    : allow_default ? _grid_element_default()
    : assert(false, "No grid element available.");

/**
 * @brief If the passed variable is the default element.
 * @details Default element is created when calling ` grid_element_current(allow_default=true)` outside of `pattern_grid`.
 * @param element The variable returned by a call to `grid_element_current`
 */
function grid_element_is_default(element) =
    assert(_is_grid_element(element), "Not a grid element.")
    let(index=element[1])
    let(num_elements=element[3])
    index == [0, 0] == num_elements;

/**
 * @brief Multidimensional index of the current element.
 */
function grid_element_get_index(element) =
    assert(_is_grid_element(element), "Not a grid element.")
    element[1];

function grid_element_get_position(element) =
    assert(_is_grid_element(element),
        "Not a grid element.")
    element[2];

function grid_element_get_num_elements(element) =
    assert(_is_grid_element(element), "Not a grid element.")
    element[3];

function grid_element_get_dimensions(element) =
    assert(_is_grid_element(element), "Not a grid element.")
    element[4];

/**
 * @brief numeric index of the current element.
 * @warning: Ordering in which elements are rendered is **not** finalized and may change.
 */
function grid_element_get_sequence_number(element) =
    assert(_is_grid_element(element), "Not a grid element.")
    element[5];

function grid_element_is_first_col(element) =
    assert(_is_grid_element(element), "Not a grid element.")
    let(index=element[1])
    index.x == 0; //i == 0;

function grid_element_is_first_row(element) =
    assert(_is_grid_element(element), "Not a grid element.")
    let(index=element[1])
    index.y == 0; //j == 0;

function grid_element_is_last_col(element) =
    assert(_is_grid_element(element), "Not a grid element.")
    let(index=element[1])
    let(num_elements=element[3])
    index.x == num_elements.x -1; //i == num_elements.x -1;

function grid_element_is_last_row(element) =
    assert(_is_grid_element(element), "Not a grid element.")
    let(index=element[1])
    let(num_elements=element[3])
    index.y == num_elements.y -1; //j == num_elements.y -1;


/**
 * @brief Internal function. Do not use directly.
 */
function _grid_element_default() =
    [
        "grid_element_struct",
        [0, 0],  // index
        [0, 0, 0], // position
        [0, 0], // num_elements
        [0, 0] // element_dimensions
    ];

/**
 * @brief Internal function. Do not use directly.
 */
function _is_grid_element(element) =
    is_list(element) &&
    element[0] == "grid_element_struct";

/**
 * @brief Internal helper function for marking grid elements.
 */
function _element_color(element) =
    grid_element_is_first_row(element) && grid_element_is_first_col(element) ? "Green"
    : grid_element_is_last_row(element) && grid_element_is_last_col(element) ? "Red"
    : grid_element_is_first_row(element) && grid_element_is_last_col(element) ? "Maroon"
    : grid_element_is_last_row(element) && grid_element_is_first_col(element) ? "Olive"
    : grid_element_is_first_row(element) ? "Blue"
    : grid_element_is_last_row(element) ? "Aqua"
    : grid_element_is_first_col(element) ? "Fuchsia"
    : grid_element_is_last_col(element) ? "Purple"
    : "Yellow";

$test_grid = true;
//NOTE: The seeming offset between the circles and the squares is because the squares are not centered per element.
if(!is_undef($test_grid) && $test_grid){
    pattern_grid([3, 5], [10, 20], true, false){
        element = grid_element_current();
        echo(
            index=grid_element_get_index(element),
            position=grid_element_get_position(element)
        );
        //square(grid_element_get_dimensions(element));
        color(_element_color(element))
        square([9, 19]);
    }
    translate([0, 0, 2])
    pattern_grid([3, 5], [10, 20], true, true){
        element = grid_element_current();
        echo("\n",
            sequence_number=grid_element_get_sequence_number(element), "\n",
            index=grid_element_get_index(element), "\n",
            position=grid_element_get_position(element), "\n",
            num_elements=grid_element_get_num_elements(element), "\n",
            dimensions=grid_element_get_dimensions(element)
        );
        color(_element_color(element))
        circle(r=4.5);
    }

    translate([0, 0, 3])
    subdivide_grid([3, 5], [30, 100], true, true) {
        circle(1);
    }

    // These should produce nothing.
    translate([0, 0, 10])
    subdivide_grid([0, 0], [10, 10], true, true) {
        circle(100);
    }
    translate([0, 0, 10])
    subdivide_grid([1, 0], [10, 10], true, true) {
        circle(100);
    }
    translate([0, 0, 10])
    subdivide_grid([0, 1], [1, 1], true, true) {
        circle(100);
    }
}
