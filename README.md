# Gridfinity Rebuilt in OpenSCAD 

[![CC BY-NC-SA 4.0][cc-by-nc-sa-shield]][cc-by-nc-sa]

A ground-up port (with a few extra features) of the stock [gridfinity](https://www.youtube.com/watch?v=ra_9zU-mnl8) bins in OpenSCAD. Open to feedback, because I could not feasibly test all combinations of bins. I tried my best to exactly match the original gridfinity dimensions, but some of the geometry is slightly incorrect (mainly fillets). However, I think they are negligible differences, and will not appear in the printed model.

[<img src="./images/base_dimension.gif" width="320">]()
[<img src="./images/compartment_dimension.gif" width="320">]()
[<img src="./images/height_dimension.gif" width="320">]()
[<img src="./images/tab_dimension.gif" width="320">]()
[<img src="./images/holes_dimension.gif" width="320">]()
[<img src="./images/custom_dimension.gif" width="320">]()

## Features
- any size of bin (width/length/height)
- height by units, internal depth, or overall size
- any number of compartments (along both X and Y axis)
- togglable scoop
- togglable tabs, split tabs, and tab alignment
- togglable holes (with togglable supportless printing hole structures)
- manual compartment construction (make the most wacky bins imaginable)
- togglable lip (if you don't care for stackability)
- dividing bases (if you want a 1.5 unit long bin, for instance)

### Printable Holes
The printable holes allow your slicer to bridge the gap inside the countersunk magnet hole (using the technique shown [here](https://www.youtube.com/watch?v=W8FbHTcB05w)) so that supports are not needed.

[<img src="./images/slicer_holes.png" height="200">]()
[<img src="./images/slicer_holes_top.png" height="200">]()

## Recommendations
For best results, use a version of OpenSCAD with the fast-csg feature. As of writing, this feature is only implemented in the [development snapshots](https://openscad.org/downloads.html). To enable the feature, go to Edit > Preferences > Features > fast-csg. On my computer, this sped up rendering from 10 minutes down to a couple of seconds, even for comically large bins.  

## Modules  
Run these functions inside the *Commands* section of *gridfinity-rebuilt-bins.scad*.

### `gridfinityInit(gridx, gridy, height, height_internal, length)`  
Initializes the top part of the bin (walls and solid section). All bins have to use this module, and have the compartments cut out from it. 

Parameter | Range | Description
--- | ----- | ---
`gridx` | {n>0\|n∈R} | number of bases along the x-axis  
`gridy` | {n>0\|n∈R} | number of bases along the y-axis  
`height` | {n>0\|n∈R} | height of the bin, in millimeters (but not exactly). See the `height()` function for more info.
`height_internal` | {n>0\|n∈R} | height of the internal block. Can be lower than bin height to save filament on custom bins. default of 0 means use the calculated height.
`length` | {n>0\|n∈R} | length of one unit of the base. default: 42 (The Answer to the Ultimate Question of Life, the Universe, and Everything.)

```
// Example: generate a 3x3x6 bin with a 42mm unit size
gridfinityInit(3, 3, height(6), 0, 42) {
	cutEqual(n_divx = 3, n_divy = 3, style_tab = 0, enable_scoop = true);
}
```

### `height(gridz, gridz_define, enable_lip, enable_zsnap)`  
Calculates the proper height for bins. 

Parameter | Range | Description
--- | ----- | ---
`gridz` | {n>0\|n∈R} | bin height. See bin height information and "gridz_define" below.  
`gridz_define` | {n>0\|n∈R} | determine what the variable "gridz" applies to based on your use case. default: 0. <br>     • (0) gridz is the height of bins in units of 7mm increments - Zack's method <br>     • (1) gridz is the internal height in millimeters <br>     • (2) gridz is the overall external height of the bin in millimeters
`enable_lip` | boolean | if you are not stacking the bin, you can disable the top lip to save space. default: true
`enable_zsnap` | boolean | automatically snap the bin size to the nearest 7mm increment. default: true

```
// Example: height for a 6 unit high bin
height(6);

// Example: height for a bin that can fit (at maximum) a 30mm high object inside
height(30, 1, true, false); 
```

### `gridfinityBase(gridx, gridy, length, div_base_x, div_base_y, style_hole)`  
Generates the bases for bins. Has various different hole styles, and can be subdivided.

Parameter | Range | Description
--- | ----- | ---
`gridx` | {n>0\|n∈R} | number of bases along the x-axis  
`gridy` | {n>0\|n∈R} | number of bases along the y-axis 
`length` | {n>0\|n∈R} | length of one unit of the base. default: 42
`div_base_x` | {n>=0\|n∈Z} | number of divisions per 1 unit of base along the X axis. (default 1, only use integers. 0 means automatically guess the division)
`div_base_y` | {n>=0\|n∈Z} | number of divisions per 1 unit of base along the Y axis. (default 1, only use integers. 0 means automatically guess the division)
`style_hole` | {0, 1, 2, 3} | the style of holes in the bases <br>     • (0) No holes <br>     • (1) Magnet holes only <br>     • (2) Magnet and screw holes - no printable slit <br>     • (3) Magnet and screw holes - with printable slit

```
// Example: generate a 3x3 base with a 42mm unit size and clean magnet holes
gridfinityBase(3, 3, 42, 0, 0, 1);
```

### `cutEqual(n_divx, n_divy, style_tab, enable_scoop)`  
Generates the "traditional" bin cutters. It is a utility function that creates evenly distributed compartments. 

Parameter | Range | Description
--- | ----- | ---
`n_divx` | {n>0\|n∈Z}  | number of compartments along X
`n_divy` | {n>0\|n∈Z}  | number of compartments along Y
`style_tab` | {0,1,2,3,4,5} | how the tabs for labels are generated. <br>     • (0) Full tabs across the entire compartment <br>     • (1) automatic tabs, meaning left aligned tabs on the left edge, right aligned tabs on right edge, center tabs otherwise <br>     • (2) left aligned tabs <br>     • (3) center aligned tabs <br>     • (4) right aligned tabs <br>     • (5) no tabs
`enable_scoop` | boolean | toggles the scoopy bit on the bottom edge that allows easy removal of items

```
// Example: this generates 9 compartments in a 3x3 grid, and all compartments have a full tab and a scoop
gridfinityInit(3, 3, height(6), 0, 42) {
	cutEqual(n_divx = 3, n_divy = 3, style_tab = 0, enable_scoop = true);
}
```

### `cut(x, y, w, h, t, s)` 
Cuts a single compartment into the bin at the provided location with the provided attributes. The coordinate system for compartments originates (0,0) at the bottom left corner of the bin, where 1 unit is the length of 1 base. Positive X and positive Y are in the same direction as the global coordinate system.
Parameter | Range | Description
--- | ----- | ---
`x` | {n>=0\|n∈R} | X coordinate of the compartment (position of left edge of compartment)
`y` | {n>=0\|n∈R} | Y coordinate of the compartment (position of bottom edge of compartment)
`w` | {n>0\|n∈R} | Width of the compartment, in base units (1 unit = 1 `length`)
`h` | {n>0\|n∈R} | Height of the compartment, in base units (1 unit = 1 `length`)
`t` | {0,1,2,3,4,5} | how the tabs for labels are generated for this specfic compartment. <br>     • (0) Full tabs across the entire compartment <br>     • (1) automatic tabs, meaning left aligned tabs on the left edge, right aligned tabs on right edge, center tabs otherwise <br>     • (2) left aligned tabs <br>     • (3) center aligned tabs <br>     • (4) right aligned tabs <br>     • (5) no tabs
`s` | boolean | toggles the scoopy bit on the bottom edge that allows easy removal of items, for this specific compartment

```
// Example:
// this cuts two compartments that are both 1 wide and 2 high. 
// One is on the bottom left, and the other is at the top right. 
gridfinityInit(3, 3, height(6), 0, 42) {
    cut(0, 0, 1, 2, 0, true);
    cut(2, 1, 1, 2, 0, true);
}
```

### `cut_move(x, y, w, h)` 
Moves all of its children from the global origin to the center of the area that a compartment would normally fill, and uses them to cut from the bin. This allows you to easily make custom cutouts in the bin.
Parameter | Range | Description
--- | ----- | ---
`x` | {n>=0\|n∈R} | X coordinate of the area (position of left edge)
`y` | {n>=0\|n∈R} | Y coordinate of the area (position of bottom edge)
`w` | {n>0\|n∈R} | Width of the area, in base units (1 unit = 1 `length`)
`h` | {n>0\|n∈R} | Height of the area, in base units (1 unit = 1 `length`)

```
// Example:
// cuts a cylindrical hole of radius 5
// hole center is located 1/2 units from the right edge of the bin, and 1 unit from the top
gridfinityInit(3, 3, height(6), 0, 42) {
    cut_move(x=2, y=1, w=1, h=2) {
          cylinder(r=5, h=100, center=true);
    }
}
```

More complex examples of all modules can be found in the scripts.

## Enjoy!

[<img src="./images/spin.gif" width="160">]()

[Gridfinity](https://www.youtube.com/watch?v=ra_9zU-mnl8) by [Zack Freedman](https://www.youtube.com/c/ZackFreedman/about)

This work is licensed under the same license as Gridfinity, being a 
[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License][cc-by-nc-sa].

[![CC BY-NC-SA 4.0][cc-by-nc-sa-image]][cc-by-nc-sa]

[cc-by-nc-sa]: http://creativecommons.org/licenses/by-nc-sa/4.0/
[cc-by-nc-sa-image]: https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png
[cc-by-nc-sa-shield]: https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg
