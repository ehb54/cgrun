#!/usr/bin/perl

$min_bond_len = .95;
$max_bond_len = 2.1;

# tmpdir is where coor to somo.pdb conversion takes place if needed

$tmpdir = "tmppdb";

$notes = "usage: $0 tag refpdb pdb|coor ...

finds CONECTs from refpdb
builds list of atoms pairs
ignores hydrogens

for each refpdb,pdb,coor
computes distances of atom pairs

warns about bond lengths less than $min_bond_len or greater than $max_bond_len

outputs tag.csv & tag.warn.txt

";

$tag = shift || die $notes;
$f   = shift || die $notes;

die "$f does not exist\n" if !-e $f;
die "$f is not readable\n" if !-r $f;
die "$f must end in .pdb\n" if $f !~ /\.pdb$/;

use File::Basename;
{
    my $scriptd = dirname(__FILE__);
    require "$scriptd/pdbutil.pm";
}

open IN, $f || die "$f open error $!\n";
@l = <IN>;
close IN;
grep chomp, @l;

## stage 1, build key pairs from refpdb

foreach $l ( @l ) {
    $r = pdb_fields( $l );
    
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        $name[ $r->{ "serial" } ] = $r->{"name" };
        next if $r->{"name"} =~ /^H/;
        $d[ $r->{ "serial" } ] = sprintf( "%s-%s-%s-%s", $r->{"chainid"}, $r->{"resname"}, $r->{"resseq"}, $r->{"name"} );
    } elsif ( $r->{"recname"}  =~ /^CONECT$/ ) {
        my $ts    = $r->{ "serial" };
        if ( !$d[ $ts ] ) {
            warn "atom with serial $ts not defined\n";
            next;
        }
        my @bonds;
        for ( my $i = 1; $i <= 4; ++$i ) {
            my $b = $r->{ "bond$i" };
            if ( $b > 0 ) {
                if ( !$name[ $b ] ) {
                    warn "atom with serial $b not defined\n";
                    next;
                }
                next if $name[ $b ] =~ /^H/;
                $c{ $d[ $ts ] . "|" . $d[ $b ] } = '' if !exists $c{ $d[ $b ] . "|" . $d[ $ts ] };
            }
        }
    }
}

print sprintf( "found %d bonds to check\n", scalar keys %c );

push @header, "atom 1", "atom 2";

## now build up distances for each file

$reff = $f;

unshift @ARGV, $f;

while( $f = shift ) {
    print "processing $f\n";

    die "$f does not exist\n" if !-e $f;
    die "$f is not readable\n" if !-r $f;

    push @header, $f;

    ### is coor file?
    if ( $f =~ /\.coor$/ ) {
        print "converting to somo.pdb format using $reff as reference\n";
        my $cmds = [
            "rm -fr $tmpdir 2> /dev/null; mkdir $tmpdir 2> /dev/null"
            ,"ln $f $tmpdir/"
            ,"cd $tmpdir && ~/mdutil/coor2somopdb.pl $f"
            ];
        runcmds( $cmds );
        $f = "$tmpdir/$f.somo.pdb";
        die "$f does not exist\n" if !-e $f;
        die "$f is not readable\n" if !-r $f;
    }        

    ### find distances
    open IN, $f || die "$f open error $!\n";
    my @l = <IN>;
    close IN;
    grep chomp, @l;

    my %x;
    my %y;
    my %z;
    
    for my $l ( @l ) {
        $r = pdb_fields( $l );
        if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
            my $k = sprintf( "%s-%s-%s-%s", $r->{"chainid"}, $r->{"resname"}, $r->{"resseq"}, $r->{"name"} );
            $x{ $k } = $r->{"x"};
            $y{ $k } = $r->{"y"};
            $z{ $k } = $r->{"z"};
        }
    }

    my %missing_warned;

    for my $k ( sort { $a cmp $b } keys %c ) {
        $c{$k} .= '|';
        ( $a1, $a2 ) = split /\|/, $k;
        my $ok = 1;
        if ( !exists $x{ $a1 } ) {
            $c{ $k } .= "$a1 missing";
            push @warn, "$f $a1 missing" if !$missing_warned{ $a1 }++;
            $ok = 0;
        }
        if ( !exists $x{ $a2 } ) {
            $c{ $k } .= "$a2 missing";
            push @warn, "$f $a2 missing" if !$missing_warned{ $a2 }++;
            $ok = 0;
        }

        if ( $ok ) {
            my $dist =
                sprintf(
                    "%.3f",
                    sqrt( 
                        ( $x{ $a1 } - $x{ $a2 } ) * ( $x{ $a1 } - $x{ $a2 } ) +
                        ( $y{ $a1 } - $y{ $a2 } ) * ( $y{ $a1 } - $y{ $a2 } ) +
                        ( $z{ $a1 } - $z{ $a2 } ) * ( $z{ $a1 } - $z{ $a2 } )
                    )
                );
            $c{ $k } .= $dist;
            push @warn, "$f $k length $dist to small" if $dist < $min_bond_len;
            push @warn, "$f $k length $dist to large" if $dist > $max_bond_len;
        }                
    }
}

$fo = "$tag.csv";
print ">$fo\n";
open OUT, ">$fo" || die "$fo can not create for output\n";

print OUT sprintf( "%s\n", ( join '|', @header ) );

for $k ( sort { $a cmp $b } keys %c ) {
    print OUT sprintf( "%s%s\n", $k, $c{ $k } );
}
close OUT;

    
$fo = "$tag.warn.txt";
if ( @warn ) {
    print ">$fo\n";
    open OUT, ">$fo" || die "$fo can not create for output\n";
    print OUT sprintf( "%s\n", ( join "\n", @warn ) );
    close OUT;
    exit -1;
}
unlink $fo;
print "all ok\n";
