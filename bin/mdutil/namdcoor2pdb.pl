#!/usr/bin/perl


use File::Temp qw(tempfile);

$notes = "usage: $0 psf coor

";

$fpsf = shift || die $notes;
die "$fpsf does not exist\n" if !-e $fpsf;
die "$fpsf is not readable\n" if !-r $fpsf;

$fcoor = shift || die $notes;
die "$fcoor does not exist\n" if !-e $fcoor;
die "$fcoor is not readable\n" if !-r $fcoor;


sub runcmd {
    my $cmd = shift;
    print "$cmd\n";
    print `$cmd`;
    die "error status returned $?\n" if $?;
}


# 

$fo = "$fcoor.pdb";

$tcl =
    "mol new $fpsf
mol addfile $fcoor
set sel [atomselect top all]
\$sel writepdb $fo
"
    ;

my ( $fh, $ft ) = tempfile( "namdcoor2pdbtcl.XXXXXX", UNLINK => 0 );
print $fh $tcl;
close $fh;

runcmd( "vmd -dispdev text -eofexit < $ft" );
print ">$fo\n";
