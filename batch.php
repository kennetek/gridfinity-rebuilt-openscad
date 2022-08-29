<?php
$maxhorizontal = 6;
for ($h=3;$h<=12;$h+=3) {
    for ($w=1;$w<=$maxhorizontal;$w++){
        for ($d=$w;$d<=$maxhorizontal;$d++){
            $outdir = "./batchout/{$h}h/";
            $outfile = $outdir . "gridfinity-lite-{$w}x{$d}x{$h}.stl";
            if (!file_exists($outdir)){
                mkdir($outdir);
            }
            if (!file_exists($outfile)) {
                echo $outfile . "\n";
                $outfile = addslashes($outfile);
                exec("openscad gridfinity-rebuilt.scad -o {$outfile} -Dgridx={$w} -Dgridy={$d} -Dgridz={$h}");
            }
        }
    }
}

