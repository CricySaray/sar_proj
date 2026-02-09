#!/usr/bin/perl
# --------------------------
# author    : sar song
# date      : 2026/02/09 12:30:24 Monday
# label     : getInfo_sub
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This Perl script processes normal, gzip, or tar-compressed input files to count lines matching user-specified keywords, 
#             with the option to split the input file into separate output files based on these keywords. It supports custom prefixes, 
#             suffixes, and extensions for split filenames, includes robust error handling, and outputs formatted statistics of matched 
#             lines for each keyword and unmatched lines categorized as "other".
# return    : output file
# ref       : link url
# --------------------------
use strict;
use warnings;
use Getopt::Long;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Archive::Tar;
use File::Basename;

# --------------- Default Configuration Section (Editable Directly) ---------------
my $DEFAULT_SPLIT_FLAG    = 0;       # Default: do not split files, only count matching lines
my $DEFAULT_PREFIX        = '';      # Default prefix for split filenames
my $DEFAULT_SUFFIX        = '';      # Default suffix for split filenames
my $DEFAULT_EXTENSION     = 'txt';   # Default extension for split filenames
my $DEFAULT_OTHER_NAME    = 'other'; # Default category name for unmatched lines
my $DEFAULT_KEYWORDS      = 'DEFAULT_KEYWORD'; # Default keywords (space-separated)
my $DEFAULT_INPUT_FILE    = 'input.txt'; # Default input file path
# ---------------------------------------------------------------------------------

# Global variables to store parameters
my ($input_file, $keywords_str, $split_flag, $prefix, $suffix, $extension, $help);
my %file_handles;  # Store file handles for each keyword
my %count_stats;   # Store count of matched lines for each keyword
my @keywords;      # Store parsed keywords array

# Parse command line arguments (supports short and long formats)
GetOptions(
  'i|input=s'       => \$input_file,    # Input file path (optional)
  'k|keywords=s'    => \$keywords_str,  # Space-separated keywords (optional)
  's|split'         => \$split_flag,    # File split switch (optional)
  'p|prefix=s'      => \$prefix,        # Filename prefix (optional)
  'x|extension=s'   => \$extension,     # File extension (optional)
  'h|help'          => \$help,          # Help option (optional)
) or die "Error parsing command line arguments. Use -h or --help for usage.\n";

# Apply default values if parameters are not specified
$input_file = $DEFAULT_INPUT_FILE unless defined $input_file;
$split_flag = $DEFAULT_SPLIT_FLAG unless defined $split_flag;
$prefix     = $DEFAULT_PREFIX     unless defined $prefix;
$suffix     = $DEFAULT_SUFFIX     unless defined $suffix;
$extension  = $DEFAULT_EXTENSION  unless defined $extension;
$keywords_str = $DEFAULT_KEYWORDS unless defined $keywords_str;

# Print help information and exit if -h/--help is specified
if ($help) {
  print_help();
  exit 0;
}

# -------------------------- Core Error Handling --------------------------
# 1. Check if input file exists and is readable
die "Error: Input file '$input_file' does not exist or is not readable.\n" unless (-e $input_file && -r $input_file);
# 2. Split keywords and remove duplicates (avoid duplicate matching)
@keywords = split(/\s+/, $keywords_str);
@keywords = uniq(@keywords);
die "Error: No valid keywords after parsing. Please check your keyword format or set DEFAULT_KEYWORDS.\n" unless scalar @keywords;
# -------------------------------------------------------------------------

# Initialize statistics hash (all keywords + other set to 0)
$count_stats{$_} = 0 for @keywords;
$count_stats{$DEFAULT_OTHER_NAME} = 0;

# Open input file (supports normal, gzip, tar compressed files)
my $input_fh;
my $file_type = get_file_type($input_file);
if ($file_type eq 'gzip') {
  # Handle gzip compressed file
  $input_fh = IO::Uncompress::Gunzip->new($input_file)
    or die "Error opening gzip file '$input_file': $GunzipError\n";
} elsif ($file_type eq 'tar') {
  # Handle tar compressed file (read content of the first file)
  my $tar = Archive::Tar->new;
  $tar->read($input_file) or die "Error reading tar file '$input_file': " . Archive::Tar->error . "\n";
  my @tar_files = $tar->get_files;
  die "Error: Tar file '$input_file' is empty.\n" unless scalar @tar_files;
  my $tar_content = $tar_files[0]->get_content;
  open $input_fh, '<', \$tar_content or die "Error processing tar content: $!\n";
} else {
  # Handle normal file
  open $input_fh, '<', $input_file or die "Error opening input file '$input_file': $!\n";
}

# File split mode: initialize file handles for each keyword
if ($split_flag) {
  for my $kw (@keywords, $DEFAULT_OTHER_NAME) {
    my $filename = build_filename($kw, $prefix, $suffix, $extension);
    open my $fh, '>', $filename 
      or die "Error creating output file '$filename': $!\n";
    $file_handles{$kw} = $fh;
  }
}

# -------------------------- Core Logic: Process Line by Line --------------------------
while (my $line = <$input_fh>) {
  chomp $line;
  my $matched_kw = $DEFAULT_OTHER_NAME;  # Default to other category

  # Match the first hit keyword (avoid duplicate matching)
  for my $kw (@keywords) {
    if ($line =~ /\Q$kw\E/) {  # \Q escapes special characters to avoid regex conflicts
      $matched_kw = $kw;
      last;
    }
  }

  # Count matched lines
  $count_stats{$matched_kw}++;

  # File split mode: write to corresponding file
  if ($split_flag) {
    print {$file_handles{$matched_kw}} "$line\n" 
      or die "Error writing to file for keyword '$matched_kw': $!\n";
  }
}

# Close all file handles
close $input_fh or die "Error closing input file: $!\n";
for my $kw (keys %file_handles) {
  close $file_handles{$kw} or die "Error closing file for keyword '$kw': $!\n";
}

# -------------------------- Optimized Statistics Output with Left Alignment --------------------------
# Calculate maximum length of all keywords (including other) for dynamic alignment
my @all_categories = (@keywords, $DEFAULT_OTHER_NAME);
my $max_kw_length = 0;
for my $kw (@all_categories) {
  my $len = length($kw);
  $max_kw_length = $len if $len > $max_kw_length;
}
# Set fixed width for line count column (ensure number alignment)
my $count_col_width = 10;

# Print formatted statistics with left alignment
print "\n------------------------ Matching Statistics ------------------------\n";
for my $kw (@all_categories) {
  # Format: keyword (left-aligned, dynamic width) + count (left-aligned) + description
  printf "Keyword: %-*s | Matched Lines: %-*d\n", $max_kw_length, $kw, $count_col_width, $count_stats{$kw};
}
print "--------------------------------------------------------------------\n";

exit 0;

# -------------------------- Subroutine Definition Section --------------------------
# Subroutine 1: Print help information
sub print_help {
  my $script_name = basename($0);
  print <<"HELP";
Usage: $script_name [OPTIONS]

Description:
  This script processes a file (normal, gzip, or tar) and splits/statistic lines 
  based on user-specified keywords. It supports file splitting, custom filename 
  rules, and detailed statistics. All parameters are optional with default values.

Options:
  -i, --input FILE        (Optional) Path to the input file (normal/gzip/tar). Default: '$DEFAULT_INPUT_FILE'
  -k, --keywords STR     (Optional) Space-separated keywords for matching. Default: '$DEFAULT_KEYWORDS'
  -s, --split            (Optional) Enable file splitting (default: $DEFAULT_SPLIT_FLAG).
  -p, --prefix STR       (Optional) Prefix for split filenames (default: '$DEFAULT_PREFIX').
  -x, --extension STR    (Optional) Extension for split filenames (default: '$DEFAULT_EXTENSION').
  -h, --help             (Optional) Show this help message and exit.

Examples:
  1. Run with default settings (no parameters needed):
     $script_name

  2. Basic statistics (no splitting) with custom input file and keywords:
     $script_name -i input.log -k "ERROR WARN INFO"

  3. Split file with custom prefix and extension:
     $script_name -i data.txt -k "TOP_CRG MAIN_SUB PHY_2G" -s -p "split_" -x "log"

  4. Process a gzip-compressed file and split into files:
     $script_name -i data.gz -k "SUCCESS FAIL" -s -x "out"
HELP
}

# Subroutine 2: Get file type (normal/gzip/tar)
sub get_file_type {
  my $file = shift;
  if ($file =~ /\.gz$/) {
    return 'gzip';
  } elsif ($file =~ /\.tar$/) {
    return 'tar';
  } else {
    return 'normal';
  }
}

# Subroutine 3: Build filename for split files
sub build_filename {
  my ($kw, $prefix, $suffix, $ext) = @_;
  return $prefix . $kw . $suffix . '.' . $ext;
}

# Subroutine 4: Remove duplicates from array
sub uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}
