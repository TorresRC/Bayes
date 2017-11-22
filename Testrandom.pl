#!/usr/local/bin/perl -w

use strict;
use warnings;
# Given an array of weights, chooses an array element
# pseudo-randomly based on those weights.
#
# For example, given (1, 1.25, 3.6, 2)
# The chance that the 2nd element will be chosen is
# 3.6 times as large as the chance that the 0th element
# will be chosen
#
sub choose_weighted
{
    my @weights = @{$_[0]};
    my $acc = 0;
    my @acc_arr;

    foreach (@weights)
    {
    $acc += $_;
    push(@acc_arr, $acc);
    }

    my $rand_val = $acc * rand;

    my $i = 0;

    ++$i while ($acc_arr[$i] <= $rand_val);

    return $i;
}



# Test code - just to prove that we get reasonable
# distributions
#
# With the test array used below, $count[3] obviously
# should be about twice as large as $count[1], etc...
#
my @ss = (1.75, 2, 3.6, 4);
my @count = (0, 0, 0, 0);

for (my $i = 0; $i < 500000; ++$i)
{
    ++$count[choose_weighted(\@ss)];
}

$, = "\n";
print @count;