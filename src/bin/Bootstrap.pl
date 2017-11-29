#!/usr/bin/perl -w
use strict;
use List::MoreUtils qw(uniq);
use List::Util qw(reduce);
#use Math::Random::Secure qw(rand);
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
   $ColumnsOnClassification, $Replaces);
my($i, $j, $k, $l);
my(@TrainingFile, @TrainingFileFields, @TrainingMatrix, @MetaDataField, @MetaDataFile,
   @MetaDataFileFields, @MetaDataMatrix, @Classes, @Elements, @QryFile, @QryFileFields,
   @QryMatrix, @Bootstrap, @BootstrapedQry, @BootstrapedQryFields, @BootstrapedQryMatrix);
my(%ClassOfElement, %TotalFeatureHits, %HitsOfFeaturesInClass, %pHitsOfFeaturesInClass,
   %cpHitsOfFeaturesInClass,
   %ElementClass, %Elements, %pClass, %cpClass, %ClassHits, %FeatureClass,
   %pFeatureClass, %cpFeatureClass, %FeatureTotalHits, %cpQry, %pQry, %BootstrapFile);
my $TrainingMatrix = [ ];
my $QryMatrix = [ ];
my $Report = [ ];
my $Bootstrap = [ ];
my $BootstrapedQryMatrix = [ ];

$ReportFile = $MainPath ."/". "Prediction.csv";
$Classification = $OutPath ."/". "AsignedClass.txt";
$BootstrapedMetadata = $OutPath ."/". "Bootstraped_Metadata.csv";

if($Stat == 1){
        $Probabilities = $MainPath ."/". "Probabilities.csv";
}

#Loading the bolean training file
@TrainingFile = ReadFile($TrainingFile);
$LinesOnTrainingFile = scalar@TrainingFile;
$nFeature = $LinesOnTrainingFile-1;
for ($i=0; $i<$LinesOnTrainingFile; $i++){
	$Line = $TrainingFile[$i];
	@TrainingFileFields = split(",",$Line);
	push (@TrainingMatrix, [@TrainingFileFields]);
}
$ColumnsOnTrainingFile = scalar@TrainingFileFields;
$N = $ColumnsOnTrainingFile-1;

#Loading the bolean query file
@QryFile = ReadFile($QryFile);
$LinesOnQryFile = scalar@QryFile;
for ($i=0; $i<$LinesOnQryFile; $i++){
	$Line = $QryFile[$i];
	@QryFileFields = split(",",$Line);
	push (@QryMatrix, [@QryFileFields]);
}
$ColumnsOnQryFile = scalar@QryFileFields;

#Loading the metadata file
@MetaDataFile = ReadFile($MetadataFile);
$LinesOnMetaDataFile = scalar@MetaDataFile;
for ($i=0; $i<$LinesOnMetaDataFile; $i++){
	$Line = $MetaDataFile[$i];
	@MetaDataFileFields = split(",",$Line);
	push (@MetaDataMatrix, [@MetaDataFileFields]);
}
$ColumnsOnMetaDataFile = scalar@MetaDataFileFields;

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

$Bootstrap -> [0][0] = "";
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
                                if (rand()<= $pHitFeatureClass){
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
                $cmd = `perl BayesianClassifier.pl $TrainingFile $MetadataFile $Qry $OutPath 1 0`;
        }
}

# Building a bootstrapped Metadata file 
open (FILE, ">$BootstrapedMetadata");
        for ($i=0; $i<$LinesOnMetaDataFile; $i++){
                $Line = $MetaDataFile[$i];
                print FILE $Line, "\n";
        }
close FILE;

# Put the bootstrapped metadata into an array of arrays
@BootstrapedQry = ReadFile($Classification);
$LinesOnClassification = scalar@BootstrapedQry;
for ($i=0; $i<$LinesOnClassification; $i++){
	$Line = $BootstrapedQry[$i];
	@BootstrapedQryFields = split(",",$Line);
	push (@BootstrapedQryMatrix, [@BootstrapedQryFields]);
}
$ColumnsOnClassification = scalar@BootstrapedQryFields;

foreach $Class (@Classes){
        if ($Elements{$Class} < $HigherClassLen){
                $Replaces = $HigherClassLen - $Elements{$Class};
                $i = 0;
                for ($j=0; $j<$LinesOnClassification; $j++){
                        if ($BootstrapedQryMatrix[$j][1] eq $Class && $i < $Replaces){
                                open (FILE, ">>$BootstrapedMetadata");
                                print FILE "\n$BootstrapedQryMatrix[$j][0],$BootstrapedQryMatrix[$j][1]";
                                close FILE;
                                for ($k=$ColumnsOnTrainingFile+1; $k<$ColumnsOnTrainingFile+$Replaces;$k++){
                                        for ($l=0; $l< $LinesOnTrainingFile; $l++){
                                                
                                        }
                                }
                                $i++;
                        }
                }
        }
}

exit;

