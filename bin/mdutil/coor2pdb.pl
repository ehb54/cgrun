#!/usr/bin/perl

die "use coor2somopdb.pl\n";

$notes = "usage: $0 refpdb coor

takes coordinates from coor and applies to refpdb
writes out coor.pdb without hydrogens with full info
";

@resclist = (
    "HSD"     ,"HIS"

    ,"ILE:CD"  ,"CD1"


    ,"BGLC"    ,"NAG"
    ,"BGLC:C"   ,"C1"
    ,"BGLC:C1"  ,"C2"
    ,"BGLC:C2"  ,"C3"
    ,"BGLC:C3"  ,"C4"
    ,"BGLC:C4"  ,"C5"
    ,"BGLC:C5"  ,"C6"
    ,"BGLC:C6"  ,"C7"
    ,"BGLC:CT"  ,"C8"
    ,"BGLC:N"   ,"N2"
    ,"BGLC:O"   ,"O3"
    ,"BGLC:O3"  ,"O4"
    ,"BGLC:O4"  ,"O5"
    ,"BGLC:O5"  ,"O6"
    ,"BGLC:O6"  ,"O7"

    ,"AGLC"   ,"NDG"
    ,"AGLC:C"   ,"C1"
    ,"AGLC:C1"  ,"C2"
    ,"AGLC:C2"  ,"C3"
    ,"AGLC:C3"  ,"C4"
    ,"AGLC:C4"  ,"C5"
    ,"AGLC:C5"  ,"C6"
    ,"AGLC:C6"  ,"C7"
    ,"AGLC:CT"  ,"C8"
    ,"AGLC:N"   ,"N2"
    ,"AGLC:O"   ,"O3"
    ,"AGLC:O3"  ,"O4"
    ,"AGLC:O4"  ,"O"
    ,"AGLC:O5"  ,"O6"
    ,"AGLC:O6"  ,"O7"

    ,"AMAN"   ,"MAN"

    ,"BMAN"   ,"BMA"

    ,"AGAL"   ,"GAL"

    ,"BGAL"   ,"GAL"
    
    ,"ANE5"   ,"SIA"
    ,"ANE5:C"   ,"C1"
    ,"ANE5:C1"  ,"C2"
    ,"ANE5:C2"  ,"C3"
    ,"ANE5:C3"  ,"C4"
    ,"ANE5:C4"  ,"C5"
    ,"ANE5:C5"  ,"C6"
    ,"ANE5:C6"  ,"C7"
    ,"ANE5:C7"  ,"C8"
    ,"ANE5:C8"  ,"C9"
    ,"ANE5:C9"  ,"C10"
    ,"ANE5:CT"  ,"C11"
    ,"ANE5:N"   ,"N5"
    ,"ANE5:O"   ,"O10"
    ,"ANE5:O11" ,"O1A"
    ,"ANE5:O12" ,"O1B"
    
    );

while ( my $i = shift @resclist ) {
    $resmap{ $i } = shift @resclist;
}

$fr = shift || die $notes;

die "$fr does not exist\n" if !-e $fr;
die "$fr is not readable\n" if !-r $fr;

$fc = shift || die $notes;

die "$fc does not exist\n" if !-e $fc;
die "$fc is not readable\n" if !-r $fc;


use File::Basename;
{
    my $scriptd = dirname(__FILE__);
    require "$scriptd/pdbutil.pm";
}

open IN, $fr || die "$fr open error $!\n";
@lr = <IN>;
close IN;
grep chomp, @lr;

open IN, $fc || die "$fc open error $!\n";
@lc = <IN>;
close IN;
grep chomp, @lc;

$chainnum    = ord('A') - 1;
$maxchainnum = ord('Z');
$lastresseq = 0;

my @ol;

## add chain ids
$specfix{"AGLC:I:1"} = "BGLC";
$specfix{"AGLC:J:1"} = "BGLC";


foreach $l ( @lc ) {
    $r = pdb_fields( $l );
    if ( $r->{"recname"}  =~ /^MODEL$/ ) {
        $chainnum = ord('A') - 1;
        $lastresseq = 0;
        push @ol, $l;
        next;
    } elsif ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        $name    = $r->{"name"};
        $resseq  = $r->{"resseq"};
        $resname = $r->{"resname"};
        if ( $resseq == 1 && $lastresseq != 1 ) {
            $chainid = chr( ++$chainnum );
            die "too too many chains\n" if $chainnum > $maxchainnum;
            if ( $chainid ne 'A' ) {
                push @ol, "TER";
            }
        }
        # special fixes
        my $checkfix = "$resname:$chainid:$resseq";
        if (  exists $specfix{$checkfix} ) {
            print "Notice:patching resname '$checkfix' to " . $specfix{$checkfix}  . "\n" if !$specfixprinted{$checkfix}++;
            $resname = $specfix{$checkfix};
        }
        if ( exists $resmap{$resname} ) {
            $name = $resmap{"$resname:$name"} if exists $resmap{"$resname:$name"};
            $resname = $resmap{$resname};
        } else {
            $name = $resmap{"$resname:$name"} if exists $resmap{"$resname:$name"};
        }
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
        $l = substr( $l, 0, 21 ) . $chainid . substr( $l, 22 );
    }
    push @ol, $l;
}

@lcf = @ol;
undef @ol;


## now @lcf has the fixed up coor file
## get coordinates by atomname:chainid:resseq


foreach $l ( @lcf ) {
    $r = pdb_fields( $l );
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        next if $r->{"element"} eq 'H';
        $name    = $r->{"name"};
        $chainid = $r->{"chainid"};
        $resseq  = $r->{"resseq"};

        $name    = "O"   if $name eq 'OT1';
        $name    = "OXT" if $name eq 'OT2';

        my $v = "$name:$chainid:$resseq";
        $cx{$v} = $r->{"x"};
        $cy{$v} = $r->{"y"};
        $cz{$v} = $r->{"z"};
    }
}

my @ol;

## now apply coordinates to @lr        
foreach $l ( @lr ) {
    $r = pdb_fields( $l );
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        next if $r->{"element"} eq 'H';
        $name    = $r->{"name"};
        $chainid = $r->{"chainid"};
        $resseq  = $r->{"resseq"};

        my $v = "$name:$chainid:$resseq";

        if ( !$cx{$v} ) {
            warn "missing $v in $fr\n";
            next;
        }

        $l =
            substr( $l, 0, 30 )
            . myleftpad( $cx{$v}, 8 )
            . myleftpad( $cy{$v}, 8 )
            . myleftpad( $cz{$v}, 8 )
            . substr( $l, 54 )
            ;
    }            

    push @ol, $l;
}


$ft = $fc;
$ft =~ s/\.pdb$//;
$ft .= ".somo.pdb";
$fo = ">$ft";
print "$fo\n";
open OUT, $fo || die "can not open $fo $!\n";
print OUT ( join "\n", @ol ) . "\n";
close OUT;

$ft = $fc;
$ft =~ s/\.pdb$//;
$ft .= ".coor.pdb";
$fo = ">$ft";
print "$fo\n";
open OUT, $fo || die "can not open $fo $!\n";
print OUT ( join "\n", @lc ) . "\n";
close OUT;
