#!/usr/bin/perl -w
#use strict;
use List::MoreUtils qw(uniq);
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);
#use lib "/Users/rc/Bayes/lib";
#use Routines;

my ($TrainingFileName, $MetaDataFileName, $QryFile, $Statistics);

$Statistics = 0;
GetOptions(
        'help'        => \$Help,
        'training|t:s'=> \$TrainingFileName,
        'metadata|m:s'=> \$MetaDataFileName,
        'query|q:s'   => \$QryFile,
        'stat|s'      => \$Statistics
        ) or die "USAGE:\n  $0 [--help] [--training -t filename] [--metadata -m filename]
      [--query -q filename] [--class -c string]
\n  Use \'--help\' to print detailed descriptions of options.\n\n";

if($Help){
        print "
        \t--training <Training_File_Name>
        \t--metadata <Metadata_File_Name>
        \t--query <Query_fasta>";
        exit;
}

my($MainPath, $nTrainingFile, $Line, $nTrainingFileFields, $N, $MetaData,
   $nMetaDataFile, $nMetaDataFileFields, $Region, $Strain, $Class, $nClasses,
   $Counter, $Hit, $Count, $Probe, $StrainHit, $StrainHits, $ProbeHit, $ProbeHits,
   $nProbe, $nQryFile, $nQryFileFields, $QryHit, $QryStrain, $PossibleClass,
   $Probabilities, $Column);
my($i, $j);
my(@TrainingFile, @TrainingFileFields, @TrainingMatrix, @MetaDataField, @MetaDataFile,
   @MetaDataFileFields, @MetaData, @Classes, @Strains, @QryFile, @QryFileFields,
   @QryMatrix);
my(%StrainClass, %Classes, %pClasses, %cpClasses, %ClassHits, %ProbeClass,
   %pProbeClass, %cpProbeClass, %ProbeTotalHits, %cpQry, %pQry);
my $TrainingMatrix = [ ];
my $QryMatrix = [ ];
my $Report = [ ];

$MainPath = "/Users/rc/Bayes";
#$TrainingFileName = $MainPath ."/". "Tabla.csv";
#$MetaDataFileName = $MainPath ."/". 'MetaData.csv';
#$QryFile = $MainPath ."/". "Qry.csv";
$Report = $MainPath ."/". "Prediction.csv";
if($Statistics == 1){
        $Probabilities = $MainPath ."/". "Probabilities.txt";
}

#Loading the bolean training file
@TrainingFile = ReadFile($TrainingFileName);
$nTrainingFile = scalar@TrainingFile;
$nProbe = $nTrainingFile-1;
for ($i=0; $i<$nTrainingFile; $i++){
	$Line = $TrainingFile[$i];
	@TrainingFileFields = split(",",$Line);
	push (@TrainingMatrix, [@TrainingFileFields]);
}
$nTrainingFileFields = scalar@TrainingFileFields;
$N = $nTrainingFileFields-1;

#Loading the bolean query file
@QryFile = ReadFile($QryFile);
$nQryFile = scalar@QryFile;
for ($i=0; $i<$nQryFile; $i++){
	$Line = $QryFile[$i];
	@QryFileFields = split(",",$Line);
	push (@QryMatrix, [@QryFileFields]);
}
$nQryFileFields = scalar@QryFileFields;

#Loading the metadata file
@MetaDataFile = ReadFile($MetaDataFileName);
$nMetaDataFile = scalar@MetaDataFile;
for ($i=0; $i<$nMetaDataFile; $i++){
	$Line = $MetaDataFile[$i];
	@MetaDataFileFields = split(",",$Line);
	push (@MetaData, [@MetaDataFileFields]);
}
$nMetaDataFileFields = scalar@MetaDataFileFields;

#Obtaining classes
print "\nThe following columns were detected as possible classes:";
for ($i=1;$i<$nMetaDataFileFields;$i++){
        $PossibleClass = $MetaData[0][$i];
        print "\n\t[$i] $PossibleClass";
}
print "\n\nPlease type the number of the desired class: ";
$Column = <STDIN>;
chomp $Column;

for ($i=1;$i<$nMetaDataFile;$i++){
	$Class = $MetaData[$i]->[$Column];
	push @Classes, $Class;
}
@Classes = uniq(@Classes);
$nClasses = scalar@Classes;

for ($i=0;$i<$nClasses;$i++){
	$Counter = 0;
	for ($j=1;$j<$nMetaDataFile;$j++){
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

#Calculating the total of hits into the training matrix
$GlobalHits = 0;
for ($i=1; $i<$nTrainingFile; $i++){
	for ($j=1; $j<$nTrainingFileFields; $j++){
		$Hit = $TrainingMatrix[$i][$j];
		if ($Hit != 0){
			$GlobalHits++;
		}
	}
}

#Calculating the total of hits in each class
foreach $Class(@Classes){
	$StrainHits = 0; 
	for ($i=1;$i<$nTrainingFileFields; $i++){
		$Strain = $TrainingMatrix[0][$i];
		if ($StrainClass{$Strain} eq $Class){
			for ($j=1;$j<$nTrainingFile;$j++){
				$StrainHit = $TrainingMatrix[$j][$i];
				$StrainHits += $StrainHit;
			}
		}
	}
	$ClassHits{$Class} = $StrainHits;	
}

foreach $Class(@Classes){
	for ($i=1;$i<$nTrainingFile;$i++){
		$Probe = $TrainingMatrix[$i][0];
      $ProbeTotalHits{$Probe} = 0;
		for ($j=1;$j<$nTrainingFileFields; $j++){         
			$Strain = $TrainingMatrix[0][$j];
         $ProbeTotalHits{$Probe} += $TrainingMatrix[$i][$j];
			if ($StrainClass{$Strain} eq $Class){
				$ProbeClassHit = $TrainingMatrix[$i][$j];
				$ProbeClass{$Probe}{$Class} += $ProbeClassHit;
			}
		}
	}
}

#print "\n-->$ProbeTotalHits{j}<--\n";

for ($i=1;$i<$nTrainingFile;$i++){
	$Probe = $TrainingMatrix[$i][0];
	foreach $Class(@Classes){
      $pProbeClass{$Probe}{$Class} = ($ProbeClass{$Probe}{$Class}+1)/($ClassHits{$Class}+$nProbe);
      $cpProbeClass{$Probe}{$Class} = ($ProbeTotalHits{$Probe}-$ProbeClass{$Probe}{$Class}+1)/(($GlobalHits-$ClassHits{$Class})+$nProbe);
		#print "\nThe probe $Probe has $ProbeClass{$Probe}{$Class} hits in class $Class";
	}
}

$Report -> [0][0] = "";

for ($i=1;$i<$nQryFileFields;$i++){
   $QryStrain = $QryMatrix[0][$i];
   foreach $Class(@Classes){     
      $pQryClass = $pClasses{$Class};
      $cpQryClass = $cpClasses{$Class}; 
      for ($j=1;$j<$nQryFile;$j++){
         $Probe = $QryMatrix[$j][0];
         $QryHit = $QryMatrix[$j][$i];
         if($QryHit == 1){
            $pQryClass = $pQryClass*$pProbeClass{$Probe}{$Class};
            $cpQryClass = $cpQryClass*$cpProbeClass{$Probe}{$Class};
         }
      }
      $pQry{$Class}{$QryStrain} = $pQryClass;
      $cpQry{$Class}{$QryStrain} = $cpQryClass;
   }
}
  
#print "\n->$pQry{C}{16}\n$cpQry{C}{16}<-\n";
open (FILE, ">$Probabilities");
for($i=1; $i<$nQryFileFields; $i++){
   $QryStrain = $QryMatrix[0][$i];
   print FILE "$QryStrain\n";
   for($j=0; $j<$nClasses; $j++){
      $Class = $Classes[$j];
      $Report -> [$i][0] = $QryStrain;
      $Report -> [0][$j+1] = $Class;
      $Class = $Classes[$j];
      
      print FILE "Class $Class -> [p]-$pQry{$Class}{$QryStrain}\t[cp]-$cpQry{$Class}{$QryStrain}\n";
      if ($pQry{$Class}{$QryStrain} > $cpQry{$Class}{$QryStrain}){
         $Report -> [$i][$j+1] = "Accepted";
      }else{
         $Report -> [$i][$j+1] = "Rejected";
      }
   }
}
close FILE;
   
open (FILE, ">$Report");
   for($i=0;$i<$nQryFileFields;$i++){
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

#######################################################
sub ReadFile{
    my ($InputFile) = @_;
    unless (open(FILE, $InputFile)){
        print "The Routine ReadFile Can not open $InputFile file\n";
        exit;
    }
    
    my @Temp = <FILE>;
    chomp @Temp;
    close FILE;
    my @File;
    foreach my $Row (@Temp){
        if ($Row =~/^#/) {
            }else{ push @File, $Row;
        }
    }
    return @File;
}

