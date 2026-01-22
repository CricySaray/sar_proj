#!/usr/bin/perl -w
# --------------------------
# from      : yzq
# date      : 2025/07/11 20:03:11 Friday
# label     : task_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : Fix the setup based on the rpt. It has an automatic path deduplication function, so there will be 
#             no repeated VT replacement. It can merge the rpts of all views into a single file and fix them all at once, which saves time.
# ref       : link url
# --------------------------
use strict;
use List::Util qw(sum min max);

my $promptERROR = "songERROR";
if ("" eq $ARGV[0] || "" eq $ARGV[1]) { print "$promptERROR : no <file> and <suffix> arguments specified.\nUsage: > perl $0 xxx_aon2aon_detail.rpt 121115\n";}
my (%instHash, @pathInfo, %pathHash, $endPt);
my ($i, $pathFlag) = (0, 0);

open my $fi, '<', $ARGV[0];
open my $fo, '>', "fix_setup_$ARGV[1].tcl";
open my $fo2, '>', "fail_$ARGV[1].list";

while (<$fi>) {
  if (/Point/../data arrival time/) {
  #push @pathInfo, [$i, $2, $3] if /(\S+)\/(?:ZN?|CO|Q) \((\S+?BWP\S+?(?<!ULVT))\).* (\S+) &/;
    push @pathInfo, [$i, $2, $3] if /(\S+)\/(?:O?|CO|Q) \((\S+?X\d\+\S*?(?<!AL9))\).* (\S+) &/;
    $endPt = $1 if /(\S+?\/\S+)/;
    $pathFlag = 1 if /data arrival time/;
  }
  if ($pathFlag) {
    next if !/slack/;
    push @pathInfo, $1 if /slack \(.* (\S+)$/;
    $endPt .= "_nworst$i", $i += 1 if exists $pathHash{$endPt};
    $pathHash{$endPt} = [@pathInfo];
    @pathInfo = ();
    $pathFlag = 0; 
  }
}
close $fi;
print $fo "setEcoMode -reset\nsetEcoMode -batchMode true -updateTiming false -refinePlace false -honorDontTouch false -honorDontUse false -honorFixedNetWire false -honorFixedStatus false\n";

my ($arrCnt, $slack, $lvlNum);
foreach my $key (keys %pathHash) {
  $arrCnt = $#{$pathHash{$key}}; $slack = $pathHash{$key}->[$arrCnt];
  if (!$arrCnt) {print $fo2 "$slack $key\n"; next}
  if ($slack >= -0.01) {
    $lvlNum = 2; 
  } elsif ($slack >= -0.02) {
    $lvlNum = 3;
  } elsif ($slack >= -0.03) {
    $lvlNum = 4; 
  } elsif ($slack >= -0.04) {
    $lvlNum = 5; 
  } elsif ($slack >= -0.05) {
    $lvlNum = 6; 
  } elsif ($slack >= -0.06) {
    $lvlNum = 7; 
  } elsif ($slack >= -0.07) {
    $lvlNum = 8; 
  } elsif ($slack >= -0.08) {
    $lvlNum = 9; 
  } elsif ($slack >= -0.09) {
    $lvlNum = 10; 
  } elsif ($slack >= -0.10) {
    $lvlNum = 11; 
  } else {
    $lvlNum = 100; 
  }
  $lvlNum = min($arrCnt, $lvlNum);
  print $fo "\n# $slack avail: $arrCnt  actual: $lvlNum   $key\n";
  for my $idx (1..$lvlNum) {
    my ($inst, $refOrg, $delay) = @{$pathHash{$key}->[$arrCnt-$idx]}[0,1,2];
    $inst =~ s/$ARGV[2]\/// if defined $ARGV[2];
    my $refNew = $refOrg;
    if (exists $instHash{$inst}) {
      if ($delay > adb($slack) * 2) {
        print $fo "#Already sized before and should be enough, stop. ($refOrg $delay $inst)\n";
        last;
      } else {
        print $fo "#Already sized before but maybe not enough, continue. ($refOrg $delay $inst)\n";
        next;
      }
    } else {
      $instHash{$inst} = $delay; 
    }
    #$refNew =~ s/CPDLVT$/CPDULVT/; $refNew =~ s/CPD$/CPDLVT/;
    $refNew =~ s/AR9$/AL9/;
    if ($delay > abs($slack) * 2) {
      print $fo "ecoChangeCell -inst $inst -cell $refNew; #($delay $refOrg) (Enough, stopped)\n";
      last; 
    } else {
      print $fo "ecoChangeCell -inst $inst -cell $refNew; #($delay $refOrg)\n"; 
    }
  }
}
print $fo "\nsetEcoMode -reset\n";
close $fo; close $fo2;
