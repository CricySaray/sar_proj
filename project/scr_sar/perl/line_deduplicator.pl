#!/usr/bin/perl -w
# --------------------------
# author    : sar song
# date      : 2026/02/09 15:20:16 Monday
# label     : format_sub
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This Perl script deduplicates rows based on a specified column while keeping the row with the larger or 
#             smaller value in another designated column, supporting both plain text and gzipped files. It features flexible 
#             command-line configuration for key parameters, comprehensive error validation to prevent runtime issues, and 
#             a debug mode for tracking processing details.
# return    : output file
# ref       : link url
# --------------------------
use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

# -------------------------- Default Configuration (EASY TO MODIFY) --------------------------
my $DEFAULT_INPUT_FILE   = '';      # Input file path (required, no default)
my $DEFAULT_DEDUP_COL    = 1;       # Column to deduplicate (1-based/index: 1, end, end-1)
my $DEFAULT_COMPARE_COL  = 'end-1';       # Column for numeric comparison (1-based/index: 1, end, end-1)
my $DEFAULT_KEEP         = 'smaller';# Keep 'larger' or 'smaller' value (only these two options)
my $DEFAULT_DEBUG        = 0;       # Debug mode (0=disabled, 1=enabled)
my $DEFAULT_OUTPUT_FILE  = '';      # Default output file (empty = auto add sorted_ prefix)
my $DEFAULT_SUMMARY      = 1;       # Summary mode (0=disabled, 1=enabled)
# -------------------------------------------------------------------------------------------

# Initialize parameters with default values
my $input_file   = $DEFAULT_INPUT_FILE;
my $dedup_col    = $DEFAULT_DEDUP_COL;
my $compare_col  = $DEFAULT_COMPARE_COL;
my $keep         = $DEFAULT_KEEP;
my $debug        = $DEFAULT_DEBUG;
my $output_file  = $DEFAULT_OUTPUT_FILE;
my $summary      = $DEFAULT_SUMMARY;
my $help         = 0;
my $script_name  = basename($0);    # Auto get script filename

# Parse command line options (long + short)
GetOptions(
  'input|i=s'        => \$input_file,
  'dedup-col|d=s'    => \$dedup_col,  # String to support end/end-N
  'compare-col|c=s'  => \$compare_col,# String to support end/end-N
  'keep|k=s'         => \$keep,
  'debug|g'          => \$debug,
  'output|o=s'       => \$output_file,
  'summary|s'        => \$summary,
  'help|h'           => \$help,
) or die "Error: Invalid command line options! Use --help for usage.\n";

# Print help and exit if requested
if ($help) {
  print_help();
}

# -------------------------- Parameter Validation --------------------------
# Check input file (mandatory via --input/-i)
unless (defined $input_file && $input_file ne '' && -e $input_file) {
  die "Error: Input file must be specified with --input/-i and must exist!\nUse --help for usage examples.\n";
}

# Validate keep parameter (only 'larger' or 'smaller')
unless ($keep eq 'larger' || $keep eq 'smaller') {
  die "Error: --keep must be 'larger' or 'smaller' (current: $keep)!\n";
}

# Validate column format (basic check before file processing)
unless (is_valid_column_format($dedup_col)) {
  die "Error: Invalid dedup column format '$dedup_col' (supported: positive integer, end, end-N)\n";
}
unless (is_valid_column_format($compare_col)) {
  die "Error: Invalid compare column format '$compare_col' (supported: positive integer, end, end-N)\n";
}

# -------------------------- Output File Configuration --------------------------
# Auto generate output file if not specified
if ($output_file eq '') {
  my ($file_name, $file_dir, $file_ext) = fileparse($input_file, qr/\.[^.]*/);
  $output_file = $file_dir . "sorted_" . $file_name . $file_ext;
}
if ($debug) {
  print "Output file set to: $output_file\n";
}

# -------------------------- Debug Info Print --------------------------
if ($debug) {
  print "=== DEBUG MODE ENABLED ===\n";
  print "Configuration:\n";
  print "  Script Name: $script_name\n";
  print "  Input File (specified via --input): $input_file\n";
  print "  Dedup Column (raw): $dedup_col (supports 1-based/end/end-N)\n";
  print "  Compare Column (raw): $compare_col (supports 1-based/end/end-N)\n";
  print "  Keep: $keep value\n";
  print "  Output File: $output_file\n";
  print "  Summary Mode: " . ($summary ? "Enabled" : "Disabled") . "\n";
  print "==========================\n\n";
}

# -------------------------- File Type Check & Handling --------------------------
my $fh;
my $is_gzipped = 0;

# Check file type via magic bytes (gzip: 0x1f 0x8b) instead of extension
open my $temp_fh, '<:raw', $input_file or die "Error opening $input_file for type detection: $!\n";
my $magic_bytes;
read($temp_fh, $magic_bytes, 2); # Read first 2 bytes for magic number check
close $temp_fh;

# Gzip magic number: 0x1f 0x8b (decimal 31 139)
if (ord(substr($magic_bytes, 0, 1)) == 31 && ord(substr($magic_bytes, 1, 1)) == 139) {
  $is_gzipped = 1;
}

# Debug: print file type detection result
if ($debug) {
  print "Detected file type via magic bytes: " . ($is_gzipped ? "Gzipped compressed file" : "Plain text file") . "\n";
}

# Open gzipped file
if ($is_gzipped) {
  if ($debug) {
    print "File type: Gzipped compressed file -> Using IO::Uncompress::Gunzip to read\n";
  }
  $fh = IO::Uncompress::Gunzip->new($input_file) 
    or die "Error opening gzipped file $input_file: $GunzipError\n";
} 
# Open plain text file (non-gzipped)
else {
  if ($debug) {
    print "File type: Plain text file -> Using standard file read\n";
  }
  open $fh, '<', $input_file 
    or die "Error opening plain text file $input_file: $!\n";
}

# -------------------------- Data Processing --------------------------
my %data_hash;
my $total_lines = 0;          # Total lines processed
my $skipped_lines = 0;        # Lines skipped (empty or insufficient columns)

while (my $line = <$fh>) {
  chomp $line;
  # Remove leading/trailing whitespace (spaces/tabs) from the entire line first
  $line =~ s/^\s+|\s+$//g; 
  $total_lines++;
  
  # Skip empty lines (after trimming whitespace)
  if ($line eq '') {
    $skipped_lines++;
    next;
  }

  my $line_num = $.; # Current line number
  my @cols = split /\s+/, $line; # Split by one or more spaces/tabs
  
  # Convert cols to 1-based index (insert empty element at position 0)
  unshift @cols, '';
  my $total_cols = scalar(@cols) - 1; # Actual column count (exclude empty 0th element)

  # Parse column indices (resolve to 1-based index)
  my ($dedup_col_idx, $compare_col_idx);
  eval {
    $dedup_col_idx = parse_column_index($dedup_col, $total_cols, $line_num);
    $compare_col_idx = parse_column_index($compare_col, $total_cols, $line_num);
  };
  if ($@) {
    die $@; # Die on column index error
  }

  # Extract key and comparison value (use 1-based index directly)
  my $dedup_key = $cols[$dedup_col_idx];
  my $compare_val = $cols[$compare_col_idx];

  # Validate comparison value is numeric (die on invalid value)
  unless ($compare_val =~ /^[-+]?\d+(\.\d+)?$/) {
    die "Error: Line $line_num, compare column $compare_col (resolved to 1-based index $compare_col_idx) value '$compare_val' is not numeric! Aborting process.\n";
  }

  if ($debug) {
    print "Processing Line $line_num: Total cols=$total_cols\n";
    print "  Original line (after trimming): '$line'\n"; # Debug: show trimmed line
    print "  Dedup column: $dedup_col (resolved to 1-based index $dedup_col_idx) -> Key='$dedup_key'\n";
    print "  Compare column: $compare_col (resolved to 1-based index $compare_col_idx) -> Value='$compare_val'\n";
  }

  # Update hash: keep larger/smaller value (store full line and compare value)
  if (exists $data_hash{$dedup_key}) {
    my $existing_val = $data_hash{$dedup_key}->{compare_val};
    if ($keep eq 'larger') {
      if ($compare_val > $existing_val) {
        $data_hash{$dedup_key} = {
          compare_val => $compare_val,
          line        => $line
        };
        $debug && print "  Updated $dedup_key: $existing_val -> $compare_val (keep larger)\n";
      } else {
        $debug && print "  Skipped update: $existing_val >= $compare_val (keep larger)\n";
      }
    } else { # keep smaller
      if ($compare_val < $existing_val) {
        $data_hash{$dedup_key} = {
          compare_val => $compare_val,
          line        => $line
        };
        $debug && print "  Updated $dedup_key: $existing_val -> $compare_val (keep smaller)\n";
      } else {
        $debug && print "  Skipped update: $existing_val <= $compare_val (keep smaller)\n";
      }
    }
  } else {
    $data_hash{$dedup_key} = {
      compare_val => $compare_val,
      line        => $line
    };
    $debug && print "  Added new key $dedup_key with value $compare_val\n";
  }
}
close $fh;

# -------------------------- Output Result --------------------------
if ($debug) {
  print "\nWriting results to $output_file...\n";
}

open my $out_fh, '>', $output_file 
  or die "Error opening output file $output_file: $!\n";

# Sort by comparison value (numeric) and write full line
foreach my $key (sort { $data_hash{$a}->{compare_val} <=> $data_hash{$b}->{compare_val} } keys %data_hash) {
  my $output_line = $data_hash{$key}->{line} . "\n";
  print $out_fh $output_line;
  $debug && print "  Wrote: $output_line";
}
close $out_fh;

# -------------------------- Summary Print --------------------------
if ($summary) {
  my $kept_lines = scalar keys %data_hash;
  print "\n=== PROCESS SUMMARY ===\n";
  print "  Total lines processed: $total_lines\n";
  print "  Lines skipped (empty/insufficient columns): $skipped_lines\n";
  print "  Lines kept after deduplication: $kept_lines\n";
  print "  Input file: $input_file\n";
  print "  Output file: $output_file\n";
  print "========================\n";
}

if ($debug) {
  print "\n=== Processing Complete ===\nOutput file: $output_file\n";
}

# -------------------------- Subroutines --------------------------
# Validate column format (basic check: number, end, end-N)
sub is_valid_column_format {
  my ($col_str) = @_;
  return 1 if $col_str =~ /^\d+$/;          # Numeric (1,2,3...)
  return 1 if $col_str =~ /^end(?:-\d+)?$/; # end or end-N (end-1, end-2...)
  return 0;
}

# Parse column index (resolve end/end-N to actual 1-based number)
sub parse_column_index {
  my ($col_str, $total_cols, $line_num) = @_;
  my $col_idx; # 1-based index to return
  
  # Handle numeric index (1-based, direct use)
  if ($col_str =~ /^\d+$/) {
    $col_idx = $col_str;
  }
  # Handle end-based index (end = last column (1-based: total_cols), end-1 = second last, etc.)
  elsif ($col_str =~ /^end(?:-(\d+))?$/) {
    my $offset = $1 || 0;
    $col_idx = $total_cols - $offset;
  }
  # Invalid format (should be caught by is_valid_column_format earlier)
  else {
    die "Error: Invalid column format '$col_str' (supported: positive integer, end, end-N)\n";
  }
  
  # Check if column index is valid (1-based range: >=1 and <= total_cols)
  if ($col_idx < 1 || $col_idx > $total_cols) {
    die "Error: Line $line_num has only $total_cols columns\n  Cannot access column '$col_str' (resolved to 1-based index $col_idx)\n";
  }
  
  return $col_idx;
}

# Print help message
sub print_help {
  print <<"HELP";
Usage: perl $script_name [OPTIONS]

Description:
  Deduplicate rows based on a specified column while keeping the full row with larger/smaller value in another column,
  support plain text and gzipped (.gz) files, with strict input validation and flexible configuration.
  Column index supports 1-based number (1,2,3...), end (last column), end-N (N=offset, e.g., end-1 = second last column).
  Automatically trims leading/trailing whitespace (spaces/tabs) from each line and splits columns by one or more spaces/tabs.

Mandatory Option:
  -i, --input FILE       Path to input file (plain text or gzipped .gz, no default - MUST specify)

Configuration Options:
  -d, --dedup-col STR     Column to deduplicate (format: 1/end/end-N, default: $DEFAULT_DEDUP_COL)
  -c, --compare-col STR   Column for numeric comparison (format: 1/end/end-N, default: $DEFAULT_COMPARE_COL)
  -k, --keep STR          Keep 'larger' or 'smaller' value (default: $DEFAULT_KEEP)

Output/Logging Options:
  -o, --output FILE       Specify output file path (default: add 'sorted_' prefix to input file)
  -g, --debug             Enable debug mode (print detailed processing logs, default: off)
  -s, --summary           Enable summary mode (print process statistics, default: off)
  -h, --help              Print this help message and exit

Examples:
  1. Basic usage (plain text file, default config):
     perl $script_name -i data.txt

  2. Gzipped file + custom columns + keep smaller + specify output:
     perl $script_name -i metrics.gz -d end -c end-1 -k smaller -o /tmp/result.txt

  3. Debug + summary + custom columns (dedup col 2, compare last column):
     perl $script_name -i access.log -d 2 -c end --debug --summary
HELP
  exit 0;
}
