#!/usr/bin/perl

### user defines

$basedir  = "/home/ehb/srv";
$prefix   = "md-";
$vacuumd  = "vacuumd";
$solmind  = "solmin";
$mdutils  = "/home/ehb/mdutil";

### endif

$notes = "usage: $0 charmm-gui-XXX.tgz refpdb maxatom

extracts charm gui into $basedir/${prefix}XXX
creates namd/min0
inserts HELIX & SHEET info from refpdb
setup for vacuum minimized runs

";

use File::Basename;
my $scriptd = dirname(__FILE__);
print "$scriptd/pdbutil.pm\n";
require "$scriptd/pdbutil.pm";
use File::Spec;
use Cwd qw(abs_path);

$f       = shift || die $notes;
$refpdb  = shift || die $notes;
$maxatom = shift || die $notes;
die "$f does not exist\n" if !-e $f;
die "$f is not readable\n" if !-r $f;

$refpdb  = abs_path( File::Spec->canonpath( $refpdb ) );

( $tag ) = $f =~ /^charmm-gui-(.*)\.tgz$/;

die "no extractable XXX found in tgz named $f\n" if !length($tag);

$do = "$basedir/$prefix$tag";
die "directory $do already exists, remove or rename\n" if -e $do;

# mkdir & extract

@cmds = (
    "mkdir $do"
    ,"tar zxf $f --directory $do"
    );

runcmds( \@cmds );

# get charmm directory and change to it
chdir $do;
$workdir = runcmd( "ls" );
chomp $workdir;
chdir $workdir;
$pwd = runcmd( "pwd" );
chomp $pwd;
$workdir = "$pwd/namd";

die "no namd directory in $pwd\n" if !-x $workdir;
chdir $workdir || die "can't change to directory $workdir\n";

print "Working in directory:\n$workdir\n";

# setup min0

@cmds = (
    "mkdir $vacuumd"
    ,"cd $vacuumd && cp ../step3_input.pdb ."
    ,"cd $vacuumd && cp ../step3_input.psf ."
    ,"cd $vacuumd && $mdutils/pdbcutwi.pl step3_input.pdb"
    ,"cd $vacuumd && $mdutils/somopdb.pl step3_input.pdb"
    ,"cd $vacuumd && $mdutils/pdbhelixsheet.pl step3_input.somo.pdb $refpdb"
    ,"cd $vacuumd && $mdutils/restraints.pl step3_input.somo.pdb"
    ,"cd $vacuumd && $mdutils/restraintscoc.pl step3_input.somo.pdb 10"
    ,"cd $vacuumd && $mdutils/psfcut.pl step3_input.psf $maxatom"
    ,"mkdir $solmind"
    ,"cd $solmind && cp ../step3_input.pdb ."
    ,"cd $solmind && cp ../step3_input.psf ."
    ,"cd $solmind && $mdutils/somopdb.pl step3_input.pdb"
    ,"cd $solmind && $mdutils/pdbhelixsheet.pl step3_input.somo.pdb $refpdb"
    ,"cd $solmind && $mdutils/restraints.pl step3_input.somo.pdb"
    ,"cd $solmind && $mdutils/restraintscoc.pl step3_input.somo.pdb 10"
    );

runcmds( \@cmds );
