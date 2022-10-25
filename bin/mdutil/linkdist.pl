#!/usr/bin/perl

$notes = "usage: $0 pdb

reports LINK distances
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

# get atom/hetatm positions

foreach $l ( @l ) {
    $r = pdb_fields( $l );
    $recname = $r->{"recname"};
    if ( $recname =~ /^(ATOM|HETATM)$/ ) {
        my $serial  = $r->{"serial"};
        my $x       = $r->{"x"};
        my $y       = $r->{"y"};
        my $z       = $r->{"z"};
        my $name    = $r->{"name"};
        my $chainid = $r->{"chainid"};
        my $resname = $r->{"resname"};
        my $resseq  = $r->{"resseq"};
        my $v = "$name:$resname:$chainid:$resseq";
        $posx{$v}   = $x;
        $posy{$v}   = $y;
        $posz{$v}   = $z;
        $serial{$v} = $serial
    }
}

# find links and compute distances


foreach $l ( @l ) {
    $r = pdb_fields( $l );
    $recname = $r->{"recname"};
    next if $recname !~ /^LINK/;
    my $name1     = $r->{ "name1"     };
    my $resname1  = $r->{ "resname1"  };
    my $chainid1  = $r->{ "chainid1"  };
    my $resseq1   = $r->{ "resseq1"   };
    my $name2     = $r->{ "name2"     };
    my $resname2  = $r->{ "resname2"  };
    my $chainid2  = $r->{ "chainid2"  };
    my $resseq2   = $r->{ "resseq2"   };
    my $v1 = "$name1:$resname1:$chainid1:$resseq1";
    my $v2 = "$name2:$resname2:$chainid2:$resseq2";

    die "missing $v1 info\n" if !exists $posx{$v1};
    die "missing $v2 info\n" if !exists $posx{$v2};

    my $dx = $posx{$v1} - $posx{$v2};
    my $dy = $posy{$v1} - $posy{$v2};
    my $dz = $posz{$v1} - $posz{$v2};

    my $d  = sqrt( $dx * $dx + $dy * $dy + $dz * $dz );
    print sprintf( "%20s %20s distance %.2f %s\n", $v1, $v2, $d, sprintf( "CONECT%5d%5d", $serial{$v1}, $serial{$v2} ) );
}
