#!/usr/bin/perl

$notes = "usage: $0 n directory outfile

takes n random pdbs from directory and builds an nmr-style output file

";

$n = shift || die $notes;
$d = shift || die $notes;
$of = shift || die $notes;

die "$0: $d not a directory\n" if !-d $d;

@f = `find $d -name "*.pdb" | shuf | head -$n`;
grep chomp, @f;

if ( $debug ) {
    print join "\n", @f;
    print "\n";
}

$cmd = "cat " . ( join ' ',@f ) . " > $of";

print "$cmd\n";
print `$cmd`;


