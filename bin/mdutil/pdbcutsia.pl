#!/usr/bin/perl

use File::Basename;
{
    my $scriptd = dirname(__FILE__);
    require "$scriptd/pdbutil.pm";
}

$notes = "usage: $0 pdb*

cuts SIA 11 from all carbs, all models

";

$f = shift || die $notes;

open IN, $f || die "$f open error $!\n";
@l = <IN>;
close IN;
grep chomp, @l;

$fo = $f;
$fo =~ s/\.pdb$/_1SIA.pdb/;

die "$fo exists\n" if -e $fo;

foreach $l ( @l ) {
    my $r = pdb_fields( $l );
    
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        if ( $r->{"resname"} eq 'SIA' &&
             $r->{"resseq"}  == 11 ) {
            ++$sia11s;
            next;
        }
    }
    push @ol, $l;
}

print "$sia11s SIA 11's cut\n";

print "$fo\n";
open OUT, ">$fo" || die "can not open $fo $!\n";
print OUT ( join "\n", @ol ) . "\n";
close OUT;
        
    
