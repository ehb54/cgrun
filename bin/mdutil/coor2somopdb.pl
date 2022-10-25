#!/usr/bin/perl

### user defines

### end user defines

use File::Temp qw(tempfile);
use File::Basename;

my $dirname = dirname(__FILE__);

$notes = "usage: $0 ascii-coor-file

takes ascii coor file and produces a somo pdb

";

$f = shift || die $notes;

$f =~ s/\.coor$//;
$basename = $f;

$f = "$f.coor";

die "$f does not exist\n" if !-e $f;
die "$f is not readable\n" if !-r $f;

sub echoline {
    print '-'x80 . "\n"
}

sub runcmd {
    my $cmd = shift;
    echoline();
    print "$cmd\n";
    echoline();
    print `$cmd`;
    die "error status returned $?\n" if $?;
}

$fsomo = "${basename}.coor.somo.pdb";

$mkchimera =
    "open $fsomo; write format pdb 0 $fsomo; close all";

my ( $fh, $ft ) = tempfile( "mkchimera.XXXXXX", UNLINK => 1 );
print $fh $mkchimera;
close $fh;

@cmds = (
    "~/mdutil/somopdb.pl ${basename}.coor"
    ,"~/mdutil/pdbcutwi.pl $fsomo"
    ,"chimera --nogui < $ft"
    );

for $cmd ( @cmds ) {
    runcmd( $cmd );
}

    
