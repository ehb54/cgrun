#!/usr/bin/perl

use File::Basename;
{
    my $scriptd = dirname(__FILE__);
    require "$scriptd/pdbutil.pm";
}

$notes = "usage: $0 pdb*

cuts from all models

creates 4 files
_1SIA      removal of SIA 11 all chains
_1SIA_54BE removal of SIA 11 all chains and residues 1-54 of chains B & E
_1SIA_54B  removal of SIA 11 all chains and residues 1-54 of chain B
_1SIA_54E  removal of SIA 11 all chains and residues 1-54 of chain E

";

$f = shift || die $notes;

open IN, $f || die "$f open error $!\n";
@l = <IN>;
close IN;
grep chomp, @l;

## 1SIA

undef @ol;
undef $atomscut;

$fo = $f;
$fo =~ s/\.pdb$/_1SIA.pdb/;

die "$fo exists\n" if -e $fo;

foreach $l ( @l ) {
    my $r = pdb_fields( $l );
    
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        if ( $r->{"resname"} eq 'SIA' &&
             $r->{"resseq"}  == 11 ) {
            ++$atomscut;
            next;
        }
    }
    push @ol, $l;
}

print "$atomscut SIA 11 atoms cut\n";

print "$fo\n";
open OUT, ">$fo" || die "can not open $fo $!\n";
print OUT ( join "\n", @ol ) . "\n";
close OUT;
        
## 54BE

undef @ol;
undef $atomscut;

$fo = $f;
$fo =~ s/\.pdb$/_1SIA_54BE.pdb/;
die "$fo exists\n" if -e $fo;

foreach $l ( @l ) {
    my $r = pdb_fields( $l );
    
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        if (
            ( $r->{"resname"} eq 'SIA' && $r->{"resseq"}  == 11 )
            || ( $r->{"chainid"} eq 'B' && $r->{"resseq"} <= 54 )
            || ( $r->{"chainid"} eq 'E' && $r->{"resseq"} <= 54 )
            ) {
            ++$atomscut;
            next;
        }
    }
    push @ol, $l;
}

print "$atomscut SIA 11, B 1-54 & E 1-54 atoms cut\n";

print "$fo\n";
open OUT, ">$fo" || die "can not open $fo $!\n";
print OUT ( join "\n", @ol ) . "\n";
close OUT;
        
    
## 54B

undef @ol;
undef $atomscut;

$fo = $f;
$fo =~ s/\.pdb$/_1SIA_54B.pdb/;
die "$fo exists\n" if -e $fo;

foreach $l ( @l ) {
    my $r = pdb_fields( $l );
    
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        if (
            ( $r->{"resname"} eq 'SIA' && $r->{"resseq"}  == 11 )
            || ( $r->{"chainid"} eq 'B' && $r->{"resseq"} <= 54 )
            ) {
            ++$atomscut;
            next;
        }
    }
    push @ol, $l;
}

print "$atomscut SIA 11, B 1-54 atoms cut\n";

print "$fo\n";
open OUT, ">$fo" || die "can not open $fo $!\n";
print OUT ( join "\n", @ol ) . "\n";
close OUT;
        
    
## 54E

undef @ol;
undef $atomscut;

$fo = $f;
$fo =~ s/\.pdb$/_1SIA_54E.pdb/;
die "$fo exists\n" if -e $fo;

foreach $l ( @l ) {
    my $r = pdb_fields( $l );
    
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        if (
            ( $r->{"resname"} eq 'SIA' && $r->{"resseq"}  == 11 )
            || ( $r->{"chainid"} eq 'E' && $r->{"resseq"} <= 54 )
            ) {
            ++$atomscut;
            next;
        }
    }
    push @ol, $l;
}

print "$atomscut SIA 11, E 1-54 atoms cut\n";

print "$fo\n";
open OUT, ">$fo" || die "can not open $fo $!\n";
print OUT ( join "\n", @ol ) . "\n";
close OUT;
        
    
