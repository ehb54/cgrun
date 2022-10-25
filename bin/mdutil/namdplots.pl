#!/usr/bin/perl

#### user defines
@skipplots = (
    "pressavg"
    ,"gpressavg"
    ,"gpressure"
    ,"total3"
    ,"boundary"
    ,"misc"
   ,"volume"
#    ,"kinetic"
    );

#### end user defines

while ( my $s = shift @skipplots ) {
    $skipplotmap{$s}++;
}

use File::Temp qw(tempfile);

$notes = "usage: $0 outfile {destdir {xrangestart:xrangeend}}

extracts data into outfile.energy
& later creates plots
optionally puts outputs into destdir
";

$f = shift || die $notes;
$fb = $f;
$fb =~ s/\..*$//;
die "$f does not exist\n" if !-e $f;
die "$f is not readable\n" if !-r $f;
$dd = shift;
$dd = "." if !$dd;
$xr = shift;
if ( $xr ) {
    $xrange = "set xrange [$xr]\n";
}


# subs
sub echoline {
    print '-'x80 . "\n"
}

sub runcmd {
    my $cmd = shift;
    print "$cmd\n";
    print `$cmd`;
    die "error status returned $?\n" if $?;
}

sub plotone {
    my $title  = shift;
    my $suffix = shift;
    my $col    = shift;

    echoline();
    print "building plot for $title\n";

    my $fo = "${fb}_${suffix}.png";

    $gnuout = <<"__EOD"
set term png medium size 1024,1024
# set title font "Ariel,20"
# set title "$title"
set xlabel "timestep"
set xlabel font "Ariel,18"
set xtics font "Ariel,16"
set ytics font "Ariel,16"
set key font "Ariel,24"
set output "$dd/$fo"
set margin 23,10,4,4
$xrange
plot "$fb.energy" using 2:$col with lines title "$title"
set output
__EOD
    ;
    
    my ( $fh, $ft ) = tempfile( "gnuplot.${title}.XXXXXX", UNLINK => 1 );
    print $fh $gnuout;
    close $fh;
    runcmd( "gnuplot $ft" );
    $fo;
}




# main logic

$hdr = `grep -P "^ETITLE:" $f | head -1`;

@l = `grep -P "^ENERGY:" $f`;

$fene = "$fb.energy";
open OUT, ">$fene" || die "$fene open $!\n";
print OUT "#";
print OUT "$hdr";
print OUT join '', @l;
close OUT;
print ">$fene\n";

@h = split /\s+/, lc($hdr);

shift @h;
shift @h;

print join ':', @h;
print "\n";

$col = 3;

for $h ( @h ) {
    if ( $skipplotmap{ $h } ) {
        $col++;
    } else {
        push @plots, plotone( $h, $h, $col++ );
    }
}

print join( " ", @plots ) . "\n";

$cmd .= "cd $dd && convert";
$cnt = 0;
$ppr = 3; # plots per row
$done1 = 0;
while ( @plots ) {
    $cmd .= " \\(" if $done1; 
    for ( $i = 0; $i < $ppr; ++$i ) {
        if ( @plots ) {
            $cmd .= " ";
            $cmd .= shift @plots;
        }
    }
    $cmd .= " +append";
    $cmd .= " \\)" if $done1++; 
}
$cmd .= " -append ${fb}_energy.png";
# print "$cmd\n";
runcmd( $cmd );

     
