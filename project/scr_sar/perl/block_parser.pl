#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use File::Spec;

# Default configuration - overridden by command line options
our $METHOD = 'start';                  # Block extraction method (start/separator/end/start_end)
our $INPUT_FILE = '';                       # Input file path (reads from STDIN if empty)
our $START_PATTERN = '^Path \d+:';          # Regex for block start line (line-wise match)
our $SEPARATOR_PATTERN = '';          # Regex for block separator line (line-wise match)
our $END_PATTERN = '';                # Regex for block end line (line-wise match)
our $FILTER_PATTERN = '\bram_';               # Regex to filter blocks (any line matches)
our $RETAIN_PATTERN = '\bram_|^Path \d+:';               # Regex to extract lines (line-wise match)
our $OUTPUT_FILE = 'reg_mem_reg_pickup.rpt';            # Path to output file
our $BLOCK_SEPARATOR = '';  # Separator between output blocks (auto-newline)
our $BLOCK_PREFIX = 'song_path <id>:';       # Prefix for each output block (auto-newline)
our $BLOCK_SUFFIX = '';                     # Suffix for each output block (auto-newline)
our $DEBUG = 0;                             # Enable debug mode (0=disabled, 1=enabled)
our $ALLOW_EMPTY = 1;                       # Allow empty blocks (0=disable, 1=enable)
my $show_help = 0;                          # Flag for help command

# Parse command line options
GetOptions(
  'method|m=s'        => \$METHOD,
  'input|i=s'         => \$INPUT_FILE,
  'start|s=s'         => \$START_PATTERN,
  'separator|r=s'     => \$SEPARATOR_PATTERN,
  'end|e=s'           => \$END_PATTERN,
  'filter|f=s'        => \$FILTER_PATTERN,
  'retain|t=s'        => \$RETAIN_PATTERN,
  'output|o=s'        => \$OUTPUT_FILE,
  'block-sep|b=s'     => \$BLOCK_SEPARATOR,
  'block-prefix|p=s'  => \$BLOCK_PREFIX,
  'block-suffix|x=s'  => \$BLOCK_SUFFIX,
  'allow-empty|a'     => \$ALLOW_EMPTY,
  'debug|d'           => \$DEBUG,
  'help|h'            => \$show_help,
) or die "Error in command line arguments. Use --help (-h) for usage instructions.\n";

# Show help and exit
if ($show_help) {
  &help;
  exit 0;
}

# Process escape sequences for formatting options
eval {
  $BLOCK_SEPARATOR = qq{$BLOCK_SEPARATOR};
  $BLOCK_PREFIX = qq{$BLOCK_PREFIX};
  $BLOCK_SUFFIX = qq{$BLOCK_SUFFIX};
};
if ($@) {
  die "Invalid escape sequence in formatting option: $@\n";
}

# Validate input file (if provided)
if ($INPUT_FILE) {
  unless (-e $INPUT_FILE) { die "ERROR: Input file '$INPUT_FILE' does not exist\n"; }
  unless (-r $INPUT_FILE) { die "ERROR: Input file '$INPUT_FILE' is not readable\n"; }
  unless (-f $INPUT_FILE) { die "ERROR: '$INPUT_FILE' is not a regular file\n"; }
  $DEBUG && print "DEBUG: Input file validated - '$INPUT_FILE'\n";
}

# Map method to standard name
my %method_map = (
  's'         => 'start',
  'start'     => 'start',
  'r'         => 'separator',
  'sep'       => 'separator',
  'separator' => 'separator',
  'e'         => 'end',
  'end'       => 'end',
  'se'        => 'start_end',
  'b'         => 'start_end',
  'start_end' => 'start_end',
);

# Validate method
unless (exists $method_map{lc $METHOD}) {
  die "Invalid method '$METHOD'. Valid methods: start (s), separator (sep/r), end (e), start_end (se/b).\n";
}
my $standard_method = $method_map{lc $METHOD};
$DEBUG && print "DEBUG: Using extraction method - $standard_method\n";

# Validate required patterns
my $is_valid = 1;
if ($standard_method eq 'start') {
  unless ($START_PATTERN) { print "ERROR: --start (-s) pattern required for 'start' method\n"; $is_valid = 0; }
} elsif ($standard_method eq 'separator') {
  unless ($SEPARATOR_PATTERN) { print "ERROR: --separator (-r) pattern required for 'separator' method\n"; $is_valid = 0; }
} elsif ($standard_method eq 'end') {
  unless ($END_PATTERN) { print "ERROR: --end (-e) pattern required for 'end' method\n"; $is_valid = 0; }
} elsif ($standard_method eq 'start_end') {
  unless ($START_PATTERN && $END_PATTERN) { print "ERROR: --start (-s) and --end (-e) patterns required for 'start_end' method\n"; $is_valid = 0; }
}
exit 1 unless $is_valid;

# Validate output directory
my $output_dir = dirname($OUTPUT_FILE);
if ($output_dir && !-d $output_dir) {
  die "ERROR: Output directory '$output_dir' does not exist\n";
}
if (-e $OUTPUT_FILE && !-w $OUTPUT_FILE) {
  die "ERROR: Output file '$OUTPUT_FILE' is not writable\n";
}
$DEBUG && print "DEBUG: Output path validated - '$OUTPUT_FILE'\n";

# Core variables for line-by-line processing
my $in_block = 0;                          # Flag: whether currently inside a block
my @current_block;                         # Store lines of current block (array for line-wise processing)
my @output_entries;                        # Store final entries for output

# Open input (file or STDIN)
my $in_fh;
if ($INPUT_FILE) {
  open $in_fh, '<', $INPUT_FILE or die "ERROR: Cannot open input file '$INPUT_FILE' - $!\n";
} else {
  open $in_fh, '<', \*STDIN or die "ERROR: Cannot read from STDIN - $!\n";
}
$DEBUG && print "DEBUG: Started line-by-line input processing\n";

# Line-by-line processing (core logic)
while (my $line = <$in_fh>) {
  chomp $line;  # Remove trailing newline (consistent processing across OS)
  $DEBUG && print "DEBUG: Processing line - '$line'\n";

  # Handle block start/end based on selected method
  if ($standard_method eq 'start') {
    # Start method: new block on START_PATTERN, end on next START_PATTERN or EOF
    if ($line =~ /$START_PATTERN/) {
      $DEBUG && print "DEBUG: Found start pattern - starting new block\n";
      # Process previous block if exists
      if ($in_block) {
        &process_block(\@current_block);
        @current_block = ();
      }
      $in_block = 1;
      push @current_block, $line;
    } elsif ($in_block) {
      # Continue adding lines to current block
      push @current_block, $line;
    }

  } elsif ($standard_method eq 'separator') {
    # Separator method: blocks separated by SEPARATOR_PATTERN (skip separator lines)
    if ($line =~ /$SEPARATOR_PATTERN/) {
      $DEBUG && print "DEBUG: Found separator - ending current block\n";
      if ($in_block) {
        &process_block(\@current_block);
        @current_block = ();
        $in_block = 0;
      }
    } else {
      $in_block = 1;
      push @current_block, $line;
    }

  } elsif ($standard_method eq 'end') {
    # End method: block ends on END_PATTERN (include END_PATTERN line)
    if ($in_block) {
      push @current_block, $line;
      if ($line =~ /$END_PATTERN/) {
        $DEBUG && print "DEBUG: Found end pattern - ending block\n";
        &process_block(\@current_block);
        @current_block = ();
        $in_block = 0;
      }
    } else {
      # Start collecting lines until end pattern is found
      push @current_block, $line;
      $in_block = 1;
    }

  } elsif ($standard_method eq 'start_end') {
    # Start_end method: block starts on START_PATTERN, ends on END_PATTERN
    if (!$in_block && $line =~ /$START_PATTERN/) {
      $DEBUG && print "DEBUG: Found start pattern - starting block\n";
      $in_block = 1;
      push @current_block, $line;
    } elsif ($in_block) {
      push @current_block, $line;
      if ($line =~ /$END_PATTERN/) {
        $DEBUG && print "DEBUG: Found end pattern - ending block\n";
        &process_block(\@current_block);
        @current_block = ();
        $in_block = 0;
      }
    }
  }
}
close $in_fh or die "ERROR: Failed to close input - $!\n";

# Process remaining block (if any) after EOF
if ($in_block && @current_block) {
  $DEBUG && print "DEBUG: Processing remaining block after EOF\n";
  &process_block(\@current_block);
}

# Validate output entries
unless (@output_entries) {
  print "WARNING: No valid content to write (check method/pattern settings)\n";
  exit 0;
}
$DEBUG && print "DEBUG: Generated " . scalar(@output_entries) . " output entries\n";

# Write output to file
open my $out_fh, '>', $OUTPUT_FILE or die "ERROR: Cannot open output file '$OUTPUT_FILE' - $!\n";
my $block_id = 1;
my $is_first = 1;
foreach my $entry (@output_entries) {
  # Print block separator (skip first)
  if (!$is_first && defined $BLOCK_SEPARATOR && length $BLOCK_SEPARATOR) {
    print $out_fh $BLOCK_SEPARATOR . "\n";
  }
  $is_first = 0;

  # Print block prefix
  if (defined $BLOCK_PREFIX && length $BLOCK_PREFIX) {
    my $current_prefix = $BLOCK_PREFIX;
    $current_prefix =~ s/<id>/$block_id/gs;
    print $out_fh $current_prefix . "\n";
  }

  # Print block content
  print $out_fh $entry . "\n" if defined $entry && length $entry;

  # Print block suffix
  if (defined $BLOCK_SUFFIX && length $BLOCK_SUFFIX) {
    print $out_fh $BLOCK_SUFFIX . "\n";
  }

  $block_id++;
}
close $out_fh or die "ERROR: Failed to close output file - $!\n";
$DEBUG && print "DEBUG: Processing completed - output written to '$OUTPUT_FILE'\n";

exit 0;

# Subroutine: Process a single block (filter + retain)
sub process_block {
  my ($block_ref) = @_;
  my @block = @$block_ref;
  $DEBUG && print "DEBUG: Processing block with " . scalar(@block) . " lines\n";

  # Step 1: Filter block (keep if any line matches FILTER_PATTERN)
  my $block_passes = 0;
  if (!$FILTER_PATTERN) {
    $block_passes = 1;  # No filter: keep all blocks
  } else {
    foreach my $line (@block) {
      if ($line =~ /$FILTER_PATTERN/) {
        $block_passes = 1;
        $DEBUG && print "DEBUG: Block passed filter (matched line: '$line')\n";
        last;
      }
    }
  }

  # Skip block if filter fails
  unless ($block_passes) {
    $DEBUG && print "DEBUG: Block rejected by filter\n";
    return;
  }

  # Step 2: Retain lines (extract lines matching RETAIN_PATTERN)
  my @retained_lines;
  if (!$RETAIN_PATTERN) {
    @retained_lines = @block;  # No retain: keep all lines
  } else {
    @retained_lines = grep { $_ =~ /$RETAIN_PATTERN/ } @block;
  }
  $DEBUG && print "DEBUG: Retained " . scalar(@retained_lines) . " lines from block\n";

  # Step 3: Handle empty retain results
  if (!@retained_lines) {
    if ($ALLOW_EMPTY) {
      $DEBUG && print "DEBUG: Adding empty block (--allow-empty enabled)\n";
      push @output_entries, '';
    } else {
      $DEBUG && print "DEBUG: Skipping empty block (--allow-empty disabled)\n";
    }
    return;
  }

  # Step 4: Prepare entry (join retained lines with newlines)
  my $entry = join "\n", @retained_lines;
  push @output_entries, $entry;
}

# Subroutine: Help message
sub help {
  my $display_start = $START_PATTERN;
  my $display_sep = $SEPARATOR_PATTERN;
  my $display_end = $END_PATTERN;
  my $display_filter = $FILTER_PATTERN;
  my $display_retain = $RETAIN_PATTERN;
  my $display_block_sep = $BLOCK_SEPARATOR;
  my $display_block_prefix = $BLOCK_PREFIX;
  my $display_block_suffix = $BLOCK_SUFFIX;

  $display_block_sep =~ s/\n/\\n/g;
  $display_block_sep =~ s/\t/\\t/g;
  $display_block_prefix =~ s/\n/\\n/g;
  $display_block_prefix =~ s/\t/\\t/g;
  $display_block_suffix =~ s/\n/\\n/g;
  $display_block_suffix =~ s/\t/\\t/g;

  print <<HELP;
Usage: perl block_parser.pl [OPTIONS]
A lightweight line-by-line text block parser with simple regex matching.

Core Features:
  - Line-by-line input processing (no full-file slurp)
  - 4 block extraction methods (start/separator/end/start_end)
  - Block-level filter (keep blocks with matching lines)
  - Line-level extraction (retain only matching lines from blocks)
  - Native ^/\$ anchor support (works as line start/end directly)
  - Auto-newline for formatting (separator/prefix/suffix)
  - Cross-OS compatibility (handles all line endings)
  - Input from file or STDIN
  - Customizable output formatting
  - Debug mode for visibility
  - Minimal regex syntax (no complex modifiers needed)

Command Line Options:
  --method|-m      Block extraction method (required)
                   Valid values (full/simplified):
                     start (s)        : New block on --start pattern line
                     separator (sep/r): Blocks separated by --separator lines
                     end (e)          : Block ends on --end pattern line
                     start_end (se/b) : Block starts on --start AND ends on --end
                   Default: $METHOD

  --input|-i       Input file path (reads from STDIN if empty)
                   Default: '$INPUT_FILE' (STDIN)
                   Example: 'data.txt', '/path/to/logs'

  --start|-s       Regex for block start line (start/start_end methods)
                   Default: '$display_start'
                   Example: '^Path \\d+:', '^## Chapter'
                   Note: ^ = line start, \$ = line end (works natively)

  --separator|-r   Regex for block separator line (separator method)
                   Default: '$display_sep'
                   Example: '-----+', '^\\d{4}-\\d{2}-\\d{2}'
                   Note: Matches entire separator lines (skipped in output)

  --end|-e         Regex for block end line (end/start_end methods)
                   Default: '$display_end'
                   Example: '^1\\s*$', '^## End'
                   Note: ^ = line start, \$ = line end (works natively)

  --filter|-f      Regex to filter blocks (keep if any line matches)
                   Default: '$display_filter'
                   Example: 'ram_', '(?i)error'
                   Note: Checks each line in block; keeps entire block if match

  --retain|-t      Regex to extract lines (retain matching lines)
                   Default: '$display_retain'
                   Example: 'ram_', '^Path \\d+:'
                   Note: Extracts only matching lines; discards others

  --output|-o      Output file path
                   Default: '$OUTPUT_FILE'
                   Example: 'results.txt', '/path/to/output'

  --block-sep|-b   Separator between output blocks
                   Default: '$display_block_sep'
                   Example: '--- Next Block ---', '====='
                   Note: Auto-appends newline (no need for \\n)

  --block-prefix|-p Prefix for each output block (replaces <id> with number)
                   Default: '$display_block_prefix'
                   Example: 'Block <id>:', 'Path Data <id>'
                   Note: Auto-appends newline; <id> = sequential number

  --block-suffix|-x Suffix for each output block
                   Default: '$display_block_suffix'
                   Example: 'End of Block <id>', ';'
                   Note: Auto-appends newline (no need for \\n)

  --allow-empty|-a  Allow empty blocks (when retain has no matches)
                   Default: @{[$ALLOW_EMPTY ? 'Enabled' : 'Disabled']}

  --debug|-d       Enable debug mode (print processing details)
                   Default: @{[$DEBUG ? 'Enabled' : 'Disabled']}

  --help|-h        Show this help message and exit

Important Notes:
  1. Line-by-line processing: Each regex matches individual lines natively.
     - ^ reliably matches LINE START (no extra modifiers needed)
     - \$ reliably matches LINE END (no extra modifiers needed)
     - Example: '^Path \\d+:' matches lines starting with "Path X:" exactly

  2. Regex simplicity: No complex modifiers (sm/g) required. Use basic Perl regex:
     - Literal special chars: Escape with \\ (e.g., \\., \\+, \\^ for literal ^)
     - Case insensitivity: Add (?i) (e.g., '(?i)error' matches Error/ERROR)
     - Optional parts: Use ? (e.g., 'Path \\d+:\\s?' matches "Path 1:" or "Path 1: ")

  3. FILTER vs RETAIN:
     - FILTER: Block-level check (keep/reject entire block)
     - RETAIN: Line-level extraction (keep only matching lines in accepted blocks)

  4. Empty blocks: --allow-empty only affects blocks where retain finds no matches.
     Empty input/filtered blocks are always skipped with a warning.

Usage Examples:
Example 1: Extract Path blocks and retain ram_ lines
perl block_parser.pl \\
  -m se \\
  -i input.txt \\
  -s '^Path \\d+:' \\  # Matches lines starting with "Path X:"
  -e '^1\\s*$' \\      # Matches lines with only "1"
  -f 'ram_' \\          # Keep blocks with any ram_ line
  -t '^Path \\d+|ram_' \\# Extract Path lines and ram_ lines
  -o output.txt \\
  -b "--- Next Block ---" \\
  -p "Block <id>" \\
  -d

Example 2: Extract error lines from log (separator method)
perl block_parser.pl \\
  -m sep \\
  -i app.log \\
  -r '^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}' \\  # Timestamp separator
  -f '(?i)error' \\                                   # Keep error blocks
  -t '(?i)error|exception' \\                          # Extract error/exception lines
  -o errors.txt \\
  -p "Error Block <id>" \\
  -a \\
  -d

Example 3: Match line-start patterns (^ works natively)
perl block_parser.pl \\
  -m start \\
  -s '^## Section' \\   # Matches lines starting with "## Section"
  -i docs.txt \\
  -f '^## Section' \\   # Keep blocks starting with section header
  -t '^## Section|^- ' \\# Extract headers and list items
  -o sections.txt \\
  -d
HELP
}
