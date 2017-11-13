#!/usr/bin/perl -w
use strict;
use List::MoreUtils qw(uniq);
use FindBin;
use lib "$FindBin::Bin/lib";
use Routines;
my $MainPath = "$FindBin::Bin";

my ($Usage, $TrainingFile, $MetadataFile, $OutPath, $Chi2, $MLE, $PsCounts);

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
$TrainingFile = $ARGV[0];
$MetadataFile = $ARGV[1];
$OutPath      = $ARGV[2];
$PsCounts     = $ARGV[3];
$MLE          = $ARGV[4];
$Chi2         = $ARGV[5];


my($Test, $TestReport, $Plot, $HeatMap, $PlotRScript, $LinesOnTrainingFile,
   $nFeature, $Line, $ColumnsOnTrainingFile, $N, $LinesOnMetaDataFile,
   $ColumnsOnMetaDataFile, $PossibleClass, $Column, $Class, $nClasses, $Element,
   $GlobalHits, $Hit, $Feature, $iClass, $a, $b, $c, $d, $nConfusion,
   $ChiConfidence, $Round, $HeatMapRScript);
my($i, $j);
my(@TrainingFile, @TrainingFileFields, @TrainingMatrix, @MetaDataFile,
   @MetaDataFileFields, @MetaDataMatrix, @Classes, @Elements, @ChiConfidence,
   @ChiConfidences);
my(%ClassOfElement, %Elements, %pClass, %cpClass, %ClassHits,
   %HitsOfFeaturesInClass, %TotalFeatureHits, %Test);
my(%a, %b, %c, %d);
my $Report = [ ];

if ($MLE == 1 && $Chi2 == 0){
   $Test = "MaximumLikelihoodEstimation";
}elsif ($MLE == 0 && $Chi2 == 1){
   $Test = "ChiSquare";
}else {
   print "\nYou should select only one test option (--Chi2 or --MLE)\n\tProgram finished!\n\n";
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
	for ($j=1;$j<$LinesOnMetaDataFile;$j++){
		$Element = $MetaDataMatrix[$j]->[0];
		$Class = $MetaDataMatrix[$j]->[1];
		$ClassOfElement{$Element} = $Class;
		if($Class eq $Classes[$i]){
                        $Elements{$Classes[$i]}++; #   <-------- Number of elements in each class
		}
	}
	#$pClass{$Classes[$i]} = $Elements{$Classes[$i]}/$N; # Probability of each class
	#$cpClass{$Classes[$i]} = 1-$Elements{$Classes[$i]}/$N; # Complement probability of each class
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
		$Element = $TrainingMatrix[0][$i];
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
      
      if ($MLE == 1){         # <------------------ Maximum Likelihood Estimation
         $Test{$Feature} = (($a/$nConfusion)*(log2(($nConfusion*$a)/(($a+$b)*($a+$c)))))+
                           (($b/$nConfusion)*(log2(($nConfusion*$b)/(($b+$a)*($b+$d)))))+
                           (($c/$nConfusion)*(log2(($nConfusion*$c)/(($c+$d)*($c+$a)))))+
                           (($d/$nConfusion)*(log2(($nConfusion*$d)/(($d+$c)*($d+$b)))));
      }elsif ($Chi2 == 1){    # <------------------------------------ Chi squared
        $Test{$Feature} = (($nConfusion*(($a*$d)-($b*$c))**2))/(($a+$c)*($a+$b)*($b+$d)*($c+$d));
      } 
      $Report -> [$j][0] = $Feature;
      $Report -> [$j][$iClass] = $Test{$Feature};
   }
   $iClass++;
}

# Building output file
open (FILE, ">$TestReport");
for ($i=0;$i<$LinesOnTrainingFile;$i++){
   for ($j=0;$j<5;$j++){
        if($j < 4){
                print FILE $Report -> [$i][$j], ",";
        }elsif($j == 4){
                print FILE $Report -> [$i][$j];
        }
   }
   print FILE "\n";
}
close FILE;

# Building dot plot
print "\n Building Plots...";
chdir($OutPath);

# Dot plot
open(RSCRIPT, ">$PlotRScript");
   print RSCRIPT 'library(ggplot2)' . "\n";
   print RSCRIPT "df <- read.csv(\"$TestReport\")" . "\n";
   print RSCRIPT 'ggplot(df, aes(Feature))';
   foreach $Class(@Classes){
      print RSCRIPT "+ geom_point(aes(y=$Class,color=\"$Class\"))";
   }
   if($Chi2 == 1){
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
   
# Heat Map;
open(RSCRIPT, ">$HeatMapRScript");
   print RSCRIPT 'library(gplots)' . "\n";
   print RSCRIPT 'library(RColorBrewer)' . "\n";
   print RSCRIPT 'rnames <- df[,1]' . "\n";
   print RSCRIPT 'mat_data <- data.matrix(df[,2:ncol(df)])' . "\n";
   print RSCRIPT 'rownames(mat_data) <- rnames' . "\n";
   
   print RSCRIPT 'Colors <- colorRampPalette(c("red", "yellow", "green"))(n=299)' . "\n";
   if ($nClasses < 5){
        $Round = 5;
   }
   
   print RSCRIPT "png(\"$HeatMap\"," . "\n";
   print RSCRIPT "width = 5*300," . "\n";
   print RSCRIPT "height = 5*300," . "\n";
   print RSCRIPT "res = 300," . "\n";
   print RSCRIPT "pointsize = 8)" . "\n";
   
   print RSCRIPT 'heatmap.2(mat_data,' . "\n";                    
   print RSCRIPT "cellnote = round(mat_data,$Round)," . "\n"; # Shows data in cell 
   print RSCRIPT "main = \"$Test\"," . "\n";                  # Title
   print RSCRIPT 'xlab = "Class",' . "\n";
   print RSCRIPT 'ylab = "Feature",' . "\n";
   print RSCRIPT 'keysize = 0.8,' . "\n";
   print RSCRIPT 'key.title = "Confidence",' . "\n";
   print RSCRIPT 'key.xlab = "Probability",' . "\n";
   print RSCRIPT 'density.info="none",' . "\n";                # Turns of density plot un legend
   print RSCRIPT 'notecol = "black",' . "\n";                  # font of cell labels in black
   print RSCRIPT 'trace = "none",' . "\n";                     # Turns of trace lines in heat map
   print RSCRIPT 'col = Colors,' . "\n";                       # Use defined palette
   print RSCRIPT 'dendrogram = "none",' ."\n";                 # Hides dendrogram
   print RSCRIPT 'Colv = "NA",' . "\n";                        # Turn off column sort
   print RSCRIPT 'Rowv = "NA")' . "\n";                        # Turn off row sort
   
   print RSCRIPT 'dev.off()';
close RSCRIPT;

system ("R CMD BATCH $HeatMapRScript");

system ("rm $PlotRScript $HeatMapRScript $OutPath/*.Rout $OutPath/Rplots.pdf");
print "Done!\n\n";

exit;


