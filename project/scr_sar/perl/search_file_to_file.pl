#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Basename;

# Global variables for command line options
my ($search_file, $target_file, $output_file, $debug, $help);

# Parse command line options (long and short formats)
GetOptions(
  'searchfile|s=s' => \$search_file,  # File containing search terms
  'targetfile|t=s' => \$target_file,  # File to be searched
  'output|o=s'     => \$output_file,  # Output file path
  'debug|d'        => \$debug,        # Enable debug mode
  'help|h'         => \$help          # Show help message
) or die "Error in command line arguments. Use -h/--help for usage.\n";

# Show help and exit if requested
if ($help) {
  print_help();
  exit 0;
}

# Validate mandatory arguments
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

Mandatory Options:
  -s, --searchfile   FILE    File containing search terms (one per line)
  -t, --targetfile   FILE    File to be searched
  -o, --output       FILE    Output file to write results

Optional Options:
  -d, --debug                Enable debug mode (print process info)
  -h, --help                 Show this help message and exit

Search Term File Rules:
  1. Leading/trailing whitespaces of each line are ignored
  2. Each line must contain exactly one continuous non-empty string
  3. No whitespace allowed in the middle of the search term (script will die if found)

Output File Format:
  - Each search term is printed on a separate line
  - Next line shows matched line numbers (space-separated) or "noMatchedLineNumber"

Examples:
  1. Basic usage:
     $script_name -s search_terms.txt -t target_data.txt -o results.txt

  2. Usage with debug mode (long options):
     $script_name --searchfile /tmp/terms.txt --targetfile /var/log/app.log --output /tmp/matches.txt --debug
HELP
}

###########################################################################
# Subroutine: validate_arguments - Check mandatory arguments and file accessibility
###########################################################################
sub validate_arguments {
  # Check if all mandatory options are provided
  my @missing;
  push @missing, "--searchfile/-s" unless $search_file;
  push @missing, "--targetfile/-t" unless $target_file;
  push @missing, "--output/-o"     unless $output_file;

  if (@missing) {
    die "Missing mandatory options: " . join(", ", @missing) . "\nUse -h/--help for usage.\n";
  }

  # Check if input files exist and are readable
  check_file_readable($search_file, "search");
  check_file_readable($target_file, "target");

  # Check if output file directory is writable (if file exists, check writable; if not, check parent dir)
  check_output_writable($output_file);
}

###########################################################################
# Subroutine: check_file_readable - Verify file exists and is readable
###########################################################################
sub check_file_readable {
  my ($file, $type) = @_;
  unless (-e $file) {
    die "Error: $type file '$file' does not exist.\n";
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
# Subroutine: read_search_terms - Read and validate search terms from file
###########################################################################
sub read_search_terms {
  my @terms;
  open(my $sfh, '<', $search_file) or die "Cannot open search file '$search_file': $!\n";
  
  my $line_num = 0;
  while (my $line = <$sfh>) {
    $line_num++;
    chomp $line;
    
    # Remove leading/trailing whitespaces
    $line =~ s/^\s+|\s+$//g;
    
    # Skip empty lines (after trimming)
    if ($line eq '') {
      print "Debug: Skipping empty line $line_num in search file.\n" if $debug;
      next;
    }
    
    # Check for whitespace in the middle of the term
    if ($line =~ /\s/) {
      die "Error: Line $line_num in search file contains whitespace in the middle ('$line').\n";
    }
    
    push @terms, $line;
    print "Debug: Added search term (line $line_num): '$line'\n" if $debug;
  }
  close($sfh) or die "Cannot close search file '$search_file': $!\n";
  
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
  open(my $tfh, '<', $target_file) or die "Cannot open target file '$target_file': $!\n";
  
  my $line_num = 0;
  while (my $line = <$tfh>) {
    $line_num++;
    chomp $line;
    $target_lines{$line_num} = $line;  # Store original content (without newline)
    print "Debug: Read target line $line_num: '$line'\n" if $debug && $line_num % 100 == 0;  # Avoid too much debug output
  }
  close($tfh) or die "Cannot close target file '$target_file': $!\n";
  
  unless (%target_lines) {
    die "Error: Target file '$target_file' is empty.\n";
  }
  
  print "Debug: Total lines read from target file: $line_num\n" if $debug;
  return %target_lines;
}

###########################################################################
# Subroutine: match_terms - Match each search term against target lines and collect line numbers
###########################################################################
sub match_terms {
  my ($terms_ref, $target_lines_ref) = @_;
  my %matches;
  
  foreach my $term (@$terms_ref) {
    my @matched_lines;
    print "Debug: Searching for term '$term' in target file...\n" if $debug;
    
    foreach my $line_num (sort { $a <=> $b } keys %$target_lines_ref) {
      my $content = $target_lines_ref->{$line_num};
      
      if (index($content, $term) != -1) {  # Case-sensitive match (use lc() for case-insensitive)
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
    # Write search term
    print $ofh "$term\n";
    
    # Write matched line numbers or noMatchedLineNumber
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
  print "Debug: Starting script execution...\n" if $debug;
  
  # Step 1: Read and validate search terms
  my @search_terms = read_search_terms();
  
  # Step 2: Read target file content
  my %target_lines = read_target_lines();
  
  # Step 3: Match search terms against target lines
  my %term_matches = match_terms(\@search_terms, \%target_lines);
  
  # Step 4: Write results to output file
  write_output(\%term_matches, \@search_terms);
  
  print "Script completed successfully. Results written to '$output_file'\n";
}
