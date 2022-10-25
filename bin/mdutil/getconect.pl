#!/usr/bin/perl


$notes = "usage: $0 pdb {startatom2 endatom2}*

reports CONECT pdb records that are in the specified atom number range(s)
reports distances between each atom pair

";

$f = shift || die $notes;

while ( @ARGV ) {
    $s = shift;
    $e = shift || die $notes;
    die "startatom must be less than endatom\n" if $s >= $e;
    push @s, $s;
    push @e, $e;
}

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
#    print "$l\n";
#    print 
#        $r->{"recname"} 
#        . " " . $r->{"x"} 
#        . " " . $r->{"y"} 
#        . " " . $r->{"z"} 
#        . "\n";
    
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        $x[ $r->{ "serial" } ] = $r->{"x"};
        $y[ $r->{ "serial" } ] = $r->{"y"};
        $z[ $r->{ "serial" } ] = $r->{"z"};
        $d[ $r->{ "serial" } ] = sprintf( "%s %s %s %s", $r->{"name"}, $r->{"resname"}, $r->{"chainid"}, $r->{"resseq"} );
    } elsif ( $r->{"recname"}  =~ /^CONECT$/ ) {
        my $ts    = $r->{ "serial" };
        if ( !$x[ $ts ] ) {
            warn "atom with serial $ts not defined\n";
            next;
        }
        my @bonds;
        for ( my $i = 1; $i <= 4; ++$i ) {
            my $b = $r->{ "bond$i" };
            if ( $b > 0 ) {
                if ( !$x[ $b ] ) {
                    warn "atom with serial $b not defined\n";
                    next;
                }
                $dist =
                    sqrt( 
                        ( $x[ $ts ] - $x[ $b ] ) * ( $x[ $ts ] - $x[ $b ] ) +
                        ( $y[ $ts ] - $y[ $b ] ) * ( $y[ $ts ] - $y[ $b ] ) +
                        ( $z[ $ts ] - $z[ $b ] ) * ( $z[ $ts ] - $z[ $b ] )
                        )
                    ;
                $d{ sprintf( "%s %s", $d[$ts], $d[$b] ) } = sprintf( "%.3f", $dist );
                # $d{ sprintf( "%s %s", $ts, $b ) } = sprintf( "%.3f", $dist );
            }
        }
    }
}

foreach $k ( keys %d ) {
    push @out, $d{$k}.  " $k\n";
}

print join '', sort { $a <=> $b } @out;

