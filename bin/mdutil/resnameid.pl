#!/usr/bin/perl

$notes = "usage: $0 pdb*

prints each residue name and seq number
skips protein AAs
";

use File::Basename;
my $scriptd = dirname(__FILE__);
require "$scriptd/pdbutil.pm";

$f = shift || die $notes;

die "$f does not exist\n" if !-e $f;
die "$f is not readable\n" if !-r $f;

open IN, $f || die "$f open error $!\n";
@l = <IN>;
close IN;
grep chomp, @l;

undef %seen;

foreach $l ( @l ) {
    $r = pdb_fields( $l );
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        $resname = $r->{"resname"};
        $resseq  = $r->{"resseq"};
        next if $prmap{$resname};
        my $v = "$resseq $resname\n";
        push @ol, $v if !$seen{$v}++;
    }
}

print ( sort { $a <=> $b } @ol ) . "\n";

    
