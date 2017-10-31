#!/usr/bin/perl -w
#use strict;
use List::MoreUtils qw(uniq);
use lib "/home/rtorres/Bayes/lib";
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

$MainPath = "/home/rtorres/Bayes";
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
		}
	}
	$ClassHits{$Class} = $StrainHits;		
}
foreach my $Class(@Classes){
	print "\nThe Class $Class have $ClassHits{$Class} hits";
}

foreach $Class(@Classes){
	for ($i=1;$i<$nBoleanFile;$i++){
		$Probe = $BoleanTable[$i][0];
		for ($j=1;$j<$nBoleanFileFields; $j++){
			$Strain = $BoleanTable[0][$j];
			if ($StrainClass{$Strain} eq $Class){
				$ProbeClassHit = $BoleanTable[$i][$j];
				$ProbeClass{$Probe}{$Class} += $ProbeClassHit;
			}
		}
	}
}
for ($i=1;$i<$nBoleanFile;$i++){
	$Probe = $BoleanTable[$i][0];
	foreach $Class(@Classes){
		print "\nThe probe $Probe has $ProbeClass{$Probe}{$Class} hits in class $Class";
	}
}
print "\n";
exit;

