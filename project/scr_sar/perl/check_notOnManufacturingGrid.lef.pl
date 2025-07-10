#!/usr/bin/perl -w
use strict;
use warnings;

open my $fi, '<', $ARGV[0] or die "ERROR: Cannot open input!!!";
open my $fo, '>', $ARGV[1] or die "ERROR: Cannot open output!!!";

my @errorBlock;
my ($in_block, $i);
# this var $ignoreExp can't be empty!!! It will can't pick out any ERROR although original file has many ERRORS.
#my $ignoreExp = '\(TCLCMD-917\)|\(IMPLF-40\)|\(TA-1015\)|\(TCLCMD-927\)|\(IMPFP-3415\)';
my $ignoreExp = 'empty_sar';
my $pickoutExp = '\*\*ERROR';

sub arrayExp {
	my ($matchFlag, $ignoreFlag) = (0, 1);
	for (@_) {
		$matchFlag = 1 if /$pickoutExp/;
		next;
	}
	for (@_) {
		$ignoreFlag = 0 if /$ignoreExp/;
		next;
	}
	print $fo "EOR ", ++$i, ":\n\n @_\n" if $matchFlag && $ignoreFlag;
}
while (<$fi>) {
	if (/PIN|OBS/) {
		&arrayExp(@errorBlock);
		@errorBlock = ();
		$in_block = 1;
	}
	push @errorBlock, $_ if $in_block;
}
#last block 
&arrayExp(@errorBlock) if @errorBlock;
print $fo "No matched RECT that is not on manufacturing grid in file : $ARGV[0]" if !$i;
close $fi; close $fo;
