#!/usr/bin/perl

$notes = "usage: $0 pdb

cuts out " . join( " ", @cutres ) . " 
note - currently doesn't check CONECTs (or HELIX or SHEET) for exceptions

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
    next if $name =~ /^H/;
    push @ol, $l;
}

$fo = ">$f";
open OUT, $fo || die "open $fo error $!\n";
print OUT join ( '', @ol );
close OUT;
print "$fo\n";


       

    
