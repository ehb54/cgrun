#!/usr/bin/perl

$notes = "usage: $0 pdb*

lists all resnames used

";

$f = shift || die $notes;

die "$f does not exist\n" if !-e $f;
die "$f is not readable\n" if !-r $f;

use File::Basename;
{
    my $scriptd = dirname(__FILE__);
    require "$scriptd/pdbutil.pm";
}

open IN, $f || die "$f open error $!\n";
@l = <IN>;
close IN;
grep chomp, @l;

undef %seen;

foreach $l ( @l ) {
    $r = pdb_fields( $l );
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        $resname = $r->{"resname"};
        $chainid = $r->{"chainid"};
        $resseq  = $r->{"resseq"};
        my $v = "$resname $chainid $resseq\n";
        push @ol, $v if !$seen{$v}++;
    }
}

print join( "", @ol ) . "\n";

    
