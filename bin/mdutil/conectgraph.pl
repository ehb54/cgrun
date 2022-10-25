#!/usr/bin/perl

$notes = "usage: $0 pdb*

for each non AA chain, create a graphviz dot png for connectivity
";

$f = shift || die $notes;

die "$f does not exist\n" if !-e $f;
die "$f is not readable\n" if !-r $f;

use File::Basename;
{
    my $scriptd = dirname(__FILE__);
    require "$scriptd/pdbutil.pm";
}

open IN, $f || die "$f open error $!\n";
@l = <IN>;
close IN;
grep chomp, @l;

foreach $l ( @l ) {
    $r = pdb_fields( $l );
    if ( $r->{"recname"}  =~ /^(ATOM|HETATM)$/ ) {
        next if exists $prmap{ $r->{ "resname" } } || $r->{"element"} eq 'H' || $r->{'name'} =~ /^H/;
        my $serial  = $r->{ "serial" };
        $name    = $name   { $serial } = $r->{ "name" };
        $resname = $resname{ $serial } = $r->{ "resname" };
        $chainid = $chainid{ $serial } = $r->{ "chainid" };
        $resseq  = $resseq { $serial } = $r->{ "resseq" };
        # graph node info
        $node_residue  = "${resname}_${chainid}_${resseq}";
        $node_element  = "${resname}_${chainid}_${resseq}_${name}";
        if ( !exists $cluster_label{$node_residue} ) {
            $cluster_label{$node_residue} = "label = \"${resname} ${chainid} ${resseq}\";\n";
        }
        $cluster_elements{$node_residue} .= "${node_element}\[label=\"$name\"\];\n";
    } elsif ( $r->{"recname"}  =~ /^CONECT$/ ) {
        my $ts    = $r->{ "serial" };
        if ( !$resname{ $ts } ) {
            # warn "atom with serial $ts not defined\n";
            next;
        }
        my $node_element1  = sprintf( "%s_%s_%s_%s", $resname{$ts}, $chainid{$ts}, $resseq{$ts}, $name{$ts} );
        for ( my $i = 1; $i <= 4; ++$i ) {

            my $b = $r->{ "bond$i" };
            my $bcolor = "grey";
            if ( $resseq{$ts} ne $resseq{$b} ) {
                $bcolor = "blue";
            }
            if ( $chainid{$ts} ne $chainid{$b} ) {
                $bcolor = "red";
            }

            if ( $b > 0 ) {
                if ( !$resname{ $b } ) {
                    # warn "atom with serial $b not defined\n";
                    next;
                }
                
                my $node_element2  = sprintf( "%s_%s_%s_%s", $resname{$b}, $chainid{$b}, $resseq{$b}, $name{$b} );

                my $thispair = "${node_element1}->${node_element2}\[dir=\"none\",color=\"$bcolor\"];\n";
                my $revpair  = "${node_element2}->${node_element1}\[dir=\"none\",color=\"$bcolor\"];\n";
                
                next if $alreadypaired{ $revpair };
                $bonds .= $thispair;
                $alreadypaired{ $thispair }++;
            }
        }
    } elsif ( $r->{"recname"}  =~ /^LINK$/ ) {
        my $name1    = $r->{"name1"};
        my $resname1 = $r->{"resname1"};
        my $chainid1 = $r->{"chainid1"};
        my $resseq1  = $r->{"resseq1"};
        my $name2    = $r->{"name2"};
        my $resname2 = $r->{"resname2"};
        my $chainid2 = $r->{"chainid2"};
        my $resseq2  = $r->{"resseq2"};
        my $bcolor   = "green";
        
        my $node_element1  = sprintf( "%s_%s_%s_%s", $resname1, $chainid1, $resseq1, $name1 );
        my $node_element2  = sprintf( "%s_%s_%s_%s", $resname2, $chainid2, $resseq2, $name2 );

        my $thispair = "${node_element1}->${node_element2}\[dir=\"none\",color=\"$bcolor\"];\n";
        my $revpair  = "${node_element2}->${node_element1}\[dir=\"none\",color=\"$bcolor\"];\n";
        
        next if $alreadypaired{ $revpair };
        $bonds .= $thispair;
        $alreadypaired{ $thispair }++;
    }
}

$out = "
digraph G {
";

for $k ( keys %cluster_label ) {
   $out .= "  subgraph cluster_$k {
$cluster_label{$k}
$cluster_elements{$k}
}
";
}


$out .= "$bonds}\n";

print $out;

