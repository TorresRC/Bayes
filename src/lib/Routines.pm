#!/usr/bin/perl -w
#################################################################################
#Routines colecction                                                            #
#                                                                               #
#Programmer:    Roberto C. Torres                                               #
#e-mail:        torres.roberto.c@gmail.com                                      #
#################################################################################
use strict;

#################################################################################

#################################################################################
#ReadFile subrutine reads a whole file and puts it in an array
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

#################################################################################
sub log2{
   my $x = shift;
   return log($x)/log(2);
}

#################################################################################
sub log10{
   my $x = shift;
   return log($x)/log(10);
}

1;