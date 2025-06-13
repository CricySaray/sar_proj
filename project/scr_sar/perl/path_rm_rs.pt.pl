#!/bin/perl -w
use strict;
####################################
# author     : sar
# descrip    : sort path block in PT report_timing rpt.
# date       : Wen Jan 15 16:40:19 CST 2025
# ref				 : https://www.notion.so/path_rm_rs-pt-pl-pt_rpt_timing_path_reserve_and_remove-pl-17ba8d0ab3d880709922d069dda3a077?source=copy_link
####################################

# Below are variables you can configure:
my $reserveExp = '';
my $removeExp  = '';
my $splitFlag  = 1;
my $canCovered = 1;

# !!! - DO NOT TOUCH CONTENT BELOW - !!! #
# INTEGRITY CHECK
die "\nHelp: arg1 is input file, arg2 is output file
     1. rs == '' & rm == '' : all path can be printed with text 'PATH'.
     2. rs != '' & rm != '' : rs has a higher priority.
     3. rs != '' & rm == '' : path that meets rs rule will be reserved.
     4. rs == '' & rm != '' : path that meets rm rule will be removed.
     5. \$splitFlag variable switch can be used to split files according to conditions.
     6. \$canCovered variable switch control if existed files be covered.\n\n" if !defined($ARGV[0]) && !defined($ARGV[1]);
die "Error : input file not exist!!!\n" if !(-e $ARGV[0]);
die "Warn : Don't specify same file name between input and output file!!!\n" if $ARGV[0] eq $ARGV[1];
die "Warn : File \"$ARGV[1]\" has existed, if you hope cover it, please turn on switch \'\$canCovered\'\n" if (-e $ARGV[1]) && !$canCovered;
open my $fi, '<', $ARGV[0] or die "Error: Please write input file!!!\n";
open my $fo, '>', $ARGV[1] or die "Error: Please write output file!!!\n";
open my $fo1, '>', "$ARGV[1]_subsidiary";

# LOGIC
my @pathBlock;
my ($reportFlag, $removeFlag, $reserveFlag, $i, $j) = (0, 0, 0, 0, 0);
while (<$fi>) {
  if (/Report/../Date/) {
    if (!$reportFlag) {
      print $fo "*" x 40, "\n" if /Report/;
      print $fo1 "*" x 40, "\n" if /Report/;
      print $fo $_;
      print $fo1 $_;
      print $fo "*" x 40, "\n\n" if /Date/;
      print $fo1 "*" x 40, "\n\n" if /Date/;
      $reportFlag = 1 if /Date/;
    }
  }
  if (/Startpoint/../slack \(.*\)|\(Path is unconstrained\)/) {
    push @pathBlock, "$_";
    # IMPORTANT logic !!!
    $reserveFlag = 1 if ($reserveExp ne '') && m!$reserveExp!;
    $removeFlag = 1 if ($reserveExp ne '') || (m!$removeExp! && ($removeExp ne ''));
  }
  if (/slack \(.*\)|\(Path is unconstrained\)/) {
    #print $reserveFlag; #debug
    #print $removeFlag;  #debug
    if ($reserveFlag || !$removeFlag) {
      print $fo "\nPATH ", ++$i, ":\n\n";
      print $fo " @pathBlock\n";
    } elsif ($splitFlag) {
      print $fo1 "\nPATH ", ++$j, ":\n\n";
      print $fo1 " @pathBlock\n";
    }
    @pathBlock = ();
    ($removeFlag, $reserveFlag) = (0, 0);
  }
}
print $fo1 "No PATH can be filtered!!!" if !$j;
print $fo "No PATH can be filtered!!!" if !$i;
close $fo1;
close $fo; close $fi;
system "rm $ARGV[1]_subsidiary" if !$splitFlag;
