#!/usr/bin/perl
# --------------------------
# author    : aiden song
# date      : 2026/02/23 12:20:52 Monday
# label     : format_sub
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc|clock_tree_relative_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Process the timing violation path report and generate an ECO script. for pt eco script
# return    : output file
# ref       : link url
# --------------------------
use strict;
use warnings;

# ==============================================================================
# DEFAULT CONFIGURATION (EASY TO MODIFY) - All default parameters centralized
# ==============================================================================
my $DEFAULT_INPUT_FILE    = '';          # Input file (required, no default)
my $DEFAULT_OUTPUT_FILE   = '';          # Output file (optional, higher priority than prefix)
my $DEFAULT_PREFIX        = 'pt_eco_';# Default prefix for output file name
my $DEFAULT_PROCESS_CMD   = "| sed -ne '/BWP/p' | awk '{print \"ecoChangeCell -cell\", \$2, \"-inst\", \$1}' | sed -Ene 's?U_M3KL_MAIN_SUB_WRAP/??g' -e 's?\\(\|\\)??g' -e 's?([a-zA-Z0-9_/]+)/[0-9A-Za-z]+\$?\\1?gp' | sort -u";          # Processing command (required, no default) ; # for invs eco
# my $DEFAULT_PROCESS_CMD   = "| sed -ne '/BWP/p' | awk '{print \"size_cell\", \$1, \$2}' | sed -Ene 's?\\(\|\\)??g' -e 's? ([a-zA-Z0-9_/]+)/[0-9A-Za-z]+ ? \\1 ?gp' | sort -u";          # Processing command (required, no default) ; # for pt eco
my $DEFAULT_DEBUG_MODE    = 0;           # Debug mode disabled by default (0=disabled, 1=enabled)
my $DEFAULT_SHOW_HELP     = 0;           # Help info disabled by default

# ==============================================================================
# MODULE IMPORTS
# ==============================================================================
use Getopt::Long;
use File::Basename;
use Cwd 'abs_path';

# ==============================================================================
# GLOBAL VARIABLES (bind default values)
# ==============================================================================
my $input_file   = $DEFAULT_INPUT_FILE;
my $output_file  = $DEFAULT_OUTPUT_FILE;
my $prefix       = $DEFAULT_PREFIX;
my $process_cmd  = $DEFAULT_PROCESS_CMD;
my $debug        = $DEFAULT_DEBUG_MODE;
my $help         = $DEFAULT_SHOW_HELP;

# ==============================================================================
# PARSE COMMAND LINE OPTIONS
# ==============================================================================
GetOptions(
  'input|i=s'     => \$input_file,    # Input file path (required)
  'output|o=s'    => \$output_file,   # Output file path (optional)
  'prefix|p=s'    => \$prefix,        # Prefix for default output name (optional)
  'process|c=s'   => \$process_cmd,   # Processing command (required, starts with |)
  'debug|d'       => \$debug,         # Debug mode (optional)
  'help|h'        => \$help           # Show help (optional)
) or die "Error in command line arguments. Use -h/--help for usage.\n";

# ==============================================================================
# SHOW HELP IF REQUESTED
# ==============================================================================
&print_help() if $help;

# ==============================================================================
# VALIDATE REQUIRED PARAMETERS
# ==============================================================================
unless (defined $input_file && $input_file ne '') {
  die "ERROR: Input file is required! Use -i/--input to specify. See -h for help.\n";
}
unless (defined $process_cmd && $process_cmd ne '') {
  die "ERROR: Processing command is required! Use -c/--process to specify. See -h for help.\n";
}

# ==============================================================================
# VALIDATE INPUT FILE EXISTS AND IS READABLE
# ==============================================================================
unless (-f $input_file && -r $input_file) {
  die "ERROR: Input file '$input_file' does not exist or is not readable!\n";
}

# ==============================================================================
# DEBUG MODE - PRINT INPUT PARAMETERS
# ==============================================================================
if ($debug) {
  print "=== DEBUG MODE (DEFAULT CONFIG REFERENCE) ===\n";
  print "Default prefix (from config): $DEFAULT_PREFIX\n";
  print "Default debug mode (from config): $DEFAULT_DEBUG_MODE\n";
  print "=== DEBUG MODE (ACTUAL PARAMETERS) ===\n";
  print "Input file: $input_file\n";
  print "Custom output file: " . (defined $output_file && $output_file ne '' ? $output_file : "NOT specified (using default prefix)\n");
  print "Used prefix: $prefix\n";
  print "Processing command: $process_cmd\n";
  print "=============================================\n";
}

# ==============================================================================
# GENERATE OUTPUT FILE NAME IF NOT SPECIFIED
# ==============================================================================
unless (defined $output_file && $output_file ne '') {
  my ($filename, $dir, $suffix) = fileparse($input_file);
  my $new_filename = $prefix . $filename;
  $output_file = $dir . $new_filename;
  
  if ($debug) {
    print "DEBUG: Generated output path: $output_file (prefix '$prefix' added to basename)\n";
  }
}

# ==============================================================================
# VALIDATE PROCESSING COMMAND FORMAT
# ==============================================================================
# Check if the first non-whitespace character is |
unless ($process_cmd =~ /^\s*\|/) {
  die "ERROR: Invalid process command format! The command must start with a pipe symbol (|) (ignoring leading whitespace).\nExample: | sed -e 's/SONG/song/g' | awk '{print \$2,\$1}'\n";
}

# ==============================================================================
# EXTRACT ACTUAL PROCESSING COMMAND
# ==============================================================================
# Remove leading whitespace to get clean command (keep the |)
my $actual_cmd = $process_cmd;
$actual_cmd =~ s/^\s+//;  # Remove leading whitespace only

if ($debug) {
  print "DEBUG: Cleaned processing command: $actual_cmd\n";
}

# ==============================================================================
# BUILD FULL EXECUTION COMMAND
# ==============================================================================
# No extra | after cat (process_cmd already starts with |)
my $full_cmd = "cat " . abs_path($input_file) . " $actual_cmd > " . abs_path($output_file);

if ($debug) {
  print "DEBUG: Full execution command: $full_cmd\n";
}

# ==============================================================================
# EXECUTE THE COMMAND AND HANDLE ERRORS
# ==============================================================================
print "Processing file...\n";
my $exit_code = system($full_cmd);

if ($exit_code != 0) {
  die "ERROR: Failed to process file! Command exited with code $exit_code.\n";
} else {
  print "Success! Processed file saved to: $output_file\n";
}

# ==============================================================================
# SUBROUTINE: PRINT HELP INFORMATION
# ==============================================================================
sub print_help {
  my $help_text = <<'HELP';
Usage: perl file_processor.pl [OPTIONS]

Description:
  Processes a file with a custom pipe command and generates an output file with a user-specified or default name.
  All default parameters can be modified directly at the top of the script (DEFAULT CONFIGURATION section).

Required Options:
  -i, --input       Path to input file (required, no default value)
  -c, --process     Processing command (required)
                    Must start with a pipe symbol (|) (leading whitespace is allowed)
                    Example: | sed -e 's/OLD/NEW/g' | awk '{print $1}' | sort

Optional Options:
  -o, --output      Path/name of output file (high priority, no default value)
  -p, --prefix      Prefix for default output name (default: processed_)
                    Only used if --output is not specified
  -d, --debug       Enable debug mode (default: disabled)
  -h, --help        Show this help message

Default Configuration (modify at top of script):
  - DEFAULT_PREFIX: 'processed_' (default prefix for output file)
  - DEFAULT_DEBUG_MODE: 0 (0=disabled, 1=enabled)

Examples:
  1. Basic usage (use default prefix):
     perl file_processor.pl -i data.txt -c "| sed -e 's/SONG/song/g'"

  2. Custom prefix and output path:
     perl file_processor.pl -i /tmp/input.log -c "| awk '{print $2}' | sort -n" -p "sorted_" -o /tmp/sorted_log.txt

  3. Use default debug mode (modified in script) + complex processing:
     (Edit script: set $DEFAULT_DEBUG_MODE = 1, then run)
     perl file_processor.pl -i report.csv -c "| cut -d',' -f1,3 | tr ',' '|'" -p "transformed_"
HELP
  print $help_text;
  exit 0;
}
