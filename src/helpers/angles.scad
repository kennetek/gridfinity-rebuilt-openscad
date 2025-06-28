/**
 * @file angles.scad
 * @brief Helper functions for angle calculations.
 * @details Not gridfinity specific.
 */

/**
 * @brief `sign` function, but 0 means a positive sign.
 * @description This is useful for applying signs to trig functions.
 * @returns -1 or 1.
 */
function signp(number) =
    assert(is_num(number))
    let(n = sign(number))
    n == 0 ? 1 : n;

/*
 * @brief Convert an angle to between -180 and +180 degrees.
 */
function normalize_angle(angle) =
    assert(is_num(angle))
    let(a = angle%360)
    a > 180 ? a - 360 :
    a < -180 ? a + 360 : a;

/*
 * @brief Convert an angle to between 0 and +360 degrees.
 */
function positive_angle(angle) =
    assert(is_num(angle))
    let(a = angle%360)
    a < 0 ? (a + 360) % 360 : a;

/**
 * @brief Determines the number of fragments in a circle. Aka, Circle resolution.
 * @param r Radius of the circle.
 * @details Recommended function from the manual as a translation of the OpenSCAD function.
 *          Used to improve performance by not rendering every single degree of circles/spheres.
 * @see https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Other_Language_Features#Circle_resolution:_$fa,_$fs,_and_$fn
 */
function get_fragments_from_r(r) =
    assert(r > 0)
    ($fn>0?($fn>=3?$fn:3):ceil(max(min(360/$fa,r*2*PI/$fs),5)));
