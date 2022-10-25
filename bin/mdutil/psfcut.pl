#!/usr/bin/perl

$notes = "usage: $0 psf maxatom

cuts atoms with atom number greater than maxatom from pdb

";

$f = shift || die $notes;
die "$f does not exist\n" if !-e $f;
die "$f is not readable\n" if !-r $f;
$maxatom = shift || die $notes;

# subs

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

sub myleftpad0 {
    my $s = shift;
    my $l = shift;
    while( length( $s ) < $l ) {
        $s = "0$s";
    }
    $s;
}

sub linedata {
    my $l = shift;
    my @result;
    chomp $l;
    
    while( length( $l ) ) {
        push @result, mytrim( substr( $l, 0, 10 ) );
        $l = substr( $l, 10 );
    }
    \@result;
}

sub alldata {
    my $sect  = shift;
    my $desc  = shift;
    my $count = shift;
    my $epl   = shift;
    my $epg   = shift;
    my $lines = int( $count / $epl );
    ++$lines if $count % $epl;
    print "lines expected for $sect $lines\n";
    my @all;
    for ( my $i = 0; $i < $lines; ++$i ) {
        my $l = shift @l;
        my $d = linedata( $l );
        push @all, @$d;
        # print "line $i: " .  ( join ":", @$d ) . "\n";
    }
    # now @all should be $epg * $count
    die "section $sect : count mismatch found " . ( @all / $epg ) . " data elements, but expected $count\n" if @all / $epg != $count;
    print "section $sect : count match found " . ( @all / $epg ) . " data elements, expected $count\n";

    my @accepted;
    # redo for max atom
    for ( my $i = 0; $i < @all; $i += $epg ) {
        my $lemc = 0;
        my @this;
        for ( my $j = 0; $j < $epg; ++$j ) {
            push @this,  $all[ $i + $j ];
            ++$lemc if $all[$i + $j] <= $maxatom;
        }
        # $lemc should be either zero or $epg otherwise we have a cross-bond
        die "ERROR $sect bond crossing cutoff found, did you select the correct maxatom #?\n" if $lemc && $lemc != $epg;
        push @accepted, @this if $lemc;
    }
    my $newcount = @accepted / $epg;
    print "$sect count was $count now is $newcount\n";
    push @ol, sprintf( "%10d !%s%s\n", $newcount, $sect, $desc );
    my $newlines = int( $newcount / $epl );
    ++$newlines if $newcount % $epl;
    for ( my $i = 0; $i < $newlines; ++$i ) {
        my $out = "";
        for ( my $j = 0; $j < $epl * $epg; ++$j ) {
            $out .= sprintf( "%10d", shift @accepted ) if @accepted;
        }
        $out .= "\n";
        push @ol, $out;
    }
}

# main logic

open IN, $f || die "$f bad open $!\n";
@l = <IN>;
close IN;

# header
$l = shift @l;
die "not psf file\n" if $l !~ /^PSF/;
push @ol, $l;

# blank line
$l = shift @l;
push @ol, $l;

while ( $l = shift @l ) {
    if ( $l =~ /^\s*$/ ) {
        push @ol, $l;
        next;
    }

    my $count           = mytrim( substr( $l, 0, 10 ) );
    my $bang            = mytrim( substr( $l, 11, 1 ) );
    my ( $sect, $desc ) = mytrim( substr( $l, 12 ) ) =~ /^([A-Z]+)(.*)$/;

    die "Error on line " . scalar( @ol ) . " no ! found\n$l"  if $bang ne '!';

    print "section $sect count '$count' desc '$desc'\n";

    if ( $sect =~ /^NTITLE$/ ) {
        push @ol, $l;
        for ( my $i = 0; $i < $count; ++$i ) {
            $l = shift @l;
            push @ol, $l;
        }
        next;
    } elsif ( $sect =~ /^NATOM$/ ) {
        # seems good
        die "requested maxatom $maxatom is greater than the number of atoms $count\n" if $maxatom > $count;
        push @ol, sprintf( "%10d !%s%s\n", $maxatom, $sect, $desc );
        for ( my $i = 0; $i < $count; ++$i ) {
            $l = shift @l;
            push @ol, $l if $i < $maxatom;
        }
        next;
    } elsif ( $sect =~ /^NBOND$/ ) {
        # check each pair
        #  if one element of pair is > maxatoms, drop it
        #  else add to list
        # output count of list, then list
        #
        alldata( $sect, $desc, $count, 4, 2 );
        next;
    } elsif ( $sect =~ /^NTHETA$/ ) {
        alldata( $sect, $desc, $count, 3, 3 );
        next;
    } elsif ( $sect =~ /^(NPHI|NIMPHI)$/ ) {
        alldata( $sect, $desc, $count, 2, 4 );
        next;
    } elsif ( $sect =~ /^(NDON|NACC)$/ ) {
        push @ol, $l;
        next;
    } elsif ( $sect =~ /^NNB$/ ) {
        while ( @l > 1 && substr( $l[1], 11, 1 ) ne '!' ) {
            push @ol, $l;
            $l = shift @l;
        }
        next;
    } elsif ( $sect =~ /^NCRTERM$/ ) {
        alldata( $sect, $desc, $count, 1, 8 );
        next;
    } else {
        die "unsupported section name '$sect'\n";
    }
}

$fo = ">$f";
open OUT, $fo || die "$fo $!\n";
print OUT join '', @ol;
close OUT;
print "$fo\n";
