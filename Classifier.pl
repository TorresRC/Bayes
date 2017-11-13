#!/usr/bin/perl -w
use strict;
use Getopt::Long qw(GetOptions);
use FindBin;
use lib "$FindBin::Bin/lib";
use Routines;
my $MainPath = "$FindBin::Bin";

my $Usage = "USAGE:\n  $0 [--help] [options] [--training -t Absolute File] [--metadata -m File]
      [--query -q File] [--out Path] [--bayes --mle --chi2]
\n  Use \'--help\' to print detailed descriptions of options.\n\n";

my ($Help, $TrainingFile, $MetadataFile, $QryFile, $OutPath, $Bayes, $PsCounts,
    $Stat, $MLE, $Chi2);

$Bayes    = 0;
$MLE      = 0;
$Chi2     = 0;
$Stat     = 0;
$PsCounts = 0;
$OutPath  = $MainPath;

GetOptions(
        'help'              => \$Help,
        'training|t:s'      => \$TrainingFile,
        'metadata|m:s'      => \$MetadataFile,
        'query|q:s'         => \$QryFile,
        'out|o:s'           => \$OutPath,
        'bayes'             => \$Bayes,
        'mle'               => \$MLE,
        'chi2'              => \$Chi2,
        'pseudo-counts|c:i' => \$PsCounts,
        'stat|s'            => \$Stat,
        ) or die $Usage;

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

my ($BayesPrediction, $TestClassifier, $Start, $End, $Time, $RunTime, $Period);

$Start = time();

if(defined $TrainingFile && defined $MetadataFile){

   $BayesPrediction  = $MainPath ."/". "BayesianClassifier.pl";
   $TestClassifier   = $MainPath ."/". "FeaturesClassifier.pl";

   if($Bayes == 1){
      if(defined $QryFile){
         system("perl $BayesPrediction $TrainingFile $MetadataFile $QryFile $OutPath $Stat $PsCounts");
      }else{
         print "\nA bolean query file is needed! \n $Usage";
      }
   }elsif($Bayes == 0 && $MLE == 1 or $Chi2 == 1){
      system("perl $TestClassifier $TrainingFile $MetadataFile $OutPath $PsCounts $MLE $Chi2");
   }else{
      print "\nYou must to select at least but one statistic test (--bayes, --mle or --chi2)\n";
      print "\tFinished\n";
      exit;
   }
}else{
   print "\nA bolean training and a metadata files are needed! \n $Usage";
}

$End = time();
$Time = ($End-$Start);
if ($Time < 3600){
        $RunTime = ($Time)/60;
        $Period = "minutes";
}elsif ($Time >= 3600 && $Time < 86400){
        $RunTime = (($Time)/60)/60;
        $Period = "hours";
}elsif ($Time >= 86400){
        $RunTime = ((($Time)/60)/60)/24;
        $Period = "days";
}

print "\n\tFinished! The estimation took $RunTime $Period\n\n";
exit;


