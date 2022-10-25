#!/usr/bin/perl


$notes = "usage: $0 outname pdb1 pdb2 ...*

joins the models as a multimodel pdb
";


$fo = shift || die $notes;

die "$fo exists remove before running\n" if -e $f;

die "$0 requires at least two pdbs\n\n$notes" if @ARGV < 2;


my @ol;
my $model = 1;

for $f ( @ARGV ) {
    push @ol, sprintf( "MODEL     %4d\n", $model++ );
    open IN, $f || die "$f open error $!\n";
    push @ol, <IN>;
    close IN;
    push @ol, "ENDMDL\n";
}
@ol = grep !/^END\s*$/, @ol;
push @ol, "END\n";

$fo = ">$fo";
open my $fh, $fo || die "could not create fo\n";
print $fh ( join "", @ol ) . "\n";
close $fh;
print "$fo\n";

