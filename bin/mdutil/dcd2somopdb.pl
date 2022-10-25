#!/usr/bin/perl

### user defines

$ref_pdb   = "step3_input.pdb";

### end user defines

use File::Basename;
my $dirname = dirname(__FILE__);

$notes = "usage: $0 step

takes step.dcd
extracts pdbs
removes WAT,POT,CLA,SOD
makes step_nowat.pdb
splits into individual pdbs 
runs molprobity
summarizes stats
";

$f = shift || die $notes;

$f =~ s/\.dcd$//;

$fdcd = "$f.dcd";

die "$fdcd does not exist\n" if !-e $fdcd;
die "$fdcd is not readable\n" if !-r $fdcd;

sub echoline {
    print '-'x80 . "\n"
}

sub runcmd {
    my $cmd = shift;
    echoline();
    print "$cmd\n";
    echoline();
    print `$cmd`;
    die "error status returned $?\n" if $?;
}

$prefix = $f;
$prefix =~ s/_.*$//;
# $prefix =~ s/(\d+)$/_\1/;

print "output prefix is $prefix\n";

$ref = $ref_pdb;
if ( !-e $ref ) {
    $ref = "../$ref";
    if ( !-e $ref ) {
        $ref = "../$ref";
        die "could not find $ref_pdb in current nor parent nor grandparent directory\n" if !-e $ref;
    }
}

@cmds = (
    "mdconvert -o $f.pdb -t $ref $f.dcd"
### remove 72-76 SOLV, IONS
    ,"sed -E  '/^.{72}(IONS|SOLV)/d' ${f}.pdb > ${f}_nowat.pdb && mv ${f}_nowat.pdb ${f}.pdb"
# old way    ,"grep -v ' HOH ' ${f}.pdb | grep -v '  POT POT ' | grep -v ' CLA  CLA ' | grep -v ' SOD  SOD ' | grep -v ' MG  MG ' > ${f}_nowat.pdb && mv ${f}_nowat.pdb ${f}.pdb"
#    ,"$dirname/pdbcutwi.pl ${f}.pdb"
    ,"$dirname/somopdb.pl ${f}.pdb"
    ,"$dirname/splitmodels.pl ${f}.somo.pdb $prefix"
    );

for $cmd ( @cmds ) {
    runcmd( $cmd );
}

    
