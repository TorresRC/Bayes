#!/usr/bin/perl -w

#################################################################################
#By:       Roberto C. Torres & Mauricio Flores                                  #
#e-mail:   torres.roberto.c@gmail.com                                           #
#################################################################################
use strict;
use List::MoreUtils qw(uniq);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Routines;
my $MainPath = "$FindBin::Bin";

my ($Usage, $TrainingFile, $MetadataFile, $QryFile, $OutPath, $Stat, $PsCounts);

$Usage = "\nUSAGE\n  $FindBin::Script <Observed Data [File]>
                        <Metadata [File]>
                        <Query [File]>
                        <Output Path [Path]>
                        <Statistics [Bolean]>
                        <Pseudo Counts [Bolean]>\n\n";
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


my($LinesOnTrainingFile, $Line, $ColumnsOnTrainingFile, $N, $MetaData,
   $LinesOnMetaDataFile, $ColumnsOnMetaDataFile, $GlobalHits,
   $Region, $Element, $Class, $nClasses, $Classification,
   $Counter, $Hit, $Count, $Feature, $ElementHit, $ElementHits, $FeatureHit, $FeatureHits,
   $nFeature, $LinesOnQryFile, $ColumnsOnQryFile, $QryHit, $QryElement, $PossibleClass,
   $Probabilities, $Column, $pQryClass, $cpQryClass, $ReportFile);
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

$ReportFile = $OutPath ."/". "Prediction.csv";
$Classification = $OutPath ."/". "AsignedClass.txt";

if($Stat == 1){
        $Probabilities = $OutPath ."/". "Probabilities.csv";
}

#Loading the bolean training file
($LinesOnTrainingFile, $ColumnsOnTrainingFile, @TrainingMatrix) = Matrix($TrainingFile);
$nFeature = $LinesOnTrainingFile-1;
$N = $ColumnsOnTrainingFile-1;

#Loading the bolean query file
($LinesOnQryFile, $ColumnsOnQryFile, @QryMatrix) = Matrix($QryFile);

#Loading the metadata file
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
################################################################################
	$pClass{$Classes[$i]} = ($Elements{$Classes[$i]}/$N); # Probability of each class
	$cpClass{$Classes[$i]} = (1-$Elements{$Classes[$i]}/$N); # Complement probability of each class
}

# Hits into the training matrix
$GlobalHits = 0;
for ($i=1; $i<$LinesOnTrainingFile; $i++){
	for ($j=1; $j<$ColumnsOnTrainingFile; $j++){
		$Hit = $TrainingMatrix[$i][$j];
		if ($Hit != 0){
			$GlobalHits++; #   <----------------------- Total of hits
		}
	}
}

#Hits of each class
foreach $Class(@Classes){
	for ($i=1;$i<$ColumnsOnTrainingFile; $i++){
		$Element = $TrainingMatrix[0][$i];
		if ($ClassOfElement{$Element} eq $Class){
			for ($j=1;$j<$LinesOnTrainingFile;$j++){
                                $ClassHits{$Class} += $TrainingMatrix[$j][$i]+$PsCounts;  # <- Total of hits in class
			}
		}
	}
}

#Hits of each feature in each class
foreach $Class(@Classes){
	for ($i=1;$i<$LinesOnTrainingFile;$i++){
		$Feature = $TrainingMatrix[$i][0];
                $TotalFeatureHits{$Feature} = 0;
		for ($j=1;$j<$ColumnsOnTrainingFile; $j++){
			$Element = $TrainingMatrix[0][$j];
                        $TotalFeatureHits{$Feature} += $TrainingMatrix[$i][$j]+$PsCounts; # <- Total Feature Hits
			if ($ClassOfElement{$Element} eq $Class){
				$HitsOfFeaturesInClass{$Feature}{$Class} += $TrainingMatrix[$i][$j]+$PsCounts; # <- Total Feature Hits in Class
			}
		}
	}
}

for ($i=1;$i<$LinesOnTrainingFile;$i++){
        $Feature = $TrainingMatrix[$i][0];
	foreach $Class(@Classes){
                $pHitsOfFeaturesInClass{$Feature}{$Class} = (($HitsOfFeaturesInClass{$Feature}{$Class}+1)/($ClassHits{$Class}+$nFeature));
                $cpHitsOfFeaturesInClass{$Feature}{$Class} = (($TotalFeatureHits{$Feature}-$HitsOfFeaturesInClass{$Feature}{$Class}+1)/(($GlobalHits-$ClassHits{$Class})+$nFeature));
	}
}

$Report -> [0][0] = "";

for ($i=1;$i<$ColumnsOnQryFile;$i++){
        $QryElement = $QryMatrix[0][$i];
        foreach $Class(@Classes){
                $pQryClass = $pClass{$Class};
                $cpQryClass = $cpClass{$Class};
                for ($j=1;$j<$LinesOnQryFile;$j++){
                        $Feature = $QryMatrix[$j][0];
                        $QryHit = $QryMatrix[$j][$i];
                        if($QryHit == 1){
                                #$pQryClass = ((log10($pQryClass))**2)*((log10($pHitsOfFeaturesInClass{$Feature}{$Class}))**2);
                                #$cpQryClass = ((log10($cpQryClass))**2)*((log10($cpHitsOfFeaturesInClass{$Feature}{$Class}))**2);
                                $pQryClass = ($pQryClass)*(1000*$pHitsOfFeaturesInClass{$Feature}{$Class});
                                $cpQryClass = ($cpQryClass)*(1000*$cpHitsOfFeaturesInClass{$Feature}{$Class});
                        }
                }
                $pQry{$Class}{$QryElement} = ($pQryClass);
                $cpQry{$Class}{$QryElement} = ($cpQryClass);
                
                  #$pQryClass = (10**$pQryClass);
                  #$cpQryClass = (10**$cpQryClass);
                
        }
}

open (PFILE, ">$Probabilities");
open (CFILE, ">>$Classification");
        print CFILE "Feature,Class\n";
for($i=1; $i<$ColumnsOnQryFile; $i++){
   $QryElement = $QryMatrix[0][$i];
   print PFILE "$QryElement\n";
   print CFILE "$QryElement";
   for($j=0; $j<$nClasses; $j++){
      $Class = $Classes[$j];
      $Report -> [$i][0] = $QryElement;
      $Report -> [0][$j+1] = $Class;
      $Class = $Classes[$j];

      print PFILE "Class $Class -> [p]=$pQry{$Class}{$QryElement}\t[cp]=$cpQry{$Class}{$QryElement}\n";
      if ($pQry{$Class}{$QryElement} > $cpQry{$Class}{$QryElement}){
         $Report -> [$i][$j+1] = "Accepted";
         print CFILE ",$Class";
      }else{
         $Report -> [$i][$j+1] = "Rejected";
      }
   }
   print CFILE "\n";
}
close PFILE;

open (FILE, ">$ReportFile");
   for($i=0;$i<$ColumnsOnQryFile;$i++){
      for($j=0;$j<$nClasses+1;$j++){
         print FILE $Report -> [$i][$j], ",";
         print $Report -> [$i][$j], " ";
      }
      print "\n";
      print FILE "\n";
   }
close FILE;

print "\n";
exit;
