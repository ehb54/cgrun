#!/usr/bin/perl


$notes = "usage: $0 pdb refpdb

inserts HELIX & SHEET from refpdb into pdb named _hs.pdb
";

use File::Basename;
my $scriptd = dirname(__FILE__);
require "$scriptd/pdbutil.pm";

$f       = shift || die $notes;
die "$f does not exist\n" if !-e $f;
die "$f is not readable\n" if !-r $f;

$fr      = shift || die $notes;
die "$fr does not exist\n" if !-e $fr;
die "$fr is not readable\n" if !-r $fr;

$fb = $f;
$fb =~ s/\.pdb$//;
$fo = ">$f"; # ">${fb}_hs.pdb";

open IN, $f || die "can not open $f $!\n";
@l = <IN>;
close IN;
@l = grep chomp, @l;

@hso = grep /^(HELIX|SHEET)/, @l;
die "$f already has HELIX or SHEET lines\n" if @hso;

open IN, $fr || die "can not open $fr $!\n";
@lr = <IN>;
close IN;
@lr = grep chomp, @lr;

@hsl = grep /^(HELIX|SHEET)/, @lr;
warn "$f has no HELIX or SHEET lines\n" if !@hsl;
grep s/\r//, @hsl;

@l_remarks    = grep /^REMARK/, @l;
@l_notremarks = grep !/^REMARK/, @l;

open OUT, $fo || die "can not create $fo $!\n";
print OUT join( "\n", @l_remarks ) . "\n" . join( "\n", @hsl ) . "\n" . join( "\n", @l_notremarks ) . "\n";
close OUT;
print "$fo\n";
