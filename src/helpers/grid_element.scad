/**
 * @file
 * @brief An element inside a grid ojbect.
 * @details Provides information which can be used as a modifier.
 */

 use <grid.scad>

/**
 * @brief Internal variable.  Do not use directly!
 */
$_grid_element = undef;

/**
 * @brief If the object is a grid_element.
 * @param element The object to check.
 */
function is_grid_element(element) =
    is_list(element)
    && element[0] == "grid_element_struct"
    && len(element) == 4;

/**
 * @brief Internal function. Do not use directly.
 */
_grid_element_default = function()
    [
        "grid_element_struct",
        [], //grid object
        [0, 0],  // index
        false // centered
    ];

/**
 * @brief Information about the given element from `grid_translate` or `grid_foreach`.
 * @details To be used by a child element.
 * @param allow_default If true, returns an empty element.
 *                      False triggers an assert.
 * @returns An opaque data type to be passed to accessor functions.
 */
function grid_element_current(allow_default = false) =
    is_grid_element($_grid_element) ? $_grid_element
    : allow_default ? _grid_element_default()
    : assert(false, "No grid element available.");

/**
 * @brief If the passed variable is the default element.
 * @details Default element is created when calling ` grid_element_current(allow_default=true)` outside of `grid_translate` or `grid_foreach`.
 * @param element The variable returned by a call to `grid_element_current`
 */
function grid_element_is_default(element) =
    assert(is_grid_element(element), "Not a grid element.")
    let(grid=element[1])
    let(index=element[2])
    let(centered=element[3])
    !is_grid(grid);

/**
 * @brief Parent grid of the current element.
 * @param element An opaque "grid_element" data object.
 * @returns An opaque "grid" data object.
 */
function grid_element_get_grid(element) =
    assert(is_grid_element(element), "Not a grid element.")
    assert(!grid_element_is_default(element))
    let(grid=element[1])
    let(index=element[2])
    let(centered=element[3])
    grid;

/**
 * @brief Multidimensional index of the current element.
 * @param element An opaque "grid_element" data object.
 */
function grid_element_get_index(element) =
    assert(is_grid_element(element), "Not a grid element.")
    let(grid=element[1])
    let(index=element[2])
    let(centered=element[3])
    index;

/**
 * @brief If `grid_element_get_position` returns the center of the element.
 * @details Otherwise it returns the bottom left corner.
 * @param element An opaque "grid_element" data object.
 */
function grid_element_is_centered(element) =
    assert(is_grid_element(element), "Not a grid element.")
    assert(!grid_element_is_default(element))
    let(grid=element[1])
    let(index=element[2])
    let(centered=element[3])
    centered;

/**
 * @brief Position of the current element, relative to the parent grid's [0, 0, 0] position.
 * @details Will either be the center of the element, or the lower bottom left corner.
 * @param element An opaque "grid_element" data object.
 * @returns A 3d vector.
 */
function grid_element_get_position(element) =
    assert(is_grid_element(element), "Not a grid element.")
    assert(!grid_element_is_default(element))
    let(grid=element[1])
    let(index=element[2])
    let(centered=element[3])

    let(perimeter = grid_get_perimeter(grid))
    let(raw_element_dimensions = grid_get_element_dimensions(grid))
    let(element_dimensions = grid_element_get_dimensions(element))

    let(raw_element_offset = [
        index.x * raw_element_dimensions.x,
        index.y * raw_element_dimensions.y,
        0
    ])
    let(perimeter_offset = [
        grid_element_is_first_col(element) ? perimeter[0] : 0,
        grid_element_is_first_row(element) ? perimeter[1] : 0,
        0
    ])
    grid_get_position_bottom_left(grid)
        + raw_element_offset + perimeter_offset
        + (centered ? element_dimensions/2 : [0, 0, 0]);

/**
 * @brief Numeric index of the current element.
 * @warning: Ordering in which elements are rendered is **not** finalized and may change.
 * @param element An opaque "grid_element" data object.
 * @returns A positive integer.
 */
function grid_element_get_sequence_number(element) =
    assert(is_grid_element(element), "Not a grid element.")
    assert(!grid_element_is_default(element))
    let(grid=element[1])
    let(index=element[2])
    let(centered=element[3])
    index.x * grid_get_num_elements(grid).y + index.y;

/**
 * @brief Dimensions of the current grid_element.
 * @details Takes the grid perimeter into account.
 * @param element An opaque "grid_element" data object.
 * @returns [length, width]
 */
function grid_element_get_dimensions(element) =
    assert(is_grid_element(element), "Not a grid element.")
    assert(!grid_element_is_default(element))
    let(grid=element[1])
    let(perimeter = grid_get_perimeter(grid))
    let(perimeter_adjustment = [
        (grid_element_is_first_col(element) ? perimeter[0] : 0)
        + (grid_element_is_last_col(element) ? perimeter[2] : 0),
        (grid_element_is_first_row(element) ? perimeter[1] : 0)
        + (grid_element_is_last_row(element) ? perimeter[3] : 0)
    ])
    grid_get_element_dimensions(grid) - perimeter_adjustment;

function grid_element_is_first_col(element) =
    assert(is_grid_element(element), "Not a grid element.")
    grid_element_is_default(element) ? false
    : grid_element_get_index(element).x == 0;

function grid_element_is_first_row(element) =
    assert(is_grid_element(element), "Not a grid element.")
    grid_element_is_default(element) ? false
    : grid_element_get_index(element).y == 0;

function grid_element_is_last_col(element) =
    assert(is_grid_element(element), "Not a grid element.")
    let(grid=element[1])
    grid_element_is_default(element) ? false
    : grid_element_get_index(element).x
        == grid_get_num_elements(grid).x - 1;

function grid_element_is_last_row(element) =
    assert(is_grid_element(element), "Not a grid element.")
    let(grid=element[1])
    grid_element_is_default(element) ? false
    : grid_element_get_index(element).y
        == grid_get_num_elements(grid).y - 1;

/**
 * @brief Label the element with it's index.
 * @param element An opaque "grid_element" data object.
 * @param label To write on the element.
 *      Automatically passed through `str`.
 *      Accepts functions in the form `fn(element)`.
 */
module grid_element_label(element,
    label=function(e) grid_element_get_index(e)) {
    assert(is_grid_element(element), "Not a grid element.");
    assert(!grid_element_is_default(element));
    assert(!is_undef(label));

    dimensions = grid_element_get_dimensions(element);
    centered = grid_element_is_centered(element);

    output = str(is_function(label) ? label(element) : label);
    rotate_text = dimensions.x < dimensions.y;
    max_width = (rotate_text ? dimensions.y : dimensions.x)/4;
    max_height = (rotate_text ? dimensions.x : dimensions.y)/2;
//    echo(max_width=max_width,max_height=max_height);

    color("black")
    translate(concat(centered ? [0, 0] : dimensions/2, 0))
    rotate([0, 0, rotate_text ? 90 : 0])
    text(output,
        halign="center",
        valign="center",
        size=min(max_width, max_height)
    );
}

/**
 * @brief Color and label a grid element based on it's index.
 * @param element An opaque "grid_element" data object.
 * @param gap Spacing between grid elements.
 * @param alpha 0-1 How transparent the colors are.
 * @param layer_spacing Height difference between elements.
 *                      Helps fix rendering issues.
 */
module debug_grid_element(element, gap=1.0, alpha=1.0, layer_spacing=0.01) {
    assert(is_grid_element(element), "Not a grid element.");
    assert(!grid_element_is_default(element));
    assert(is_num(gap) && gap >= 0);
    assert(is_num(alpha));
    assert(is_num(layer_spacing));

    dimensions = grid_element_get_dimensions(element);
    centered = grid_element_is_centered(element);

    gap_2d = [gap, gap]/2;
    border_2d = [0.1, 0.1] / 2;

    if(alpha > 0) {
        color(_element_color(element), alpha)
        square(dimensions-gap_2d, center=centered);

        // Border
        color("black", alpha)
        translate([0, 0, layer_spacing])
        difference() {
            square(dimensions+border_2d, center=centered);
            translate(concat(border_2d, 0))
            square(dimensions-border_2d, center=centered);
        }

        // Center dot
        color("grey", alpha)
        translate([0, 0, 2*layer_spacing])
        circle(0.5);
    }

    translate([0, 0, layer_spacing])
    grid_element_label(element);
//    grid_element_label(element, function(e) grid_element_get_sequence_number(e));
}

/**
 * @brief Internal helper function for assigning colors to grid elements.
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

/*
 * @brief Print information about a grid element.
 */
module print_grid_element(element) {
    assert(is_grid_element(element), "Not a grid element.")
    assert(!grid_element_is_default(element))

    echo("grid_element:");
    echo(str("  index:\t    ", grid_element_get_index(element)));
    echo(str("  sequence_number:  ", grid_element_get_sequence_number(element)));
    echo(str("  position:\t    ", grid_element_get_position(element)));
    echo(str("  is_centered:\t    ", grid_element_is_centered(element)));
    echo(str("  dimensions:\t    ", grid_element_get_dimensions(element)));
}
