#!/usr/bin/perl -w
####################################
# author     : sar
# descrip    : pick out the ERROR text block in invs logv file.
# date       : Wen Jan 15 16:40:19 CST 2025
# ref				 : https://www.notion.so/invs_logv_ERROR_pick_out-pl-1aca8d0ab3d8801da4c7cfee9103a477?source=copy_link
####################################
use strict;
use warnings;

open my $fi, '<', $ARGV[0] or die "ERROR: Cannot open input!!!";
open my $fo, '>', $ARGV[1] or die "ERROR: Cannot open output!!!";

my @errorBlock;
my ($in_block, $i);
my $ignoreExp = '\(TCLCMD-917\)|\(IMPLF-40\)|\(TA-1015\)|\(TCLCMD-927\)|\(IMPFP-3415\)';

sub arrayExp {
	my ($matchFlag, $ignoreFlag) = (0, 1);
	for (@_) {
		$matchFlag = 1 if /\*\*ERROR/;
		next;
	}
	for (@_) {
		$ignoreFlag = 0 if /$ignoreExp/;
		next;
	}
	print $fo "EOR ", ++$i, ":\n\n @_\n" if $matchFlag && $ignoreFlag;
}
while (<$fi>) {
	if (/<CMD>/) {
		&arrayExp(@errorBlock);
		@errorBlock = ();
		$in_block = 1;
	}
	push @errorBlock, $_ if $in_block;
}
#last block 
&arrayExp(@errorBlock) if @errorBlock;
print $fo "No matched ERROR in file : $ARGV[0]" if !$i;
close $fi; close $fo;
