#!/usr/bin/perl
# --------------------------
# author    : sar song
# date      : 2026/02/10 10:00:00 Tuesday
# label     : getInfo_sub
# descrip   : This Perl script extracts text blocks from input (compressed/plain), processes each block with piped shell commands,
#             deduplicates blocks based on extracted numeric values (keep larger/smaller), sorts remaining blocks,
#             and writes to output with customizable formatting. Supports debug mode, summary stats, and strict validation.
# return    : deduplicated & sorted block output file
# --------------------------
use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use File::Spec;
use IO::Uncompress::AnyUncompress qw($AnyUncompressError);
use IPC::Open3;
use Symbol qw(gensym);

# ==============================
# DEFAULT CONFIGURATION (EASY TO MODIFY)
# ==============================
# Block Extraction (mirror block_classifier.pl)
our $DEFAULT_METHOD = 'start_end';                  # Block extraction method (start/separator/end/start_end)
our $DEFAULT_START_PATTERN = 'Startpoint';          # Regex for block start line
our $DEFAULT_SEPARATOR_PATTERN = '';                # Regex for block separator line
our $DEFAULT_END_PATTERN = 'slack \(VIOLATED(:\s.*)?\)';    # Regex for block end line
# Input/Output
our $DEFAULT_INPUT_FILE = '';                       # Input file path (required)
our $DEFAULT_OUTPUT_FILE = '';                      # Output file path (auto: input dir + dedup_filename if empty)
# Block Processing
our $DEFAULT_BLOCK_PROCESS_CMD = "| sed -ne '/Point/,/data arrival time/p' | grep 'BWP' | awk '{print \$1}'";                # Piped shell cmd for block processing (e.g., "| sed -n '/slack/p' | awk '{print $2}'")
our $DEFAULT_NUM_REGEX = 'slack \(VIOLATED.*\)\s+(-\d+\.\d+)\s*$'; # Regex to extract numeric value
our $DEFAULT_CAPTURE_GROUP = 1;                     # Capture group index for numeric value (1-based)
our $DEFAULT_KEEP = 'smaller';                      # Keep 'larger' or 'smaller' numeric value
# Output Formatting
our $DEFAULT_BLOCK_PREFIX = 'songpath <id>:';          # Prefix for each output block (supports \n/\t/<id>)
our $DEFAULT_BLOCK_SUFFIX = '';                     # Suffix for each output block (supports \n/\t/<id>)
our $DEFAULT_BLOCK_SEP = "\n---\n";                 # Separator between output blocks
# Sorting
our $DEFAULT_SORT_METHOD = 'smaller_first';              # Sort method: original/larger_first/smaller_first
# Logging/Debug
our $DEFAULT_DEBUG = 0;                             # Debug mode (0=off, 1=on)
our $DEFAULT_SHOW_SUMMARY = 1;                      # Show summary table (0=off, 1=on)

# ==============================
# Initialize Parameters
# ==============================
my $method = $DEFAULT_METHOD;
my $start_pattern = $DEFAULT_START_PATTERN;
my $separator_pattern = $DEFAULT_SEPARATOR_PATTERN;
my $end_pattern = $DEFAULT_END_PATTERN;
my $input_file = $DEFAULT_INPUT_FILE;
my $output_file = $DEFAULT_OUTPUT_FILE;
my $block_process_cmd = $DEFAULT_BLOCK_PROCESS_CMD;
my $num_regex = $DEFAULT_NUM_REGEX;
my $capture_group = $DEFAULT_CAPTURE_GROUP;
my $keep = $DEFAULT_KEEP;
my $block_prefix = $DEFAULT_BLOCK_PREFIX;
my $block_suffix = $DEFAULT_BLOCK_SUFFIX;
my $block_sep = $DEFAULT_BLOCK_SEP;
my $sort_method = $DEFAULT_SORT_METHOD;
my $debug = $DEFAULT_DEBUG;
my $show_summary = $DEFAULT_SHOW_SUMMARY;
my $help = 0;

# ==============================
# Command Line Option Parsing
# ==============================
GetOptions(
  # Block Extraction
  'method|m=s'          => \$method,
  'start|s=s'           => \$start_pattern,
  'separator|r=s'       => \$separator_pattern,
  'end|e=s'             => \$end_pattern,
  # Input/Output
  'input|i=s'           => \$input_file,
  'output|o=s'          => \$output_file,
  # Block Processing
  'process-cmd|p=s'     => \$block_process_cmd,
  'num-regex|n=s'       => \$num_regex,
  'capture-group|g=i'   => \$capture_group,
  'keep|k=s'            => \$keep,
  # Output Formatting
  'block-prefix|b=s'    => \$block_prefix,
  'block-suffix|x=s'    => \$block_suffix,
  'block-sep|t=s'       => \$block_sep,
  # Sorting
  'sort-method|S=s'     => \$sort_method,
  # Debug/Summary
  'debug|D!'            => \$debug,
  'show-summary|S!'     => \$show_summary,
  'help|h!'             => \$help
) or do {
  print STDERR "Error: Invalid command line arguments! Use --help for usage.\n";
  exit 1;
};

# Show help and exit
if ($help) {
  &print_help();
  exit 0;
}

# ==============================
# Validation
# ==============================
# Input file validation
unless ($input_file && -e $input_file && -r $input_file) {
  die "ERROR: Input file '$input_file' does not exist or is unreadable!\n";
}

# Method validation
my %valid_methods = (start=>1, separator=>1, end=>1, start_end=>1);
unless ($valid_methods{lc $method}) {
  die "ERROR: Invalid method '$method'! Valid: start, separator, end, start_end\n";
}
my $standard_method = lc $method;

# Pattern validation for methods
if ($standard_method eq 'start' && !$start_pattern) {
  die "ERROR: --start pattern required for 'start' method!\n";
} elsif ($standard_method eq 'separator' && !$separator_pattern) {
  die "ERROR: --separator pattern required for 'separator' method!\n";
} elsif ($standard_method eq 'end' && !$end_pattern) {
  die "ERROR: --end pattern required for 'end' method!\n";
} elsif ($standard_method eq 'start_end' && (!$start_pattern || !$end_pattern)) {
  die "ERROR: --start and --end patterns required for 'start_end' method!\n";
}

# Keep value validation
unless ($keep eq 'larger' || $keep eq 'smaller') {
  die "ERROR: --keep must be 'larger' or 'smaller' (current: $keep)\n";
}

# Sort method validation
my %valid_sort = (original=>1, larger_first=>1, smaller_first=>1);
unless ($valid_sort{lc $sort_method}) {
  die "ERROR: Invalid sort method '$sort_method'! Valid: original, larger_first, smaller_first\n";
}

# Capture group validation
unless ($capture_group =~ /^\d+$/ && $capture_group >= 1) {
  die "ERROR: Capture group must be positive integer (current: $capture_group)\n";
}

# Auto-generate output file if not specified
if (!$output_file) {
  my ($name, $dir, $ext) = fileparse($input_file, qr/\.[^.]*/);
  # Add 'dedup_' prefix to filename instead of appending suffix
  $output_file = File::Spec->catfile($dir, "dedup_${name}${ext}");
}
$debug && print "DEBUG: Output file set to '$output_file'\n";

# Parse escape sequences for formatting
eval {
  $block_prefix = $block_prefix =~ s/\\n/\n/gr =~ s/\\t/\t/gr;
  $block_suffix = $block_suffix =~ s/\\n/\n/gr =~ s/\\t/\t/gr;
  $block_sep = $block_sep =~ s/\\n/\n/gr =~ s/\\t/\t/gr;
};
if ($@) {
  die "ERROR: Invalid escape sequence in formatting options: $@\n";
}

# Validate output directory writability
my $output_dir = File::Basename::dirname($output_file);
unless (-w $output_dir) {
  die "ERROR: Output directory '$output_dir' is not writable!\n";
}

# ==============================
# Core Variables
# ==============================
my @blocks;                     # All extracted blocks (raw content + processed content + numeric value + original index)
my $in_block = 0;               # Flag: inside a block
my @current_block;              # Current block lines
my $total_blocks = 0;           # Total extracted blocks
my $block_index = 0;            # Original index of blocks (for "original" sort)

# ==============================
# Open Input Stream (Compressed/Plain)
# ==============================
my $in_fh;
if ($input_file) {
  $in_fh = IO::Uncompress::AnyUncompress->new($input_file) 
    or die "ERROR: Cannot open input file '$input_file' - $AnyUncompressError\n";
} else {
  open $in_fh, '<', \*STDIN or die "ERROR: Cannot read from STDIN - $!\n";
}
$debug && print "DEBUG: Started processing input file (compressed support enabled)\n";

# ==============================
# Extract Blocks (mirror block_classifier.pl logic)
# ==============================
while (my $line = <$in_fh>) {
  chomp $line;
  $debug && print "DEBUG: Processing line: '$line'\n";

  if ($standard_method eq 'start') {
    if ($line =~ /$start_pattern/) {
      if ($in_block) {
        &process_raw_block(\@current_block);
        @current_block = ();
      }
      $in_block = 1;
      push @current_block, $line;
    } elsif ($in_block) {
      push @current_block, $line;
    }
  } elsif ($standard_method eq 'separator') {
    if ($line =~ /$separator_pattern/) {
      if ($in_block) {
        &process_raw_block(\@current_block);
        @current_block = ();
        $in_block = 0;
      }
    } else {
      $in_block = 1;
      push @current_block, $line;
    }
  } elsif ($standard_method eq 'end') {
    if ($in_block) {
      push @current_block, $line;
      if ($line =~ /$end_pattern/) {
        &process_raw_block(\@current_block);
        @current_block = ();
        $in_block = 0;
      }
    } else {
      push @current_block, $line;
      $in_block = 1;
    }
  } elsif ($standard_method eq 'start_end') {
    if (!$in_block && $line =~ /$start_pattern/) {
      $in_block = 1;
      push @current_block, $line;
    } elsif ($in_block) {
      push @current_block, $line;
      if ($line =~ /$end_pattern/) {
        &process_raw_block(\@current_block);
        @current_block = ();
        $in_block = 0;
      }
    }
  }
}
close $in_fh or die "ERROR: Failed to close input file - $!\n";

# Process remaining block after EOF
if ($in_block && @current_block) {
  $debug && print "DEBUG: Processing remaining block after EOF\n";
  &process_raw_block(\@current_block);
}

# ==============================
# Deduplicate Blocks
# ==============================
my %dedup_hash;                 # Key: processed content, Value: block data
foreach my $block (@blocks) {
  my $key = $block->{processed_content};
  my $num = $block->{numeric_value};
  
  if (exists $dedup_hash{$key}) {
    my $existing_num = $dedup_hash{$key}->{numeric_value};
    if ($keep eq 'larger') {
      if ($num > $existing_num) {
        $dedup_hash{$key} = $block;
        $debug && print "DEBUG: Updated key '$key' (keep larger): $existing_num -> $num\n";
      }
    } else {
      if ($num < $existing_num) {
        $dedup_hash{$key} = $block;
        $debug && print "DEBUG: Updated key '$key' (keep smaller): $existing_num -> $num\n";
      }
    }
  } else {
    $dedup_hash{$key} = $block;
    $debug && print "DEBUG: Added new key '$key' with value $num\n";
  }
}

# ==============================
# Sort Deduplicated Blocks
# ==============================
my @sorted_blocks;
if ($sort_method eq 'original') {
  @sorted_blocks = sort { $a->{original_index} <=> $b->{original_index} } values %dedup_hash;
} elsif ($sort_method eq 'larger_first') {
  @sorted_blocks = sort { $b->{numeric_value} <=> $a->{numeric_value} } values %dedup_hash;
} elsif ($sort_method eq 'smaller_first') {
  @sorted_blocks = sort { $a->{numeric_value} <=> $b->{numeric_value} } values %dedup_hash;
}
$debug && print "DEBUG: Sorted blocks using method '$sort_method' (total: " . scalar(@sorted_blocks) . ")\n";

# ==============================
# Write Output File
# ==============================
open my $out_fh, '>', $output_file or die "ERROR: Cannot open output file '$output_file' - $!\n";
my $block_id = 1;
foreach my $block (@sorted_blocks) {
  my $raw_content = join("\n", @{$block->{raw_content}});
  
  # Write block separator (skip first block)
  if ($block_id > 1) {
    print $out_fh $block_sep;
  }
  
  # Write block prefix (replace <id>)
  my $prefix = $block_prefix;
  $prefix =~ s/<id>/$block_id/gs;
  print $out_fh $prefix . "\n";
  
  # Write raw block content
  print $out_fh $raw_content . "\n";
  
  # Write block suffix (replace <id>)
  my $suffix = $block_suffix;
  $suffix =~ s/<id>/$block_id/gs;
  print $out_fh $suffix;
  
  $block_id++;
}
close $out_fh or die "ERROR: Failed to close output file - $!\n";
$debug && print "DEBUG: Successfully wrote output to '$output_file'\n";

# ==============================
# Print Summary
# ==============================
if ($show_summary) {
  &print_summary($total_blocks, scalar(@sorted_blocks));
}

exit 0;

# ==============================
# Subroutines
# ==============================

# Process raw block: extract processed content + numeric value
sub process_raw_block {
  my ($block_ref) = @_;
  my @raw_lines = @$block_ref;
  $total_blocks++;
  $block_index++;
  $debug && print "DEBUG: Processing raw block #$total_blocks (lines: " . scalar(@raw_lines) . ")\n";

  # Step 1: Process block with shell command
  my $processed_content = &execute_block_process_cmd(\@raw_lines);
  $debug && print "DEBUG: Block #$total_blocks processed content: '$processed_content'\n";

  # Step 2: Extract numeric value from raw block
  my $numeric_value = &extract_numeric_value(\@raw_lines);
  unless (defined $numeric_value && $numeric_value =~ /^[-+]?\d+(\.\d+)?$/) {
    die "ERROR: Failed to extract valid numeric value from block #$total_blocks (regex: $num_regex, capture group: $capture_group)\n";
  }
  $debug && print "DEBUG: Block #$total_blocks numeric value: $numeric_value\n";

  # Store block data
  push @blocks, {
    raw_content => \@raw_lines,
    processed_content => $processed_content,
    numeric_value => $numeric_value,
    original_index => $block_index
  };
}

# Execute shell command on block content (piped commands)
sub execute_block_process_cmd {
  my ($lines_ref) = @_;
  my $raw_content = join("\n", @$lines_ref);
  
  # Return raw content if no process cmd
  return $raw_content unless $block_process_cmd;

  # Sanitize cmd (remove leading | if present)
  my $cmd = $block_process_cmd;
  $cmd =~ s/^\|//;
  $cmd = "echo '" . $raw_content =~ s/'/'"'"'/gr . "' $cmd"; # Escape single quotes

  $debug && print "DEBUG: Executing block process cmd: $cmd\n";

  # Execute cmd and capture output
  my ($wtr, $rdr, $err);
  $err = gensym;
  my $pid = open3($wtr, $rdr, $err, $cmd);
  waitpid($pid, 0);
  
  my $output = do { local $/; <$rdr> };
  my $error = do { local $/; <$err> };
  
  if ($error) {
    die "ERROR: Failed to execute block process cmd: $error\n";
  }
  
  chomp $output;
  return $output;
}

# Extract numeric value from block using regex + capture group
sub extract_numeric_value {
  my ($lines_ref) = @_;
  my $numeric_value;
  
  foreach my $line (@$lines_ref) {
    if ($line =~ /$num_regex/) {
      my @matches = ($&, $1, $2, $3, $4, $5); # Capture groups 0-5
      $numeric_value = $matches[$capture_group];
      last if defined $numeric_value;
    }
  }
  
  return $numeric_value;
}

# Print summary table with dynamically adjusted column widths
sub print_summary {
  my ($total, $kept) = @_;
  my $removed = $total - $kept;
  
  # Define all metrics and their values
  my %metrics = (
    'Total Blocks Processed'    => $total,
    'Blocks Kept (Deduplicated)'=> $kept,
    'Blocks Removed'            => $removed
  );
  
  # Calculate maximum widths for each column
  my $max_col1 = 0;
  my $max_col2 = 0;
  foreach my $metric (keys %metrics) {
    my $val = $metrics{$metric};
    $max_col1 = length($metric) if length($metric) > $max_col1;
    $max_col2 = length($val) if length($val) > $max_col2;
  }
  # Ensure header columns are also considered
  $max_col1 = length('Metric') if length('Metric') > $max_col1;
  $max_col2 = length('Value') if length('Value') > $max_col2;
  
  # Create separator line ( +1 for space on each side of column values)
  my $separator = '+' . '-' x ($max_col1 + 2) . '+' . '-' x ($max_col2 + 2) . '+';
  
  # Print summary table
  print "\n=== BLOCK DEDUPLICATION SUMMARY ===\n";
  print $separator . "\n";
  printf "| %-${max_col1}s | %${max_col2}s |\n", 'Metric', 'Value';
  print $separator . "\n";
  foreach my $metric (sort keys %metrics) {
    printf "| %-${max_col1}s | %${max_col2}s |\n", $metric, $metrics{$metric};
  }
  print $separator . "\n\n";
}

# Print help message
sub print_help {
  my $script_name = basename($0);
  
  print <<HELP;
Usage: perl $script_name [OPTIONS]

Description:
  Extracts text blocks from input (compressed/plain files), processes each block with piped shell commands,
  deduplicates blocks based on extracted numeric values (keep larger/smaller), sorts remaining blocks,
  and writes to output with customizable formatting.

Mandatory Option:
  -i, --input FILE       Input file path (plain/gzipped/bzip2, required)
                         Default: '$DEFAULT_INPUT_FILE'

Block Extraction Options (mirror block_classifier.pl):
  -m, --method STR       Block extraction method (start/separator/end/start_end)
                         Default: '$DEFAULT_METHOD'
  -s, --start STR        Regex for block start line (required for start/start_end)
                         Default: '$DEFAULT_START_PATTERN'
  -r, --separator STR    Regex for block separator line (required for separator)
                         Default: '$DEFAULT_SEPARATOR_PATTERN'
  -e, --end STR          Regex for block end line (required for end/start_end)
                         Default: '$DEFAULT_END_PATTERN'

Block Processing Options:
  -p, --process-cmd STR  Piped shell command to process each block (e.g., "| sed -n '/slack/p' | awk '{print \$2}'")
                         Default: '$DEFAULT_BLOCK_PROCESS_CMD'
  -n, --num-regex STR    Regex to extract numeric value from block (supports capture groups)
                         Default: '$DEFAULT_NUM_REGEX'
  -g, --capture-group INT Capture group index for numeric value (1-based)
                         Default: $DEFAULT_CAPTURE_GROUP
  -k, --keep STR         Keep 'larger' or 'smaller' numeric value during deduplication
                         Default: '$DEFAULT_KEEP'

Output Formatting Options:
  -b, --block-prefix STR Prefix for each output block (supports \\n/\\t/<id> for block number)
                         Default: '$DEFAULT_BLOCK_PREFIX' (escaped: 'Block <id>:')
  -x, --block-suffix STR Suffix for each output block (supports \\n/\\t/<id>)
                         Default: '$DEFAULT_BLOCK_SUFFIX'
  -t, --block-sep STR    Separator between output blocks (supports \\n/\\t)
                         Default: '$DEFAULT_BLOCK_SEP' (escaped: '\\n---\\n')

Sorting Options:
  -S, --sort-method STR  Sort method for output blocks:
                           original = keep original input order
                           larger_first = sort by numeric value (descending)
                           smaller_first = sort by numeric value (ascending)
                         Default: '$DEFAULT_SORT_METHOD'

Output Options:
  -o, --output FILE      Output file path (auto: input dir + dedup_filename if empty)
                         Default: '$DEFAULT_OUTPUT_FILE'

Debug/Summary Options:
  -D, --debug            Enable debug mode (print detailed processing logs)
                         Default: @{[$DEFAULT_DEBUG ? 'Enabled' : 'Disabled']}
  --show-summary         Show summary table (toggle: --show-summary/--no-show-summary)
                         Default: @{[$DEFAULT_SHOW_SUMMARY ? 'Enabled' : 'Disabled']}
  -h, --help             Print this help message and exit

Examples:
  1. Basic usage (start_end method, default numeric regex):
     perl $script_name -i input.log -m start_end -s 'Startpoint' -e 'slack \(VIOLATED\)'

  2. Custom processing + keep larger + sort by value:
     perl $script_name -i /path/to/data.gz \\
       -m start_end -s 'Path' -e 'slack' \\
       -p "| sed -n '/slack/p' | awk '{print \$5}'" \\
       -n 'slack:\s+(\d+\.\d+)' -g 1 \\
       -k larger -S larger_first \\
       -o /path/to/custom_output.log \\
       -b "Block <id> (slack):\\n" -t "\\n===\\n" \\
       --debug --show-summary
HELP
}
