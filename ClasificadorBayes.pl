#!/usr/bin/perl -w
use strict;
use List::MoreUtils qw(uniq);
use lib "/Users/rc/lib";
use Routines;

my($MainPath, $BoleanFileName, $MetaDataFileName, $nBoleanFile, $Line,
   $nBoleanFileFields, $N, $MetaData, $nMetaDataFile, $nMetaDataFileFields,
   $Region, $Strain, $Class, $nClasses, $Counter, $Hit, $Count);
my($i, $j);
my(@BoleanFile, @BoleanFileFields, @BoleanTable, @MetaDataField, @MetaDataFile,
   @MetaDataFileFields, @MetaData, @Classes, @Strains);
my(%StrainClass, %Classes, %pClasses, %cpClasses, %ClassHits);
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
		push @Strains, $Strain;
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

print "\nThe total of Hits into the bolean table are $Count";

foreach $Class(@Classes){
	$Count = 0;
	for ($i=1;$i<$nBoleanFileFields; $i++){
		$Strain = $BoleanTable[0][$i];
		if ($StrainClass{$Strain} eq $Class){
			for ($j=1;$j<$nBoleanFile;$j++){
				$Hit = $BoleanTable[$j][$i];
				$Count += $Hit;
			}
		}
	}
	$ClassHits{$Class} = $Count;
}

foreach my $Class(@Classes){
print "\nThe Class $Class have $ClassHits{$Class} hits";
}
print "\n";
exit;