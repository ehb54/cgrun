#!/usr/bin/perl


$notes = "usage: $0 pdb*

for each MODEL inserts chain ids, starting at A
maps residue names to original values

";

@resclist = (
    "HSD"     ,"HIS"

    ,"BGLC"    ,"NAG"
    ,"BGLC:C"   ,"C7"
    ,"BGLC:CT"  ,"C8"
    ,"BGLC:N"   ,"N2"

    ,"AGLC"   ,"NDG"

    ,"AMAN"   ,"MAN"

    ,"BMAN"   ,"BMA"

    ,"AGAL"   ,"GAL"

    ,"BGAL"   ,"GAL"
    
    ,"ANE5"   ,"SIA"
    
    );

while ( my $i = shift @resclist ) {
    $resmap{ $i } = shift @resclist;
}

$f = shift || die $notes;

die "$f does not exist\n" if !-e $f;
die "$f is not readable\n" if !-r $f;

sub mytrim {
    my $s = shift;
    $s =~ s/^\s+|\s+$//g;
    $s;
}

sub mypad {
    my $s = shift;
    my $l = shift;
    while( length( $s ) < $l ) {
        $s .= " ";
    }
    $s;
}

sub pdb_fields {
    my $l = shift;
    my %r;

    $r{ "recname" } = mytrim( substr( $l, 0, 6 ) );

    # pdb data from https://www.wwpdb.org/documentation/file-format-content/format33

    if ( $r{ "recname" } eq "LINK" ) {
        $r{ "name1"     } = mytrim( substr( $l, 12, 4 ) );
        $r{ "resname1"  } = mytrim( substr( $l, 17, 3 ) );
        $r{ "chainid1"  } = mytrim( substr( $l, 21, 1 ) );
        $r{ "resseq1"   } = mytrim( substr( $l, 22, 4 ) );
        $r{ "name2"     } = mytrim( substr( $l, 42, 4 ) );
        $r{ "resname2"  } = mytrim( substr( $l, 47, 3 ) );
        $r{ "chainid2"  } = mytrim( substr( $l, 51, 1 ) );
        $r{ "resseq2"   } = mytrim( substr( $l, 52, 4 ) );
        $r{ "length"    } = mytrim( substr( $l, 73, 5 ) );
    } elsif ( $r{ "recname" } eq "ATOM" ||
                $r{ "recname" } eq "HETATM" ) {
        $r{ "serial"    } = mytrim( substr( $l,  6, 5 ) );
        $r{ "name"      } = mytrim( substr( $l, 12, 4 ) );
        $r{ "resname"   } = mytrim( substr( $l, 17, 4 ) ); # note this is officially only a 3 character field!
        $r{ "chainid"   } = mytrim( substr( $l, 21, 1 ) );
        $r{ "resseq"    } = mytrim( substr( $l, 22, 4 ) );
        $r{ "element"   } = mytrim( substr( $l, 76, 2 ) );
        $r{ "x"         } = mytrim( substr( $l, 30, 8 ) );
        $r{ "y"         } = mytrim( substr( $l, 38, 8 ) );
        $r{ "z"         } = mytrim( substr( $l, 46, 8 ) );
    } elsif ( $r{ "recname" } eq 'CONECT' ) {
        $r{ "serial"    } = mytrim( substr( $l,  6, 5 ) );
        $r{ "bond1"     } = mytrim( substr( $l, 11, 5 ) );
        $r{ "bond2"     } = mytrim( substr( $l, 16, 5 ) );
        $r{ "bond3"     } = mytrim( substr( $l, 21, 5 ) );
        $r{ "bond4"     } = mytrim( substr( $l, 26, 5 ) );
    }

    \%r;
}

open IN, $f || die "$f open error $!\n";
@l = <IN>;
close IN;
grep chomp, @l;

$chainnum    = ord('A') - 1;
$maxchainnum = ord('Z');
$lastresseq = 0;

my @ol;

foreach $l ( @l ) {
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
        if ( $resmap{$resname} ) {
            $resname = $resmap{$resname};
        }
        $l = substr( $l, 0, 17 ) . mypad( $resname, 4 ) . substr( $l, 21 );
        $lastresseq = $resseq;
        die "no chainid defined: $l\n" if !defined $chainid;
        $l = substr( $l, 0, 21 ) . $chainid . substr( $l, 22 );
    }
    push @ol, $l;
}

$fo = ">$f";
print "$fo\n";
open OUT, $fo || die "can not open $fo $!\n";
print OUT ( join "\n", @ol ) . "\n";
close OUT;
