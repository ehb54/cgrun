#!/usr/bin/perl

@hinge =
    (
     "A", 99, 110
     ,"B", 130, 155
     ,"C", 70, 100
     ,"D", 99, 110
     ,"E", 130, 155
     ,"F", 70, 100
    );

while ( my $chain = shift @hinge ) {
    my $start = shift @hinge || die "$0 : improper hinge array\n";
    my $end   = shift @hinge || die "$0 : improper hinge array\n";
    $hinge_start{$chain} = $start;
    $hinge_end  {$chain} = $end;
}
     
foreach my $k ( sort { $a cmp $b } keys %hinge_start ) {
    $desc_hinge .= sprintf( "$k %5d %5d\n", $hinge_start{$k}, $hinge_end{$k} );
}

$notes = "usage: $0 pdb

creates:
 pdbname_f_nonhinge.pdb


carbs are fixed
protein atoms ouside of hinge region are fixed
Hydrogens are never fixed

Current hinge:
$desc_hinge

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

# debugging print join( "\n", sort { $a cmp $b } keys %pssa ) . "\n";

sub setbeta {
    my $l      = shift;
    my $v      = shift;
    my $tf     = "  0.00";
    $tf        = "  1.00" if $v;
    
    substr( $l, 0, 60 ) . $tf . substr( $l, 66 );
}

# fixed non hinge
{
    my $fo = ">${fb}_f_nonhinge.pdb";
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
        if ( exists $crmap{ $resname } ) {
            # carbs fixed
            push @ol, setbeta( $l, 1 );
            next;
        }
        if ( !exists $prmap{ $resname } ) {
            warn "residue $resname $resseq not protein or carb, will be left floating (only reported once)\n" if !$unknown{$resname}++;
            push @ol, setbeta( $l, 0 );
            next;
        }
        my $chainid = $r->{"chainid"};
        my $resseq  = $r->{"resseq"};
        if ( !exists $hinge_start{ $chainid } ||
             $resseq < $hinge_start{ $chainid } ||
             $resseq > $hinge_end{ $chainid }
            ) {
            push @ol, setbeta( $l, 1 );
        } else {
            push @ol, setbeta( $l, 0 );
        }
        next;
    }
    print "$fo\n";
    open OUT, $fo || die "can not open $fo $!\n";
    print OUT ( join "\n", @ol ) . "\n";
    close OUT;
}
  
