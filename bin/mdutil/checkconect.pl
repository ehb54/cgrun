#!/usr/bin/perl


$notes = "usage: $0 pdb*

checks each non AA chain for connections between residues
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

foreach $l ( @l ) {
    $r = pdb_fields( $l );

    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        my $serial  = $r->{ "serial" };
        $resname{ $serial } = $r->{ "resname" };
        $chainid{ $serial } = $r->{ "chainid" };
        $resseq { $serial } = $r->{ "resseq" };
    } elsif ( $r->{"recname"}  =~ /^CONECT$/ ) {
        my $ts    = $r->{ "serial" };
        if ( !$resname{ $ts } ) {
            warn "atom with serial $ts not defined\n";
            next;
        }
        my @bonds;
        for ( my $i = 1; $i <= 4; ++$i ) {
            my $b = $r->{ "bond$i" };
            if ( $b > 0 ) {
                if ( !$resname{ $b } ) {
                    warn "atom with serial $b not defined\n";
                    next;
                }
                next if
                    $resname{ $ts } eq $resname{ $b }
                    && $chainid{ $ts } eq $chainid{ $b }
                    && $resseq{ $ts } eq $resseq{ $b }
                ;
                
                my $revpair =
                    sprintf( 
                    "%s %s %s <-> %s %s %s\n"
                    ,$resname{ $b }
                    ,$chainid{ $b }
                    ,$resseq { $b }
                    ,$resname{ $ts }
                    ,$chainid{ $ts }
                    ,$resseq { $ts }
                    );
                my $thispair =
                    sprintf( 
                    "%s %s %s <-> %s %s %s\n"
                    ,$resname{ $ts }
                    ,$chainid{ $ts }
                    ,$resseq { $ts }
                    ,$resname{ $b }
                    ,$chainid{ $b }
                    ,$resseq { $b }
                    );
                next if $alreadypaired{ $revpair };
                print $thispair;
                $alreadypaired{ $thispair }++;
            }
        }
    }
}


