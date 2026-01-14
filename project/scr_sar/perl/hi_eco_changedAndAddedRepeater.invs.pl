#!/usr/bin/perl
# --------------------------
# author    : sar song
# date      : 2025/07/19 16:33:12 Saturday
# label     : gui_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : select and highlight pins and inst with different colors on invs GUI according to eco script
# update    : 2025/07/19 19:16:50 Saturday
#             can specify color for between changed inst and added inst and term by -c(changed) and -a(added)
# ref       : link url
# --------------------------
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use File::Basename;

# Initialize option variables
my $changedInstColor = 36;
my $addedInstOfTermColor = 38;
my $help = 0;

# Process command-line options
GetOptions(
  'c=i' => \$changedInstColor,
  'a=i' => \$addedInstOfTermColor,
  'help|h'   => \$help
) or pod2usage(2);

# Display help information
pod2usage(1) if $help;

# Check positional arguments
my $input_file = shift @ARGV || pod2usage("Input filename is required for conversion\n");
my ($file, $dir, $suffix) = fileparse($input_file, qr/\.[^.]*/);
my $pure_basename = $file;
$pure_basename =~ s/$suffix$//;
my $new_pure_basename = "so_instAndPins_from_${pure_basename}";
my $new_filename = $new_pure_basename . $suffix;
my $new_path = $dir . $new_filename;
my $output_file = shift @ARGV || $new_path;

# Output option values
print "Changed Instance Color: $changedInstColor\n";
print "Added Instance of Terminal Color: $addedInstOfTermColor\n";
print "Input File: $input_file\n";
print "Output File: $output_file\n";

# Open files
open(my $in_fh, '<', $input_file) or die "Cannot open input file: '$input_file': $!";
open(my $out_fh, '>', $output_file) or die "Cannot open output file: '$output_file': $!";

# Process file content
while (my $line = <$in_fh>) {
  chomp $line;
  next if $line =~ /^\s*#/;  # Skip comment lines
  next unless $line =~ /ecoChangeCell|ecoAddRepeater|ecoDeleteRepeater/;
  print $out_fh "# $line\n";
  
  if ($line =~ /(ecoChangeCell|ecoDeleteRepeater)\s+(.*\s+)?-inst\s+(\S+)/) {
    my $instname = $3;
    $instname =~ s/[\{\}]//g;  # Remove braces
    print $out_fh "selectInst $instname\n";
    print $out_fh "highlight -index $changedInstColor $instname\n";
  }
  elsif ($line =~ /ecoAddRepeater\s+(.*\s+)?-term\s+(.*)(-(\w+).*)?$/) {
    my $pins = $2;
    if ($pins =~ /\{(.*?)\}/) {
      my $pin_content = $1;
      my @pin_list = split(/\s+/, $pin_content);
      foreach my $pin (@pin_list) {
        next if $pin eq '';
        print $out_fh "selectPin $pin\n";
        print $out_fh "highlight -index 6 $pin\n";
        my $instOfPin = substr($pin, 0, rindex($pin, '/')) if $pin =~ m!/!;
        print $out_fh "selectInst $instOfPin\n";
        print $out_fh "highlight -index $addedInstOfTermColor $instOfPin\n";
      }
    } else {
      print $out_fh "selectPin $pins\n";
      print $out_fh "highlight -index 6 $pins\n";
      my $instOfPin = substr($pins, 0, rindex($pins, '/')) if $pins =~ m!/!;
      print $out_fh "selectInst $instOfPin\n";
      print $out_fh "highlight -index $addedInstOfTermColor $instOfPin\n";
    }
  }
}

print $out_fh "puts \"color #$addedInstOfTermColor is used for added instances, color #$changedInstColor is used for changed instances. \"\n";
close($in_fh);
close($out_fh);

print "Success! Please view the generated TCL script: $output_file\n";
print "color #$addedInstOfTermColor is used for added instances, color #$changedInstColor is used for changed instances. \n";

__END__

=head1 NAME

script.pl - Process ECO scripts and generate TCL highlighting commands

=head1 SYNOPSIS

script.pl [options] input_file [output_file]

  Options:
    --c N         Highlight color index for changed instances (default: 36)
    --a N         Highlight color index for added instances (default: 38)
    --help, -h    Display this help message

=head1 DESCRIPTION

This script processes ECO scripts and generates TCL commands to highlight specific 
pins and instances in the GUI.

=head1 OPTIONS

=over 4

=item B<--c N>

Color index for highlighting instances modified by ecoChangeCell/ecoDeleteRepeater.

=item B<--a N>

Color index for highlighting instances associated with ecoAddRepeater terms.

=item B<--help, -h>

Display help information and exit.

=back

=head1 ARGUMENTS

=over 4

=item B<input_file>

Required. Input ECO script file.

=item B<output_file>

Optional. Output TCL script file. Defaults to "so_instAndPins_from_<input_file>".

=back

=cut
