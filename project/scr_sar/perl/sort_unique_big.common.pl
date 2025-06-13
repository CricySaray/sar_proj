#!/usr/bin/perl -w
################
# author : yzq
# date   : 2025/01/07
# descrip: unique, sort and take the big one of value
# ref		 : https://www.notion.so/sort_unique_big-pl-173a8d0ab3d88062929ef3c325cc96f3?source=copy_link
################
use strict;

my %pathHash;
my @line;

open my $fileIn, '<', "$ARGV[0]" or die "Can not read! $!\n";
while (<$fileIn>) {
	chomp;
	@line = split /\s+/; # split by backspace
	print "#### Warn: format error at <$ARGV[0]> line $..\n", next if @line != 2;
	if (exists $pathHash{$line[0]}) {
		@{$pathHash{$line[0]}}[0] = $line[1] if $pathHash{$line[0]}->[0] > $line[1];
	} else { $pathHash{$line[0]} = [$line[1]];}
}
close $fileIn;

open my $fileOut, '>', "sorted_$ARGV[0]" or die "Can not write:$!\n";
print $fileOut map {"$_ $pathHash{$_}->[0]\n"} sort {$pathHash{$a}->[0] <=> $pathHash{$b}->[0]} keys %pathHash;
close $fileOut;
