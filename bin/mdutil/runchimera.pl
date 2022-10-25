#!/usr/bin/perl

### user defines

### end user defines

use File::Temp qw(tempfile);
use File::Basename;

my $dirname = dirname(__FILE__);

$notes = "usage: $0 pdb-file

runs pdb through chimera

";

$f = shift || die $notes;

$f =~ s/\.pdb$//;
$basename = $f;

$f = "$f.pdb";

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

$fsomo = "${basename}.pdb";
$fout = "${basename}.chimera.pdb";

$mkchimera =
    "open $fsomo; write format pdb 0 $fout; close all";

my ( $fh, $ft ) = tempfile( "mkchimera.XXXXXX", UNLINK => 1 );
print $fh $mkchimera;
close $fh;

@cmds = (
    "chimera --nogui < $ft"
    );

for $cmd ( @cmds ) {
    runcmd( $cmd );
}

    
