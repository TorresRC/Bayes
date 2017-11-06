#!/usr/bin/perl -w
#use strict;
use List::MoreUtils qw(uniq);
use lib "/Users/rc/Bayes/lib";
use Routines;

my($MainPath, $BoleanFileName, $MetaDataFileName, $nBoleanFile, $Line,
   $nBoleanFileFields, $N, $MetaData, $nMetaDataFile, $nMetaDataFileFields,
   $Region, $Strain, $Class, $nClasses, $Counter, $Hit, $Count, $Probe, $StrainHit,
   $StrainHits, $ProbeHit, $ProbeHits, $nProbe, $BoleanQry, $nBoleanQry, $nBoleanQryFields,
   $QryHit, $QryStrain);
my($i, $j);
my(@BoleanFile, @BoleanFileFields, @BoleanTable, @MetaDataField, @MetaDataFile,
   @MetaDataFileFields, @MetaData, @Classes, @Strains, @BoleanQry, @BoleanQryFields, @QryTable);
my(%StrainClass, %Classes, %pClasses, %cpClasses, %ClassHits, %ProbeClass, %pProbeClass, %cpProbeClass, %ProbeTotalHits, %cpQry, %pQry);
my $BoleanTable = [ ];
my $QryTable = [ ];

$MainPath = "/Users/rc/Bayes";
$BoleanFileName = $MainPath ."/". "Tabla.csv";
$MetaDataFileName = $MainPath ."/". 'MetaData.csv';
$BoleanQry = $MainPath ."/". "Qry.csv";

@BoleanFile = ReadFile($BoleanFileName);
$nBoleanFile = scalar@BoleanFile;
$nProbe = $nBoleanFile-1;
for ($i=0; $i<$nBoleanFile; $i++){
	$Line = $BoleanFile[$i];
	@BoleanFileFields = split(",",$Line);
	push (@BoleanTable, [@BoleanFileFields]);
}
$nBoleanFileFields = scalar@BoleanFileFields;
$N = $nBoleanFileFields-1;



@BoleanQry = ReadFile($BoleanQry);
$nBoleanQry = scalar@BoleanQry;
for ($i=0; $i<$nBoleanQry; $i++){
	$Line = $BoleanQry[$i];
	@BoleanQryFields = split(",",$Line);
	push (@QryTable, [@BoleanQryFields]);
}
$nBoleanQryFields = scalar@BoleanQryFields;



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
#foreach my $Class(@Classes){
#   print "\nThe Class $Class have $Classes{$Class} elements, and its probability is $pClasses{$Class} while the complemented probability is $cpClasses{$Class}";
#}

$GlobalHits = 0;

for ($i=1; $i<$nBoleanFile; $i++){
	for ($j=1; $j<$nBoleanFileFields; $j++){
		$Hit = $BoleanTable[$i][$j];
		if ($Hit != 0){
			$GlobalHits++;
		}
	}
}
#print "\nThe total of Hits into the bolean table are $GlobalHits\n";

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
#foreach my $Class(@Classes){
#	print "\nThe Class $Class have $ClassHits{$Class} hits";
#}

foreach $Class(@Classes){
	for ($i=1;$i<$nBoleanFile;$i++){
		$Probe = $BoleanTable[$i][0];
      $ProbeTotalHits{$Probe} = 0;
		for ($j=1;$j<$nBoleanFileFields; $j++){
			$Strain = $BoleanTable[0][$j];
         $ProbeTotalHits{$Probe} += $BoleanTable[$i][$j];
			if ($StrainClass{$Strain} eq $Class){
				$ProbeClassHit = $BoleanTable[$i][$j];
				$ProbeClass{$Probe}{$Class} += $ProbeClassHit;
			}
		}
	}
}

#print "\n-->$ProbeTotalHits{j}<--\n";

for ($i=1;$i<$nBoleanFile;$i++){
	$Probe = $BoleanTable[$i][0];
	foreach $Class(@Classes){
      $pProbeClass{$Probe}{$Class} = ($ProbeClass{$Probe}{$Class}+1)/($ClassHits{$Class}+$nProbe);
      $cpProbeClass{$Probe}{$Class} = ($ProbeTotalHits{$Probe}-$ProbeClass{$Probe}{$Class}+1)/(($GlobalHits-$ClassHits{$Class})+$nProbe);
		#print "\nThe probe $Probe has $ProbeClass{$Probe}{$Class} hits in class $Class";
	}
}

for ($i=1;$i<$nBoleanQryFields;$i++){
   foreach $Class(@Classes){
      $QryStrain = $QryTable[0][$i];
      $pQryClass = $pClasses{$Class};
      $cpQryClass = $cpClasses{$Class}; 
      for ($j=1;$j<$nBoleanQry;$j++){
         $Probe = $QryTable[$j][0];
         $QryHit = $QryTable[$j][$i];
         if($QryHit == 1){
            $pQryClass = $pQryClass*$pProbeClass{$Probe}{$Class};
            $cpQryClass = $cpQryClass*$cpProbeClass{$Probe}{$Class};
         }
      }
      #$pQry{$Class}{$QryStrain} = $pQryClass;
      #$cpQry{$Class}{$QryStrain} = $cpQryClass;
      $pQry{$Class}{$QryStrain} = $pQryClass;
      $cpQry{$Class}{$QryStrain} = $cpQryClass;
   }
}
  
#print "\n->$pQry{C}{16}\n$cpQry{C}{16}<-\n";
for($i=0; $i<$nBoleanQryFields; $i++){
   $QryStrain = $QryTable[0][$i]; 
   foreach $Class (@Classes){
   print "\nClase $Class -> $pQry{$Class}{17}\t$cpQry{$Class}{17}"; 
}

print "\n";
exit;

