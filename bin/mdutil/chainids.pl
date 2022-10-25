#!/usr/bin/perl


$notes = "usage: $0 pdb*

for each MODEL inserts chain ids, starting at A

";


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
        $lastresseq = $resseq;
        die "no chainid defined: $l\n" if !defined $chainid;
        $l = substr( $l, 0, 21 ) . $chainid . substr( $l, 22 );
    }
    push @ol, $l;
}

$ft = $f;
$ft =~ s/\.pdb$//;
$ft .= ".somo.pdb";
$fo = ">$ft";
print "$fo\n";
open OUT, $fo || die "can not open $fo $!\n";
print OUT ( join "\n", @ol ) . "\n";
close OUT;
