#!/usr/bin/perl

### user config (could be in a specific config.json

$mdhome = "/home/ehb";
$mdutil = "$mdhome/mdutil";
$mdjson = "$mdhome/mdjson";
$mdtmpl = "$mdhome/mdtmpl";
# $debug++;

### end user config    
use File::Basename;
{
    my $scriptd = dirname(__FILE__);
    require "$scriptd/pdbutil.pm";
}


use JSON;

$notes = "usage: $0 name

processes name.json and creates inp files for mdruns

";

$f = shift || die $notes;
$fb = $f;
$fb =~ s/\.json$//;

$f = "$mdjson/$fb.json";

die "$f does not exist\n" if !-e $f;
die "$f is  at readable\n" if !-r $f;

### open json

open IN, $f || die "$f $!\n";
@l = <IN>;
close IN;

$l = join( '', @l );
$json = decode_json( $l );


### build up base dictionary
$skipkey{ "prep" }++;


for my $k ( keys %$json ) {
    print "$k\n" if $debug;
    next if $skipkey{$k};
    if ( ref( $$json{$k} ) eq "ARRAY" ) {
        print "setting $k as array\n" if $debug;
        $gsub{ "__${k}__" } = join( "\n", @{$$json{$k}} );
        next;
    } elsif ( ref( $$json{$k} ) eq "HASH" ) {
        die "unexpected top level ref type $k (perhaps add to skipkey?)\n";
    }
    $gsub{ "__${k}__" } = $$json{$k};
}

for my $k ( keys %gsub ) {
    print "key $k : value:\n" . $gsub{$k} . "\n" if $debug;
}

### process each prep

die "no 'prep' in $f\n" if !$$json{"prep"};

# $stages = scalar @{$$json{"prep"}};
# print "total defined stages $stages [some may be inactive]\n";

$lreq{ "template" }++;

my %psub = %gsub; # previous values

$mfuncs{ "add" }++;

@allshtorun;

for my $stage ( @{$$json{"prep"}} ) {
    print "found a stage\n" if $debug;
    my %lsub;
    my @to_process;
    print sprintf( "start of loop starttime %d psubstarttime %d\n", $sub{"__starttime__"}, $psub{"__starttime__"} ) if $debugmath;
    
    for my $k ( keys %$stage ) {
        print "found stage key $k\n" if $debug;
        if ( ref( $$stage{$k} ) eq "ARRAY" ) {
            print "$k is an array - check for special processing\n" if $debug;
            # array size 1 and match of keyword means use variable
            if ( $mfuncs{ $k } ) {
                push @to_process, $k;
                next;
            }
            if ( @{$$stage{$k}} == 1 &&
                 $$stage{$k}[0] eq $k ) {
                if ( exists $psub{"__${k}__" } ) {
                    $lsub{"__${k}__" } = $psub{"__${k}__" };
                    print "variable $k = " . $psub{"__${k}__" } . "\n";
                    next;
                }
                die "expected variable $k to set, but currently undefined\n";
            }
            
            print "setting $k as array\n" if $debug;
            $lsub{ "__${k}__" } = join( "\n", @{$$stage{$k}} );
            next;
        } elsif ( ref( $$stage{$k} ) eq "HASH" ) {
            die "unexpected top level ref type $k (perhaps add to skipkey?)\n";
        }
        $lsub{ "__${k}__" } = $$stage{$k};
    }
    for my $k ( keys %lreq ) {
        die "key $k not defined in prep stage\n" if !exists $lsub{"__${k}__"};
    }
    for my $k ( keys %lsub ) {
        print "key $k : value:" . $lsub{$k} . "\n" if $debug;
    }

    next if exists $$stage{"active"} && !$$stage{"active"};

    my $ftmpl = $mdtmpl . "/" . $lsub{ "__template__" } . ".tmpl";
    print "ftmpl is $ftmpl\n" if $debug;
    die "$ftmpl does not exist\n" if !-e $ftmpl;
    die "$ftmpl is not readable\n" if !-r $ftmpl;

    my %sub = ( %gsub, %lsub );

    for my $k ( @to_process ) {
        my @stack = @{$$stage{$k}};
        my $resk = shift @stack || die "$k empty stack\n";
        my $resv = 0;
        
        for my $k1 ( @stack ) {
            die "$k: missing key $k1 value\n" if !exists $sub{ "__${k1}__" };
            $resv += $sub{ "__${k1}__" };
            print sprintf( "--> for stack element $k1 adding %d to total in $resk\n", $sub{ "__${k1}__" } ) if $debugmath;
        }
        $psub{ "__${resk}__" } = $resv;
        print "--> $resk total $resv\n" if $debugmath;
    }
    print sprintf( "after adds starttime %d psubstarttime %d\n", $sub{"__starttime__"}, $psub{"__starttime__"} ) if $debugmath;
    %psub = ( %sub, %psub );
    print sprintf( "merging hash starttime %d psubstarttime %d\n", $sub{"__starttime__"}, $psub{"__starttime__"} ) if $debugmath;

    my $tout  = $sub{ "__template__" };
    {
        my $ext = 0;
        while ( $nused{ "${tout}_" . myleftpad0( $ext, 3 ) } ) {
            ++$ext;
        }
        $tout = "${tout}_" . myleftpad0( $ext, 3 );
        $nused{ $tout }++;
    }
    
    # create inp
    {
        my @ol;
        open my $fh, $ftmpl || die "$ftmpl error opening $!\n";
        my @l = <$fh>;
        close $fh;

        for my $l ( @l ) {
            if ( $l !~ /(__\S+__)/ ) {
                push @ol, $l;
                next;
            }
            my $k = $1;
            die "key '$k' not defined in $f\n" if !exists $sub{$k};
            $l =~ s/$k/$sub{$k}/;
            push @ol, $l;
        }


        my $fo = ">$tout.inp"; # probably need some dir info
        open my $fh, $fo || die "$fo error opening $!\n";
        print $fh join( '', @ol );
        close $fh;
        print "$fo\n";
    }

    # create .sh to run
    {
        my @ol;
        my @req = (
            "namdenv"
            ,"namdrun"
            ,"output"
            );

        for my $k ( @req ) {
            die "missing __${k}__\n" if !$sub{ "__${k}__" };
        }

        push @ol,
            "#!/bin/bash\n"
            ;

        my $outdir = $sub{ "__output__" };
        if ( $outdir =~ /\// ) {
            $outdir =~ s/\/[^\/]*$//;
            push @ol,
                "mkdir -p $outdir 2> /dev/null\n"
                ;
        } else {
            $outdir = "";
        }
        
        push @ol, sprintf( "echo description: %s\n", $sub{'__description__'} );

        push @ol,
            $sub{"__namdenv__"} . "\n"
            . $sub{"__namdrun__"} . " ${tout}.inp 2>&1 > ${tout}.out\n"
            ;

        push @ol,
            "$mdutil/namdplots.pl $tout.out $outdir\n"
            ;

        my $fo = ">$tout.sh"; # probably need some dir info
        open my $fh, $fo || die "$fo error opening $!\n";
        print $fh join( '', @ol );
        close $fh;
        print "$fo\n";
        `chmod +x $tout.sh`;
        push @allshtorun, "echo $tout.sh && ./$tout.sh";
    }
}

my $fo = "ndrp_all.sh";
open my $fh, ">$fo" || die "$fo error opening $!\n";
print $fh join( ' && ', @allshtorun ) . "\n";
close $fh;
print ">$fo\n";
`chmod +x $fo`;

