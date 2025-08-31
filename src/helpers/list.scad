/**
 * @file
 * @brief List helper functions.
 * @details These include some common operations which should probably be included with OpenSCAD.
 */

 /**
 * @brief Reverse the order of elements in a list.
 */
function reverse(list) =
    assert(is_list(list))
    [for(i=[len(list)-1:-1:0]) list[i]];

/**
 * @brief Use an accumulator function to convert a list to a single element.
 * @param list
 * @param accumulator Function to accumulate values.
 *     Must be in the form `accumulated=fn(accumulated, current)`.
 * @param start Initial value.
 */
function aggregate(list, accumulator, start) =
    assert(is_list(list))
    assert(is_function(accumulator))
    assert(!is_undef(start))
    let(count=len(list))
    [
        for(i=0, a=start; i<count; a=accumulator(a, list[i]),i=i+1)
        accumulator(a, list[i])
    ][count-1];

/**
 * @brief Add all list elements together.
 */
function sum(list) =
    let(add = function(a, b) a+b)
    aggregate(list, add, 0);

/**
 * @brief If all list elements return true.
 * @param list
 * @param test_fn Function in the form `bool=fn(value)`
 * @returns boolean
 */
function all(list, test_fn) =
    assert(is_list(list))
    assert(is_function(test_fn))
    min([for(e=list) test_fn(e) ? 1 : 0]) == 1;

/**
 * @brief If any list element returns true.
 * @param list
 * @param test_fn Function in the form `bool=fn(value)`
 * @returns boolean
 */
function any(list, test_fn) =
    assert(is_list(list))
    assert(is_function(test_fn))
    max([for(e=list) test_fn(e) ? 1 : 0]) == 1;

/**
 * @brief If no list element return true.
 * @param list
 * @param test_fn Function in the form `bool=fn(value)`
 * @returns boolean
 */
function none(list, test_fn) =
    !any(list, test_fn);

/**
 * @brief Convert anything to a list.
 * @param object The object to convert.
 *        Lists are trimmed.
 *        All other types are replicated.
 * @param n Final number of objects.
 * @throws If object is a list with less than n elements.
 * @returns A list with n elements.
 */

function as_list(object, n) =
    is_list(object) ?
        assert(len(object) >= n)
        [for(i=[0:n-1]) object[i]]
    : [for(i=[0:n-1]) object];
/**
 * @brief Convert anything to a 2d list.
 */
function as_2d(object) = as_list(object, 2);

/**
 * @brief Convert anything to a 3d list.
 */
function as_3d(object) = as_list(object, 3);

$test_list = true;
if($test_list) {
    assert(reverse([]) == []);
    assert(reverse([1]) == [1]);
    assert(reverse([1, 2, 3, 4]) == [4, 3, 2, 1]);

    assert(sum([1, 2, 3])==6);

    test_f = function(v) v!=0;
    assert(any([1, 1, 1], test_f));
    assert(any([0, 1, 0], test_f));
    assert(!any([0, 0, 0], test_f));
    assert(all([1, 1, 1], test_f));
    assert(!all([0, 1, 0], test_f));
    assert(!all([0, 0, 0], test_f));
    assert(!none([1, 1, 1], test_f));
    assert(!none([0, 1, 0], test_f));
    assert(none([0, 0, 0], test_f));

    assert(as_2d(undef) == [undef, undef]);
    assert(as_2d("abc") == ["abc", "abc"]);
    assert(as_2d(1) == [1, 1]);
    assert(as_2d([1, 2]) == [1, 2]);
    assert(as_2d([1, 2, 3]) == [1, 2]);
}
