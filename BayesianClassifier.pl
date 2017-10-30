#!/usr/bin/perl -w
#use strict;
use List::MoreUtils qw(uniq);
use lib "/Users/rc/Bayes/lib";
use Routines;

my($MainPath, $BoleanFileName, $MetaDataFileName, $nBoleanFile, $Line,
   $nBoleanFileFields, $N, $MetaData, $nMetaDataFile, $nMetaDataFileFields,
   $Region, $Strain, $Class, $nClasses, $Counter, $Hit, $Count, $Probe, $StrainHit,
   $StrainHits, $ProbeHit, $ProbeHits);
my($i, $j);
my(@BoleanFile, @BoleanFileFields, @BoleanTable, @MetaDataField, @MetaDataFile,
   @MetaDataFileFields, @MetaData, @Classes, @Strains);
my(%StrainClass, %Classes, %pClasses, %cpClasses, %ClassHits, %ProbeClass);
my $BoleanTable = [ ]; 

$MainPath = "/Users/rc/Bayes";
$BoleanFileName = $MainPath ."/". "Tabla.csv";
$MetaDataFileName = $MainPath ."/". 'MetaData.csv';

@BoleanFile = ReadFile($BoleanFileName);
$nBoleanFile = scalar@BoleanFile;
for ($i=0; $i<$nBoleanFile; $i++){
	$Line = $BoleanFile[$i];
	@BoleanFileFields = split(",",$Line);
	push (@BoleanTable, [@BoleanFileFields]);
}
$nBoleanFileFields = scalar@BoleanFileFields;
$N = $nBoleanFileFields-1;

@MetaDataFile = ReadFile($MetaDataFileName);
$nMetaDataFile = scalar@MetaDataFile;
for ($i=0; $i<$nMetaDataFile; $i++){
	$Line = $MetaDataFile[$i];
	@MetaDataFileFields = split(",",$Line);
	push (@MetaData, [@MetaDataFileFields]);
}
$nMetaDataFileFields = scalar@MetaDataFileFields;

for ($i=1;$i<$nMetaDataFile;$i++){
	$Class = $MetaData[$i]->[1];
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
	$Classes{$Classes[$i]} = $Counter;
	$pClasses{$Classes[$i]} = $Counter/$N;
	$cpClasses{$Classes[$i]} = 1-$Counter/$N;
}

foreach my $Class(@Classes){
print "\nThe Class $Class have $Classes{$Class} elements, and its probability is $pClasses{$Class} while the complemented probability is $cpClasses{$Class}";
}

$Count = 0;
for ($i=1; $i<$nBoleanFile; $i++){
	for ($j=1; $j<$nBoleanFileFields; $j++){
		$Hit = $BoleanTable[$i][$j];
		if ($Hit != 0){
			$Count++;
		}
	}
}

print "\nThe total of Hits into the bolean table are $Count\n";

foreach $Class(@Classes){
	$StrainHits = 0; 
	for ($i=1;$i<$nBoleanFileFields; $i++){
		$Strain = $BoleanTable[0][$i];   
		if ($StrainClass{$Strain} eq $Class){
			for ($j=1;$j<$nBoleanFile;$j++){
				$StrainHit = $BoleanTable[$j][$i];
				$StrainHits += $StrainHit;
			}
			for ($j=1;$j<$nBoleanFile; $j++){
				$Probe = $BoleanTable[$j][0];
				$ProbeHit = $BoleanTable[$j][$$i];
		}
	}
	$ClassHits{$Class} = $StrainHits;
	
	$ProbeHits = 0;
	
		for ($j=1; $j<$nBoleanFileFields;$j++){
				
				$ProbeHits += $ProbeHit;
			}
		$Classes{$Probe}{$Class} = $ProbeHits;
	}
		#$StrainClass{$Strain}{$Probe} = $ProbeHits;
    print "\n$Classes{$Probe}{$Class}\n$Classes{$Class}\n$StrainClass{$Strain}\n";
    exit;
}

##foreach my $Class(@Classes){
##print "\nThe Class $Class have $ClassHits{$Class} hits";
##}

#foreach $Class(@Classes){
#   for ($i=1; $i<$nBoleanFile; $i++){
#      $Probe = $BoleanTable[$i][0];
#      for ($j=1; $j<$Classes{$Class}; $j++){
#         $Probes{$Class} += $BoleanTable[$i][$j];
#      }
#   }

print "\n";
exit;
