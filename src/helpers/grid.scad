/**
 * @file grid.scad
 * @brief pattern_grid, and helpers to change child behavior based on position within the grid.
 */

/**
  * @brief Create a 2d grid pattern of child items.
  * @details Use `grid_element_current` in child elements to control their behavior.
  *          Use `center_elements=false` for squares and other things in quadrant 1.
  *          Use `center_elements=true` for circles and things centered.
  * @param grid_size Number of elements to create. [x, y]
  * @param element_dimensions_mm [length, width] of a single element.
  * @param center Center the entire grid.
  *               Otherwise grid starts at bottom left corner.
  * @param center_elements Center each element.
  *                        Otherwise each element starts at the bottom left corner.
 */
module pattern_grid(grid_size, element_dimensions_mm, center=false, center_elements=false) {
    assert(is_list(grid_size) && len(grid_size) >= 2 && grid_size.x > 0 && grid_size.y > 0);
    assert(is_list(element_dimensions_mm) && len(element_dimensions_mm) >= 2 && element_dimensions_mm.x > 0 && element_dimensions_mm.y > 0);

    total_size = [
        grid_size.x * element_dimensions_mm.x,
        grid_size.y * element_dimensions_mm.y,
        0
    ];
    element_center = [element_dimensions_mm.x/2, element_dimensions_mm.y/2, 0];

    // Local coordinates
    position_start = center ? -total_size/2 : [0, 0, 0];

    for (i = [0:grid_size.x -1]) {
        for (j = [0:grid_size.y -1]) {
            position_offset = [
                i * element_dimensions_mm.x,
                j * element_dimensions_mm.y,
                0
            ] + (center_elements ? element_center : [0, 0, 0]);
            position = position_start + position_offset;
            $_grid_element = [
                "grid_element_struct",
                [i, j],  // index
                position, // position
                grid_size,
                element_dimensions_mm
            ];
            translate(position)
            children();
        }
    }
}

/**
 * @brief Internal variable.  Do not use!
 */
$_grid_element = undef;

/**
 * @brief Information about the given element from `pattern_grid`.
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
    let(grid_size=element[3])
    index == [0, 0] == grid_size;

function grid_element_get_index(element) =
    assert(_is_grid_element(element), "Not a grid element.")
    element[1];

function grid_element_get_position(element) =
    assert(_is_grid_element(element),
        "Not a grid element.")
    element[2];

function grid_element_get_grid_size(element) =
    assert(_is_grid_element(element), "Not a grid element.")
    element[3];

function grid_element_get_dimensions_mm(element) =
    assert(_is_grid_element(element), "Not a grid element.")
    element[4];

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
    let(grid_size=element[3])
    index.x == grid_size.x -1; //i == grid_size.x -1;

function grid_element_is_last_row(element) =
    assert(_is_grid_element(element), "Not a grid element.")
    let(index=element[1])
    let(grid_size=element[3])
    index.y == grid_size.y -1; //j == grid_size.y -1;


/**
 * @brief Internal function. Do not use directly.
 */
function _grid_element_default() =
    [
        "grid_element_struct",
        [0, 0],  // index
        [0, 0, 0], // position
        [0, 0], // grid_size
        [0, 0] // element_dimensions_mm
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
if(!is_undef($test_grid) && $test_grid){
    pattern_grid([3, 5], [10, 20], true, false){
        element = grid_element_current();
        echo(
            index=grid_element_get_index(element),
            position=grid_element_get_position(element)
        );
        color(_element_color(element))
        square([9, 19]);
    }

    translate([0, 0, 10])
    pattern_grid([3, 5], [10, 20], true, true){
        element = grid_element_current();
        echo("\n",
            index=grid_element_get_index(element), "\n",
            position=grid_element_get_position(element), "\n",
            grid_size=grid_element_get_grid_size(element), "\n",
            dimensions_mm=grid_element_get_dimensions_mm(element)
        );
        color(_element_color(element))
        circle([9, 19]);
    }
}
