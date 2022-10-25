#!/usr/bin/perl

use File::Basename;
{
    my $scriptd = dirname(__FILE__);
    require "$scriptd/pdbutil.pm";
}


### user defines

$runtime   = 5000000;
$fsperstep = 2;

### end user defines
$nsperfs = 1e-6;

$nsperstep  = $runtime * $fsperstep * $nsperfs;

$notes = "usage: $0 steps

creates json for inserting into ~/mdjson for production steps
each step is a production step of ${nsperstep}ns

    ";

$steps = shift || die $notes;



for ( $i = 1; $i <= $steps; ++$i ) {
    $fin  = sprintf( "prod%4sns", myleftpad0( ($i - 1 ) * $nsperstep, 4 ) );
    $fout = sprintf( "prod%4sns", myleftpad0( $i * $nsperstep, 4 ) );
    
    $out .= <<"__EOD";
        ,{
            "description"  : "namd production $i"
            ,"active"      : true
            ,"template"    : "namdprod"
            ,"run"         : $runtime
            ,"structure"   : "step3_input.psf"
            ,"coordinates" : "step3_input.pdb"
            ,"inputname"   : "output/$fin"
            ,"output"      : "output/$fout"
        }
__EOD
}

print $out;

