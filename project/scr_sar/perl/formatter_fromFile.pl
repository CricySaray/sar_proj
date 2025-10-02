#!/usr/bin/perl
# --------------------------
# author    : sar song
# date      : 2025/10/02 12:24:42 Thursday
# label     : format_sub
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : A Perl script that extracts a specific column from whitespace-separated files, formats entries using a custom string with the '<target>' placeholder, saves results 
#             to an output file, and supports command-line options like -i, -o, and debug mode.
# return    : processed output file
# ref       : link url
# --------------------------
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

# ==================================================
# DEFAULT CONFIGURATION - MODIFY THESE VALUES AS NEEDED
# ==================================================
my $DEFAULT_INPUT_FILE    = 'input.txt';   # Default path to the input file to process
my $DEFAULT_TARGET_COLUMN = 1;             # Default column number to extract (1-based index)
my $DEFAULT_FORMAT_STR    = 'highlight -index 1 <target>';    # Default format string with <target> placeholder
my $DEFAULT_OUTPUT_FILE   = 'output.txt';  # Default path for the output file
my $DEFAULT_DEBUG_MODE    = 0;             # Default debug mode (0 = disabled, 1 = enabled)
# ==================================================

# ==============================================
# 1. Define the core processing subroutine
# ==============================================
sub process_file {
  my ($input_file, $target_column, $format_str, $output_file, $debug) = @_;
  
  $input_file    ||= $DEFAULT_INPUT_FILE;
  $target_column ||= $DEFAULT_TARGET_COLUMN;
  $format_str    ||= $DEFAULT_FORMAT_STR;
  $output_file   ||= $DEFAULT_OUTPUT_FILE;
  $debug         ||= $DEFAULT_DEBUG_MODE;
  
  print "Debug: Received parameters:\n" if $debug;
  print "Debug: Input file: $input_file\n" if $debug;
  print "Debug: Target column: $target_column\n" if $debug;
  print "Debug: Format string: $format_str\n" if $debug;
  print "Debug: Output file: $output_file\n" if $debug;
  print "Debug: Debug mode: " . ($debug ? "enabled" : "disabled") . "\n\n" if $debug;
  
  if ($target_column !~ /^\d+$/ || $target_column < 1) {
    die "Error: Target column must be a positive integer. Provided value: $target_column\n";
  }
  
  if (index($format_str, '<target>') == -1) {
    die "Error: Format string must contain '<target>' placeholder. Provided string: $format_str\n";
  }
  
  unless (-e $input_file) {
    die "Error: Input file does not exist: $input_file\n";
  }
  
  unless (-r $input_file) {
    die "Error: Input file is not readable: $input_file\n";
  }
  
  my $input_fh;
  unless (open($input_fh, '<', $input_file)) {
    die "Error: Failed to open input file '$input_file': $!\n";
  }
  
  my @column_data;
  my $line_number = 0;
  
  while (my $line = <$input_fh>) {
    $line_number++;
    chomp $line;
    next if $line =~ /^\s*$/;
    
    my @columns = split(/\s+/, $line);
    if (scalar @columns < $target_column) {
      close $input_fh;
      die "Error: Line $line_number in '$input_file' has insufficient columns. Required: $target_column, Found: " . scalar(@columns) . "\n";
    }
    
    push @column_data, $columns[$target_column - 1];
    print "Debug: Line $line_number - Extracted value: $columns[$target_column - 1]\n" if $debug;
  }
  
  close $input_fh;
  
  if (scalar @column_data == 0) {
    die "Error: No valid data found in input file: $input_file\n";
  }
  
  print "\nDebug: Successfully extracted " . scalar(@column_data) . " entries from column $target_column\n" if $debug;
  
  my @formatted_data;
  foreach my $item (@column_data) {
    my $formatted = $format_str;
    $formatted =~ s/<target>/$item/g;
    push @formatted_data, $formatted;
    print "Debug: Formatted result: $formatted\n" if $debug;
  }
  
  my $output_fh;
  unless (open($output_fh, '>', $output_file)) {
    die "Error: Failed to open output file '$output_file' for writing: $!\n";
  }
  
  print $output_fh join("\n", @formatted_data) . "\n";
  close $output_fh;
  
  print "\nDebug: Processing completed. Output written to $output_file\n" if $debug;
  return scalar @formatted_data;
}

# ==============================================
# 2. Command line argument parsing
# ==============================================
my $input_file    = $DEFAULT_INPUT_FILE;
my $target_column = $DEFAULT_TARGET_COLUMN;
my $format_str    = $DEFAULT_FORMAT_STR;
my $output_file   = $DEFAULT_OUTPUT_FILE;
my $debug         = $DEFAULT_DEBUG_MODE;
my $help;

# Parse command line options (overrides defaults)
GetOptions(
  'i|input=s'   => \$input_file,    # -i or --input: input file path (string)
  'c|column=i'  => \$target_column, # -c or --column: target column number (integer)
  'f|format=s'  => \$format_str,    # -f or --format: format string with <target>
  'o|output=s'  => \$output_file,   # -o or --output: output file path (string)
  'debug'       => \$debug,         # --debug: enable debug mode (flag)
  'h|help'      => \$help,          # -h or --help: show help message
) or pod2usage(2); # Exit with error if options are invalid

# Show help documentation with examples when requested
pod2usage(-verbose => 2) if $help;  # 调整verbose级别以显示更多内容

# ==============================================
# 3. Execute processing and handle results
# ==============================================
eval {
  my $processed_count = process_file($input_file, $target_column, $format_str, $output_file, $debug);
  print "Successfully processed $processed_count entries. Output saved to: $output_file\n" unless $debug;
};

if ($@) {
  chomp $@;
  print "Processing failed: $@\n";
  exit 1;
}

exit 0;

# ==============================================
# 4. Help documentation
# ==============================================
__END__

=head1 NAME

file_formatter.pl - Extract specific column from file and format output

=head1 SYNOPSIS

file_formatter.pl [options]

 Options:
   -i, --input     Input file path (default: input.txt)
   -c, --column    Target column number (1-based, default: 1)
   -f, --format    Format string with '<target>' placeholder (default: <target>)
   -o, --output    Output file path (default: output.txt)
   --debug         Enable debug mode (print detailed logs)
   -h, --help      Show this help message

=head1 EXAMPLES

All examples use input file 'data.csv' with content:
  apple  100  red
  banana 200  yellow
  orange 300  orange

1. Basic format with prefix:
   Command: perl file_formatter.pl -i data.csv -c 1 -f "Fruit: <target>" -o out1.txt
   Output (out1.txt) contains:
     Fruit: apple
     Fruit: banana
     Fruit: orange

2. Format for command-line tools:
   Command: perl file_formatter.pl -i data.csv -c 2 -f "highlight -index 2 <target>" -o out2.txt
   Output (out2.txt) contains:
     highlight -index 2 100
     highlight -index 2 200
     highlight -index 2 300

3. Multiple placeholders:
   Command: perl file_formatter.pl -i data.csv -c 3 -f "<target> is color of <target>" -o out3.txt
   Output (out3.txt) contains:
     red is color of red
     yellow is color of yellow
     orange is color of orange

=head1 DESCRIPTION

This script extracts a specific column from a whitespace-separated file,
formats each entry using a custom string with '<target>' as placeholder for column values,
and writes results to an output file. Default values can be modified at the top of the script.

