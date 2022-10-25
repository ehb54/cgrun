#!/usr/bin/perl

$notes = "usage: $0 pdb

sets element name from name and occupancy to 1

";

$f = shift || die $notes;
$fb = $f;
$fb =~ s/\.pdb$//;

die "$f does not exist\n" if !-e $f;
die "$f is not readable\n" if !-r $f;

# subs

use File::Basename;
{
    my $scriptd = dirname(__FILE__);
    require "$scriptd/pdbutil.pm";
}

open IN, $f || die "open $f failed $!\n";
@l = <IN>;
close IN;

my @ol;
foreach $l ( @l ) {
    $r = pdb_fields( $l );
    $recname = $r->{"recname"};
    if ( $recname !~ /^(ATOM|HETATM)$/ ) {
        push @ol, $l;
        next;
    }            
    $name = $r->{"name"};
    $element = substr( $name, 0, 1 );
    $l = substr( $l, 0, 54 ) . "  1.00" . substr( $l, 60, 17 ) . $element . substr( $l, 78 );
    push @ol, $l;
}

$fo = ">$f";
open OUT, $fo || die "open $fo error $!\n";
print OUT join ( '', @ol );
close OUT;
print "$fo\n";


       

    
