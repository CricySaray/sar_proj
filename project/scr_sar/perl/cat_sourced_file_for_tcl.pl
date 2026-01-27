#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Spec;

# Global variables (for song numbering, maintain recursion state, debug, duplicate tracking)
my $song_counter = 1;
my $INDENT_SPACE = '  '; # 2 spaces for each indent level
my $debug = 0; # Debug mode flag (0 = off, 1 = on)
my %processed_files; # Hash to track processed files (for duplicate checking)
my $allow_duplicates = 0; # Flag to allow duplicate source insertion (0 = disallow, 1 = allow)

# -----------------------------------------------------------------------------
# [USER CONFIGURABLE DEFAULT VALUES] - Explicit default settings for input/output
# User can directly modify the values below to change default input/output files
# No need to modify other parts of the script
# -----------------------------------------------------------------------------
my $DEFAULT_INPUT_FILE  = "input.tcl";        # Default input TCL file (user can modify this)
my $DEFAULT_OUTPUT_FILE = "output_merged.tcl"; # Default merged output file (user can modify this)

# -----------------------------------------------------------------------------
# Subroutine: print_help
# Description: Print the help information for this script
# -----------------------------------------------------------------------------
sub print_help {
  my $help_text = <<'HELP';
Usage: tcl_source_expander.pl [OPTIONS]

Description:
  This script parses a TCL file, recursively expands all 'source' commands,
  and generates a single merged output file with indented content and traceable comments.

Options:
  -i, --inputfile FILE     Specify the input TCL file (default: input.tcl)
  -o, --outputfile FILE    Specify the output merged file (default: output_merged.tcl)
  -h, --help               Print this help message and exit
  -d, --debug              Enable debug mode (show processing details, found/missing files)
  -a, --allow-duplicates   Allow duplicate insertion of the same source file (default: disallow)

Examples:
  1. Basic usage with default input/output (no options needed, uses default values below):
     ./tcl_source_expander.pl
  2. Basic usage with short options:
     ./tcl_source_expander.pl -i my_input.tcl -o my_output.tcl -d
  3. Basic usage with long options and allow duplicates:
     ./tcl_source_expander.pl --inputfile project.tcl --outputfile project_merged.tcl --debug --allow-duplicates
HELP
  print $help_text;
  exit 0;
}

# -----------------------------------------------------------------------------
# Subroutine: process_file
# Description: Recursively process a file, expand 'source' commands, write to output
# Parameters:
#   $file_path   - Path of the file to process
#   $indent_level - Current indent level (for nested source commands)
#   $out_fh      - File handle of the output file
# -----------------------------------------------------------------------------
sub process_file {
  my ($file_path, $indent_level, $out_fh) = @_;
  
  # Debug: Print current processing file and indent level
  if ($debug) {
    print STDOUT "[DEBUG] Processing file: '$file_path' (indent level: $indent_level)\n";
  }
  
  # Calculate current indent string
  my $current_indent = $INDENT_SPACE x $indent_level;
  
  # Open input file or die with error
  open my $in_fh, '<', $file_path or die "Error: Cannot open input file '$file_path' - $!";
  
  while (my $line = <$in_fh>) {
    chomp $line;
    
    # Step 1: Remove inline comments (everything after ';')
    my $clean_line = $line;
    $clean_line =~ s/;.*$//;
    $clean_line =~ s/^\s+//;
    $clean_line =~ s/\s+$//;
    
    # Step 2: Check if the line is a 'source' command
    if ($clean_line =~ /^source\s+.+$/) {
      # Parse original source command (keep full line for comment trace)
      my $original_source_cmd = $line;
      $original_source_cmd =~ s/;.*$//; # Remove inline comment but keep original format
      $original_source_cmd =~ s/^\s+//;
      
      # Extract file path by filtering out options (-e, -v)
      my @parts = split /\s+/, $clean_line;
      my @file_parts = grep { !/^-(e|v)$/ } @parts; # Filter out -e and -v options
      shift @file_parts; # Remove 'source' keyword from the list
      my $file_pattern = join ' ', @file_parts;
      
      # Step 3: Resolve wildcards (e.g., *.tcl)
      my @source_files = glob $file_pattern;
      if (scalar @source_files == 0) {
        warn "Warning: No files matched pattern '$file_pattern' in '$file_path'\n";
        # Debug: Print missing file pattern
        if ($debug) {
          print STDOUT "[DEBUG] No files found for pattern '$file_pattern' in parent file '$file_path'\n";
        }
        # Print original source line if no matching files (keep trace)
        print $out_fh $current_indent . $line . "\n";
        next;
      }
      
      # Step 4: Process each matched source file
      foreach my $source_file (@source_files) {
        $source_file = File::Spec->rel2abs($source_file); # Convert to absolute path for clarity and duplicate check
        
        # Debug: Print matched file
        if ($debug) {
          print STDOUT "[DEBUG] Found matched file for pattern '$file_pattern': '$source_file'\n";
        }
        
        # Step 4.1: Check for duplicates (skip if disallowed and already processed)
        if (!$allow_duplicates && exists $processed_files{$source_file}) {
          if ($debug) {
            print STDOUT "[DEBUG] Skipping duplicate file: '$source_file' (already processed, duplicates disallowed)\n";
          }
          next;
        }
        
        # Mark file as processed (if duplicates are disallowed, or track for debug even if allowed)
        $processed_files{$source_file} = 1 unless exists $processed_files{$source_file};
        
        # -------------------------- MODIFIED PART --------------------------
        # Generate unique song number for current source file FIRST
        my $song_number = sprintf("song%03d", $song_counter);
        # Increment counter IMMEDIATELY to ensure nested source files get new number
        $song_counter++;
        # -------------------------------------------------------------------
        
        my $comment_line = "# $song_number: $original_source_cmd";
        
        # Print start comment (with current indent)
        print $out_fh $current_indent . $comment_line . "\n";
        
        # Print expanded content (with +1 indent level for nested files)
        process_file($source_file, $indent_level + 1, $out_fh);
        
        # Print end comment (same song number, with current indent)
        print $out_fh $current_indent . "# $song_number: End of $original_source_cmd" . "\n";
        
        # -------------------------- REMOVED HERE --------------------------
        # Original increment: after recursive processing (caused nested number reuse)
        # $song_counter++;
        # -------------------------------------------------------------------
      }
    } else {
      # Step 5: Print non-source lines with current indent (keep original content)
      print $out_fh $current_indent . $line . "\n";
    }
  }
  
  close $in_fh or die "Error: Cannot close input file '$file_path' - $!";
}

# -----------------------------------------------------------------------------
# Main program: Parse command line options and execute workflow
# -----------------------------------------------------------------------------
sub main {
  # Initialize command line options with EXPLICIT DEFAULT VALUES (from user configurable section above)
  my $input_file  = $DEFAULT_INPUT_FILE;  # Use default input file (user can modify above)
  my $output_file = $DEFAULT_OUTPUT_FILE; # Use default output file (user can modify above)
  my $show_help;
  
  # Parse long/short options with Getopt::Long (updated long option names)
  GetOptions(
    'inputfile|i=s'        => \$input_file,
    'outputfile|o=s'       => \$output_file,
    'help|h'               => \$show_help,
    'debug|d'              => \$debug,
    'allow-duplicates|a'   => \$allow_duplicates
  ) or die "Error: Invalid command line options. Use -h for help.\n";
  
  # Show help if requested
  print_help() if $show_help;
  
  # Validate input file exists (even for default value)
  unless (-e $input_file && -r $input_file) {
    die "Error: Input file '$input_file' does not exist or is not readable.\n";
  }
  
  # Debug: Print command line options and defaults
  if ($debug) {
    print STDOUT "[DEBUG] Script configuration:\n";
    print STDOUT "[DEBUG]   Input file: $input_file (default: $DEFAULT_INPUT_FILE)\n";
    print STDOUT "[DEBUG]   Output file: $output_file (default: $DEFAULT_OUTPUT_FILE)\n";
    print STDOUT "[DEBUG]   Allow duplicates: " . ($allow_duplicates ? "Yes" : "No") . "\n";
  }
  
  # Open output file (overwrite if exists)
  open my $out_fh, '>', $output_file or die "Error: Cannot open output file '$output_file' - $!";
  
  # Start processing the root input file (indent level 0)
  print STDOUT "Processing input file: $input_file\n";
  print STDOUT "Generating output file: $output_file\n";
  process_file($input_file, 0, $out_fh);
  
  # Clean up
  close $out_fh or die "Error: Cannot close output file '$output_file' - $!";
  print STDOUT "Process completed successfully.\n";
  
  # Debug: Print final summary
  if ($debug) {
    my $processed_count = scalar keys %processed_files;
    print STDOUT "[DEBUG] Final summary: Total unique files processed: $processed_count\n";
  }
}

# Run the main program
main();
