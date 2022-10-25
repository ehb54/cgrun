#!/usr/bin/perl

$ussomosc = "/opt/ultrascan3ehb/bin/us_saxs_cmds_t json";

use File::Basename;
{
    my $scriptd = dirname(__FILE__);
    require "$scriptd/pdbutil.pm";
    require "$scriptd/af/af.pm";
}

$notes = "usage: $0 pdb {outpdb}*

prints ssbond info
if outpdb specified, writes ssbond info to pdb

";

$f = shift || die $notes;
$fo = shift;

die "$f does not exist\n" if !-e $f;

$cmd = qq[$ussomosc '{"ssbond":1,"pdbfile":"$f"}' 2>/dev/null];

$res = run_cmd( $cmd );
$res =~ s/\n/\\n/g;

$dj = decode_json( $res );
if (!$fo ) {
    print $$dj{"ssbonds"};
    exit;
}

open IN, $f || die "$f open error $!\n";
@l = <IN>;
close IN;

if ( length( $$dj{"ssbonds"} ) ) {
    push @ol, "REMARK 777 SOMO added SSBONDS\n";
    push @ol, $$dj{"ssbonds"};
} else {
    push @ol, "REMARK 777 SOMO no SSBONDS found\n";
}
push @ol, @l;

print "$fo\n";
open OUT, ">$fo" || die "can not open $fo $!\n";
print OUT join '', @ol;
close OUT;



