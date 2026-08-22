#!/usr/bin/perl
# --------------------------
# author    : aiden song
# date      : 2026/02/16 12:28:20 Monday
# label     : getInfo_sub
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : 
#             ### Perl Script Function Overview
#             This Perl script compares structured blocks of text between two files (File A and File B) with flexible customization options. It extracts text 
#             blocks using user-defined rules (e.g., start/end markers or separators), processes each block (optional custom commands), and categorizes blocks 
#             into three groups: blocks common to both files, blocks unique to File A, and blocks unique to File B.
#             Key features:
#             - Extract blocks via 4 modes: `start`, `end`, `start_end`, or `separator` (empty line by default)
#             - Simplify blocks (filter lines by regex, replace consecutive spaces with single space)
#             - Case-sensitive block comparison (no case conversion)
#             - Generate 8 output files (4 original blocks + 4 simplified blocks)
#             - Create a dynamic summary report with block statistics
#             - Configurable output paths, block formatting (prefix/suffix/separator), and debug mode
#             In short: It helps identify differences and similarities between text blocks in two files, with flexible extraction and formatting options.
# return    : output diff files
# ref       : link url
# --------------------------
use strict;
# use warnings;
use Getopt::Long;
use File::Basename;
use File::Path qw(make_path); # For creating directories

# ======================== DEFAULT CONFIGURATION (Prominent default parameter section) ========================
# Basic file configuration
my $DEFAULT_FILE_A          = 'old_file.txt';       # Default path for comparison file A (old file)
my $DEFAULT_FILE_B          = 'new_file.txt';       # Default path for comparison file B (new file)
# Block splitting configuration
my $DEFAULT_BLOCK_MODE      = 'start_end';          # Block splitting mode: start/end/start_end/separator
my $DEFAULT_START_REGEX     = 'Startpoint:';        # Regex for block start (start/start_end mode)
my $DEFAULT_END_REGEX       = 'slack \(VIO';          # Regex for block end (end/start_end mode)
my $DEFAULT_SEP_REGEX       = '^\s*$';              # Regex for block separator (separator mode, default empty line)
# Block processing configuration
my $DEFAULT_BLOCK_PROCESS_CMD = "| sed -ne '/Point/,/data arrival time/p' | grep 'BWP' | awk '{print \$1}'"; # Command to process each block
# Simplified block configuration
my $DEFAULT_SIMPLIFY_REGEX  = 'Startpoint:|Endpoint:|slack \(VIO';    # Updated default regex for simplifying blocks (line-level match)
# Sorting configuration
my $DEFAULT_ORDER_BY        = 'A';                  # Sort rule for common blocks: A/B/BOTH
# Block format configuration
my $DEFAULT_BLOCK_PREFIX    = "songpath <id>";      # Block prefix
my $DEFAULT_BLOCK_SUFFIX    = "\n";               # Block suffix
my $DEFAULT_BLOCK_SEP       = ""; # Separator between blocks
# Output configuration
my $DEFAULT_OUTPUT_PREFIX   = 'diff_';              # Prefix for output filenames (empty for none)
my $DEFAULT_OUTPUT_DIR      = './';                 # Output directory path
# Debug configuration
my $DEFAULT_DEBUG_MODE      = 0;                    # Default: Debug mode disabled

# ======================== GLOBAL VARIABLES ========================
my ($file_a, $file_b, $block_mode, $start_regex, $end_regex, $sep_regex);
my ($block_process_cmd, $simplify_regex, $order_by, $block_prefix, $block_suffix, $block_sep);
my ($output_prefix, $output_dir, $help, $debug);

# ======================== OPTION PARSING ========================
GetOptions(
  # Basic file parameters
  'a|fileA=s'       => \$file_a,          # Short -a, long --fileA: Path to file A
  'b|fileB=s'       => \$file_b,          # Short -b, long --fileB: Path to file B
  # Block splitting parameters
  'm|mode=s'        => \$block_mode,      # Short -m, long --mode: Block splitting mode
  't|startRegex=s'  => \$start_regex,     # Short -t, long --startRegex: Regex for block start
  'e|endRegex=s'    => \$end_regex,       # Short -e, long --endRegex: Regex for block end
  'k|sepRegex=s'    => \$sep_regex,       # Short -k, long --sepRegex: Regex for block separator
  # Block processing parameters
  'c|processCmd=s'  => \$block_process_cmd,# Short -c, long --processCmd: Command to process each block
  # Simplified block parameters
  'r|regex=s'       => \$simplify_regex,  # Short -r, long --regex: Regex for simplifying blocks
  # Sorting parameters
  'o|orderBy=s'     => \$order_by,        # Short -o, long --orderBy: Sort rule
  # Block format parameters
  'p|prefix=s'      => \$block_prefix,    # Short -p, long --prefix: Block prefix
  's|suffix=s'      => \$block_suffix,    # Short -s, long --suffix: Block suffix
  'd|separator=s'   => \$block_sep,       # Short -d, long --separator: Separator between blocks
  # Output configuration parameters
  'f|outputPrefix=s'=> \$output_prefix,   # Short -f, long --outputPrefix: Prefix for output filenames
  'l|outputDir=s'   => \$output_dir,      # Short -l, long --outputDir: Output directory
  # Debug parameter
  'g|debug'         => \$debug,           # Short -g, long --debug: Enable debug mode (print intermediate steps)
  # Help parameter
  'h|help'          => \$help             # Short -h, long --help: Show help documentation
) or die "Error in command line arguments. Use -h/--help for usage.\n";

# Load default values (when parameters are not specified)
$file_a         //= $DEFAULT_FILE_A;
$file_b         //= $DEFAULT_FILE_B;
$block_mode     //= $DEFAULT_BLOCK_MODE;
$start_regex    //= $DEFAULT_START_REGEX;
$end_regex      //= $DEFAULT_END_REGEX;
$sep_regex      //= $DEFAULT_SEP_REGEX;
$block_process_cmd //= $DEFAULT_BLOCK_PROCESS_CMD;
$simplify_regex //= $DEFAULT_SIMPLIFY_REGEX;
$order_by       //= $DEFAULT_ORDER_BY;
$block_prefix   //= $DEFAULT_BLOCK_PREFIX;
$block_suffix   //= $DEFAULT_BLOCK_SUFFIX;
$block_sep      //= $DEFAULT_BLOCK_SEP;
$output_prefix  //= $DEFAULT_OUTPUT_PREFIX;
$output_dir     = ($output_dir && $output_dir ne '') ? $output_dir : './';
$debug          //= $DEFAULT_DEBUG_MODE;

# Print debug info: Loaded parameters
debug_print("Loaded parameters:", 
  "File A: $file_a", "File B: $file_b",
  "Block mode: $block_mode", "Start regex: $start_regex", "End regex: $end_regex",
  "Process cmd: $block_process_cmd", "Simplify regex: $simplify_regex",
  "Output prefix: $output_prefix", "Output dir: $output_dir",
  "Debug mode: " . ($debug ? "ENABLED" : "DISABLED")
);

# Print help documentation
if ($help) {
  print_help();
  exit 0;
}

# Validate parameters
validate_parameters();

# Create output directory (if not exists)
make_path($output_dir, { error => \my $err });
if (@$err) {
  for my $diag (@$err) {
    my ($file, $message) = %$diag;
    die "Error creating directory $file: $message\n";
  }
}
debug_print("Output directory created/verified: $output_dir");

# ======================== MAIN LOGIC ========================
# 1. Extract and parse blocks from both files (original + processed + simplified)
debug_print("Starting to parse File A: $file_a");
my ($blocks_a, $processed_blocks_a, $simplified_blocks_a) = parse_file($file_a);
debug_print("File A parsed: " . scalar @$blocks_a . " original blocks, " . scalar @$processed_blocks_a . " processed blocks, " . scalar @$simplified_blocks_a . " simplified blocks");

debug_print("Starting to parse File B: $file_b");
my ($blocks_b, $processed_blocks_b, $simplified_blocks_b) = parse_file($file_b);
debug_print("File B parsed: " . scalar @$blocks_b . " original blocks, " . scalar @$processed_blocks_b . " processed blocks, " . scalar @$simplified_blocks_b . " simplified blocks");

# Statistics of basic data
my $total_blocks_a = scalar @$blocks_a;
my $total_blocks_b = scalar @$blocks_b;
debug_print("Basic statistics:", "Total blocks in A: $total_blocks_a", "Total blocks in B: $total_blocks_b");

# 2. Build mapping from processed blocks to original blocks (for comparison)
my %proc_to_original_a = map { $processed_blocks_a->[$_] => $blocks_a->[$_] } 0..$#$blocks_a;
my %proc_to_original_b = map { $processed_blocks_b->[$_] => $blocks_b->[$_] } 0..$#$blocks_b;
# Fixed: keys operates on hash itself, not reference
debug_print("Mapping built: processed blocks -> original blocks (A: " . scalar keys(%proc_to_original_a) . ", B: " . scalar keys(%proc_to_original_b) . ")");

# 3. Build mapping from simplified blocks to processed/original blocks (for output)
my %simp_to_processed_a = map { $simplified_blocks_a->[$_] => $processed_blocks_a->[$_] } 0..$#$simplified_blocks_a;
my %simp_to_processed_b = map { $simplified_blocks_b->[$_] => $processed_blocks_b->[$_] } 0..$#$simplified_blocks_b;
my %simp_to_original_a  = map { $simplified_blocks_a->[$_] => $blocks_a->[$_] } 0..$#$simplified_blocks_a;
my %simp_to_original_b  = map { $simplified_blocks_b->[$_] => $blocks_b->[$_] } 0..$#$simplified_blocks_b;
# Fixed: add parentheses to ensure correct syntax
debug_print("Mapping built: simplified blocks -> processed/original blocks (A: " . scalar keys(%simp_to_original_a) . ", B: " . scalar keys(%simp_to_original_b) . ")");

# 4. Build comparison sets (based on processed blocks)
my (%set_a, %set_b);
@set_a{@$processed_blocks_a} = (0..$#$processed_blocks_a);  # Processed block => original index
@set_b{@$processed_blocks_b} = (0..$#$processed_blocks_b);
# Fixed: add parentheses to ensure correct syntax
debug_print("Comparison sets built: A (" . scalar keys(%set_a) . " unique processed blocks), B (" . scalar keys(%set_b) . " unique processed blocks)");

# 5. Categorize results: intersection, only A, only B
my (@intersection, @only_a, @only_b);
foreach my $proc (keys %set_a) {
  if (exists $set_b{$proc}) {
    push @intersection, $proc;
  } else {
    push @only_a, $proc;
  }
}
foreach my $proc (keys %set_b) {
  push @only_b, $proc unless exists $set_a{$proc};
}

# Statistics of comparison data
my $intersection_count = scalar @intersection;
my $only_a_count       = scalar @only_a;
my $only_b_count       = scalar @only_b;
debug_print("Comparison results:",
  "Common blocks: $intersection_count",
  "Blocks only in A: $only_a_count",
  "Blocks only in B: $only_b_count"
);

# 6. Sort intersection (by specified rule)
my @sorted_intersection;
if ($order_by eq 'A') {
  # Sort by original order of file A
  @sorted_intersection = sort { $set_a{$a} <=> $set_a{$b} } @intersection;
} elsif ($order_by eq 'B') {
  # Sort by original order of file B
  @sorted_intersection = sort { $set_b{$a} <=> $set_b{$b} } @intersection;
} elsif ($order_by eq 'BOTH') {
  # Keep original order respectively (intersection sorted by A here)
  @sorted_intersection = sort { $set_a{$a} <=> $set_a{$b} } @intersection;
} else {
  die "Invalid order_by value: $order_by. Must be A/B/BOTH\n";
}
debug_print("Intersection sorted by $order_by: " . scalar @sorted_intersection . " blocks");

# 7. Sort only A/only B (by their original order)
my @sorted_only_a = sort { $set_a{$a} <=> $set_a{$b} } @only_a;
my @sorted_only_b = sort { $set_b{$a} <=> $set_b{$b} } @only_b;
debug_print("Only A sorted: " . scalar @sorted_only_a . " blocks", "Only B sorted: " . scalar @sorted_only_b . " blocks");

# 8. Generate 8 output files
# Build output path: output directory + output prefix + original filename (NO extra underscore)
my $get_output_path = sub {
  my ($filename) = @_;
  # Ensure directory path ends with '/'
  my $dir = $output_dir;
  $dir .= '/' unless $dir =~ /\/$/;
  # Direct concatenation (no extra underscore between prefix and filename)
  return $dir . $output_prefix . $filename;
};
debug_print("Output path function initialized: prefix='$output_prefix', dir='$output_dir'");

# Output original blocks: intersection(A), intersection(B), only A, only B (UNMODIFIED original content)
my $orig_a_path = $get_output_path->("intersection_original_A.txt");
write_blocks_to_file($orig_a_path, \@sorted_intersection, \%proc_to_original_a, 0);
debug_print("Original blocks written: $orig_a_path");

my $orig_b_path = $get_output_path->("intersection_original_B.txt");
write_blocks_to_file($orig_b_path, \@sorted_intersection, \%proc_to_original_b, 0);
debug_print("Original blocks written: $orig_b_path");

my $only_a_orig_path = $get_output_path->("only_A_original.txt");
write_blocks_to_file($only_a_orig_path, \@sorted_only_a, \%proc_to_original_a, 0);
debug_print("Original blocks written: $only_a_orig_path");

my $only_b_orig_path = $get_output_path->("only_B_original.txt");
write_blocks_to_file($only_b_orig_path, \@sorted_only_b, \%proc_to_original_b, 0);
debug_print("Original blocks written: $only_b_orig_path");

# Output simplified blocks: intersection(A), intersection(B), only A, only B (line-level match, original order)
# Build reverse mapping from processed blocks to simplified blocks (for output)
my %processed_to_simplified_a = reverse %simp_to_processed_a;
my %processed_to_simplified_b = reverse %simp_to_processed_b;
my @sorted_intersection_simp_a = map { $processed_to_simplified_a{$_} } @sorted_intersection;
my @sorted_intersection_simp_b = map { $processed_to_simplified_b{$_} } @sorted_intersection;
my @sorted_only_a_simp = map { $processed_to_simplified_a{$_} } @sorted_only_a;
my @sorted_only_b_simp = map { $processed_to_simplified_b{$_} } @sorted_only_b;
# Fixed: add parentheses to ensure correct syntax
debug_print("Reverse mapping built: processed blocks -> simplified blocks (A: " . scalar keys(%processed_to_simplified_a) . ", B: " . scalar keys(%processed_to_simplified_b) . ")");

my $simp_a_path = $get_output_path->("intersection_simplified_A.txt");
write_blocks_to_file($simp_a_path, \@sorted_intersection_simp_a, \%simp_to_original_a, 1);
debug_print("Simplified blocks written: $simp_a_path");

my $simp_b_path = $get_output_path->("intersection_simplified_B.txt");
write_blocks_to_file($simp_b_path, \@sorted_intersection_simp_b, \%simp_to_original_b, 1);
debug_print("Simplified blocks written: $simp_b_path");

my $only_a_simp_path = $get_output_path->("only_A_simplified.txt");
write_blocks_to_file($only_a_simp_path, \@sorted_only_a_simp, \%simp_to_original_a, 1);
debug_print("Simplified blocks written: $only_a_simp_path");

my $only_b_simp_path = $get_output_path->("only_B_simplified.txt");
write_blocks_to_file($only_b_simp_path, \@sorted_only_b_simp, \%simp_to_original_b, 1);
debug_print("Simplified blocks written: $only_b_simp_path");

# 9. Generate summary report
generate_summary_report(
  $total_blocks_a, $total_blocks_b,
  $intersection_count, $only_a_count, $only_b_count,
  $get_output_path
);

print "\nComparison completed! All output files are saved to: $output_dir\n";
debug_print("Script execution completed successfully");

# ======================== SUBROUTINES ========================

# Debug print function: print intermediate steps only if debug mode is enabled
sub debug_print {
  return unless $debug;
  my @messages = @_;
  print "\n[DEBUG] " . localtime() . "\n";
  foreach my $msg (@messages) {
    print "  - $msg\n";
  }
}

# Validate parameter legality
sub validate_parameters {
  debug_print("Starting parameter validation");
  
  # Check file existence
  unless (-f $file_a) {
    die "Error: File A ($file_a) does not exist or is not a regular file.\n";
  }
  unless (-f $file_b) {
    die "Error: File B ($file_b) does not exist or is not a regular file.\n";
  }
  debug_print("File existence check passed: A=$file_a, B=$file_b");

  # Validate block splitting mode
  unless ($block_mode =~ /^(start|end|start_end|separator)$/i) {
    die "Error: block_mode must be 'start', 'end', 'start_end', or 'separator' (case-insensitive).\n";
  }
  $block_mode = lc($block_mode); # Unify to lowercase (only for mode validation, not comparison)
  debug_print("Block mode validated: $block_mode");

  # Validate block splitting regex (as needed)
  if ($block_mode eq 'start' || $block_mode eq 'start_end') {
    unless ($start_regex) {
      die "Error: startRegex is required for '$block_mode' mode.\n";
    }
    eval { qr/$start_regex/ };
    if ($@) {
      die "Error: Invalid startRegex ($start_regex): $@\n";
    }
  }
  if ($block_mode eq 'end' || $block_mode eq 'start_end') {
    unless ($end_regex) {
      die "Error: endRegex is required for '$block_mode' mode.\n";
    }
    eval { qr/$end_regex/ };
    if ($@) {
      die "Error: Invalid endRegex ($end_regex): $@\n";
    }
  }
  if ($block_mode eq 'separator') {
    eval { qr/$sep_regex/ };
    if ($@) {
      die "Error: Invalid sepRegex ($sep_regex): $@\n";
    }
  }
  debug_print("Block splitting regex validation passed");

  # Validate simplify regex
  eval { qr/$simplify_regex/ };
  if ($@) {
    die "Error: Invalid simplify regex ($simplify_regex): $@\n";
  }
  debug_print("Simplify regex validation passed: $simplify_regex");

  # Validate sorting rule
  unless ($order_by =~ /^[AB](OTH)?$/i) {
    die "Error: orderBy must be 'A', 'B', or 'BOTH' (case-insensitive).\n";
  }
  $order_by = uc($order_by); # Unify to uppercase (only for validation, not comparison)
  debug_print("Sorting rule validated: $order_by");

  # Replace escape characters in prefix/suffix/separator (\n, \t)
  $block_prefix =~ s/\\n/\n/g;
  $block_prefix =~ s/\\t/\t/g;
  $block_suffix =~ s/\\n/\n/g;
  $block_suffix =~ s/\\t/\t/g;
  $block_sep    =~ s/\\n/\n/g;
  $block_sep    =~ s/\\t/\t/g;
  debug_print("Escape characters replaced in prefix/suffix/separator",
    "Prefix: " . (defined $block_prefix ? $block_prefix : "undef"),
    "Suffix: " . (defined $block_suffix ? $block_suffix : "undef"),
    "Separator: " . (defined $block_sep ? $block_sep : "undef")
  );
  
  debug_print("Parameter validation completed successfully");
}

# Parse file: support multi-mode extraction of original/processed/simplified blocks
sub parse_file {
  my ($file) = @_;
  debug_print("Parsing file: $file", "Block mode: $block_mode");
  
  my (@original_blocks, @processed_blocks, @simplified_blocks);
  my $current_block = '';
  my $in_block = 0; # Mark if inside a block (for start/end/start_end mode)

  # Read file
  open my $fh, '<', $file or die "Cannot open $file for reading: $!\n";
  while (my $line = <$fh>) {
    chomp $line;
    my $line_original = $line; # Keep original line (avoid modification affecting judgment)

    # Split blocks according to different modes
    if ($block_mode eq 'separator') {
      # Separator mode: split blocks when separator is matched (default empty line)
      if ($line =~ /$sep_regex/) {
        if ($current_block !~ /^\s*$/) { # Ignore empty blocks
          push @original_blocks, $current_block;
          debug_print("Found non-empty block (separator mode), processing...", "Block content preview: " . substr($current_block, 0, 50) . "...");
          
          # Process block (execute custom command)
          my $processed_block = process_block($current_block);
          push @processed_blocks, $processed_block;
          
          # Generate simplified block (line-level match, original order, replace consecutive spaces)
          my $simplified_block = generate_simplified_block($current_block);
          push @simplified_blocks, $simplified_block;
          debug_print("Block processed: simplified lines count: " . scalar(split /\n/, $simplified_block));
        }
        $current_block = '';
      } else {
        $current_block .= "$line_original\n";
      }
    } else {
      # start/end/start_end mode
      if ($block_mode eq 'start') {
        # Start mode: start new block when start regex is matched, end before next start
        if ($line =~ /$start_regex/) {
          if ($current_block !~ /^\s*$/) { # Save previous non-empty block
            push @original_blocks, $current_block;
            debug_print("Found non-empty block (start mode), processing...", "Block content preview: " . substr($current_block, 0, 50) . "...");
            
            my $processed_block = process_block($current_block);
            push @processed_blocks, $processed_block;
            
            my $simplified_block = generate_simplified_block($current_block);
            push @simplified_blocks, $simplified_block;
            debug_print("Block processed: simplified lines count: " . scalar(split /\n/, $simplified_block));
          }
          $current_block = "$line_original\n";
          $in_block = 1;
          debug_print("New block started (start regex matched): $start_regex");
        } elsif ($in_block) {
          $current_block .= "$line_original\n";
        }
      } elsif ($block_mode eq 'end') {
        # End mode: end block when end regex is matched
        if ($line =~ /$end_regex/) {
          $current_block .= "$line_original\n";
          if ($current_block !~ /^\s*$/) {
            push @original_blocks, $current_block;
            debug_print("Found non-empty block (end mode), processing...", "Block content preview: " . substr($current_block, 0, 50) . "...");
            
            my $processed_block = process_block($current_block);
            push @processed_blocks, $processed_block;
            
            my $simplified_block = generate_simplified_block($current_block);
            push @simplified_blocks, $simplified_block;
            debug_print("Block processed: simplified lines count: " . scalar(split /\n/, $simplified_block));
          }
          $current_block = '';
          $in_block = 0;
          debug_print("Block ended (end regex matched): $end_regex");
        } else {
          $current_block .= "$line_original\n";
          $in_block = 1;
        }
      } elsif ($block_mode eq 'start_end') {
        # Start_end mode: start with start regex, end with end regex
        if ($line =~ /$start_regex/) {
          $current_block = "$line_original\n";
          $in_block = 1;
          debug_print("New block started (start_end mode): $start_regex");
        } elsif ($line =~ /$end_regex/ && $in_block) {
          $current_block .= "$line_original\n";
          if ($current_block !~ /^\s*$/) {
            push @original_blocks, $current_block;
            debug_print("Found non-empty block (start_end mode), processing...", "Block content preview: " . substr($current_block, 0, 50) . "...");
            
            my $processed_block = process_block($current_block);
            push @processed_blocks, $processed_block;
            
            my $simplified_block = generate_simplified_block($current_block);
            push @simplified_blocks, $simplified_block;
            debug_print("Block processed: simplified lines count: " . scalar(split /\n/, $simplified_block));
          }
          $current_block = '';
          $in_block = 0;
          debug_print("Block ended (start_end mode): $end_regex");
        } elsif ($in_block) {
          $current_block .= "$line_original\n";
        }
      }
    }
  }
  close $fh;
  debug_print("File read completed: $file");

  # Process the last block at the end of file
  if ($current_block !~ /^\s*$/) {
    push @original_blocks, $current_block;
    debug_print("Processing last block in file: $file", "Block content preview: " . substr($current_block, 0, 50) . "...");
    
    my $processed_block = process_block($current_block);
    push @processed_blocks, $processed_block;
    
    my $simplified_block = generate_simplified_block($current_block);
    push @simplified_blocks, $simplified_block;
    debug_print("Last block processed: simplified lines count: " . scalar(split /\n/, $simplified_block));
  }

  debug_print("File parsing completed: $file", 
    "Original blocks: " . scalar @original_blocks,
    "Processed blocks: " . scalar @processed_blocks,
    "Simplified blocks: " . scalar @simplified_blocks
  );
  
  return (\@original_blocks, \@processed_blocks, \@simplified_blocks);
}

# Execute block processing command with pipe support
sub process_block {
  my ($block) = @_;
  return $block unless $block_process_cmd; # Return original block if no command
  debug_print("Executing block processing command: $block_process_cmd", "Block content preview: " . substr($block, 0, 50) . "...");

  # Create temporary file to store block content
  my $temp_file = "/tmp/block_process_$$.tmp";
  open my $tmp_fh, '>', $temp_file or die "Cannot create temp file $temp_file: $!\n";
  print $tmp_fh $block;
  close $tmp_fh;
  debug_print("Temporary file created: $temp_file");

  # Build full command with pipe: cat temp_file | custom command
  my $full_cmd = "cat $temp_file $block_process_cmd";
  debug_print("Full processing command: $full_cmd");
  
  # Execute processing command and capture stdout
  my $processed = `$full_cmd`;
  if ($?) {
    die "Error executing block process command '$full_cmd': Exit code $?\n";
  }
  debug_print("Command executed successfully: output preview: " . substr($processed, 0, 50) . "...");

  # Clean up temporary file
  unlink $temp_file or warn "Warning: Cannot delete temp file $temp_file: $!\n";
  debug_print("Temporary file deleted: $temp_file");

  return $processed;
}

# Generate simplified block: line-level match (partial match allowed) + original order + replace consecutive spaces with single space
sub generate_simplified_block {
  my ($block) = @_;
  debug_print("Generating simplified block: regex=$simplify_regex", "Original block lines count: " . scalar(split /\n/, $block));
  
  # Split block into lines (preserve original line breaks)
  my @lines = split /\n/, $block;
  # Filter lines that PARTIALLY match the regex (not just full line) + preserve original order
  my @filtered_lines = grep { /$simplify_regex/ } @lines;
  
  # Replace consecutive spaces (2 or more) with single space in each filtered line
  my @processed_lines;
  foreach my $line (@filtered_lines) {
    $line =~ s/\s{2,}/ /g; # Replace 2+ consecutive spaces with 1 space
    push @processed_lines, $line;
  }
  
  # Join lines with original line breaks
  my $simplified = join "\n", @processed_lines;
  
  debug_print("Simplified block generated: filtered lines count: " . scalar @processed_lines);
  return $simplified;
}

# Write blocks to file (support original/simplified mode)
# - Original mode: write UNMODIFIED original content
# - Simplified mode: write filtered lines (original order, consecutive spaces replaced)
# - Prefix/suffix/separator: new line separation from content
sub write_blocks_to_file {
  my ($filename, $item_list, $item_to_original, $is_simplified) = @_;
  debug_print("Writing blocks to file: $filename", "Mode: " . ($is_simplified ? "simplified" : "original"), "Items count: " . scalar @$item_list);

  open my $fh, '>', $filename or die "Cannot open $filename for writing: $!\n";
  my $block_id = 1;
  foreach my $item (@$item_list) {
    my $content;
    if ($is_simplified) {
      # Simplified block: use pre-generated simplified content (with consecutive spaces replaced)
      $content = $item;
      debug_print("Processing simplified block $block_id: content preview: " . substr($content, 0, 50) . "...");
    } else {
      # Original block: use UNMODIFIED original content
      $content = $item_to_original->{$item};
      debug_print("Processing original block $block_id: content preview: " . substr($content, 0, 50) . "...");
    }

    # Replace <id> in prefix/suffix with actual block sequence number
    my $prefix = $block_prefix;
    $prefix =~ s/<id>/$block_id/g;
    my $suffix = $block_suffix;
    $suffix =~ s/<id>/$block_id/g;

    # Ensure prefix/suffix/separator are on new lines (add \n if not present)
    # Prefix: add newline at end to separate from content
    $prefix .= "\n" unless $prefix =~ /\n$/;
    # Suffix: add newline at start to separate from content
    $suffix = "\n$suffix" unless $suffix =~ /^\n/;
    # Separator: ensure it's on a new line
    my $separator = $block_sep;
    $separator = "\n$separator" unless $separator =~ /^\n/;

    # Write block: prefix (new line) + content + suffix (new line) + separator (new line)
    print $fh $prefix;
    print $fh $content if defined $content;
    print $fh $suffix;
    print $fh $separator unless $block_id == scalar @$item_list; # No separator for last block

    debug_print("Block $block_id written to $filename");
    $block_id++;
  }
  close $fh;
  debug_print("All blocks written to file: $filename");
}

# Generate dynamic-width summary report
sub generate_summary_report {
  my ($total_a, $total_b, $intersection, $only_a, $only_b, $path_func) = @_;
  debug_print("Generating summary report");

  # Define table data
  my @table_data = (
    ['Metric', 'Value'],
    ['Total blocks in File A', $total_a],
    ['Total blocks in File B', $total_b],
    ['Common blocks (both A and B)', $intersection],
    ['Blocks only in File A', $only_a],
    ['Blocks only in File B', $only_b],
    ['Unique blocks in A (percentage)', sprintf("%.1f%%", $only_a/$total_a*100)],
    ['Unique blocks in B (percentage)', sprintf("%.1f%%", $only_b/$total_b*100)],
    ['Common blocks percentage (A)', sprintf("%.1f%%", $intersection/$total_a*100)],
    ['Common blocks percentage (B)', sprintf("%.1f%%", $intersection/$total_b*100)],
  );

  # Calculate column widths (dynamically adapt to content)
  my $col1_width = 0;
  my $col2_width = 0;
  foreach my $row (@table_data) {
    $col1_width = length($row->[0]) if length($row->[0]) > $col1_width;
    $col2_width = length($row->[1]) if length($row->[1]) > $col2_width;
  }
  $col1_width += 2; # Extra margin
  $col2_width += 2;

  # Generate separator line
  my $separator = '+' . '-' x $col1_width . '+' . '-' x $col2_width . '+';

  # Print summary table
  print "\n" . '=' x ($col1_width + $col2_width + 5) . "\n";
  print "                BLOCK COMPARISON SUMMARY                \n";
  print '=' x ($col1_width + $col2_width + 5) . "\n\n";
  print "$separator\n";
  foreach my $row (@table_data) {
    my $col1 = sprintf("%-${col1_width}s", $row->[0]);
    my $col2 = sprintf("%-${col2_width}s", $row->[1]);
    print "| $col1 | $col2 |\n";
    print "$separator\n";
  }

  # Print output file list
  print "\nOutput Files:\n";
  print "  1. Original Blocks (UNMODIFIED content):\n";
  print "     - Common (A): " . $path_func->("intersection_original_A.txt") . "\n";
  print "     - Common (B): " . $path_func->("intersection_original_B.txt") . "\n";
  print "     - Only A:     " . $path_func->("only_A_original.txt") . "\n";
  print "     - Only B:     " . $path_func->("only_B_original.txt") . "\n";
  print "  2. Simplified Blocks (line-level match, original order, consecutive spaces replaced):\n";
  print "     - Common (A): " . $path_func->("intersection_simplified_A.txt") . "\n";
  print "     - Common (B): " . $path_func->("intersection_simplified_B.txt") . "\n";
  print "     - Only A:     " . $path_func->("only_A_simplified.txt") . "\n";
  print "     - Only B:     " . $path_func->("only_B_simplified.txt") . "\n";
  
  debug_print("Summary report generated successfully");
}

# Print help documentation
sub print_help {
  my $script_name = basename($0);
  print <<"HELP";
Usage: $script_name [OPTIONS]

Description:
  Compares blocks of information between two files (A and B) with flexible block splitting modes,
  processes blocks with custom commands before comparison, categorizes blocks into intersection, 
  only A, only B, and generates 8 output files (4 original + 4 simplified) with configurable 
  output path and file prefix. A dynamic-width summary report is also generated.
  - Case-sensitive comparison for block content
  - Simplified blocks: replace consecutive spaces (2+) with single space

Options (short/long, default value):
  # Basic File Configuration
  -a --fileA       Path to file A (old file)          [default: $DEFAULT_FILE_A]
  -b --fileB       Path to file B (new file)          [default: $DEFAULT_FILE_B]

  # Block Splitting Configuration
  -m --mode        Block splitting mode               [default: $DEFAULT_BLOCK_MODE]
                   (start/end/start_end/separator)
  -t --startRegex  Regex to match block start line    [default: '$DEFAULT_START_REGEX']
                   (required for start/start_end mode)
  -e --endRegex    Regex to match block end line      [default: '$DEFAULT_END_REGEX']
                   (required for end/start_end mode)
  -k --sepRegex    Regex to match block separator     [default: '$DEFAULT_SEP_REGEX']
                   (used for separator mode)

  # Block Processing Configuration
  -c --processCmd  Command to process each block      [default: '$DEFAULT_BLOCK_PROCESS_CMD']
                   (e.g., '| sed -ne '/Point/,/data arrival time/p' | grep 'BWP' | awk '{print \$1}'')

  # Simplified Block Configuration
  -r --regex       Regex for line-level block simplification [default: '$DEFAULT_SIMPLIFY_REGEX']
                   (partial line match allowed, preserves original order, replaces consecutive spaces)

  # Sorting Configuration
  -o --orderBy     Sort intersection blocks by        [default: $DEFAULT_ORDER_BY]
                   (A=file A order, B=file B order, BOTH=respective original order)

  # Block Format Configuration
  -p --prefix      Block prefix (supports <id>, \\n, \\t) [default: '$DEFAULT_BLOCK_PREFIX']
                   (automatically followed by a new line)
  -s --suffix      Block suffix (supports <id>, \\n, \\t) [default: '$DEFAULT_BLOCK_SUFFIX']
                   (automatically preceded by a new line)
  -d --separator   Separator between blocks           [default: '$DEFAULT_BLOCK_SEP']
                   (automatically on a new line)

  # Output Configuration
  -f --outputPrefix Prefix for output filenames       [default: '$DEFAULT_OUTPUT_PREFIX']
                   (no extra underscore added, e.g., 'diff_' -> 'diff_originalA.txt')
  -l --outputDir   Directory for output files         [default: $DEFAULT_OUTPUT_DIR]
                   (created automatically if not exists, uses current dir if empty)

  # Debug Configuration
  -g --debug       Enable debug mode (print intermediate steps) [default: $DEFAULT_DEBUG_MODE]

  # Help
  -h --help        Show this help message and exit

Examples:
  1. Basic usage with default settings:
     $script_name -a old.log -b new.log

  2. Advanced usage with debug mode and custom output:
     $script_name -a /data/old.txt -b /data/new.txt -g \\
       -f 'diff_' -l /data/comparison -r 'BWP:'

  3. Custom block format (prefix/suffix with new lines):
     $script_name -p "Block <id>" -s "End <id>" -d "=== NEXT BLOCK ==="

Output Files (with default prefix 'diff_' and dir './'):
  ./diff_intersection_original_A.txt
  ./diff_intersection_original_B.txt
  ./diff_only_A_original.txt
  ./diff_only_B_original.txt
  ./diff_intersection_simplified_A.txt
  ./diff_intersection_simplified_B.txt
  ./diff_only_A_simplified.txt
  ./diff_only_B_simplified.txt

Notes:
  - Original blocks: written as-is (NO modifications, preserve all content)
  - Simplified blocks: lines that partially match simplify regex (preserve original order, 2+ spaces -> 1 space)
  - Block comparison: CASE-SENSITIVE (no case conversion)
  - Prefix/suffix/separator: automatically separated from content by new lines
  - Output prefix: no extra underscore added (user-provided underscores are preserved)
  - Debug mode (-g): prints intermediate processing steps (file parsing, block processing, mapping)
  - All parameters are case-insensitive for short options (only for parameter parsing, not block comparison)
HELP
}
