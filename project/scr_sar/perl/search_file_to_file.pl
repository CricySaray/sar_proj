#!/usr/bin/perl
# --------------------------
# author    : sar song
# date      : 2025/12/26 18:28:10 Friday
# label     : getInfo_sub
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This Perl script searches for specified terms from a dedicated search file within a target file (supporting .gz/.bz2/.xz 
#             compressed files) and tracks the line numbers of all matching content.
#             Results are saved to a user-defined output file, where each search term is listed on a line followed by its matched line 
#             numbers (or "noMatchedLineNumber" if no matches exist).
#             The search file requires one non-empty term per line (no internal whitespace, leading/trailing whitespace is ignored), while 
#             the target file has no strict line format rules and can be plain text or compressed.
# return    : output file
# ref       : link url
# --------------------------
use strict;
use warnings;
use Getopt::Long;
use File::Basename;

# ========================== DEFAULT CONFIGURATION (EASY TO MODIFY) ==========================
# All options have default values (user can edit here directly)
my $DEFAULT_SEARCH_FILE = './search_terms.txt';  # Default search terms file
my $DEFAULT_TARGET_FILE = './target.txt';        # Default target file to search
my $DEFAULT_OUTPUT_FILE = './results.txt';       # Default output file
my $DEFAULT_DEBUG       = 0;                     # Debug mode off by default (0=off, 1=on)
my $DEFAULT_HELP        = 0;                     # Help mode off by default
my $DEFAULT_USE_REGEX   = 0;                     # Wildcard mode by default (0=wildcard, 1=regex)
# ===========================================================================================

# Global variables for command line options (initialized with default values)
# 【修正点】Perl不支持my()列表内直接赋值，改为逐个声明并赋值（正确语法）
my $search_file = $DEFAULT_SEARCH_FILE;
my $target_file = $DEFAULT_TARGET_FILE;
my $output_file = $DEFAULT_OUTPUT_FILE;
my $debug       = $DEFAULT_DEBUG;
my $help        = $DEFAULT_HELP;
my $use_regex   = $DEFAULT_USE_REGEX;

# Parse command line options (values passed via CLI override defaults)
GetOptions(
  'searchfile|s=s' => \$search_file,  # File containing search terms
  'targetfile|t=s' => \$target_file,  # File to be searched
  'output|o=s'     => \$output_file,  # Output file path
  'debug|d'        => \$debug,        # Enable debug mode
  'help|h'         => \$help,         # Show help message
  'regex|r'        => \$use_regex     # Enable regex matching (default: wildcard)
) or die "Error in command line arguments. Use -h/--help for usage.\n";

# Show help and exit if requested
if ($help) {
  print_help();
  exit 0;
}

# Validate file accessibility (no more mandatory option check, since defaults exist)
validate_arguments();

# Main execution flow
main();

###########################################################################
# Subroutine: print_help - Display help information with usage examples
###########################################################################
sub print_help {
  my $script_name = basename($0);
  print <<"HELP";
Usage: $script_name [OPTIONS]

Description:
  This script searches each term from the search file in the target file,
  records matched line numbers, and writes results to the output file.
  All options are optional (default values are set at the top of the script).

Default Values (can be edited in script header):
  - Search file: $DEFAULT_SEARCH_FILE
  - Target file: $DEFAULT_TARGET_FILE
  - Output file: $DEFAULT_OUTPUT_FILE
  - Debug mode:  $DEFAULT_DEBUG (0=off, 1=on)
  - Regex mode:  $DEFAULT_USE_REGEX (0=wildcard, 1=regex)

Options:
  -s, --searchfile   FILE    File containing search terms (one per line)
  -t, --targetfile   FILE    File to be searched (supports .gz/.bz2/.xz compressed files)
  -o, --output       FILE    Output file to write results
  -d, --debug                Enable debug mode (print process info)
  -h, --help                 Show this help message and exit
  -r, --regex                Enable full regular expression matching (default: wildcard)

Search Term File Rules:
  1. Leading/trailing whitespaces of each line are ignored
  2. Each line must contain exactly one continuous non-empty string
  3. No whitespace allowed in the middle of the search term (script will die if found)

Output File Format:
  - Each search term is printed on a separate line
  - Next line shows matched line numbers (space-separated) or "noMatchedLineNumber"

Examples:
  1. Use all default values (wildcard matching):
     $script_name

  2. Override search/output file + enable regex + debug:
     $script_name -s /tmp/my_terms.txt -o /tmp/my_results.txt -r -d
HELP
}

###########################################################################
# Subroutine: validate_arguments - Check file accessibility (no mandatory option check)
###########################################################################
sub validate_arguments {
  # Check if input files exist and are readable (compressed files included)
  check_file_readable($search_file, "search");
  check_file_readable($target_file, "target");

  # Check if output file directory is writable
  check_output_writable($output_file);
}

###########################################################################
# Subroutine: check_file_readable - Verify file exists and is readable
###########################################################################
sub check_file_readable {
  my ($file, $type) = @_;
  unless (-e $file) {
    die "Error: $type file '$file' does not exist (check default value or CLI input).\n";
  }
  unless (-r $file) {
    die "Error: $type file '$file' is not readable (permission denied).\n";
  }
  print "Debug: $type file '$file' is accessible.\n" if $debug;
}

###########################################################################
# Subroutine: check_output_writable - Verify output file can be written
###########################################################################
sub check_output_writable {
  my ($file) = @_;
  my $dir = dirname($file);
  
  # Check if parent directory exists and is writable
  unless (-e $dir) {
    die "Error: Output directory '$dir' does not exist.\n";
  }
  unless (-w $dir) {
    die "Error: Output directory '$dir' is not writable (permission denied).\n";
  }

  # If file already exists, check if it's writable
  if (-e $file && !-w $file) {
    die "Error: Output file '$file' already exists but is not writable.\n";
  }
  print "Debug: Output file '$file' is writable.\n" if $debug;
}

###########################################################################
# Subroutine: open_file_handle - Support reading compressed/plain text files
###########################################################################
sub open_file_handle {
  my ($file) = @_;
  my $fh;

  if ($file =~ /\.gz$/) {
    open($fh, '-|', "zcat '$file'") or die "Failed to open gzipped file '$file' (zcat): $!\n";
    print "Debug: Opened gzipped file '$file' via zcat\n" if $debug;
  } elsif ($file =~ /\.bz2$/) {
    open($fh, '-|', "bzcat '$file'") or die "Failed to open bzipped file '$file' (bzcat): $!\n";
    print "Debug: Opened bzipped file '$file' via bzcat\n" if $debug;
  } elsif ($file =~ /\.xz$/) {
    open($fh, '-|', "xzcat '$file'") or die "Failed to open xz-compressed file '$file' (xzcat): $!\n";
    print "Debug: Opened xz-compressed file '$file' via xzcat\n" if $debug;
  } else {
    open($fh, '<', $file) or die "Failed to open text file '$file': $!\n";
    print "Debug: Opened plain text file '$file'\n" if $debug;
  }

  return $fh;
}

###########################################################################
# Subroutine: read_search_terms - Read and validate search terms from file
###########################################################################
sub read_search_terms {
  my @terms;
  my $sfh = open_file_handle($search_file);
  
  my $line_num = 0;
  while (my $line = <$sfh>) {
    $line_num++;
    chomp $line;
    
    $line =~ s/^\s+|\s+$//g;
    
    if ($line eq '') {
      print "Debug: Skipping empty line $line_num in search file.\n" if $debug;
      next;
    }
    
    if ($line =~ /\s/) {
      die "Error: Line $line_num in search file contains whitespace in the middle ('$line').\n";
    }
    
    push @terms, $line;
    print "Debug: Added search term (line $line_num): '$line'\n" if $debug;
  }
  close($sfh) or warn "Warning: Failed to close search file '$search_file': $!\n";
  
  unless (@terms) {
    die "Error: No valid search terms found in search file '$search_file'.\n";
  }
  
  print "Debug: Total valid search terms read: " . scalar(@terms) . "\n" if $debug;
  return @terms;
}

###########################################################################
# Subroutine: read_target_lines - Read target file and store line number + content
###########################################################################
sub read_target_lines {
  my %target_lines;
  my $tfh = open_file_handle($target_file);
  
  my $line_num = 0;
  while (my $line = <$tfh>) {
    $line_num++;
    chomp $line;
    $target_lines{$line_num} = $line;
    print "Debug: Read target line $line_num: '$line'\n" if $debug && $line_num % 100 == 0;
  }
  close($tfh) or warn "Warning: Failed to close target file '$target_file': $!\n";
  
  unless (%target_lines) {
    die "Error: Target file '$target_file' is empty (after decompression if needed).\n";
  }
  
  print "Debug: Total lines read from target file: $line_num\n" if $debug;
  return %target_lines;
}

###########################################################################
# Subroutine: match_terms - Match each search term (regex/wildcard logic)
###########################################################################
sub match_terms {
  my ($terms_ref, $target_lines_ref) = @_;
  my %matches;
  
  foreach my $term (@$terms_ref) {
    my @matched_lines;
    print "Debug: Searching for term '$term' (".($use_regex ? "regex" : "wildcard").")...\n" if $debug;
    
    foreach my $line_num (sort { $a <=> $b } keys %$target_lines_ref) {
      my $content = $target_lines_ref->{$line_num};
      my $match_found = 0;

      if ($use_regex) {
        eval {
          $match_found = 1 if $content =~ /$term/;
        };
        if ($@) {
          die "Error: Invalid regular expression '$term' (line $line_num): $@\n";
        }
      } else {
        my $wildcard_pattern = quotemeta($term);
        $wildcard_pattern =~ s/\\\*/.*/g;
        $wildcard_pattern =~ s/\\\?/./g;
        $match_found = 1 if $content =~ /$wildcard_pattern/;
      }

      if ($match_found) {
        push @matched_lines, $line_num;
        print "Debug:   Matched term '$term' at target line $line_num\n" if $debug;
      }
    }
    
    $matches{$term} = \@matched_lines;
    my $match_count = scalar(@matched_lines);
    print "Debug: Found $match_count matches for term '$term'\n" if $debug;
  }
  
  return %matches;
}

###########################################################################
# Subroutine: write_output - Write search terms and matched line numbers to output file
###########################################################################
sub write_output {
  my ($matches_ref, $terms_ref) = @_;
  open(my $ofh, '>', $output_file) or die "Cannot open output file '$output_file': $!\n";
  
  foreach my $term (@$terms_ref) {
    print $ofh "$term\n";
    
    my @matched_lines = @{$matches_ref->{$term}};
    if (@matched_lines) {
      print $ofh join(' ', @matched_lines) . "\n";
    } else {
      print $ofh "noMatchedLineNumber\n";
    }
    
    print "Debug: Wrote result for term '$term' to output file\n" if $debug;
  }
  
  close($ofh) or die "Cannot close output file '$output_file': $!\n";
  print "Debug: All results written to output file '$output_file'\n" if $debug;
}

###########################################################################
# Subroutine: main - Main execution logic
###########################################################################
sub main {
  print "Debug: Starting script execution (regex mode: " . ($use_regex ? "ON" : "OFF") . ")\n" if $debug;
  
  my @search_terms = read_search_terms();
  my %target_lines = read_target_lines();
  my %term_matches = match_terms(\@search_terms, \%target_lines);
  write_output(\%term_matches, \@search_terms);
  
  print "Script completed successfully. Results written to '$output_file'\n";
}
