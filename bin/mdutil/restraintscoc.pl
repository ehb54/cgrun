#!/usr/bin/perl

$notes = "usage: $0 pdb steps

compute center of coordinates 
and maximum distance
builds 'steps' restraint models with elements inside decreasing spheres left fixed

creates:
 pdbname_f_pbba_coc_NNN.pdb  - fixed backbone atoms

could later try other variants

Hydrogens are never fixed
note you may need to reassign chains, etc and include HELIX & SHEET sections of the pdb
";

use File::Basename;
my $scriptd = dirname(__FILE__);
require "$scriptd/pdbutil.pm";

$f = shift || die $notes;
$fb = $f;
$fb =~ s/\.pdb$//;

die "$f does not exist\n" if !-e $f;
die "$f is not readable\n" if !-r $f;

$steps = shift || die $notes; 
die "steps must be greater than 1\n" if $steps < 2; 
    
open IN, $f || die "$f open error $!\n";
@l = <IN>;
close IN;
grep chomp, @l;

# first get sheet & helix info

foreach $l ( @l ) {
    $r = pdb_fields( $l );
    if ( $r->{"recname"}  =~ /^(SHEET|HELIX)$/ ) {
        my $iresnam  = $r->{"initresname"};
        my $ichainid = $r->{"initchainid"};
        my $iseqnum  = $r->{"initseqnum"};
        my $eresnam  = $r->{"end"};
        my $echainid = $r->{"endchainid"};
        my $eseqnum  = $r->{"endseqnum"};

        for my $id ( $iseqnum..$eseqnum ) {
            my $tid   = $id; # for checking: myleftpad0( $id, 3 );
            my $index = "$ichainid:$tid";
            $pssa{ $index }++;
        }
    }
}

warn "No sheets or helices found\n" if !keys %pssa;

# get coc 

$xc = 0;
$yc = 0;
$zc = 0;
$ac = 0;

foreach $l ( @l ) {
    $r = pdb_fields( $l );
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        my $resname = $r->{"resname"};
        next if !exists $crmap{$resname} && !exists $prmap{$resname};
        my $x = $r->{"x"};
        my $y = $r->{"y"};
        my $z = $r->{"z"};
        $xc += $x;
        $yc += $y;
        $zc += $z;
        ++$ac;
    }
}

$xc /= $ac;
$yc /= $ac;
$zc /= $ac;

print sprintf( "center of coordinates %.2f %.2f %.2f\n",
               $xc, $yc, $zc );

# get max distance
foreach $l ( @l ) {
    $r = pdb_fields( $l );
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        my $resname = $r->{"resname"};
        next if !exists $crmap{$resname} && !exists $prmap{$resname};
        my $x = $r->{"x"};
        my $y = $r->{"y"};
        my $z = $r->{"z"};
        my $xd = $x - $xc;
        my $yd = $y - $yc;
        my $zd = $z - $zc;
        my $d  = $xd * $xd + $yd * $yd + $zd * $zd;
        $maxd  = $d if $maxd < $d;
    }
}

$maxd = sqrt( $maxd );
print sprintf( "max distance %.2f\n", $maxd );

$delta = $maxd / ( $steps + 1 );

for ( $i = 1; $i <= $steps; ++$i ) {
    push @dd, sprintf( "%.2f", $maxd - $delta * $i );
}
print "deltas:\n" . join( "\n", @dd ) . "\n\n";

warn "No sheets or helices found\n" if !keys %pssa;

# debugging print join( "\n", sort { $a cmp $b } keys %pssa ) . "\n";

sub setbeta {
    my $l      = shift;
    my $v      = shift;
    my $tf     = "  0.00";
    $tf        = "  1.00" if $v;
    
    substr( $l, 0, 60 ) . $tf . substr( $l, 66 );
}

# fixed protein backbone within step
for ( $step = 0; $step < @dd; ++$step ) {
    my $fo = sprintf( ">${fb}_f_pbba_coc_%s.pdb", myleftpad0( $step, 3 ) );
    my @ol;
    my $fixedbba = 0;
    foreach $l ( @l ) {
        $r = pdb_fields( $l );
        $recname = $r->{"recname"};
        if ( $recname !~ /^(ATOM|HETATM)$/ ) {
            push @ol, $l;
            next;
        }            
        $element = $r->{"element"};
        # leave hydrogens floating
        if ( $element eq 'H' ) {
            push @ol, setbeta( $l, 0 );
            next;
        }
        my $resname = $r->{"resname"};
        # skip non carb residue and non protein residue
        if ( !exists $crmap{$resname} && !exists $prmap{$resname} ) {
            push @ol, setbeta( $l, 0 );
            next;
        }

        my $name    = $r->{"name"};

        if ( $prmap{ $resname } && $pbbamap{ $name } ) {
            my $x = $r->{"x"};
            my $y = $r->{"y"};
            my $z = $r->{"z"};
            my $xd = $x - $xc;
            my $yd = $y - $yc;
            my $zd = $z - $zc;
            my $d  = sqrt( $xd * $xd + $yd * $yd + $zd * $zd );
            if ( $d <= $dd[$step] ) {
                push @ol, setbeta( $l, 1 );
                ++$fixedbba;
                next;
            }
        }
        push @ol, setbeta( $l, 0 );
    }
    print "$fo\n";
    print sprintf( "distance cutoff %.2f fixed backbone atoms: $fixedbba\n", $dd[$step] );
    open OUT, $fo || die "can not open $fo $!\n";
    print OUT ( join "\n", @ol ) . "\n";
    close OUT;
}

