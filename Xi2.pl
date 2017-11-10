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
   $Column, $FeaturesMLE, $Plot, $RScript);
my($i, $j);
my(@TrainingFile, @TrainingFileFields, @TrainingMatrix, @MetaDataField, @MetaDataFile,
   @MetaDataFileFields, @MetaData, @Classes, @Strains, @QryFile, @QryFileFields,
   @QryMatrix);
my(%StrainClass, %Classes, %pClasses, %cpClasses, %ClassHits, %FeatureClass,
   %pFeatureClass, %cpFeatureClass, %FeatureTotalHits, %cpQry, %pQry, %Xi);
my(%a, %b, %c, %d);
my $TrainingMatrix = [ ];
my $Report = [ ];

$MainPath = "/Users/rc/Bayes";
$TrainingFileName = $MainPath ."/". "Training.csv";
$MetaDataFileName = $MainPath ."/". 'MetaData.csv';
$FeaturesMLE = $MainPath ."/". "XiSquared.csv";
$Plot            = $MainPath ."/". "XiSquared.pdf";
$RScript         = $MainPath ."/". "XiSquared.R";

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
				$StrainHit = $TrainingMatrix[$j][$i];       #  <----- Observed Hits
            #$StrainHit = $TrainingMatrix[$j][$i]+1;    #  <----- Pseudo counts Hits
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
         $FeatureTotalHits{$Feature} += $TrainingMatrix[$i][$j];   # <--- Observed Hits
         #$FeatureTotalHits{$Feature} += $TrainingMatrix[$i][$j]+1;   # <--- Pseudo counts
			if ($StrainClass{$Strain} eq $Class){
				$FeatureClassHit = $TrainingMatrix[$i][$j];    # <---- Observed Hits
            #$FeatureClassHit = $TrainingMatrix[$i][$j]+1;  # <---- Pseudo counts
				$FeatureClass{$Feature}{$Class} += $FeatureClassHit; #Hits of probe in class
			}
		}
	}
}

# Maximum Likelihood Estimation (MLE)
$Report -> [0][0] = "Features";
$iClass = 1;
for ($i=0; $i<$nClasses; $i++){
   $Class = $Classes[$i];
   $Report -> [0][$i+1] = $Class; 
   for ($j=1;$j<$LinesOnTrainingFile;$j++){
      $Feature = $TrainingMatrix[$j][0];

      $a= (($FeatureClass{$Feature}{$Class}))+1; # hits de sonda a en clase a
      $b= (($FeatureTotalHits{$Feature}-$FeatureClass{$Feature}{$Class}))+1; # Hits de sonda a que no están en clase A
      $c= (($Classes{$Class}-$FeatureClass{$Feature}{$Class}))+1; # Numero de no hits en clase A (numero de ceros en clase A)
      $d= ((($N-$Classes{$Class})-($FeatureTotalHits{$Feature}-$FeatureClass{$Feature}{$Class})))+1; # Numero de ceros fuera de A
      
      $nConfusion = $a+$b+$c+$d;
      
      
      $Xi{$Feature} = (($nConfusion*(($a*$d)-($b*$c))**2))/(($a+$c)*($a+$b)*($b+$d)*($c+$d));
      
      $Report -> [$j][0] = $Feature;
      $Report -> [$j][$iClass] = $Xi{$Feature};
   }
   $iClass++;
}

#Building autput file
open (FILE, ">$FeaturesMLE");
for ($i=0;$i<$LinesOnTrainingFile;$i++){
   for ($j=0;$j<5;$j++){
      print FILE $Report -> [$i][$j], ",";
   }
   print FILE "\n";
}
close FILE;

chdir ($MainPath);

open (RSCRIPT, ">$RScript");
        print RSCRIPT 'library(ggplot2)' . "\n";
        print RSCRIPT "df <- read.csv(\"$FeaturesMLE\")" . "\n";
        print RSCRIPT 'ggplot(df, aes(Features))';
        foreach $Class(@Classes){
         print RSCRIPT "+ geom_point(aes(y=$Class,color=\"$Class\"))";
         #print RSCRIPT '+ geom_line(aes(y=PanGenome,linetype="PanGenome"))';
         #print RSCRIPT '+ geom_line(aes(y=NewGenes,linetype="NewGenes"))';
        }
        #print RSCRIPT "+ scale_x_continuous(breaks = 0:$nClasses+1)";
        print RSCRIPT "+ labs(x=\"Classes\", y=\"bits\", title= \"Maximum Likelihood Estimation\")";
        #print RSCRIPT '+ scale_linetype_discrete(name=NULL)';
        #print RSCRIPT '+ theme(axis.text.x = element_text(angle = 90, size=4, hjust = 1))' . "\n";
        print RSCRIPT "\n";
        print RSCRIPT "ggsave(\"$Plot\")";
close RSCRIPT;

print "\n Building Plot...";
system ("R CMD BATCH $RScript");
print "Done!\n\n";

system ("rm $RScript $MainPath/*.Rout $MainPath/Rplots.pdf");

exit;
