#!/usr/bin/perl
use strict;
use warnings;

my $input_file = 'vio_summary.rpt';
my $output_file = 'vio_summary1.csv';

open(my $in,'<',$input_file) or die "$input_file ERROR!";
open(my $out,'<',$output_file) or die "$output_file ERROR!";

while (my $line = <$in>) {
	chomp $line;
	my @fields = split /\s+|,\s*/, $line
	print $out join(',', map {s/"/""/g; $_ } @fields), "\n";
}
close $in;
close $out;
print "finish ! \n";
