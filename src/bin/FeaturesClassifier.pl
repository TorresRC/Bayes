#!/usr/bin/perl -w

#################################################################################
#By:       Roberto C. Torres & Mauricio Flores                                  #
#e-mail:   torres.roberto.c@gmail.com                                           #
#################################################################################
use strict;
use List::MoreUtils qw(uniq);
use List::MoreUtils qw(any);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Routines;
my $MainPath = "$FindBin::Bin";

my ($Usage, $TrainingFile, $MetadataFile, $OutPath, $Method, $X2, $IG, $OR,
    $PsCounts, $MI, $DotPlot, $HeatMapPlot, $Correlation, $Sort, $Clusters,
    $Dendrogram, $Threshold);

$Usage = "\nUSAGE\n  $FindBin::Script <Observed Data [Absolute Path]>
                            <Metadata [Absolute Path]>
                            <Output Path [Relative Path]>
                            <Pseudo Counts Increase [Integer]>
                            <ChiSquare Test [Bolean]>
                            <Maximum Likelihood Estimation [Bolean]>\n\n";
unless(@ARGV) {
        print $Usage;
        exit;
}
chomp @ARGV;
$TrainingFile   = $ARGV[0];
$MetadataFile   = $ARGV[1];
$OutPath        = $ARGV[2];
$PsCounts       = $ARGV[3];
$Method         = $ARGV[4];  # <- X2, IG, OR, MI
$DotPlot        = $ARGV[5];  # <- AllClasses, ForClass
$HeatMapPlot    = $ARGV[6];
$Correlation    = $ARGV[7];
$Sort           = $ARGV[8];
$Clusters       = $ARGV[9];
$Dendrogram     = $ARGV[10];
$Threshold      = $ARGV[11];

my($Test, $TestReport, $PercentagesReport, $Plot, $HeatMap, $PlotRScript,
   $LinesOnTrainingFile, $nFeature, $Line, $ColumnsOnTrainingFile, $N,
   $LinesOnMetaDataFile, $ColumnsOnMetaDataFile, $PossibleClass, $Column, $Class,
   $nClasses, $Element, $GlobalHits, $Hit, $Feature, $iClass, $a, $b, $c, $d,
   $nConfusion, $ChiConfidence, $Round, $HeatMapRScript, $Matrix, $Informative,
   $InformativeFeatures, $InformativeLines, $CombinedReport, $TestReportLine,
   $CombinedReportLine);
my($i, $j);
my(@TrainingFile, @TrainingFileFields, @TrainingMatrix, @MetaDataFile,
   @MetaDataFileFields, @MetaDataMatrix, @Classes, @Elements, @ChiConfidence,
   @ChiConfidences, @TestReport, @Combined, @TestReportData);
my(%ClassOfElement, %Elements, %pClass, %cpClass, %ClassHits,
   %HitsOfFeaturesInClass, %TotalFeatureHits, %Test,%PercentageOfFeatureInClass);
my(%a, %b, %c, %d);
my $Report = [ ];
my $Percentages = [ ];
my $Combined = [ ];

if ($Method eq "IG"){
   $Test = "Information_Gain";
}elsif ($Method eq "X2"){
   $Test = "Chi_Square";
}elsif ($Method eq "OR"){
   $Test = "Odds_Ratio";
}elsif ($Method eq "MI"){
   $Test = "Mutual_Information";
}else {
   print "\nYou should select only one test option (--X2, --MLE or --OR)\n\tProgram finished!\n\n";
   exit;
}

$TestReport          = $OutPath ."/". $Test . ".csv";
$PercentagesReport   = $OutPath ."/". "Percentages.csv";
$Plot                = $OutPath ."/". $Test . "_DotPlot.pdf";
$HeatMap             = $OutPath ."/". $Test . "_HeatMap.png";
$PlotRScript         = $OutPath ."/". "DotPlotScript.R";
$HeatMapRScript      = $OutPath ."/". "HeatMapScript.R";
$Informative         = $OutPath ."/". "InformativeFeatures.csv";
$CombinedReport      = $OutPath ."/". $Test . "_Percentages.csv";

# Loading the bolean training file
($LinesOnTrainingFile, $ColumnsOnTrainingFile, @TrainingMatrix) = Matrix($TrainingFile);
$nFeature = $LinesOnTrainingFile-1;
$N = $ColumnsOnTrainingFile-1;

# Loading the metadata file
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
	#for ($j=1;$j<$LinesOnMetaDataFile;$j++){
        for ($j=1;$j<$ColumnsOnTrainingFile;$j++){
		$Element = $TrainingMatrix[0]->[$j];
		$Class = $MetaDataMatrix[$j]->[1];
		$ClassOfElement{$Element} = $Class;
		if($Class eq $Classes[$i]){
                        $Elements{$Classes[$i]}++; #   <-------- Number of elements in each class
		}
	}
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
		$Element = "$TrainingMatrix[0][$i]";
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
                $PercentageOfFeatureInClass{$Feature}{$Class} = ($HitsOfFeaturesInClass{$Feature}{$Class})/($Elements{$Class})*100; # <- Percentage of Feature Hits in Class
	}
}

# Statistic tests
$Report -> [0][0] = "Feature";
$Percentages -> [0][0] = "Feature";
$iClass = 1;
$InformativeLines = 0; 
for ($i=0; $i<$nClasses; $i++){
   $Class = $Classes[$i];
   $Report -> [0][$i+1] = $Class;
   $Percentages -> [0][$i+1] = $Class;
   for ($j=1;$j<$LinesOnTrainingFile;$j++){
      $Feature = $TrainingMatrix[$j][0];

      $a= (($HitsOfFeaturesInClass{$Feature}{$Class}))+0.001; # hits de sonda a en clase a
      $b= (($TotalFeatureHits{$Feature}-$HitsOfFeaturesInClass{$Feature}{$Class}))+0.001; # Hits de sonda a que no están en clase A
      $c= (($Elements{$Class}-$HitsOfFeaturesInClass{$Feature}{$Class}))+0.001; # Numero de mismaches en clase A (numero de ceros en clase A)
      $d= ((($N-$Elements{$Class})-($TotalFeatureHits{$Feature}-$HitsOfFeaturesInClass{$Feature}{$Class})))+0.001; # Numero de ceros fuera de A
      $nConfusion = $a+$b+$c+$d;
            
      if ($Method eq "IG"){         # <------------------ Maximum Likelihood Estimation -- Information Gain
         $Test{$Feature} = ((-1*(($a+$c)/$nConfusion))*log10(($a+$c)/$nConfusion))+
                           (($a/$nConfusion)*log10($a/($a+$b)))+
                           (($c/$nConfusion)*log10($c/($c+$d)));
      }elsif ($Method eq "X2"){     # <------------------------------------ Chi square
        $Test{$Feature} = (($nConfusion*(($a*$d)-($b*$c))**2))/(($a+$c)*($a+$b)*($b+$d)*($c+$d));
      }elsif ($Method eq "OR"){
        $Test{$Feature} = ($a*$d)/($b*$c);
      }elsif ($Method eq "MI"){      # Mutual information
        $Test{$Feature} = log10(($a*$nConfusion)/(($a+$b)*($a+$c)));
      }
      
      #if ($Test{$Feature} >= $Threshold){
      #  $InformativeFeatures -> [$j][0] = $Feature;
      #  $InformativeFeatures -> [$j][$iClass] = $PercentageOfFeatureInClass{$Feature}{$Class};
      #  $InformativeLines++;
      #}
      
      $Report -> [$j][0] = $Feature;
      $Report -> [$j][$iClass] = $Test{$Feature};
      
      $Percentages -> [$j][0] = $Feature;
      $Percentages -> [$j][$iClass] = $PercentageOfFeatureInClass{$Feature}{$Class};
   }
   $iClass++;
}

## Building output file
open (FILE, ">$TestReport");
open (PERCENTAGES, ">$PercentagesReport");
for ($i=0;$i<$LinesOnTrainingFile;$i++){
   for ($j=0;$j<$nClasses+1;$j++){
        if($j < $nClasses){
                print FILE $Report -> [$i][$j], ",";
                print PERCENTAGES $Percentages -> [$i][$j], ",";
        }elsif($j == $nClasses){
                print FILE $Report -> [$i][$j];
                print PERCENTAGES $Percentages -> [$i][$j];
        }
   }
   print FILE "\n";
   print PERCENTAGES "\n";
}
close FILE;
close PERCENTAGES;

for ($i=0;$i<$LinesOnTrainingFile;$i++){
   for ($j=0;$j<$nClasses*2+1;$j++){
        if ($j<$nClasses+1){
                $Combined -> [$i][$j] = $Report -> [$i][$j];
        }else{
                $Combined -> [$i][$j] = $Percentages -> [$i][$j-$nClasses];
        }
   }
}

open (FILE, ">$CombinedReport");
for ($i=0;$i<$LinesOnTrainingFile;$i++){
   for ($j=0;$j<$nClasses*2+1;$j++){
        print FILE $Combined -> [$i][$j], ",";
   }
   print FILE "\n";
}
close FILE;

@TestReport = ReadFile($TestReport);
@Combined = ReadFile($CombinedReport);

for ($i=0;$i<$LinesOnTrainingFile;$i++){
        $TestReportLine = $TestReport[$i];
        $CombinedReportLine = $Combined[$i]; 
        if ($i == 0){
                open (FILE, ">$Informative");
                        print FILE $CombinedReportLine, "\n";
                close FILE;
        }else{
                @TestReportData = split(",",$TestReportLine);
                if ( any { $_ > $Threshold} @TestReportData){
                        open (FILE, ">>$Informative");
                                print FILE $CombinedReportLine, "\n";
                        close FILE;
                }
        }
}


# Building dot plot
print "\n Building Plots...";
chdir($OutPath);

# Dot plot all clases
if ($DotPlot eq "AllClasses"){
        open(RSCRIPT, ">$PlotRScript");
                print RSCRIPT 'library(ggplot2)' . "\n";
                print RSCRIPT "df <- read.csv(\"$TestReport\")" . "\n";
                print RSCRIPT 'ggplot(df, aes(Feature))';
                foreach $Class(@Classes){
                        print RSCRIPT "+ geom_point(aes(y=$Class,color=\"$Class\"))";
                }
                if($Method eq "X2"){
                        @ChiConfidences = (0.9,0.95,0.975,0.99,0.999);
                        foreach $ChiConfidence(@ChiConfidences){
                                print RSCRIPT "+ geom_hline(aes(yintercept = qchisq($ChiConfidence, df=$nClasses-1), linetype=\"$ChiConfidence\"))";
                        }
                }
                print RSCRIPT "+ labs(x=\"Features\", y=\"bits\", title= \"$Test\", color=\"Class\", linetype=\"Confidence Intervals\")";
                if($N > 100){
                        print RSCRIPT '+ theme(axis.text.x = element_text(angle = 90, size=4, hjust = 1))' . "\n";
                }
                print RSCRIPT "\n";
                print RSCRIPT "ggsave(\"$Plot\")" . "\n";
                
        close RSCRIPT;
        system ("R CMD BATCH $PlotRScript");
        system ("rm $PlotRScript");
}

# Dot plot for class
if ($DotPlot eq "ForClass"){
        foreach $Class(@Classes){
                my $ClassPlotRScript = $OutPath ."/". $Class . "_DotPlotScript.R";
                my $ClassPlot = $OutPath ."/". $Test ."_". $Class . "_DotPlot.pdf";
                open(FILE, ">$ClassPlotRScript");
                        print FILE 'library(ggplot2)' . "\n";
                        print FILE "df <- read.csv(\"$TestReport\")" . "\n";
                        print FILE 'ggplot(df, aes(Feature))';
                        print FILE "+ geom_point(aes(y=$Class,color=\"$Class\"))";
                        if($Method eq "X2"){
                                @ChiConfidences = (0.9,0.95,0.975,0.99,0.999);
                                foreach $ChiConfidence(@ChiConfidences){
                                        print FILE "+ geom_hline(aes(yintercept = qchisq($ChiConfidence, df=$nClasses-1), linetype=\"$ChiConfidence\"))";
                                }
                        }
                        print FILE "+ labs(x=\"Features\", y=\"bits\", title= \"$Test\", color=\"Class\", linetype=\"Confidence Intervals\")";
                        if($N > 100){
                                print FILE '+ theme(axis.text.x = element_text(angle = 90, size=4, hjust = 1))' . "\n";
                        }
                        print FILE "\n";
                        print FILE "ggsave(\"$ClassPlot\")" . "\n";
                        
                close FILE;
                system ("R CMD BATCH $ClassPlotRScript");
                system ("rm $ClassPlotRScript");
        }
}
 
# Heat Map;
if ($HeatMapPlot eq "on"){
        open(RSCRIPT, ">$HeatMapRScript");
                print RSCRIPT 'library(gplots)' . "\n";
                print RSCRIPT 'library(RColorBrewer)' . "\n";
                
                print RSCRIPT "png(\"$HeatMap\"," . "\n";
                print RSCRIPT "width = 5*300," . "\n";
                print RSCRIPT "height = 5*300," . "\n";
                print RSCRIPT "res = 300," . "\n";
                print RSCRIPT "pointsize = 8)" . "\n";
                
                print RSCRIPT 'Colors <- colorRampPalette(c("red", "yellow", "green"))(n=299)' . "\n";
                
                $Matrix = "Matrix";
                
                print RSCRIPT "df <- read.csv(\"$TestReport\")" . "\n";
                print RSCRIPT 'rnames <- df[,1]' . "\n";
                print RSCRIPT "$Matrix <- data.matrix(df[,2:ncol(df)])" . "\n";
                print RSCRIPT "rownames($Matrix) <- rnames" . "\n";
                
                if ($Correlation eq "on"){
                        print RSCRIPT "$Matrix <- cor($Matrix)" . "\n";
                }
                
                print RSCRIPT "heatmap.2($Matrix," . "\n";
                print RSCRIPT "main = \"$Test\"," . "\n";                        # Title
                print RSCRIPT 'keysize = 0.8,' . "\n";
                print RSCRIPT 'key.title = "Confidence",' . "\n";
                print RSCRIPT 'key.xlab = "Key",' . "\n";
                print RSCRIPT 'density.info="none",' . "\n";                     # Turns of density plot un legend
                print RSCRIPT 'notecol = "black",' . "\n";                       # font of cell labels in black
                print RSCRIPT 'trace = "none",' . "\n";                          # Turns of trace lines in heat map
                
                $Round = 5;
                if ($Correlation eq "on"){
                        print RSCRIPT 'xlab = "Class",' . "\n";
                        print RSCRIPT 'ylab = "Class",' . "\n";
                        print RSCRIPT "cellnote = round($Matrix,$Round)," . "\n"; # Shows data in cell
                        print RSCRIPT 'srtRow= 90,' ."\n";
                        print RSCRIPT 'adjRow= c (0.5,1),' ."\n";
                        print RSCRIPT 'cexRow=0.8,' ."\n";
                }else{
                        print RSCRIPT 'xlab = "Class",' . "\n";
                        print RSCRIPT 'ylab = "Feature",' . "\n";
                        if ($nClasses < 11 && $nFeature < 101){
                                print RSCRIPT "cellnote = round($Matrix,$Round)," . "\n"; # Shows data in cell
                        }
                }
                       
                if ($Sort eq "off"){
                        print RSCRIPT 'Colv = "NA",' . "\n";                     # Turn off column sort
                        print RSCRIPT 'Rowv = "NA",' . "\n";                     # Turn off row sort
                }elsif ($Sort eq "on"){
                        if ($Clusters eq "on"){
                                #print RSCRIPT "distance = distfun($Matrix, method = \"manhattan\")," . "\n";
                                #print RSCRIPT 'cluster = hclustfun(distance, method = "ward"),' . "\n";
                                print RSCRIPT "Rowv = as.dendrogram(hclust(dist($Matrix, method = \"manhattan\"), method = \"ward\"))," . "\n";      # apply default clustering method just on rows
                                print RSCRIPT "Colv = as.dendrogram(hclust(dist($Matrix, method = \"manhattan\"), method = \"ward\"))," . "\n";      # apply default clustering method just on columns
                        }
                }
                
                if ($Dendrogram eq "off"){
                        print RSCRIPT 'dendrogram = "none",' ."\n";              # Hides dendrogram
                }elsif($Dendrogram eq "row"){
                        print RSCRIPT 'dendrogram = "row",' ."\n";               # Shows dendrogram for rows
                }elsif($Dendrogram eq "column"){
                        print RSCRIPT 'dendrogram = "column",' ."\n";            # Shows dendrogram for columns
                }elsif($Dendrogram eq "both"){
                        print RSCRIPT 'dendrogram = "both",' ."\n";              # Shos dendrogram for rows and columns
                }
                
                print RSCRIPT 'srtCol= 0,' ."\n";
                print RSCRIPT 'adjCol= c (0.5,1),' ."\n";
                print RSCRIPT 'cexCol=0.8,' ."\n";
                print RSCRIPT 'col = Colors)' . "\n";                            # Use defined palette
                
                print RSCRIPT 'dev.off()';
        close RSCRIPT;
        system ("R CMD BATCH $HeatMapRScript");
        system ("rm $HeatMapRScript");
}
   
system ("rm $OutPath/*.Rout $OutPath/Rplots.pdf");

print "Done!\n\n";

exit;