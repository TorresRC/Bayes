#!/usr/bin/perl -w
#use strict;
use List::MoreUtils qw(uniq);
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);
use lib "/Users/rc/Bayes/lib";
use Routines;

my($MainPath, $LinesOnTrainingFile, $Line, $ColumnsOnTrainingFile, $N, $MetaData,
   $LinesOnMetaDataFile, $ColumnsOnMetaDataFile, $Strain, $Class, $nClasses,
   $Counter, $Hit, $Feature, $StrainHit, $StrainHits, $FeatureHit, $FeatureHits,
   $nFeature, $nQryFile, $nQryFileFields, $QryHit, $QryStrain, $PossibleClass,
   $Column);
my($i, $j);
my(@TrainingFile, @TrainingFileFields, @TrainingMatrix, @MetaDataField, @MetaDataFile,
   @MetaDataFileFields, @MetaData, @Classes, @Strains, @QryFile, @QryFileFields,
   @QryMatrix);
my(%StrainClass, %Classes, %pClasses, %cpClasses, %ClassHits, %FeatureClass,
   %pFeatureClass, %cpFeatureClass, %FeatureTotalHits, %cpQry, %pQry);
my(%aa, %ab, %ba, %bb);
my $TrainingMatrix = [ ];
my $Matrix = [ ];

$MainPath = "/Users/rc/Bayes";
$TrainingFileName = $MainPath ."/". "Training.csv";
$MetaDataFileName = $MainPath ."/". 'MetaData.csv';

#Loading the bolean training file
@TrainingFile = ReadFile($TrainingFileName);
$LinesOnTrainingFile = scalar@TrainingFile;
$nFeature = $LinesOnTrainingFile-1;
for ($i=0; $i<$LinesOnTrainingFile; $i++){
	$Line = $TrainingFile[$i];
	@TrainingFileFields = split(",",$Line);
	push (@TrainingMatrix, [@TrainingFileFields]);
}
$ColumnsOnTrainingFile = scalar@TrainingFileFields;
$N = $ColumnsOnTrainingFile-1;

#Loading the metadata file
@MetaDataFile = ReadFile($MetaDataFileName);
$LinesOnMetaDataFile = scalar@MetaDataFile;
for ($i=0; $i<$LinesOnMetaDataFile; $i++){
	$Line = $MetaDataFile[$i];
	@MetaDataFileFields = split(",",$Line);
	push (@MetaData, [@MetaDataFileFields]);
}
$ColumnsOnMetaDataFile = scalar@MetaDataFileFields;

#Obtaining classes
print "\nThe following columns were detected as possible classes:";
for ($i=1;$i<$ColumnsOnMetaDataFile;$i++){
        $PossibleClass = $MetaData[0][$i];
        print "\n\t[$i] $PossibleClass";
}
print "\n\nPlease type the number of the desired class: ";
$Column = <STDIN>;
chomp $Column;

for ($i=1;$i<$LinesOnMetaDataFile;$i++){
	$Class = $MetaData[$i]->[$Column];
	push @Classes, $Class;
}
@Classes = uniq(@Classes);
$nClasses = scalar@Classes;

for ($i=0;$i<$nClasses;$i++){
	$Counter = 0;
	for ($j=1;$j<$LinesOnMetaDataFile;$j++){
		$Strain = $MetaData[$j]->[0];
		$Class = $MetaData[$j]->[1];
		$StrainClass{$Strain} = $Class;
		if($Class eq $Classes[$i]){
			$Counter++;
		}
	}
	$Classes{$Classes[$i]} = $Counter; #Number of elements in each class
	$pClasses{$Classes[$i]} = $Counter/$N; #Probability of each class
	$cpClasses{$Classes[$i]} = 1-$Counter/$N; #Complement probability of each class
}

#Hits into the training matrix
$GlobalHits = 0;
for ($i=1; $i<$LinesOnTrainingFile; $i++){
	for ($j=1; $j<$ColumnsOnTrainingFile; $j++){
		$Hit = $TrainingMatrix[$i][$j];
		if ($Hit != 0){
			$GlobalHits++; # Total of hits
		}
	}
}

#Hits of each class
foreach $Class(@Classes){
	$StrainHits = 0; 
	for ($i=1;$i<$ColumnsOnTrainingFile; $i++){
		$Strain = $TrainingMatrix[0][$i];
		if ($StrainClass{$Strain} eq $Class){
			for ($j=1;$j<$LinesOnTrainingFile;$j++){
				$StrainHit = $TrainingMatrix[$j][$i];
				$StrainHits += $StrainHit;
			}
		}
	}
	$ClassHits{$Class} = $StrainHits; # Total of hits of each class
}

#Hits of each probe in each class
foreach $Class(@Classes){
	for ($i=1;$i<$LinesOnTrainingFile;$i++){
		$Feature = $TrainingMatrix[$i][0];
      $FeatureTotalHits{$Feature} = 0;
		for ($j=1;$j<$ColumnsOnTrainingFile; $j++){         
			$Strain = $TrainingMatrix[0][$j];
         $FeatureTotalHits{$Feature} += $TrainingMatrix[$i][$j];
			if ($StrainClass{$Strain} eq $Class){
				$FeatureClassHit = $TrainingMatrix[$i][$j];
				$FeatureClass{$Feature}{$Class} += $FeatureClassHit; #Hits of probe in class
			}
		}
	}
}

foreach $Class(@Classes){
   for ($i=1;$i<$LinesOnTrainingFile;$i++){
      $Feature = $TrainingMatrix[$i][0];
      $aa{$Feature}{$Class} = $FeatureClass{$Feature}{$Class}; # hits de sonda a en clase a
      $ab{$Feature}{$Class} = $FeatureTotalHits{$Feature}-$FeatureClass{$Feature}{$Class}; # Hits de sonda a que no están en clase A
      $ba{$Feature}{$Class} = $Classes{$Class}-$FeatureClass{$Feature}{$Class}; # Numero de no hits en clase A (numero de ceros en clase A)
      $bb{$Feature}{$Class} = ($N-$Classes{$Class})-($FeatureTotalHits{$Feature}-$FeatureClass{$Feature}{$Class}); # Numero de ceros fuera de A
   }
}

print "$aa{a}{B} - $ab{a}{B} - $ba{a}{B} - $bb{a}{B}\n";

exit;
