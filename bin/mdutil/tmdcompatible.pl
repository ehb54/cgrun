#!/usr/bin/perl


use File::Basename;
{
    my $scriptd = dirname(__FILE__);
    require "$scriptd/pdbutil.pm";
}

$notes = "usage: $0 targetpdb refpdb

determines if targetpdb is compabible with the provided refpdb for TMD


";


$ft = shift || die $notes;

die "$ft does not exist\n" if !-e $ft;
die "$ft is not readable\n" if !-r $ft;

$fr = shift || die $notes;

die "$fr does not exist\n" if !-e $fr;
die "$fr is not readable\n" if !-r $fr;

##

# Description: Biased atoms are those whose occupancy (O) is nonzero in
# the TMD PDB file. Fitted atoms are those whose altloc field is not ` '
# or `0', if present, otherwise all biased atoms are fitted. The file
# must contain no more atoms than the structure file and those atoms
# present must have the exact same index as the structure file (i.e.,
# the file may contain a truncated atom selection ``index $ < N$ '' but
# not an arbitrary selection). The coordinates for the target structure
# are also taken from the targeted atoms in this file. Non-targeted
# atoms are ignored. The beta column of targetted atoms is used to
# designate non-overlapping constraint domains. Forces will be
# calculated for atoms within a domain separately from atoms of other
# domains.

## read ATOM/HETATM characters 7-26 files


@lt = `grep -P '^(ATOM|HETATM)' $ft | cut -c 7-26`;
@lr = `grep -P '^(ATOM|HETATM)' $fr | cut -c 7-26`;

grep chomp, @lt;
grep chomp, @lr;

for $lr ( @lr ) {
    $rexists{$lr}++;
}

for $lt ( @lt ) {
    die "Target ATOM $lt does not match in Reference structure\n" if !$rexists{$lt};
}


