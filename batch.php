<?php

for ($h=3;$h<=12;$h+=3) {
    for ($w=1;$w<=4;$w++){
        for ($d=$w;$d<=4;$d++){
            $outfile = "./batchout/gridfinity-lite-{$w}x{$d}x{$h}.stl";
            if (!file_exists($outfile)) {
                echo $outfile . "\n";
                exec("openscad gridfinity-rebuilt.scad -o {$outfile} -Dgridx={$w} -Dgridy={$d} -Dgridz={$h}");
            }
        }
    }
}

