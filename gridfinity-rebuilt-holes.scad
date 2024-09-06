/**
 * @file gridfinity-rebuilt-holes.scad
 * @brief Functions to create different types of holes in an object.
 */

include <standard.scad>
use <generic-helpers.scad>

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

/**
 * @brief Wave generation function for wrapping a circle.
 * @param t An angle of the circle.  Between 0 and 360 degrees.
 * @param count The number of **full** waves in a 360 degree circle.
 * @param range **Half** the difference between minimum and maximum values.
 * @param vertical_offset Added to the output.
 *                        When wrapping a circle, radius of that circle.
 * @details
 *    If plotted on an x/y graph this produces a standard sin wave.
 *    Range only seems weird because it describes half a wave.
 *    Mapped by doing [sin(t), cost(t)] * wave_function(...).
 *    When wrapping a circle:
 *      Final Outer radius is (wave_vertical_offset + wave_range).
 *      Final Inner radius is (wave_vertical_offset - wave_range).
 */
function wave_function(t, count, range, vertical_offset) =
    (sin(t * count) * range) + vertical_offset;

/**
 * @brief A circle with crush ribs to give a tighter press fit.
 * @details Extrude and use as a negative modifier.
 *          Idea based on Slant3D's video at 5:20 https://youtu.be/Bd7Yyn61XWQ?t=320
 *          Implementaiton is completely different.
 *          Important: Lower ribs numbers just result in a deformed circle.
 * @param outer_radius Final outer radius.
 * @param inner_radius Final inner radius.
 * @param ribs Number of crush ribs the circle has.
**/
module ribbed_circle(outer_radius, inner_radius, ribs) {
    assert(outer_radius > 0, "outer_radius must be positive");
    assert(inner_radius > 0, "inner_radius must be positive");
    assert(ribs > 0, "ribs must be positive");
    assert(outer_radius > inner_radius, "outer_radius must be larger than inner_radius");

    wave_range = (outer_radius - inner_radius) / 2;
    wave_vertical_offset = inner_radius + wave_range;
    fragments=get_fragments_from_r(wave_vertical_offset);
    degrees_per_fragment = 360/fragments;

    // Circe with a wave wrapped around it
    wrapped_circle = [ for (i = [0:degrees_per_fragment:360])
        [sin(i), cos(i)] * wave_function(i, ribs, wave_range, wave_vertical_offset)
    ];

    polygon(wrapped_circle);
}

/**
 * @brief A cylinder with crush ribs to give a tighter press fit.
 * @details To be used as the negative for a hole.
 * @see ribbed_circle
 * @param outer_radius Outer Radius of the crush ribs.
 * @param inner_radius Inner Radius of the crush ribs.
 * @param height Cylinder's height.
 * @param ribs Number of crush ribs.
 */
module ribbed_cylinder(outer_radius, inner_radius, height, ribs) {
    assert(height > 0, "height must be positive");
    linear_extrude(height)
    ribbed_circle(
        outer_radius,
        inner_radius,
        ribs
    );
}

/**
 * @brief Make a hole printable without suports.
 * @see https://www.youtube.com/watch?v=W8FbHTcB05w
 * @param inner_radius Radius of the inner hole.
 * @param outer_radius Radius of the outer hole.
 * @param outer_height Height of the outer hole.
 * @param layers Number of layers to make printable.
 * @details This is the negative designed to be cut out of the magnet hole.
 *          Use it with `difference()`.
 *          Special handling is done to support a single layer,
 *          and because the last layer (unless there is only one) has a different shape.
 */
module make_hole_printable(inner_radius, outer_radius, outer_height, layers=2) {
    assert(inner_radius > 0, "inner_radius must be positive");
    assert(outer_radius > 0, "outer_radius must be positive");
    assert(layers > 0);

    tollerance = 0.01;  // Ensure everything is fully removed.
    height_adjustment = outer_height - (layers * LAYER_HEIGHT);

    // Needed, since the last layer should not be used for calculations,
    // unless there is a single layer.
    calculation_layers = max(layers-1, 1);

    cube_height = LAYER_HEIGHT + 2*tollerance;
    inner_diameter = 2*(inner_radius+tollerance);
    outer_diameter = 2*(outer_radius+tollerance);
    per_layer_difference = (outer_diameter-inner_diameter) / calculation_layers;

    initial_matrix = affine_translate([0, 0, cube_height/2-tollerance + height_adjustment]);

    // Produces data in the form [affine_matrix, [cube_dimensions]]
    // If layers > 1, the last item produced has an invalid "affine_matrix.y", because it is beyond calculation_layers.
    // That is handled in a special case to avoid doing a check every loop.
    cutout_information = [
        for(i=0; i <= layers; i=i+1)
        [
            initial_matrix * affine_translate([0, 0, (i-1)*LAYER_HEIGHT]) *
                affine_rotate([0, 0, is_even(i) ? 90 : 0]),
            [outer_diameter-per_layer_difference*(i-1),
                outer_diameter-per_layer_difference*i,
                cube_height]
        ]
    ];

    difference() {
        translate([0, 0, layers*cube_height/2 + height_adjustment])
        cube([outer_diameter+tollerance, outer_diameter+tollerance, layers*cube_height], center = true);

        for (i = [1 : calculation_layers]){
            data = cutout_information[i];
            multmatrix(data[0])
            cube(data[1], center = true);
        }
        if(layers > 1) {
            data = cutout_information[len(cutout_information)-1];
            multmatrix(data[0])
            cube([data[1].x, data[1].x, data[1].z], center = true);
        }
    }
}

/**
* @brief Refined hole based on Printables @grizzie17's Gridfinity Refined
* @details Magnet is pushed in from +X direction, and held in by friction.
*          Small slit on the bottom allows removing the magnet.
* @see https://www.printables.com/model/413761-gridfinity-refined
*/
module refined_hole() {
    refined_offset = LAYER_HEIGHT * REFINED_HOLE_BOTTOM_LAYERS;

    // Poke through - For removing a magnet using a toothpick
    ptl = refined_offset + LAYER_HEIGHT; // Additional layer just in case
    poke_through_height = REFINED_HOLE_HEIGHT + ptl;
    poke_hole_radius = 2.5;
    magic_constant = 5.60;
    poke_hole_center = [-12.53 + magic_constant, 0, -ptl];

    translate([0, 0, refined_offset])
    union() {
        // Magnet hole
        translate([0, -REFINED_HOLE_RADIUS, 0])
        cube([11, REFINED_HOLE_RADIUS*2, REFINED_HOLE_HEIGHT]);
        cylinder(REFINED_HOLE_HEIGHT, r=REFINED_HOLE_RADIUS);

        // Poke hole
        translate([poke_hole_center.x, -poke_hole_radius/2, poke_hole_center.z])
        cube([10 - magic_constant, poke_hole_radius, poke_through_height]);
        translate(poke_hole_center)
        cylinder(poke_through_height, d=poke_hole_radius);
    }
}

/**
 * @brief Create a cone given a radius and an angle.
 * @param bottom_radius Radius of the bottom of the cone.
 * @param angle Angle as measured from the bottom of the cone.
 * @param max_height Optional maximum height.  Cone will be cut off if higher.
 */
module cone(bottom_radius, angle, max_height=0) {
    assert(bottom_radius > 0);
    assert(angle > 0 && angle <= 90);
    assert(max_height >=0);

    height = tan(angle) * bottom_radius;
    if(max_height == 0 || height < max_height) {
        // Normal Cone
        cylinder(h = height, r1 = bottom_radius, r2 = 0, center = false);
    } else {
        top_angle = 90 - angle;
        top_radius = bottom_radius - tan(top_angle) * max_height;
        cylinder(h = max_height, r1 = bottom_radius, r2 = top_radius, center = false);
    }
}

/**
 * @brief Create a screw hole
 * @param radius Radius of the hole.
 * @param height Height of the hole.
 * @param supportless If the hole is designed to be printed without supports.
 * @param chamfer_radius If the hole should be chamfered, then how much should be added to radius.  0 means don't chamfer
 * @param chamfer_angle If the hole should be chamfered, then what angle should it be chamfered at.  Ignored if chamfer_radius is 0.
 */
module screw_hole(radius, height, supportless=false, chamfer_radius=0, chamfer_angle = 45) {
    assert(radius > 0);
    assert(height > 0);
    assert(chamfer_radius >= 0);

    union(){
        difference() {
            cylinder(h = height, r = radius);
            if (supportless) {
                rotate([0, 0, 90])
                make_hole_printable(0.5, radius, height, 3);
            }
        }
        if (chamfer_radius > 0) {
            cone(radius + chamfer_radius, chamfer_angle, height);
        }
    }
}

/**
 * @brief Create an options list used to configure bin holes.
 * @param refined_hole Use gridfinity refined hole type.  Not compatible with "magnet_hole".
 * @param magnet_hole Create a hole for a 6mm magnet.
 * @param screw_hole Create a hole for a M3 screw.
 * @param crush_ribs If the magnet hole should have crush ribs for a press fit.
 * @param chamfer Add a chamfer to the magnet/screw hole.
 * @param supportless If the magnet/screw hole should be printed in such a way that the screw hole does not require supports.
 * @param embedded If the magent is inserted during the print. 
 */
function bundle_hole_options(refined_hole=false, magnet_hole=false, screw_hole=false, crush_ribs=false, chamfer=false,
supportless=false, embedded=false) =
    [refined_hole, magnet_hole, screw_hole, crush_ribs, chamfer, supportless, embedded];

/**
 * @brief A single magnet/screw hole.  To be cut out of the base.
 * @details Supports multiple options that can be mixed and matched.
 * @pram hole_options @see bundle_hole_options
 * @param o Offset
 */
module block_base_hole(hole_options, o=0) {
    assert(is_list(hole_options));

    // Destructure the options
    refined_hole = hole_options[0];
    magnet_hole = hole_options[1];
    screw_hole = hole_options[2];
    crush_ribs = hole_options[3];
    chamfer = hole_options[4];
    supportless = hole_options[5];
    embedded = hole_options[6];
    embedded_extra_layers = 3;

    // Validate said options
    if(refined_hole) {
        assert(!magnet_hole, "magnet_hole is not compatible with refined_hole");
    }

    screw_radius = SCREW_HOLE_RADIUS - (o/2);
    magnet_radius = MAGNET_HOLE_RADIUS - (o/2);
    magnet_inner_radius = MAGNET_HOLE_CRUSH_RIB_INNER_RADIUS - (o/2);
    screw_depth = h_base-o;
    // If using supportless / printable mode, need to add additional layers, so they can be removed later.
    supportless_additional_layers = screw_hole ? 2 : 3;
    magnet_depth = MAGNET_HOLE_DEPTH - o +
        (supportless ? supportless_additional_layers*LAYER_HEIGHT : 0);

    embedded_depth =  embedded_extra_layers*LAYER_HEIGHT;
    if(embedded) {
        magnet_depth = magnet_depth + embedded_depth;
    }

    union() {
        if(refined_hole) {
            refined_hole();
        }

        if(magnet_hole) {
            difference() {
                if(crush_ribs) {
                    ribbed_cylinder(magnet_radius, magnet_inner_radius, magnet_depth, MAGNET_HOLE_CRUSH_RIB_COUNT);
                } else {
                    if(embedded) {
                      // Leave a gap for the screwdriver for recycling
                      intersection() {
                        translate([-magnet_radius,-magnet_radius * 0.15,0])
                        cube([2*magnet_radius, magnet_radius * 0.3, embedded_depth]);
                        cylinder(h = embedded_depth, r=magnet_radius);
                      }
                      
                      translate([0, 0, embedded_depth])
                      cylinder(h = magnet_depth, r=magnet_radius);
                    } else {
                      cylinder(h = magnet_depth, r=magnet_radius);
                    }
                }

                if(supportless) {
                    make_hole_printable(
                    screw_hole ? screw_radius : 1, magnet_radius, magnet_depth, supportless_additional_layers);
                }
            }

            if(chamfer) {
                 cone(magnet_radius + CHAMFER_ADDITIONAL_RADIUS, CHAMFER_ANGLE, MAGNET_HOLE_DEPTH - o);
            }
        }
        if(screw_hole) {
            screw_hole(screw_radius, screw_depth, supportless,
                chamfer ? CHAMFER_ADDITIONAL_RADIUS : 0, CHAMFER_ANGLE);
        }
    }
}

//$fa = 8;
//$fs = 0.25;

if(!is_undef(test_options)){
    block_base_hole(test_options);
}

//block_base_hole(bundle_hole_options(
//    refined_hole=false,
//    magnet_hole=true,
//    screw_hole=true,
//    supportless=true,
//    crush_ribs=false,
//    chamfer=true
//));
//make_hole_printable(1, 3, 0);
