#!/usr/bin/perl -w
use strict;
use List::MoreUtils qw(uniq);
use List::Util qw(reduce);
use FindBin;
use lib "$FindBin::Bin/lib";
use Routines;
my $MainPath = "$FindBin::Bin";

my ($Usage, $TrainingFile, $MetadataFile, $QryFile, $OutPath, $Stat, $PsCounts, $HighestClassLen,
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
   $LinesOnMetaDataFile, $ColumnsOnMetaDataFile, $GlobalHits,
   $Region, $Element, $Class, $nClasses, $Classification,
   $Counter, $Hit, $Count, $Feature, $ElementHit, $ElementHits, $FeatureHit, $FeatureHits,
   $nFeature, $LinesOnQryFile, $ColumnsOnQryFile, $QryHit, $QryElement, $PossibleClass,
   $Probabilities, $Column, $pQryClass, $cpQryClass, $ReportFile, $pHitFeatureClass);
my($i, $j);
my(@TrainingFile, @TrainingFileFields, @TrainingMatrix, @MetaDataField, @MetaDataFile,
   @MetaDataFileFields, @MetaDataMatrix, @Classes, @Elements, @QryFile, @QryFileFields,
   @QryMatrix);
my(%ClassOfElement, %TotalFeatureHits, %HitsOfFeaturesInClass, %pHitsOfFeaturesInClass,
   %cpHitsOfFeaturesInClass,
   %ElementClass, %Elements, %pClass, %cpClass, %ClassHits, %FeatureClass,
   %pFeatureClass, %cpFeatureClass, %FeatureTotalHits, %cpQry, %pQry);
my $TrainingMatrix = [ ];
my $QryMatrix = [ ];
my $Report = [ ];

$ReportFile = $MainPath ."/". "Prediction.csv";
$Classification = $OutPath ."/". "AsignedClass.txt";

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
$HighestClassLen = $Elements{$max_val_key};

#print "\n$ColumnsOnTrainingFile\n";
#exit;

foreach $Class(@Classes){
	for ($i=1;$i<$LinesOnTrainingFile;$i++){
		$Feature = $TrainingMatrix[$i][0];
		for ($j=1;$j<$ColumnsOnTrainingFile; $j++){         
			$Element = $TrainingMatrix[0][$j];
			if ($ClassOfElement{$Element} eq $Class){
				$HitsOfFeaturesInClass{$Feature}{$Class} += $TrainingMatrix[$i][$j]+$PsCounts; # <- Total Feature Hits in Class
            
			}
		}
	}
}

#foreach $Class(@Classes){
#   for ($i=1;$i<$LinesOnTrainingFile; $i++){
#      $Feature = $TrainingMatrix[$i][0];
#      
#            print "\n$Class\t$Feature\t$HitsOfFeaturesInClass{$Feature}{\"E\"}\n";
#   }
#}
#exit;



foreach $Class(@Classes){
   if ($Elements{$Class} < $HighestClassLen){
      for ($i=1;$i<$LinesOnTrainingFile;$i++){
         $Feature = $TrainingMatrix[$i][0];
         $pHitFeatureClass = $HitsOfFeaturesInClass{$Feature}{$Class}/$Elements{$Class};
      
         $pHitFeatureClass = $HitsOfFeaturesInClass{"a"}{"D"}/$Elements{"D"};
      
         print "\n$pHitFeatureClass\n";
         exit;
      }
   }
     
      
      
}
