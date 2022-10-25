#!/usr/bin/perl

use File::Basename;
{
    my $scriptd = dirname(__FILE__);
    require "$scriptd/pdbutil.pm";
}

$notes = "usage: $0 pdb len

returns fasta seq from pdb entries for 1st model, 1st chain
";

$f = shift || die $notes;
$len = shift;

die "$f does not exist\n" if !-e $f;
die "$f is not readable\n" if !-r $f;

if ( $f =~ /.gz$/ ) {
    open IN, "gunzip -c $f |" || die "$f open error $!\n";
} else {
    open IN, $f || die "$f open error $!\n";
}
@l = <IN>;
close IN;
grep chomp, @l;

$outseq = "";

sub printexit {
    $outseq = substr( $outseq, 0, $len ) if $len > 0;
    print "$outseq\n";
    exit;
}

foreach $l ( @l ) {
    my $r = pdb_fields( $l );
    if ( $r->{"recname"}  =~ /^MODEL$/ ) {
        if ( $modeldefined ) {
            printexit();
        }
        $modeldefined++;
        next;
    }
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        my $chainid = $r->{'chainid'};
        if ( $chainiddefined &&
             $chainid ne $lastchainid ) {
            printexit();
            exit;
        }
        $chainiddefined++;
        $lastchainid = $chainid;
        my $resseq = $r->{'resseq'};
        if ( $lastresseq != $resseq ) {
            $outseq .= fastacode( $r->{'resname'} );
            $lastresseq = $resseq;
        }
    }
}

printexit();
