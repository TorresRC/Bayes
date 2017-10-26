#!/usr/bin/perl -w
use strict;
use List::MoreUtils qw(uniq);
use lib "/home/rtorres/lib";
use Routines;

my($MainPath, $BoleanFileName, $MetaDataFileName, $nBoleanFile, $Line,
   $nBoleanFileFields, $MetaData, $nMetaDataFile, $nMetaDataFileFields,
   $Region, $Class);
my($i, $j);
my(@BoleanFile, @BoleanFileFields, @BoleanTable, @MetaDataField, @MetaDataFile,
   @MetaDataFileFields, @MetaData, @Classes);
my(%Classes);
my $BoleanTable = [ ]; 

$MainPath = "/home/rtorres/Bayes";
$BoleanFileName = $MainPath ."/". "Tabla.csv";
$MetaDataFileName = $MainPath ."/". 'MetaData.csv';

@BoleanFile = ReadFile($BoleanFileName);
$nBoleanFile = scalar@BoleanFile;

for ($i=0; $i<$nBoleanFile; $i++){
	$Line = $BoleanFile[$i];
	@BoleanFileFields = split(",",$Line);
	$nBoleanFileFields = scalar@BoleanFileFields;
	push (@BoleanTable, [@BoleanFileFields]);
}

@MetaDataFile = ReadFile($MetaDataFileName);
$nMetaDataFile = scalar@MetaDataFile;

for ($i=0; $i<$nMetaDataFile; $i++){
	$Line = $MetaDataFile[$i];
	@MetaDataFileFields = split(",",$Line);
	$nMetaDataFileFields = scalar@MetaDataFileFields;
	push (@MetaData, [@MetaDataFileFields]);
}

for ($i=1;$i<$nMetaDataFileFields;$i++){
	$Class = $MetaData[$i]->[1];
	push @Classes, $Class;
}

@Classes = uniq(@Classes);

foreach my $Element(@Classes){
	print "\n$Element\n";
}
exit;

#
#@Classes = ("A","B","C","D");
#@BoleanTable = ReadFile($BoleanTable);
#@MetaData = ReadFile($MetaData);
#$nBoleanTable = scalar@BoleanTable;
#$nMetaData = scalar@MetaData;
#$N = $nMetaData-1;
#
#
#
#for($i=1;$i<$nMetaData;$i++){
#	$Row = $MetaData[$i];
#	@StrainData = split(',',$Row);
#	$StrainRegion = $StrainData[1];
#	
#	foreach $Class(@Classes){
#		if($StrainRegion eq $Class){
#		$Classes{$Class} = $Counter++;
#	}
#}
#
#$pA = $A/$N;
#$pB = $B/$N;
#$pC = $C/$N;
#$pD = $D/$N;
#exit;
#$pNoA = 1-$pA;
#$pNoB = 1-$pB;
#$pNoC = 1-$pC;
#$pNoD = 1-$pD;
#
#for($i=1;$i<$nBoleanTable;$i++){
#	$Probe = $BoleanTable[$i];
#	@ProbeData = split(',',$Probe);
#	for($j=1;$j<$N+1;$j++){
#		$Hit = $ProbeData[$j];
#		foreach $Class (@Classes){
#		
#		if($Hit == "1"){
#			$TotalProbe++;
#		}
#	}
#}
#
#print "\nVar A:$A\nVar B:$B\nVar C:$C\nVar D:$D\nTotal Columns: $N\nTotal Probes: $TotalProbe\n";
#
#exit;
#		
