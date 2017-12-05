#!/usr/bin/perl -w
use strict;
use Getopt::Long qw(GetOptions);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Routines;
my $BinPath = "$FindBin::Bin";
my $MainPath = "$FindBin::Bin/../";

my $Usage = "USAGE:\n  $0 [--help] [--clusters -c] [--training -t File] [--metadata -m File]
      [--query -q File] [--out Path] [--stat -s Test] [--bootstrap -b Bolean]
\n  Use \'--help\' to print a detailed descriptions of options.\n\n";

my ($Help, $TrainingFile, $MetadataFile, $OutPath, $Cluster, $QryFile, $Bayes,
    $PsCounts, $Stat);

$Bayes    = 0;
$PsCounts = 0;
$Stat     = "off";
$OutPath  = $MainPath;

GetOptions(
        'help'              => \$Help,
        
        'training|t:s'      => \$TrainingFile,
        'metadata|m:s'      => \$MetadataFile,
        'out|o:s'           => \$OutPath,
        
        'cluster|c:s'       => \$Cluster,
        
        'stat|s'            => \$Stat,
        'plot|s'            => \$Plot, $AllClassesPlot $ForClassPlot $HeatMapPlot $Correlation $Sort $Clusters $Dendrogram
        
        
        'pseudo-counts|p:i' => \$PsCounts,
        'bootstrap|b:s'     => \$QryFile,
        
        'bayes'             => \$Bayes,
        'query|q:s'         => \$QryFile
        
        
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

my ($BayesPrediction, $FeaturesClassifier, $Start, $End, $Time, $RunTime, $Period);

$Start = time();

if(defined $TrainingFile && defined $MetadataFile){

   $BayesPrediction  = $OutPath ."/". "BayesianClassifier.pl";
   $FeaturesClassifier   = $OutPath ."/". "FeaturesClassifier.pl";

   if($Cluster eq "Elements"){
      if(defined $QryFile){
         system("perl $BayesPrediction $TrainingFile $MetadataFile $QryFile $OutPath $Stat $PsCounts");
      }else{
         print "\nA bolean query file is needed! \n $Usage";
      }
   }elsif($Cluster eq "Features"){
      system("perl $FeaturesClassifier $TrainingFile $MetadataFile $OutPath $PsCounts $Stat $Plot $HeatMap $Correlation $Sort $Clusters $Dendrogram");
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


