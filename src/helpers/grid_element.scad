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
 * @brief Information about the given element from `grid_translate` or `grid_foreach`.
 * @details To be used by a child of `grid_translate`.
 * @assert If called anywhere else.
 * @returns An opaque data type to be passed to accessor functions.
 */
function grid_element_current(allow_default = false) =
    assert(is_grid_element($_grid_element),
        "No grid element available.")
    $_grid_element;

/**
 * @brief Parent grid of the current element.
 * @param element An opaque "grid_element" data object.
 * @returns An opaque "grid" data object.
 */
function grid_element_get_grid(element) =
    assert(is_grid_element(element), "Not a grid element.")
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
    let(grid=element[1])
    let(index=element[2])
    let(centered=element[3])

    let(perimeter = grid_get_perimeter(grid))
    let(raw_element_dimensions = grid_get_element_dimensions(grid))
    let(element_dimensions = grid_element_get_dimensions(element))

    let(raw_element_offset = [
        index.x * raw_element_dimensions.x,
        index.y * raw_element_dimensions.y,
        len(index) >= 3 ? index.z * raw_element_dimensions.z : 0
    ])
    let(perimeter_offset = [
        grid_element_is_first(element, 0) ? perimeter[0] : 0,
        grid_element_is_first(element, 1) ? perimeter[1] : 0,
        len(index) >= 3 && grid_element_is_first(element, 2) ?
            perimeter[2] : 0
    ])
    let(element_offset =[
        element_dimensions.x/2,
        element_dimensions.y/2,
        len(index) >= 3 ? element_dimensions.z/2 : 0
    ])
    grid_get_position_bottom_left(grid)
        + raw_element_offset + perimeter_offset
        + (centered ? element_offset : [0, 0, 0]);

/**
 * @brief Numeric index of the current element.
 * @warning: Ordering in which elements are rendered is **not** finalized and may change.
 * @details Equivalent to:
 *    ```
 *    sum([
 *        index[0],
 *        index[1]*num_elements[0],
 *        index[2]*num_elements[0]*num_elements[1],
 *        ...
 *    ])
 *    ```
 * @param element An opaque "grid_element" data object.
 * @returns A positive integer.
 */
function grid_element_get_sequence_number(element) =
    assert(is_grid_element(element), "Not a grid element.")
    let(grid=element[1])
    let(index=element[2])
    let(centered=element[3])
    let(num_elements=grid_get_num_elements(grid))
    let(rank=len(num_elements))

    [for(d=0,a=0,m=1;
            d<rank;
            a=a+index[d]*m,m=m*num_elements[d],d=d+1
        )
        a+index[d] * m
    ][rank-1];

/**
 * @brief Dimensions of the current grid_element.
 * @details Takes the grid perimeter into account.
 * @param element An opaque "grid_element" data object.
 * @returns A vector with the same rank as `grid_get_element_dimensions`.
 */
function grid_element_get_dimensions(element) =
    assert(is_grid_element(element), "Not a grid element.")
    let(grid=element[1])
    let(raw_element_dimensions=grid_get_element_dimensions(grid))
    let(perimeter=grid_get_perimeter(grid))
    let(rank=len(raw_element_dimensions))
    let(perimeter_adjustment = [ for(i=[0:rank-1])
        (grid_element_is_first(element, i) ? perimeter[i] : 0)
        + (grid_element_is_last(element, i) ? perimeter[i+rank] : 0)
    ])
    raw_element_dimensions - perimeter_adjustment;

/**
 * @brief If the element's position in the given dimension matches.
 * @param element An opaque "grid_element" data object.
 * @param dimension Dimension to check.
 *                  0: column (x)
 *                  1: row (y)
 *                  2: layer (z)
 *                  So on for higher dimensional grids.
 * @param position Where in the dimension to check.
 *                 0: first
 *                 `num_elements[dimension] - 1`: last.
 */
function grid_element_is_in_position(element, dimension, position) =
    assert(is_grid_element(element), "Not a grid element.")
    assert(is_num(dimension) && dimension >= 0)
    assert(is_num(position) && position >= 0)
    grid_element_get_index(element)[dimension] == position;

/**
 * @brief If this is one of the first elements in a given dimension.
 * @see grid_element_is_in_position
 */
function grid_element_is_first(element, dimension) =
    grid_element_is_in_position(element, dimension, 0);

/**
 * @brief If this is one of the last elements in a given dimension.
 * @see grid_element_is_in_position
 */
function grid_element_is_last(element, dimension) =
    assert(is_grid_element(element), "Not a grid element.")
    let(grid = element[1])
    let(num_elements = grid_get_num_elements(grid))
    assert(dimension < len(num_elements),
        str("Maximum dimension is ", len(num_elements) - 1))
    let(last = num_elements[dimension] - 1)
    grid_element_is_in_position(element, dimension, last);

function grid_element_is_first_col(element) =
    grid_element_is_first(element, 0);

function grid_element_is_first_row(element) =
    grid_element_is_first(element, 1);

function grid_element_is_last_col(element) =
    grid_element_is_last(element, 0);

function grid_element_is_last_row(element) =
    grid_element_is_last(element, 1);

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
    assert(!is_undef(label));

    dimensions = grid_element_get_dimensions(element);
    centered = grid_element_is_centered(element);
    output = str(is_function(label) ? label(element) : label);

    rotate_text = dimensions.x < dimensions.y;
    available_2d = rotate_text ? [dimensions.y, dimensions.x]
        : [dimensions.x, dimensions.y];
    final_available = available_2d - [2.5, 2.5];

    text_size = textmetrics(output,
        halign="center",
        valign="center"
    ).size;
    scaling_factor = [
        final_available.x / text_size.x,
        final_available.y / text_size.y
    ];
    square_scaling_factor =
        [min(scaling_factor), min(scaling_factor), 1];
//    echo(is_rotated=rotate_text,
//        text_size=text_size,
//        scaling_factor=scaling_factor);

    color("black")
    translate(centered ? [0, 0, 0] : dimensions/2)
    rotate([0, 0, rotate_text ? 90 : 0])
    scale(square_scaling_factor)
    text(output,
        halign="center",
        valign="center"
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
    assert(is_num(gap) && gap >= 0);
    assert(is_num(alpha) && alpha >= 0);
    assert(is_num(layer_spacing));

    rank = len(grid_element_get_dimensions(element));

    if(alpha > 0) {
        if (rank >= 3) {
            _debug_grid_element_3d(element, gap, alpha);
        } else {
            _debug_grid_element_2d(element, gap, alpha, layer_spacing);
        }
    }
}

/**
 * @brief Internal function.  Do not use directly.
 */
module _debug_grid_element_2d(element, gap, alpha, layer_spacing) {
    assert(is_grid_element(element), "Not a grid element.");
    assert(is_num(gap) && gap >= 0);
    assert(is_num(alpha) && alpha > 0);
    assert(is_num(layer_spacing));

    dimensions = grid_element_get_dimensions(element);
    rank = len(dimensions);
    centered = grid_element_is_centered(element);
    assert(rank == 2);

    dimensions_2d = [dimensions.x, dimensions.y];
    gap_2d = [gap, gap] / 2;
    border_2d = [0.1, 0.1] / 2;

    // Zero point dot
    color("grey", alpha)
    translate([0, 0, 2*layer_spacing])
    circle(0.5);

    translate([0, 0, layer_spacing])
    grid_element_label(element);
//    grid_element_label(element, function(e) grid_element_get_sequence_number(e));

    color(_element_color(element), alpha)
    square(dimensions_2d-gap_2d, center=centered);

    // Border
    color("black", alpha)
    translate([0, 0, layer_spacing])
    difference() {
        square(dimensions+border_2d, center=centered);
        translate(concat(border_2d, 0))
        square(dimensions-border_2d, center=centered);
    }
}

/**
 * @brief Internal function.  Do not use directly.
 */
module _debug_grid_element_3d(element, gap, alpha) {
    assert(is_grid_element(element), "Not a grid element.");
    assert(is_num(gap) && gap >= 0);
    assert(is_num(alpha) && alpha >= 0);

    dimensions = grid_element_get_dimensions(element);
    rank = len(dimensions);
    centered = grid_element_is_centered(element);
    assert(rank >= 3);

    border = 0.1;
    dimensions_2d = [dimensions.x, dimensions.y];
    gap_2d = [gap, gap] / 2;
    border_2d = [border, border] / 2;

    // Zero point sphere
    color("grey", alpha)
    sphere(r=0.5);

    color("black")
    linear_extrude(0.01, center=centered)
    grid_element_label(element);
//    grid_element_label(element, function(e) grid_element_get_sequence_number(e));

    // Lightly colored cubes
    color(_element_color(element), min(alpha, 0.1))
    linear_extrude(dimensions.z-gap, center=centered)
    square(dimensions_2d-gap_2d, center=centered);

    // Border
    color("black", alpha)
    linear_extrude(border, center=centered)
    difference() {
        square(dimensions+border_2d, center=centered);
        translate(concat(border_2d, 0))
        square(dimensions-border_2d, center=centered);
    }
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

    echo("grid_element:");
    echo(str("  index:\t    ", grid_element_get_index(element)));
    echo(str("  sequence_number:  ", grid_element_get_sequence_number(element)));
    echo(str("  position:\t    ", grid_element_get_position(element)));
    echo(str("  is_centered:\t    ", grid_element_is_centered(element)));
    echo(str("  dimensions:\t    ", grid_element_get_dimensions(element)));
}
