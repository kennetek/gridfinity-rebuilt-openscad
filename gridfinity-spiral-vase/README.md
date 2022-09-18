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
As this script is a child of the `gridfinity-rebuilt-base.scad` script, it has most of the same features. Of course, vase mode does have some limitations (it can only do compartments along the X-axis, not the Y-axis). 

## Instructions
Gridfinity is impossible to convert to vase mode due to the geometry of the bases. Thus, how this script gets around the impossible is to use two separate pieces. The bin and bases must be printed separately, and then glued together to form the final bin. There is an added bonus to this method, as for larger bins, you may not need every single grid slot to have a base, you can just have them be on the corners, or the edges, with some in the middle for support. This further saves filament and print time. 
All parameters are global. The customizer has descriptions for all parameters. There are two functions, `gridfinityVase()` and `gridfinityVaseBase()`. The former builds the bin section, while the latter builds a singular base. These should be exported separately. 
It is **essential** that the section *Printer Settings* matches your preferred slicer's settings, otherwise the model will not slice correctly.

[<img src="../images/slicer_bin.png" height="200">]()
[<img src="../images/slicer_base.png" height="200">]()

## Recommendations
For best results, use a version of OpenSCAD with the fast-csg feature. As of writing, this feature is only implemented in the [development snapshots](https://openscad.org/downloads.html). To enable the feature, go to Edit > Preferences > Features > fast-csg. On my computer, this sped up rendering from 10 minutes down to a couple of seconds, even for comically large bins.  

## Enjoy!

[<img src="./images/spin.gif" width="160">]()

[Gridfinity](https://www.youtube.com/watch?v=ra_9zU-mnl8) by [Zack Freedman](https://www.youtube.com/c/ZackFreedman/about)
