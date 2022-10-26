#!/usr/bin/perl

### user defines

$chimerabin = "/usr/local/chimera-1.16/bin";

### end user defines

use File::Temp qw(tempfile);
use File::Basename;

my $dirname = dirname(__FILE__);

$notes = "usage: $0 residue-range align-pdb align-to-pdb

using chimera 'match', aligns molecule in align-pdb to align-to-pdb 

";

$rr = shift || die $notes;
$f  = shift || die $notes;
$ft = shift || die $notes;

die "$f does not exist\n" if !-e $f;
die "$f is not readable\n" if !-r $f;
die "$ft does not exist\n" if !-e $ft;
die "$ft is not readable\n" if !-r $ft;

sub echoline {
    print '-'x80 . "\n"
}

sub runcmd {
    my $cmd = shift;
    echoline() if $debug;
    print "$cmd\n" if $debug;
    echoline() if $debug;
    my $res = `$cmd`;
    die "error status returned $?\n" if $?;
    $res;
}

$fout = $f;
# $fout =~ s/\.pdb$//i;
# $fout = "${f}_aligned.pdb";

## pattern spec is in http://www.rbvi.ucsf.edu/chimera/docs/UsersGuide/midas/atom_spec.html#basic
## for now, CA only, add @CA to each range

$alignpattern = $rr;
$alignpattern =~ s/(,|$)/\@CA$1/g;

$mkchimera =
    "open 0 $f; open 1 $ft; match #0:$alignpattern #1:$alignpattern; write format pdb 0 $fout; close all";

# die "mkchimera $mkchimera\n";

my ( $fh, $ft ) = tempfile( "mkchimera.XXXXXX", UNLINK => 1 );
print $fh $mkchimera;
close $fh;

$cmd = "$chimerabin/chimera --nogui < $ft 2>/dev/null";
$res = runcmd( $cmd );

@res = split /\n/, $res;

@rmsd = grep /RMSD/, @res;

print "After alignment, $rmsd[0]\n";



    
