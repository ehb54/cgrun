#!/usr/bin/perl


$notes = "usage: $0 pdb*

for each MODEL inserts chain ids, starting at A
maps residue names to original values

";

@resclist = (
    "HSD"     ,"HIS"

    ,"ILE:CD"  ,"CD1"


    ,"BGLC"    ,"NAG"
    ,"BGLC:C"   ,"C7"
    ,"BGLC:CT"  ,"C8"
    ,"BGLC:O"   ,"O7"
    ,"BGLC:N"   ,"N2"

    ,"BGL"    ,"NAG"
    ,"BGL:C"   ,"C7"
    ,"BGL:CT"  ,"C8"
    ,"BGL:O"   ,"O7"
    ,"BGL:N"   ,"N2"

    ,"AGLC"   ,"NDG"
    ,"AGLC:C"   ,"C7"
    ,"AGLC:CT"  ,"C8"
    ,"AGLC:O"   ,"O7"
    ,"AGLC:N"   ,"N2"
    ,"AGLC:O5"  ,"O"

    ,"AGL"   ,"NDG"
    ,"AGL:C"   ,"C7"
    ,"AGL:CT"  ,"C8"
    ,"AGL:O"   ,"O7"
    ,"AGL:N"   ,"N2"
    ,"AGL:O5"  ,"O"

    ,"AMAN"   ,"MAN"
    ,"AMA"   ,"MAN"

    ,"BMAN"   ,"BMA"
    ,"BMA"   ,"BMA"

    ,"AGAL"   ,"GAL"
    ,"AGA"   ,"GAL"

    ,"BGAL"   ,"GAL"
    ,"BGA"   ,"GAL"
    
    ,"ANE5"   ,"SIA"
    ,"ANE5:N"   ,"N5"
    ,"ANE5:C"   ,"C10"
    ,"ANE5:CT"  ,"C11"
    ,"ANE5:O"   ,"O10"
    ,"ANE5:O11" ,"O1A"
    ,"ANE5:O12" ,"O1B"

    ,"ANE"   ,"SIA"
    ,"ANE:N"   ,"N5"
    ,"ANE:C"   ,"C10"
    ,"ANE:CT"  ,"C11"
    ,"ANE:O"   ,"O10"
    ,"ANE:O11" ,"O1A"
    ,"ANE:O12" ,"O1B"
    
    );

while ( my $i = shift @resclist ) {
    $resmap{ $i } = shift @resclist;
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

$chainnum    = ord('A') - 1;
$maxchainnum = ord('Z');
$lastresseq = 0;

my @ol;
my @olnr;

foreach $l ( @l ) {
    my $lnr = $l;
    my $r = pdb_fields( $l );
    if ( $r->{"recname"}  =~ /^MODEL$/ ) {
        $chainnum = ord('A') - 1;
        $lastresseq = 0;
        push @ol  , $l;
        push @olnr, $l;
        next;
    } elsif ( $r->{"recname"}  =~ /^TER$/ ) {
        $lastresseq = 0;
        undef $chainid;
    } elsif ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        $name    = $r->{"name"};
        $resseq  = $r->{"resseq"};
        $resname = $r->{"resname"};
        if ( (!defined $chainid || $resseq == 1) && $lastresseq != 1 ) {
            $chainid = chr( ++$chainnum );
            die "too too many chains\n" if $chainnum > $maxchainnum;
            if ( $chainid ne 'A' ) {
                push @ol  , "TER";
                push @olnr, "TER";
            }
        }
        if ( exists $resmap{$resname} ) {
            $name = $resmap{"$resname:$name"} if exists $resmap{"$resname:$name"};
            $resname = $resmap{$resname};
        } else {
            $name = $resmap{"$resname:$name"} if exists $resmap{"$resname:$name"};
        }
        $name = "O" if $name eq 'OT1';
        $name = "OXT" if $name eq 'OT2';
        $name = " $name" if length( $name ) < 4;
        $l =
            substr( $l, 0, 12 )
            . mypad( $name, 4 )
            . " "
            . mypad( $resname, 4 )
            . substr( $l, 21 )
            ;
        $lastresseq = $resseq;
        die "no chainid defined: $l\n" if !defined $chainid;
        $l   = substr( $l,   0, 21 ) . $chainid . substr( $l  , 22 );
        $lnr = substr( $lnr, 0, 21 ) . $chainid . substr( $lnr, 22 );
    }
    push @ol  , $l;
    push @olnr, $lnr;
}

$ft = $f;
$ft =~ s/\.pdb$//;
$ft .= ".somo.pdb";
$fo = ">$ft";
print "$fo\n";
open OUT, $fo || die "can not open $fo $!\n";
print OUT ( join "\n", @ol ) . "\n";
close OUT;

if ( $make_chainid ) {
    $ft = $f;
    $ft =~ s/\.pdb$//;
    $ft .= ".chainid.pdb";
    $fo = ">$ft";
    print "$fo\n";
    open OUT, $fo || die "can not open $fo $!\n";
    print OUT ( join "\n", @olnr ) . "\n";
    close OUT;
}
