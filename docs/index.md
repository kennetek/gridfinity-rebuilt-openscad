## Introduction
Gridfinity rebuilt aims to remake the brilliant Gridfinity project from [Zack Freedman](https://www.youtube.com/c/ZackFreedman/about) in a more robust and open-source way than the original Fusion 360 files. Many major CAD suites struggle with making parametric models constructed from linear patterns, due to changing fillet edges and seams. Thus, a pure mathematical approach using OpenSCAD can allow a single solution for all possible bin variants. 

The project has expanded into more eccentric models that use modules from the original generator. This wiki aims to document these modules in great detail. 

Models are generated subtractively. First, the solid bin and bases are constructed, and then the compartments and holes are removed. This allows for internal fillets that nearly match the originals. However, they are not exactly perfect. There are some fillets that are too small and too difficult to be worth implementing, as most printers do not have a high enough resolution for it to matter. 

## Getting Started
For best results, use a version of OpenSCAD with the fast-csg feature. As of writing, this feature is only implemented in the [development snapshots](https://openscad.org/downloads.html). To enable the feature, go to Edit > Preferences > Features > fast-csg. This can speed up rendering from 10 minutes down to a couple of seconds, even for comically large bins. It is not a requirement to use development versions of OpenSCAD. 

Most files will come ready-to-run, so parameters can be changed using OpenSCAD's built-in customizer window, and the bins will automatically generate. However, all modules are packed up nicely, so any module can be imported into other files or have more custom modifications beyond tweaking the parameters. 

## Script Structure
* Information (Imports / Script Details)
* Parameters (Shown in Customizer)
* Implementation (Executing the Parameters)
* Construction (Script-Specific Modules and Constants)
* Examples

The two files which do not follow these conventions are `gridfinity-rebuilt-utility` and `gridfinity-rebuilt-constants`. These files are not meant to be exposed to the user, except for special requirements that the normal parameters cannot handle. Their respective wiki pages go into more depth. 

**NOTE: This documentation is a work in progress, just like the rest of the repository, so parts may still be under construction.**
