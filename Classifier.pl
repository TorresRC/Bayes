#!/usr/bin/perl -w
use strict;
use List::MoreUtils qw(uniq);
use FindBin;
use lib "$FindBin::Bin/lib";
use Routines;
my $MainPath = "$FindBin::Bin";

my ($Help, $TrainingFile, $MetadataFile, $QryFile, $OutPath, $PsCounts, $Stat, $MLE, $Chi2);

$Stat     = 0;
$MLE      = 0;
$Chi2     = 0;
$PsCounts = 0;
$OutPath = $MainPath;

GetOptions(
        'help'              => \$Help,
        'training|t:s'      => \$TrainingFile,
        'metadata|m:s'      => \$MetadataFile,
        'query|q:s'         => \$QryFile,
        'out|o:s'           => \$OutPath,
        'pseudo-counts|c:i' => \$PsCounts,
        'stat|s'            => \$Stat,
        'mle'               => \$MLE,
        'chi2'              => \$Chi2,
        ) or die "USAGE:\n  $0 [--help] [options] [--training -t Absolute File] [--metadata -m File]
      [--query -q File] [--out Path]
\n  Use \'--help\' to print detailed descriptions of options.\n\n";

if($Help){
        print "
        \t--training -t 
        \t--metadata -m 
        \t--query -q 
        \t--out -o
        \t--pseudo-counts -c
        \t--stat
        \t--mle
        \t--chi2
        \n\n";
        exit;
}

if


