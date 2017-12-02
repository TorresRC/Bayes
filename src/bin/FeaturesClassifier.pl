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

my ($Usage, $TrainingFile, $MetadataFile, $OutPath, $Method, $Chi2, $IG, $OddsR,
    $PsCounts, $MI, $AllClassesPlot, $ForClassPlot, $HeatMapPlot, $Correlation,
    $Sort, $Clusters, $Dendrogram);

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
$Method         = $ARGV[4];  # <- Chi2, IG, OddsR, MI
#$IG             = $ARGV[4];
#$Chi2           = $ARGV[5];
#$OddsR          = $ARGV[6];
#$MI             = $ARGV[7];
$AllClassesPlot = $ARGV[5];
$ForClassPlot   = $ARGV[6];
$HeatMapPlot    = $ARGV[7];
$Correlation    = $ARGV[8];
$Sort           = $ARGV[9];
$Clusters       = $ARGV[10];
$Dendrogram     = $ARGV[11];

my($Test, $TestReport, $Plot, $HeatMap, $PlotRScript, $LinesOnTrainingFile,
   $nFeature, $Line, $ColumnsOnTrainingFile, $N, $LinesOnMetaDataFile,
   $ColumnsOnMetaDataFile, $PossibleClass, $Column, $Class, $nClasses, $Element,
   $GlobalHits, $Hit, $Feature, $iClass, $a, $b, $c, $d, $nConfusion,
   $ChiConfidence, $Round, $HeatMapRScript, $Matrix);
my($i, $j);
my(@TrainingFile, @TrainingFileFields, @TrainingMatrix, @MetaDataFile,
   @MetaDataFileFields, @MetaDataMatrix, @Classes, @Elements, @ChiConfidence,
   @ChiConfidences);
my(%ClassOfElement, %Elements, %pClass, %cpClass, %ClassHits,
   %HitsOfFeaturesInClass, %TotalFeatureHits, %Test);
my(%a, %b, %c, %d);
my $Report = [ ];

if ($Method eq "IG"){
   $Test = "Information Gain";
}elsif ($Method eq "Chi2"){
   $Test = "ChiSquare";
}elsif ($Method eq "OddsR"){
   $Test = "OddsRatio";
}elsif ($Method eq "MI"){
   $Test = "Mutual Information";
}else {
   print "\nYou should select only one test option (--Chi2, --MLE or --OddsR)\n\tProgram finished!\n\n";
   exit;
}

$TestReport = $OutPath ."/". $Test . ".csv";
$Plot       = $OutPath ."/". $Test . "_DotPlot.pdf";
$HeatMap    = $OutPath ."/". $Test . "_HeatMap.png";
$PlotRScript    = $OutPath ."/". "DotPlotScript.R";
$HeatMapRScript = $OutPath ."/". "HeatMapScript.R";


# Loading the bolean training file
@TrainingFile = ReadFile($TrainingFile);
$LinesOnTrainingFile = scalar@TrainingFile;
$nFeature = $LinesOnTrainingFile-1;
for ($i=0; $i<$LinesOnTrainingFile; $i++){
	$Line = $TrainingFile[$i];
	@TrainingFileFields = split(",",$Line);
        chomp @TrainingFileFields;
	push (@TrainingMatrix, [@TrainingFileFields]);
}
$ColumnsOnTrainingFile = scalar@TrainingFileFields;
$N = $ColumnsOnTrainingFile-1;

# Loading the metadata file
@MetaDataFile = ReadFile($MetadataFile);
$LinesOnMetaDataFile = scalar@MetaDataFile;
for ($i=0; $i<$LinesOnMetaDataFile; $i++){
	$Line = $MetaDataFile[$i];
	@MetaDataFileFields = split(",",$Line);
        chomp @MetaDataFileFields;
	push (@MetaDataMatrix, [@MetaDataFileFields]);
}
$ColumnsOnMetaDataFile = scalar@MetaDataFileFields;

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
	}
}

# Statistic tests
$Report -> [0][0] = "Feature";
$iClass = 1;
for ($i=0; $i<$nClasses; $i++){
   $Class = $Classes[$i];
   $Report -> [0][$i+1] = $Class; 
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
                           #(($a/$nConfusion)*(log2(($nConfusion*$a)/(($a+$b)*($a+$c)))))+
                           #(($c/$nConfusion)*(log2(($nConfusion*$c)/(($c+$d)*($c+$a)))))+
                           #(($b/$nConfusion)*(log2(($nConfusion*$b)/(($b+$a)*($b+$d)))))+
                           #(($d/$nConfusion)*(log2(($nConfusion*$d)/(($d+$c)*($d+$b)))));
      }elsif ($Method eq "Chi2"){    # <------------------------------------ Chi squared
        $Test{$Feature} = (($nConfusion*(($a*$d)-($b*$c))**2))/(($a+$c)*($a+$b)*($b+$d)*($c+$d));
      }elsif ($Method eq "OddsR"){
        #$Test{$Feature} = log10(($a*$d)/($b*$c));
        $Test{$Feature} = ($a*$d)/($b*$c);
      }elsif ($Method eq "MI"){      # Mutual information
         $Test{$Feature} = log10(($a*$nConfusion)/(($a+$b)*($a+$c)));
      }
      
      $Report -> [$j][0] = $Feature;
      $Report -> [$j][$iClass] = $Test{$Feature};
   }
   $iClass++;
}

# Building output file
open (FILE, ">$TestReport");
for ($i=0;$i<$LinesOnTrainingFile;$i++){
   #for ($j=0;$j<5;$j++){
   #     if($j < 4){
   for ($j=0;$j<$nClasses+1;$j++){
        if($j < $nClasses){
                print FILE $Report -> [$i][$j], ",";
        }elsif($j == $nClasses){
        #}elsif($j == 4){
                print FILE $Report -> [$i][$j];
        }
   }
   print FILE "\n";
}
close FILE;

# Building dot plot
print "\n Building Plots...";
chdir($OutPath);

# Dot plot all clases
if ($AllClassesPlot eq "on"){
        open(RSCRIPT, ">$PlotRScript");
                print RSCRIPT 'library(ggplot2)' . "\n";
                print RSCRIPT "df <- read.csv(\"$TestReport\")" . "\n";
                print RSCRIPT 'ggplot(df, aes(Feature))';
                foreach $Class(@Classes){
                        print RSCRIPT "+ geom_point(aes(y=$Class,color=\"$Class\"))";
                }
                if($Method eq "Chi2"){
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
}


# Dot plot for class
if ($ForClassPlot eq "on"){
        foreach $Class(@Classes){
                my $ClassPlotRScript = $OutPath ."/". $Class . "_DotPlotScript.R";
                my $ClassPlot = $OutPath ."/". $Test ."_". $Class . "_DotPlot.pdf";
                open(FILE, ">$ClassPlotRScript");
                        print FILE 'library(ggplot2)' . "\n";
                        print FILE "df <- read.csv(\"$TestReport\")" . "\n";
                        print FILE 'ggplot(df, aes(Feature))';
                        print FILE "+ geom_point(aes(y=$Class,color=\"$Class\"))";
                        if($Method eq "Chi2"){
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
                
                #print RSCRIPT 'mat_data <- data.matrix(df[,2:ncol(df)])' . "\n";
                print RSCRIPT "$Matrix <- data.matrix(df[,2:ncol(df)])" . "\n";
                print RSCRIPT "rownames($Matrix) <- rnames" . "\n";
                
                

                
                if ($Correlation eq "on"){
                        print RSCRIPT "$Matrix <- cor($Matrix)" . "\n";
                }

                print RSCRIPT "heatmap.2($Matrix," . "\n";
                 
                print RSCRIPT "main = \"$Test\"," . "\n";                  # Title
                print RSCRIPT 'keysize = 0.8,' . "\n";
                print RSCRIPT 'key.title = "Confidence",' . "\n";
                print RSCRIPT 'key.xlab = "Key",' . "\n";
                print RSCRIPT 'density.info="none",' . "\n";                # Turns of density plot un legend
                print RSCRIPT 'notecol = "black",' . "\n";                  # font of cell labels in black
                print RSCRIPT 'trace = "none",' . "\n";                     # Turns of trace lines in heat map
                
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
                        print RSCRIPT 'Colv = "NA",' . "\n";                        # Turn off column sort
                        print RSCRIPT 'Rowv = "NA",' . "\n";                        # Turn off row sort
                }elsif ($Sort eq "on"){
                        if ($Clusters eq "on"){
                                #print RSCRIPT "distance = distfun($Matrix, method = \"manhattan\")," . "\n";
                                #print RSCRIPT 'cluster = hclustfun(distance, method = "ward"),' . "\n";
                                print RSCRIPT "Rowv = as.dendrogram(hclust(dist($Matrix, method = \"manhattan\"), method = \"ward\"))," . "\n";      # apply default clustering method'
                                print RSCRIPT "Colv = as.dendrogram(hclust(dist($Matrix, method = \"manhattan\"), method = \"ward\"))," . "\n";      # apply default clustering method
                        }
                }
                
                if ($Dendrogram eq "off"){
                        print RSCRIPT 'dendrogram = "none",' ."\n";                 # Hides dendrogram
                }elsif($Dendrogram eq "row"){
                        print RSCRIPT 'dendrogram = "row",' ."\n";
                }elsif($Dendrogram eq "column"){
                        print RSCRIPT 'dendrogram = "column",' ."\n";
                }elsif($Dendrogram eq "both"){
                        print RSCRIPT 'dendrogram = "both",' ."\n";
                }
                
                print RSCRIPT 'srtCol= 0,' ."\n";
                print RSCRIPT 'adjCol= c (0.5,1),' ."\n";
                print RSCRIPT 'cexCol=0.8,' ."\n";
                
                print RSCRIPT 'col = Colors)' . "\n";                       # Use defined palette
                print RSCRIPT 'dev.off()';
        close RSCRIPT;
        system ("R CMD BATCH $HeatMapRScript");
        system ("rm $PlotRScript $HeatMapRScript $OutPath/*.Rout $OutPath/Rplots.pdf");
}

print "Done!\n\n";

exit;