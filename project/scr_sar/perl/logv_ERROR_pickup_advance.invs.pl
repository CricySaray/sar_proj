#!/usr/bin/perl -w
####################################
# author     : sar
# descrip    : pick out the ERROR text block in invs logv file.
# date       : Wen Jan 15 16:40:19 CST 2025
# updated    : Mon Nov 17 2025 (custom help sub, auto output name, explicit defaults)
# ref        : https://www.notion.so/invs_logv_ERROR_pick_out-pl-1aca8d0ab3d8801da4c7cfee9103a477?source=copy_link
####################################
use strict;
use warnings;
use Getopt::Long;
use File::Basename;  # For auto-generate output filename (core module)

# ==============================================
# Explicit Default Configuration (Easy to Modify)
# ==============================================
my $input_file  = '';    # Required: Input logv file path (can set default here, e.g., 'input.logv')
my $output_file = '';    # Optional: Output file path (auto-generated if not provided)
my $help        = 0;     # Optional: Show help message (flag, 0=disable, 1=enable)
my $debug       = 0;     # Optional: Enable debug mode (flag, 0=disable, 1=enable)
my $ignore_exp  = 'empty_sar';  # Optional: Regex to ignore blocks (CANNOT be empty)
my $pickup_exp = '\*\*ERROR';  # Optional: Regex to pick out ERROR blocks
# ==============================================

# Parse command line options (override defaults if provided)
GetOptions(
  'i|input=s'      => \$input_file,
  'o|output=s'     => \$output_file,
  'h|help'         => \$help,
  'd|debug'        => \$debug,
  'ignore-exp=s'   => \$ignore_exp,
  'pickout-exp=s'  => \$pickup_exp,
) or do {
  print STDERR "Error: Invalid command line options\n";
  show_help();
  exit 1;
};

# Show help and exit if requested
if ($help) {
  show_help();
  exit 0;
}

# Auto-generate output filename if not provided (keep input path, add "ERROR_pickup_" prefix)
if ($input_file && !$output_file) {
  my ($name, $path, $ext) = fileparse($input_file, qr/\.[^.]*/);  # Preserve path and extension
  $output_file = $path . 'ERROR_pickup_' . $name . $ext;
  print STDERR "Debug: Auto-generated output file: $output_file\n" if $debug;
}

# Validate required parameters
unless ($input_file) {
  print STDERR "Error: Required option --input (-i) must be provided (or set default in script)\n";
  show_help();
  exit 1;
}

# Validate ignore expression (cannot be empty as per original script requirement)
if ($ignore_exp eq '') {
  die "Error: Ignore expression cannot be empty (as per original script requirement)\n";
}

# Validate input file existence and readability
unless (-f $input_file && -r $input_file) {
  die "Error: Input file '$input_file' does not exist or is not readable\n";
}

# Debug: Print final configuration (defaults + command line overrides)
if ($debug) {
  print STDERR "=== Debug Mode Enabled ===\n";
  print STDERR "Input file:    $input_file\n";
  print STDERR "Output file:   $output_file\n";
  print STDERR "Ignore exp:    $ignore_exp\n";
  print STDERR "Pickout exp:   $pickup_exp\n";
  print STDERR "==========================\n";
}

# Original script core variables (explicit initialization)
my @errorBlock;
my ($in_block, $i) = (0, 0);

# Open files with detailed error messages
open my $fi, '<', $input_file or die "Error: Failed to open input file '$input_file': $!";
open my $fo, '>', $output_file or die "Error: Failed to open output file '$output_file': $!";

# Subroutine to show help message (custom implementation, no Pod::Usage)
sub show_help {
  print STDERR <<'HELP_MSG';
Usage: invs_logv_error_pick.pl [OPTIONS]

Description: Extract ERROR text blocks (delimited by '<CMD>') from invs logv files.
             Blocks are kept if they match the pickout pattern and do NOT match the ignore pattern.

Options (long/short format, defaults shown in brackets):
  -i, --input FILE        Required. Path to input logv file (can set default in script header).
  -o, --output FILE       Optional. Path to output file (auto-generated as "ERROR_pickup_<input>" if not provided).
  -h, --help              Optional. Show this help message and exit.
  -d, --debug             Optional. Enable debug mode (print details to STDERR) [0].
  --ignore-exp PATTERN    Optional. Regex to exclude blocks (blocks with this pattern are skipped) [empty_sar].
  --pickout-exp PATTERN   Optional. Regex to include blocks (blocks with this pattern are candidates) [\*\*ERROR].

Examples:
  1. Use defaults (set input in script, auto-generate output):
     ./invs_logv_error_pick.pl  # (Set $input_file = 'your_input.logv' in script header first)

  2. Basic usage (specify input, auto-generate output):
     ./invs_logv_error_pick.pl -i input.logv

  3. Specify input and output:
     ./invs_logv_error_pick.pl -i input.logv -o custom_output.errors

  4. Custom ignore pattern (skip TCLCMD-917/IMPLF-40 blocks):
     ./invs_logv_error_pick.pl -i input.logv --ignore-exp '\(TCLCMD-917\)|\(IMPLF-40\)'

  5. Debug mode (track processing):
     ./invs_logv_error_pick.pl -i input.logv -d

  6. Custom ERROR pattern (match "FATAL ERROR"):
     ./invs_logv_error_pick.pl -i input.logv --pickout-exp 'FATAL ERROR'

Notes:
  - Ignore expression cannot be empty (per original script design).
  - Blocks are delimited by lines containing '<CMD>' (each block starts with <CMD>).
  - Regular expressions follow Perl syntax: escape special characters ((), *, |) with backslashes.
  - Debug output is sent to STDERR (does not interfere with the output file).
  - Default values can be modified directly in the script header (no need for command line options).
HELP_MSG
}

# Subroutine to process error block (preserved original logic + debug)
sub arrayExp {
  my @block = @_;
  return unless @block;  # Skip empty blocks

  my ($matchFlag, $ignoreFlag) = (0, 1);

  # Check if block contains pickout pattern
  for (@block) {
    if (/$pickup_exp/) {
      $matchFlag = 1;
      last if $debug;  # Early exit in debug mode once match found
    }
  }

  # Check if block contains ignore pattern
  for (@block) {
    if (/$ignore_exp/) {
      $ignoreFlag = 0;
      last if $debug;  # Early exit in debug mode once ignore found
    }
  }

  # Debug: Block analysis result
  if ($debug) {
    my $block_lines = scalar(@block);
    my $match_str = $matchFlag ? 'YES' : 'NO';
    my $ignore_str = $ignoreFlag ? 'NO' : 'YES';
    print STDERR "Debug: Processing block (lines: $block_lines) - Match pickout: $match_str, Contains ignore: $ignore_str\n";
  }

  # Output block if conditions are met (original logic preserved)
  if ($matchFlag && $ignoreFlag) {
    $i++;
    print $fo "EOR ", $i, ":\n\n", @block, "\n";
    print STDERR "Debug: Output block EOR $i\n" if $debug;
  }
}

# Main file processing loop (original logic preserved + debug)
print STDERR "Debug: Starting to read input file...\n" if $debug;
while (<$fi>) {
  if (/<CMD>/) {
    # Process previous block before starting new one
    arrayExp(@errorBlock) if @errorBlock;
    @errorBlock = ();
    $in_block = 1;
    print STDERR "Debug: Found new block start (<CMD>) at line $. \n" if $debug;
  }
  push @errorBlock, $_ if $in_block;
}

# Process the last block (original logic preserved)
print STDERR "Debug: Processing last block...\n" if $debug;
arrayExp(@errorBlock) if @errorBlock;

# Output no match message (original logic preserved + debug)
if (!$i) {
  print $fo "No matched ERROR in file : $input_file\n";
  print STDERR "Debug: No matched ERROR blocks found\n" if $debug;
} else {
  print STDERR "Debug: Total matched ERROR blocks: $i\n" if $debug;
}

# Cleanup with warning for close failures
close $fi or warn "Warning: Failed to close input file '$input_file': $!";
close $fo or warn "Warning: Failed to close output file '$output_file': $!";
print STDERR "Debug: Script completed successfully\n" if $debug;

exit 0;
