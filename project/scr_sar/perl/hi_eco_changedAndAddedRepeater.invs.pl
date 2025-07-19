#!/usr/bin/perl
# --------------------------
# author    : sar song
# date      : 2025/07/19 16:33:12 Saturday
# label     : gui_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : select and highlight pins and inst with different colors on invs GUI according to eco script
# ref       : link url
# --------------------------
use strict;
use warnings;

my ($input_file, $output_file) = ("", "");
if (@ARGV == 2) {
  ($input_file, $output_file) = @ARGV;
} elsif (@ARGV == 1) {
  $input_file = $ARGV[0];
  $output_file = "so_instAndPins_from_${input_file}";
} else {
  die "usage: $0 inputfile [outputfile]\n";
}
open(my $in_fh, '<', $input_file) or die "can't open input file: '$input_file': $!";
open(my $out_fh, '>', $output_file) or die "can't open output file: '$output_file': $!";

while (my $line = <$in_fh>) {
  chomp $line;
  next if $line =~ /^\s*#/;  # remove comment lines
  next unless $line =~ /ecoChangeCell|ecoAddRepeater|ecoDeleteRepeater/;
  print $out_fh "# $line\n";
  if ($line =~ /(ecoChangeCell|ecoDeleteRepeater)\s+-inst\s+(\S+)/) {
    my $instname = $2;
    $instname =~ s/[\{\}]//g;  # remove { and  }
    print $out_fh "selectInst $instname\n";
    print $out_fh "highlight -index 36 $instname\n";
  }
  elsif ($line =~ /ecoAddRepeater\s+-term\s+(.*)(-(\w+).*)?$/) {
    my $pins = $1;
    if ($pins =~ /\{(.*?)\}/) {
      my $pin_content = $1;
      my @pin_list = split(/\s+/, $pin_content);
      foreach my $pin (@pin_list) {
        next if $pin eq '';
        print $out_fh "selectPin $pin\n";
        print $out_fh "highlight -index 6 $pin\n";
        print $out_fh "selectInst [regsub \{/[^/]+\$\} $pin \"\" ]\n";
        print $out_fh "highlight -index 38 [regsub \{/[^/]+\$\} $pin \"\" ]\n";
      }
    } 
    else {
      print $out_fh "pin: $pins\n";
    }
  }
}
print $out_fh "puts \"Blue is the inst of addRepeater, yellow is the inst of changeCell.\"\n";
close($in_fh);
close($out_fh);

print "succuss! please view tcl script: $output_file\n";
print "Blue is the inst of addRepeater, yellow is the inst of changeCell.\n";
