#!/usr/bin/perl

$notes = "usage: $0 pdb*

for each MODEL inserts chain ids, starting at A
maps residue names to original values

";

@skipaa = (
    "ALA"
    ,"ARG"
    ,"ASN"
    ,"ASP"
    ,"CYS"
    ,"GLU"
    ,"GLN"
    ,"GLY"
    ,"HIS"
    ,"HSD"
    ,"ILE"
    ,"LEU"
    ,"LYS"
    ,"MET"
    ,"PHE"
    ,"PRO"
    ,"SER"
    ,"THR"
    ,"TRP"
    ,"TYR"
    ,"VAL"
    );

while ( my $i = shift @skipaa ) {
    $skipaamap{ $i } = 1;
}

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
    next if $r->{"element"} eq 'H';
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        $name    = $r->{"name"};
        $resname = $r->{"resname"};
        next if $skipaamap{$resname};
        my $v = "\"$resname\",\"$name\"\n";
        push @ol, $v if !$seen{$v}++;
    }
}

print ( sort { $a cmp $b } @ol ) . "\n";

    
