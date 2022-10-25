#!/usr/bin/perl

$notes = "usage: $0 pdb

creates:
 pdbname_f_pa_c.pdb  - fixed protein and carbs
 pdbname_f_pa.pdb    - fixed protein atoms
 pdbname_f_pbba.pdb  - fixed backbone atoms
 pdbname_f_pssa.pdb  - fixed alpha helix/beta sheet and backbone protein atoms

Hydrogens are never fixed
note you may need to reassign chains, etc and include HELIX & SHEET sections of the pdb
";

use File::Basename;
my $scriptd = dirname(__FILE__);
require "$scriptd/pdbutil.pm";

$f = shift || die $notes;
$fb = $f;
$fb =~ s/\.pdb$//;

die "$f does not exist\n" if !-e $f;
die "$f is not readable\n" if !-r $f;
    
open IN, $f || die "$f open error $!\n";
@l = <IN>;
close IN;
grep chomp, @l;

# first get sheet & helix info

foreach $l ( @l ) {
    $r = pdb_fields( $l );
    if ( $r->{"recname"}  =~ /^(SHEET|HELIX)$/ ) {
        my $iresnam  = $r->{"initresname"};
        my $ichainid = $r->{"initchainid"};
        my $iseqnum  = $r->{"initseqnum"};
        my $eresnam  = $r->{"end"};
        my $echainid = $r->{"endchainid"};
        my $eseqnum  = $r->{"endseqnum"};

        for my $id ( $iseqnum..$eseqnum ) {
            my $tid   = $id; # for checking: myleftpad0( $id, 3 );
            my $index = "$ichainid:$tid";
            $pssa{ $index }++;
        }
    }
}

warn "No sheets or helices found\n" if !keys %pssa;

# debugging print join( "\n", sort { $a cmp $b } keys %pssa ) . "\n";

sub setbeta {
    my $l      = shift;
    my $v      = shift;
    my $tf     = "  0.00";
    $tf        = "  1.00" if $v;
    
    substr( $l, 0, 60 ) . $tf . substr( $l, 66 );
}


# fixed protien and carbs
{
    my $fo = ">${fb}_f_pa_c.pdb";
    my @ol;
    foreach $l ( @l ) {
        $r = pdb_fields( $l );
        $recname = $r->{"recname"};
        if ( $recname !~ /^(ATOM|HETATM)$/ ) {
            push @ol, $l;
            next;
        }            
        $element = $r->{"element"};
        # leave hydrogens floating
        if ( $element eq 'H' ) {
            push @ol, setbeta( $l, 0 );
            next;
        }
        my $resname = $r->{"resname"};
        if ( $prmap{ $resname } || $crmap{ $resname } ) {
            push @ol, setbeta( $l, 1 );
            next;
        }
        my $resseq  = $r->{"resseq"};
        warn "residue $resname $resseq not protein or carb, will be left floating (only reported once)\n" if !$unknown{$resname}++;
        push @ol, $l;
    }
    print "$fo\n";
    open OUT, $fo || die "can not open $fo $!\n";
    print OUT ( join "\n", @ol ) . "\n";
    close OUT;
}
  
# fixed protein
{
    my $fo = ">${fb}_f_pa.pdb";
    my @ol;
    foreach $l ( @l ) {
        $r = pdb_fields( $l );
        $recname = $r->{"recname"};
        if ( $recname !~ /^(ATOM|HETATM)$/ ) {
            push @ol, $l;
            next;
        }            
        $element = $r->{"element"};
        # leave hydrogens floating
        if ( $element eq 'H' ) {
            push @ol, setbeta( $l, 0 );
            next;
        }
        my $resname = $r->{"resname"};
        if ( $prmap{ $resname } ) {
            push @ol, setbeta( $l, 1 );
            next;
        }
        push @ol, setbeta( $l, 0 );
    }
    print "$fo\n";
    open OUT, $fo || die "can not open $fo $!\n";
    print OUT ( join "\n", @ol ) . "\n";
    close OUT;
}

# fixed protein backbone
{
    my $fo = ">${fb}_f_pbba.pdb";
    my @ol;
    foreach $l ( @l ) {
        $r = pdb_fields( $l );
        $recname = $r->{"recname"};
        if ( $recname !~ /^(ATOM|HETATM)$/ ) {
            push @ol, $l;
            next;
        }            
        $element = $r->{"element"};
        # leave hydrogens floating
        if ( $element eq 'H' ) {
            push @ol, setbeta( $l, 0 );
            next;
        }
        my $resname = $r->{"resname"};
        my $name    = $r->{"name"};
        if ( $prmap{ $resname } && $pbbamap{ $name } ) {
            push @ol, setbeta( $l, 1 );
            next;
        }
        push @ol, setbeta( $l, 0 );
    }
    print "$fo\n";
    open OUT, $fo || die "can not open $fo $!\n";
    print OUT ( join "\n", @ol ) . "\n";
    close OUT;
}

# fixed protein backbone and secondary structure
{
    my $fo = ">${fb}_f_pssa.pdb";
    my @ol;
    foreach $l ( @l ) {
        $r = pdb_fields( $l );
        $recname = $r->{"recname"};
        if ( $recname !~ /^(ATOM|HETATM)$/ ) {
            push @ol, $l;
            next;
        }            
        $element = $r->{"element"};
        # leave hydrogens floating
        if ( $element eq 'H' ) {
            push @ol, setbeta( $l, 0 );
            next;
        }
        my $resname = $r->{"resname"};
        my $name    = $r->{"name"};
        if ( $prmap{ $resname } && $pbbamap{ $name } ) {
            push @ol, setbeta( $l, 1 );
            next;
        }
        my $resseq  = $r->{"resseq"};
        my $chainid = $r->{"chainid"};
        my $index   = "$chainid:$resseq";
        push @ol, setbeta( $l, $pssa{$index} ? 1 : 0 );
    }
    print "$fo\n";
    open OUT, $fo || die "can not open $fo $!\n";
    print OUT ( join "\n", @ol ) . "\n";
    close OUT;
}
    
