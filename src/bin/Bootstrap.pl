#!/usr/bin/perl -w
use strict;
use List::MoreUtils qw(uniq);
use List::Util qw(reduce);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Routines;
my $MainPath = "$FindBin::Bin";

my ($Usage, $TrainingFile, $MetadataFile, $QryFile, $OutPath, $Stat, $PsCounts,
    $max_val_key, $Iter);

$Usage = "\nUSAGE\n  $FindBin::Script <Observed Data [Absolute Path]>
                            <Metadata [Absolute Path]>
                            <Output Path [Relative Path]>
                            <Pseudo Counts Increase [Integer]>
                            <ChiSquare Test [Bolean]>
                            <Maximum Likelihood Estimation [Bolean]>\n\n";
unless(@ARGV) {
        print $Usage;
        exit;
}
chomp @ARGV;
$TrainingFile = $ARGV[0];
$MetadataFile = $ARGV[1];
$QryFile      = $ARGV[2];
$OutPath      = $ARGV[3];
$Stat         = $ARGV[4];
$PsCounts     = $ARGV[5];
$Iter         = $ARGV[6];


my($LinesOnTrainingFile, $Line, $ColumnsOnTrainingFile, $N, $MetaData,
   $LinesOnMetaDataFile, $ColumnsOnMetaDataFile, $GlobalHits, $Region, $Element,
   $Class, $nClasses, $Classification, $Counter, $Hit, $Count, $Feature,
   $ElementHit, $ElementHits, $FeatureHit, $FeatureHits, $nFeature,
   $LinesOnQryFile, $ColumnsOnQryFile, $QryHit, $QryElement, $PossibleClass,
   $Probabilities, $Column, $pQryClass, $cpQryClass, $ReportFile,
   $pHitFeatureClass, $HigherClassLen, $EstimatedFeature, $NewElement,
   $BootstrapFile, $cmd, $BootstrapedMetadata, $Qry,$LinesOnClassification,
   $ColumnsOnClassification, $Repeats, $BootstrappedTraining, $LinesOnBootstrappedClass,
   $ColumnsOnBootstrappedClass, $NewColumns);
my($i, $j, $k, $l);
my(@TrainingFile, @TrainingFileFields, @TrainingMatrix, @MetaDataField, @MetaDataFile,
   @MetaDataFileFields, @MetaDataMatrix, @Classes, @Elements, @QryFile, @QryFileFields,
   @QryMatrix, @Bootstrap, @BootstrapedQry, @BootstrapedQryFields, @ClassificationMatrix,
   @BootstrappedClassMatrix);
my(%ClassOfElement, %TotalFeatureHits, %HitsOfFeaturesInClass, %pHitsOfFeaturesInClass,
   %cpHitsOfFeaturesInClass,
   %ElementClass, %Elements, %pClass, %cpClass, %ClassHits, %FeatureClass,
   %pFeatureClass, %cpFeatureClass, %FeatureTotalHits, %cpQry, %pQry, %BootstrapFile);
my $TrainingMatrix = [ ];
my $QryMatrix = [ ];
my $Report = [ ];
my $Bootstrap = [ ];
my $BootstrappedTrainingMatrix = [ ];

$ReportFile = $OutPath ."/". "Prediction.csv";
$Classification = $OutPath ."/". "AsignedClass.txt";
$BootstrapedMetadata = $OutPath ."/". "Bootstrapped_Metadata.csv";
$BootstrappedTraining = $OutPath ."/". "Bootstrapped_Training.csv";

if($Stat == 1){
        $Probabilities = $OutPath ."/". "Probabilities.csv";
}

#Loading the bolean training file
($LinesOnTrainingFile, $ColumnsOnTrainingFile, @TrainingMatrix) = Matrix($TrainingFile);
$N = $ColumnsOnTrainingFile-1;


#Loading the bolean query file
($LinesOnQryFile,$ColumnsOnQryFile, @QryMatrix) = Matrix($QryFile);

#Loading the metadata file
@MetaDataFile = ReadFile($MetadataFile);
($LinesOnMetaDataFile, $ColumnsOnMetaDataFile, @MetaDataMatrix) = Matrix($MetadataFile);

# Obtaining classes
print "\nThe following columns were detected as possible classes:";
for ($i=1;$i<$ColumnsOnMetaDataFile;$i++){
        $PossibleClass = $MetaDataMatrix[0][$i];
        print "\n\t[$i] $PossibleClass";
}
print "\n\nPlease type the number of the desired class: ";
$Column = <STDIN>;
chomp $Column;

for ($i=1;$i<$LinesOnMetaDataFile;$i++){
	$Class = $MetaDataMatrix[$i]->[$Column];
	push @Classes, $Class;
}
@Classes = uniq(@Classes);
$nClasses = scalar@Classes;

for ($i=0;$i<$nClasses;$i++){
	for ($j=1;$j<$LinesOnMetaDataFile;$j++){
		$Element = $MetaDataMatrix[$j]->[0];
		$Class = $MetaDataMatrix[$j]->[1];
		$ClassOfElement{$Element} = $Class;
		if($Class eq $Classes[$i]){
                        $Elements{$Classes[$i]}++; #   <-------- Number of elements in each class
                }
        }
#################################################################################
}

$max_val_key = reduce { $Elements{$a} > $Elements{$b} ? $a : $b } keys %Elements;
$HigherClassLen = $Elements{$max_val_key};
$Iter = $HigherClassLen*2;

foreach $Class(@Classes){
	for ($i=1;$i<$LinesOnTrainingFile;$i++){
		$Feature = $TrainingMatrix[$i][0];
		for ($j=1;$j<$LinesOnMetaDataFile; $j++){
			$Element = $MetaDataMatrix[$j][0];
			if ($ClassOfElement{$Element} eq $Class){
				$HitsOfFeaturesInClass{$Feature}{$Class} += $TrainingMatrix[$i][$j]+$PsCounts; # <- Total Feature Hits in Class    
			}
		}
	}
}

$Bootstrap -> [0][0] = "Feature";
for ($i=1;$i<$LinesOnTrainingFile;$i++){
        $Feature = $TrainingMatrix[$i][0];
        $Bootstrap -> [$i][0] = $Feature;
}

foreach $Class(@Classes){
        if ($Elements{$Class} < $HigherClassLen){
                for ($i=1; $i<$Iter+1;$i++){
                        for ($j=1;$j<$LinesOnTrainingFile;$j++){
                                $Feature = $TrainingMatrix[$j][0];
                                $NewElement = $Class . ($i);
                                $Bootstrap -> [0][$i] = $NewElement;
                                
                                $pHitFeatureClass = $HitsOfFeaturesInClass{$Feature}{$Class}/$Elements{$Class};
                                if (rand() <= $pHitFeatureClass){
                                        $EstimatedFeature = 1;    
                                }else{
                                        $EstimatedFeature = 0;
                                }
                                $Bootstrap -> [$j][$i] = $EstimatedFeature;
                        }
                }
                $BootstrapFile{$Class} = $OutPath ."/". $Class ."_Bootstrap.csv";
                $Qry = $BootstrapFile{$Class};
                open (FILE, ">>$Qry");
                for ($k=0;$k<$LinesOnTrainingFile;$k++){
                        for($l=0;$l<$Iter+1;$l++){
                                print FILE $Bootstrap -> [$k][$l], ",";
                        }
                        print FILE "\n";
                }
                close FILE;
                $cmd = `perl $MainPath/BayesianClassifier.pl $TrainingFile $MetadataFile $Qry $OutPath 1 0`;
        }
}

# Initializing the bootstrapped Metadata file 
open (FILE, ">$BootstrapedMetadata");
        for ($i=0; $i<$LinesOnMetaDataFile; $i++){
                $Line = $MetaDataFile[$i];
                print FILE $Line, "\n";
        }
close FILE;

# Initializing the bootstrapped Training file
for ($i=0; $i<$LinesOnTrainingFile;$i++){
        for ($j=0; $j<$ColumnsOnTrainingFile; $j++){
                $BootstrappedTrainingMatrix -> [$i][$j] = $TrainingMatrix [$i][$j];
        }
}

# Put the bootstrapped metadata into an array of arrays
($LinesOnClassification, $ColumnsOnClassification, @ClassificationMatrix) = Matrix($Classification);

$NewColumns = $ColumnsOnTrainingFile;
#$NewColumns = $ColumnsOnTrainingFile+1;
foreach $Class (@Classes){
        if ($Elements{$Class} < $HigherClassLen){
                ($LinesOnBootstrappedClass, $ColumnsOnBootstrappedClass, @BootstrappedClassMatrix) = Matrix($BootstrapFile{$Class});

                $Repeats = $HigherClassLen - $Elements{$Class};
                $i = 0;
                for ($j=0; $j<$LinesOnClassification; $j++){
                        if ($ClassificationMatrix[$j][1] eq $Class && $i < $Repeats){
                                
                                open (FILE, ">>$BootstrapedMetadata");
                                        print FILE "$ClassificationMatrix[$j][0],$ClassificationMatrix[$j][1]\n";
                                close FILE;
                                
                                for ($k=0; $k<$ColumnsOnBootstrappedClass; $k++){
                                        if ($BootstrappedClassMatrix[0][$k] eq $ClassificationMatrix[$j][0]){
                                                for ($l=0; $l<$LinesOnBootstrappedClass; $l++){
                                                        $BootstrappedTrainingMatrix -> [$l][$NewColumns] = $BootstrappedClassMatrix [$l][$k];
                                                }
                                        }
                                }
                                $i++;
                                $NewColumns++;
                        }
                }
        }
}

open (FILE, ">$BootstrappedTraining");
for ($i=0; $i<$LinesOnTrainingFile;$i++){
        for ($j=0; $j<$NewColumns; $j++){
                print FILE $BootstrappedTrainingMatrix -> [$i][$j], ",";
        }
        print FILE "\n";
}
close FILE;

exit;