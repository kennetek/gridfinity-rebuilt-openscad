#!/bin/env python3

# Generate Gridfinity Lite bin sets

from os import makedirs, system
from os.path import exists, join

for h in range(3, 12, 3):
    for w in range(1,6):
        for d in range(w, 6):
            out_path = join("stl", f"{h}h")
            if not exists(out_path):
                makedirs(out_path)
            out_file = join(out_path, f"gridfinity-lite-{w}x{d}x{h}.stl");
            if not exists(out_file):
                print(f"-> {out_file}")
                system(f"openscad gridfinity-rebuilt-bins.scad --export-format binstl -o {out_file} -Dgridx={w} -Dgridy={d} -Dgridz={h} -Dstyle_tab=5 -Denable_scoop=false -Dstyle_hole=0 -Dlite_mode=true");