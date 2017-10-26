#!/usr/bin/perl -w
use strict;
use lib "/home/roberto/lib";
use Routines;

my($BoleanTable, $MainPath, $Row, $MetaData, $StrainData, $StrainRegion,
   $A, $B, $C, $D, $nMetaData, $N, $pA, $pB, $pC, $pD, $pNoA, $pNoB, $pNoC, $pNoD);
my($i);
my(@BoleanTable,@MetaData, @StrainData);

$MainPath = "/home/roberto/NaiveBayes";
$BoleanTable = $MainPath ."/". "Tabla.csv";
$MetaData = $MainPath ."/". "MetaData.csv";

@BoleanTable = ReadFile($BoleanTable);
@MetaData = ReadFile($MetaData);
$nBoleanTable = scalar@nBoleanTable;
$nMetaData = scalar@MetaData;
$N = $nMetaData-1;

for($i=1;$i<$nMetaData;$i++){
	$Row = $MetaData[$i];
	@StrainData = split(',',$Row);
	$StrainRegion = $StrainData[1];
	if($StrainRegion eq 'A'){
		$A++;
	}elsif($StrainRegion eq 'B'){
		$B++;
	}elsif($StrainRegion eq 'C'){
		$C++;
	}elsif($StrainRegion eq 'D'){
		$D++;
	}
}

push $A, @nClass;


$pA = $A/$N;
$pB = $B/$N;
$pC = $C/$N;
$pD = $D/$N;
$pNoA = 1-$pA;
$pNoB = 1-$pB;
$pNoC = 1-$pC;
$pNoD = 1-$pD;


for($i=1;$i<$nBoleanTable;$i++){
	$Probe = $BoleanTable[$i];
	@ProbeData = split(',',$Probe);
	for($j=1;$j<

print "\nVar A:$A\nVar B:$B\nVar C:$C\nVar D:$D\nTotal: $N\n$nMetaData";

exit;
		
