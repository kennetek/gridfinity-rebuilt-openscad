# Gridfinity Spiral Vase

Some assembly required!
Adaptation of Gridfinity bins to work with spiral vase mode, as to save filament and print time. A big drawback of using vase mode for Gridfinity bins was that they would be very flimsy, and would lack the features that make Gridfinity such a good organizational tool. The goal of this implementation was to maintain the design philosophy while working under the constraints of vase mode. 

[<img src="../images/vase_features_front.gif" width="320">]()
[<img src="../images/vase_features_back.gif" width="320">]()
[<img src="../images/vase_dividers.gif" width="320">]()
[<img src="../images/vase_bottom.gif" width="320">]()
[<img src="../images/vase_base.gif" width="320">]()
[<img src="../images/vase_tabs.gif" width="320">]()

## Features
As this script is a child of the `gridfinity-rebuilt-base.scad` script, it has most of the same features. Of course, vase mode does have some limitations (it can only do compartments along the X-axis, not the Y-axis). This script is not stand-alone, you must download the full repository for it to work. See the full list of features [here](https://github.com/kennetek/gridfinity-rebuilt-openscad). 

## Instructions
Normal Gridfinity is impossible to convert to vase mode due to the geometry of the bases, meaning most existing vase mode Gridfinity models are limited to 1x1 bins. How this script gets around the impossible is to use two separate pieces. **The bin and bases must be printed separately, and then glued together to form the final bin.** While this is slightly more work, there is an added bonus to this method, as for larger bins you may not need every single grid slot to have a base, you only really need them on the corners, or the edges, with some in the middle for support. Using less bases saves filament and print time.

All parameters are global. The customizer has descriptions for all parameters. It is **essential** that the section *Printer Settings* matches your preferred slicer's settings, otherwise the model will not slice correctly. Additionally, you have to turn on the spiral vase parameter in your slicer. If you do not know what vase mode is, [this](https://www.youtube.com/watch?v=HZSFoFYpBaA) is a helpful video. 

1. Change the *Printer Settings* parameters to match your slicer and printer settings.
2. Run the `gridfinityVaseBase()` module. This will generate a single spiral-capable base. Export as an STL file. You will need to print multiple of these, so it recommended to fill a base plate with them using the "complete individual objects" option (or equivilant) in your slicer. You only need to do this step initially, and then each time your printer settings change afterwards. 
3. Change the bin parameters and run `gridfinityVase()` module to generate the main bin. 
4. Glue bases to the bottom of the bin. I recommend superglue on the corners and the top of the magnet holes. 

How your sliced files should look (cross section shown for 1x1 bin):

[<img src="../images/slicer_bin.png" height="200">]()
[<img src="../images/slicer_base.png" height="200">]()

Example sliced files can be found on the [Printables](https://www.printables.com/model/284371-spiral-vase-gridfinity-in-openscad) page. 

## Statistics
Given how it has become a bit of a [challenge](https://www.printables.com/model/265271-gridfinity-lite-economical-plain-storage-bins) to reduce the weight and print time for these bins, here is a comparison for a large bin:

| Type | Weight | Time |
|--------------|-----------|------------|
Plain 4x2x6 Bin | 114.66g | 3h58m
Vase 4x2x6 Bin with 8 Bases | 68.31g | 2h27m
Vase 4x2x6 Bin with 4 Bases (only corners) | 56.43g | 1h59m

Clearly, vase mode is very quick and quite lightweight. However, this fundamentally means the bins will be weaker, so keep that in mind. 

## Recommendations
For best results, use a version of OpenSCAD with the fast-csg feature. As of writing, this feature is only implemented in the [development snapshots](https://openscad.org/downloads.html). To enable the feature, go to Edit > Preferences > Features > fast-csg. On my computer, this sped up rendering from 10 minutes down to a couple of seconds, even for comically large bins.  

## Enjoy!

[<img src="../images/spin.gif" width="160">]()

[Gridfinity](https://www.youtube.com/watch?v=ra_9zU-mnl8) by [Zack Freedman](https://www.youtube.com/c/ZackFreedman/about)
