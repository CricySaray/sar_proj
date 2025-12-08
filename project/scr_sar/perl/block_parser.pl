#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Basename;  # For output directory check
use File::Spec;      # For path handling

# Default configuration - overridden by command line options
our $METHOD = 'start_end';                  # Block extraction method (start/separator/end/start_end)
our $INPUT_FILE = '';                       # Input file path (reads from STDIN if empty)
our $START_PATTERN = '^Path \d+:';          # Regex for block start (used by start/start_end methods); Use \ to escape special chars (e.g., \^ for literal ^, \$ for literal $); Matches entire line (like vim :g/pattern/p)
our $SEPARATOR_PATTERN = '-----+';          # Regex for block separator (used by separator method); Use \ to escape special chars (e.g., \+ for literal +); Matches entire line (like vim :g/pattern/p)
our $END_PATTERN = '^1\s*$';                # Regex for block end (used by end/start_end methods); Use \ to escape special chars (e.g., \$ for literal $); Matches entire line (like vim :g/pattern/p)
our $FILTER_PATTERN = 'ram_';               # Regex to filter blocks (keep blocks with matching lines); Use \ to escape special chars (e.g., \_ for literal _); Matches entire line if pattern exists (like vim :g/pattern/p)
our $RETAIN_PATTERN = 'ram_';               # Regex to extract lines from blocks; Use \ to escape special chars (e.g., \| for literal |); Extracts entire line if pattern exists (like vim :g/pattern/p)
our $OUTPUT_FILE = 'output.txt';            # Path to output file
our $BLOCK_SEPARATOR = "=== End of Block ===";  # Separator between output blocks (automatically appends newline)
our $BLOCK_PREFIX = 'song_path <id>';       # Prefix for each output block (automatically appends newline; <id> = auto-increment block number)
our $BLOCK_SUFFIX = '';                     # Suffix for each output block (automatically appends newline)
our $DEBUG = 0;                             # Enable debug mode (0 = disabled, 1 = enabled)
our $ALLOW_EMPTY = 0;                       # Allow writing empty blocks when retain has no matches (0=disable, 1=enable)
my $show_help = 0;                          # Flag for help command

# Parse command line options (long/short format)
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

# Show help and exit immediately if requested (avoid executing subsequent code)
if ($show_help) {
  &help;
  exit 0;
}

# Process escape sequences (e.g., \n, \t) in formatting options
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
  unless (-e $INPUT_FILE) {
    die "ERROR: Input file '$INPUT_FILE' does not exist\n";
  }
  unless (-r $INPUT_FILE) {
    die "ERROR: Input file '$INPUT_FILE' is not readable (check permissions)\n";
  }
  unless (-f $INPUT_FILE) {
    die "ERROR: '$INPUT_FILE' is not a regular file (directories not supported)\n";
  }
  $DEBUG && print "DEBUG: Input file validated - '$INPUT_FILE'\n";
}

# Map method input to standard name (supports full/simplified inputs)
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

# Validate method input
unless (exists $method_map{lc $METHOD}) {
  die "Invalid method '$METHOD'. Valid methods: start (s), separator (sep/r), end (e), start_end (se/b).\n";
}
my $standard_method = $method_map{lc $METHOD};
$DEBUG && print "DEBUG: Using standard extraction method - $standard_method\n";

# Validate required patterns for selected method (ignore other patterns even if set)
my $is_valid = 1;
if ($standard_method eq 'start') {
  unless ($START_PATTERN) {
    print "ERROR: --start (-s) pattern is required for 'start' method\n";
    $is_valid = 0;
  }
  $DEBUG && print "DEBUG: Ignoring separator/end patterns (not used by 'start' method)\n";
}
elsif ($standard_method eq 'separator') {
  unless ($SEPARATOR_PATTERN) {
    print "ERROR: --separator (-r) pattern is required for 'separator' method\n";
    $is_valid = 0;
  }
  $DEBUG && print "DEBUG: Ignoring start/end patterns (not used by 'separator' method)\n";
}
elsif ($standard_method eq 'end') {
  unless ($END_PATTERN) {
    print "ERROR: --end (-e) pattern is required for 'end' method\n";
    $is_valid = 0;
  }
  $DEBUG && print "DEBUG: Ignoring start/separator patterns (not used by 'end' method)\n";
}
elsif ($standard_method eq 'start_end') {
  unless ($START_PATTERN && $END_PATTERN) {
    print "ERROR: Both --start (-s) and --end (-e) patterns are required for 'start_end' method\n";
    $is_valid = 0;
  }
  $DEBUG && print "DEBUG: Ignoring separator pattern (not used by 'start_end' method)\n";
}
unless ($is_valid) {
  exit 1;
}

# Validate output directory (if output file is in a subdirectory)
my $output_dir = dirname($OUTPUT_FILE);
if ($output_dir && !-d $output_dir) {
  die "ERROR: Output directory '$output_dir' does not exist (create it first)\n";
}
# Check if output file is writable (if it already exists)
if (-e $OUTPUT_FILE && !-w $OUTPUT_FILE) {
  die "ERROR: Output file '$OUTPUT_FILE' is not writable (check permissions)\n";
}
$DEBUG && print "DEBUG: Output path validated - '$OUTPUT_FILE'\n";

# Read input content (file or STDIN)
my $input_content;
if ($INPUT_FILE) {
  open my $in_fh, '<', $INPUT_FILE or die "ERROR: Cannot open input file '$INPUT_FILE' - $!\n";
  local $/;
  $input_content = <$in_fh>;
  close $in_fh or die "ERROR: Failed to close input file '$INPUT_FILE' - $!\n";
} else {
  # Read from STDIN (slurp mode)
  $input_content = do {
    local $/;
    <STDIN>;
  };
}

# Validate input content (not empty)
unless (defined $input_content && length $input_content > 0) {
  die "ERROR: No input content found (file is empty or STDIN has no data)\n";
}
$DEBUG && print "DEBUG: Read " . length($input_content) . " bytes of input data\n";

# Extract blocks based on selected method (use original PATTERN variables directly; sm modifiers: multi-line + dotall)
my @blocks;
if ($standard_method eq 'start') {
  # Match blocks starting with START_PATTERN line, until next start line or end (preserve line anchors)
  @blocks = $input_content =~ /($START_PATTERN.*?)(?=$START_PATTERN|$)/smg;
}
elsif ($standard_method eq 'separator') {
  # Split by separator lines and remove empty blocks (use original SEPARATOR_PATTERN directly)
  @blocks = split /$SEPARATOR_PATTERN/sm, $input_content;
  @blocks = grep { defined $_ && length $_ > 0 } @blocks;
}
elsif ($standard_method eq 'end') {
  # Match blocks ending with END_PATTERN line (preserve line anchors)
  @blocks = $input_content =~ /(.*?$END_PATTERN)/smg;
}
elsif ($standard_method eq 'start_end') {
  # Match blocks from START_PATTERN line to END_PATTERN line (non-greedy, preserve line anchors)
  @blocks = $input_content =~ /($START_PATTERN.*?$END_PATTERN)/smg;
}

# Validate extracted blocks
unless (@blocks) {
  $DEBUG && print "DEBUG: No blocks extracted with pattern(s) - START='$START_PATTERN' | SEPARATOR='$SEPARATOR_PATTERN' | END='$END_PATTERN'\n";
  print "WARNING: No blocks found - check your method and pattern settings\n";
  exit 0;
}
$DEBUG && print "DEBUG: Extracted " . scalar(@blocks) . " raw blocks\n";

# Filter blocks: keep blocks with at least one line matching FILTER_PATTERN (vim :g/pattern/p logic)
my @filtered_blocks;
foreach my $block (@blocks) {
  next unless defined $block;
  
  my $passes = 1;
  if ($FILTER_PATTERN) {
    # Match entire line if pattern exists (sm: multi-line + dotall; no need for .* around pattern)
    $passes = $block =~ /$FILTER_PATTERN/sm ? 1 : 0;
  }
  
  if ($passes) {
    push @filtered_blocks, $block;
    $DEBUG && print "DEBUG: Block passed filter (length: " . length($block) . " bytes; filter pattern='$FILTER_PATTERN')\n";
  }
  else {
    $DEBUG && print "DEBUG: Block rejected by filter (no line matches '$FILTER_PATTERN')\n";
  }
}

# Validate filtered blocks
unless (@filtered_blocks) {
  $DEBUG && print "DEBUG: No blocks remaining after filtering\n";
  print "WARNING: All blocks were rejected by the filter pattern '$FILTER_PATTERN'\n";
  exit 0;
}
$DEBUG && print "DEBUG: " . scalar(@filtered_blocks) . " blocks remaining after filtering\n";

# Extract retained lines from filtered blocks (vim :g/pattern/p logic: extract entire matching lines)
my @output_entries;
foreach my $block (@filtered_blocks) {
  my @matched_lines;
  if ($RETAIN_PATTERN) {
    # Extract entire lines containing RETAIN_PATTERN (sm: multi-line + dotall; ^.*$ ensures full line)
    @matched_lines = $block =~ /^.*$RETAIN_PATTERN.*$/smg;
    $DEBUG && print "DEBUG: Extracted " . scalar(@matched_lines) . " matching lines from block (retain pattern='$RETAIN_PATTERN')\n";
  }
  else {
    # No retain pattern: use all lines of the block
    @matched_lines = split /\n/s, $block;
    $DEBUG && print "DEBUG: Using all lines from block (no retain pattern) - " . scalar(@matched_lines) . " lines\n";
  }
  
  my $content;
  if (@matched_lines) {
    $content = join "\n", @matched_lines;
  } else {
    $DEBUG && print "DEBUG: No retain matches found in block - " . ($ALLOW_EMPTY ? "allowing empty block" : "skipping") . "\n";
    $content = '' if $ALLOW_EMPTY;
    next unless $ALLOW_EMPTY;
  }
  
  # Keep entry if allowed (even if empty)
  push @output_entries, $content if $ALLOW_EMPTY || (defined $content && length $content > 0);
}

# Validate output entries
unless (@output_entries) {
  $DEBUG && print "DEBUG: No valid output entries generated\n";
  print "WARNING: No content to write (retain pattern '$RETAIN_PATTERN' found no matches and empty blocks are disabled)\n";
  exit 0;
}
$DEBUG && print "DEBUG: Generated " . scalar(@output_entries) . " valid output entries\n";

# Write output to file (auto-add newline to separator/prefix/suffix for separate lines)
open my $out_fh, '>', $OUTPUT_FILE or die "ERROR: Cannot open output file '$OUTPUT_FILE' - $!\n";
my $block_id = 1;
my $is_first = 1;
foreach my $entry (@output_entries) {
  # Print block separator (auto-newline; skip for first block)
  if (!$is_first && defined $BLOCK_SEPARATOR) {
    print $out_fh $BLOCK_SEPARATOR . "\n";  # Auto-add newline for separate line
  }
  $is_first = 0;

  # Print block prefix (auto-newline; replace <id>)
  if (defined $BLOCK_PREFIX && length $BLOCK_PREFIX > 0) {
    my $current_prefix = $BLOCK_PREFIX;
    $current_prefix =~ s/<id>/$block_id/gs;
    print $out_fh $current_prefix . "\n";  # Auto-add newline for separate line
  }

  # Print block content (preserve original line breaks)
  print $out_fh $entry . "\n" if defined $entry && length $entry > 0;  # Ensure content ends with newline

  # Print block suffix (auto-newline)
  if (defined $BLOCK_SUFFIX && length $BLOCK_SUFFIX > 0) {
    print $out_fh $BLOCK_SUFFIX . "\n";  # Auto-add newline for separate line
  }

  $block_id++;
}
close $out_fh or die "ERROR: Failed to close output file '$OUTPUT_FILE' - $!\n";
$DEBUG && print "DEBUG: Processing completed - output written to '$OUTPUT_FILE'\n";

exit 0;

# Help subroutine - detailed usage instructions and examples
sub help {
  # Escape special characters in regex patterns for help display (preserve original regex)
  my $display_start = $START_PATTERN;
  my $display_sep = $SEPARATOR_PATTERN;
  my $display_end = $END_PATTERN;
  my $display_filter = $FILTER_PATTERN;
  my $display_retain = $RETAIN_PATTERN;
  my $display_block_sep = $BLOCK_SEPARATOR;
  my $display_block_prefix = $BLOCK_PREFIX;
  my $display_block_suffix = $BLOCK_SUFFIX;

  # Preserve escape sequences in formatting options (show as user would input them)
  $display_block_sep =~ s/\n/\\n/g;
  $display_block_sep =~ s/\t/\\t/g;
  $display_block_prefix =~ s/\n/\\n/g;
  $display_block_prefix =~ s/\t/\\t/g;
  $display_block_suffix =~ s/\n/\\n/g;
  $display_block_suffix =~ s/\t/\\t/g;

  print <<HELP;
Usage: perl block_parser.pl [OPTIONS]
A flexible text block parser with vim-like line matching (g/pattern/p) and auto-newline formatting.

Core Features:
  - 4 regex-based block extraction methods (uses original pattern variables directly)
  - Vim-like line matching: Extracts entire lines containing pattern (no .* needed)
  - Direct pattern usage: No intermediate variables - original PATTERN values used for regex
  - Auto-newline for formatting: Separator/prefix/suffix automatically occupy separate lines
  - Support for input file or STDIN
  - Block filtering and full-line extraction
  - Customizable output formatting (prefix/suffix/separator)
  - Auto-increment block ID for prefix
  - Control over empty block writing
  - Full Perl regex support (modifiers, capture groups, etc.)
  - Debug mode for processing visibility
  - Comprehensive error checking

Command Line Options:
  --method|-m      Block extraction method (required to specify patterns)
                   Valid values (full/simplified):
                     start (s)        : Blocks start with --start pattern line
                     separator (sep/r): Blocks separated by --separator pattern lines
                     end (e)          : Blocks end with --end pattern line
                     start_end (se/b) : Blocks start with --start AND end with --end pattern lines
                   Default: $METHOD
                   Note: Only method-specific patterns are used (other patterns/defaults are ignored)

  --input|-i       Input file path (reads from STDIN if empty)
                   Default: '$INPUT_FILE' (STDIN)
                   Example: 'data.txt', '/path/to/input.log'
                   Note: File input takes precedence over STDIN; directories are not supported

  --start|-s       Regex for block start line (required for 'start'/'start_end' methods)
                   Default: '$display_start'
                   Example: '^## Chapter', '\\bBEGIN\\b', '(?i)section'
                   Note: Matches entire line if pattern exists (like vim :g/pattern/p);
                         No need to add .* around pattern - full line is matched automatically;
                         ^ and \$ work as line anchors (multi-line mode enabled by default);
                         Escape regex special chars with \\ to use their literal meaning (e.g., \\^ for literal ^, \\+ for literal +)

  --separator|-r   Regex for block separator line (required for 'separator' method)
                   Default: '$display_sep'
                   Example: '^---$', '\\d{4}-\\d{2}-\\d{2}', '====='
                   Note: Matches entire separator lines (like vim :g/pattern/p);
                         Consecutive separators are treated as one; empty blocks are auto-removed;
                         No need to add .* around pattern - full line is matched automatically;
                         Escape regex special chars with \\ to use their literal meaning (e.g., \\. for literal ., \\* for literal *)

  --end|-e         Regex for block end line (required for 'end'/'start_end' methods)
                   Default: '$display_end'
                   Example: '^## End', '\\bEND\\b', ';'
                   Note: Matches entire line if pattern exists (like vim :g/pattern/p);
                         No need to add .* around pattern - full line is matched automatically;
                         ^ and \$ work as line anchors (multi-line mode enabled by default);
                         Escape regex special chars with \\ to use their literal meaning (e.g., \\$ for literal \$, \\? for literal ?)

  --filter|-f      Regex to filter blocks (keep blocks with at least one matching line)
                   Default: '$display_filter'
                   Example: 'error', '(?i)warning', '^\\d+'
                   Note: Vim-like matching: Blocks with any line containing pattern are kept (like :g/pattern/p);
                         No need to add .* around pattern - full line is matched automatically;
                         Escape regex special chars with \\ to use their literal meaning (e.g., \\[ for literal [, \\] for literal ])

  --retain|-t      Regex to extract lines from filtered blocks
                   Default: '$display_retain'
                   Example: 'ram_', '(?i)important', '\\b\\d{3}-\\d{2}-\\d{4}\\b'
                   Note: Vim-like extraction: Extracts entire lines containing pattern (like :g/pattern/p);
                         No need to add .* around pattern - full line is extracted automatically;
                         Global match (extracts all matching lines in the block);
                         Escape regex special chars with \\ to use their literal meaning (e.g., \\| for literal |, \\( for literal ()

  --output|-o      Output file path
                   Default: '$OUTPUT_FILE'
                   Example: 'results.txt', '/path/to/output.log'
                   Note: Parent directory must exist (script won't create directories)

  --block-sep|-b   Separator between output blocks
                   Default: '$display_block_sep'
                   Example: '--- Next Block ---', '=====', '\\tSeparator\\t'
                   Note: Automatically appends a newline character - occupies a separate line (no need to add \\n manually);
                         Supports escape sequences (\\n=newline, \\t=tab); use quotes for spaces/escapes;
                         Empty value means no separator (no extra lines)

  --block-prefix|-p Prefix for each output block (replaces <id> with auto-increment number)
                   Default: '$display_block_prefix'
                   Example: '=== Block <id> ===', 'Data [id:<id>]', 'Path:'
                   Note: Automatically appends a newline character - occupies a separate line (no need to add \\n manually);
                         <id> is a placeholder for sequential block numbers (starts at 1);
                         Empty value means no prefix

  --block-suffix|-x Suffix for each output block
                   Default: '$display_block_suffix' (no suffix)
                   Example: '=== End of Block <id> ===', 'End of Path', ';'
                   Note: Automatically appends a newline character - occupies a separate line (no need to add \\n manually);
                         Supports escape sequences; empty value means no suffix

  --allow-empty|-a  Allow writing empty blocks when retain pattern has no matches
                   Default: @{[$ALLOW_EMPTY ? 'Enabled (1)' : 'Disabled (0)']}
                   Note: Enabled (1) = write empty content with prefix/suffix; Disabled (0) = skip empty blocks

  --debug|-d       Enable debug mode (print processing details to STDOUT)
                   Default: @{[$DEBUG ? 'Enabled' : 'Disabled']}
                   Note: Debug output does not interfere with the output file

  --help|-h        Show this help message and exit

Important Notes:
  1. Direct pattern usage: All PATTERN variables are used directly in regex matching - no intermediate variables are used,
     ensuring no loss of pattern value or syntax.
  2. Vim-like line matching: All pattern matching follows :g/pattern/p logic - if a line contains the pattern, the entire
     line is matched/extracted (no need to wrap patterns with .*).
  3. Multi-line mode default: All patterns use 'm' modifier automatically - ^ matches line start and $ matches line end
     (even within multi-line blocks).
  4. Auto-newline formatting: Block separator/prefix/suffix are automatically followed by a newline - users don't need to
     add \\n manually; this ensures each formatting element occupies a separate line.
  5. Regex special character handling:
     - Anchors (^ = line start, \$ = line end) work directly (no extra escape needed);
     - Regex special characters (e.g., ., *, +, ?, |, (), [], {}, ^, \$) must be escaped with \\ to use their literal meaning;
     - Example: To match the literal string "a.b*c", use pattern 'a\\.b\\*c' (not 'a.b*c' which would match 'aXbYYc' etc.).
  6. Default value sync: All help default values are dynamically pulled from script configuration -
     modify the top-level variables to update defaults globally.
  7. Empty block handling: --allow-empty only affects blocks where retain pattern has no matches;
     Empty input/filtered blocks are always handled separately (warning + exit).

Usage Examples:
Example 1: Extract paths with 'ram_' (start_end method, vim-like matching)
perl block_parser.pl \\
  -m se \\
  -i input.txt \\
  -o extracted_paths.txt \\
  -b "--- Next Path Block ---" \\  # Auto-newline added - no need for \\n
  -p "Path Block <id>" \\          # Auto-newline added
  -d

Example 2: Extract error lines (separator method, case-insensitive filter)
perl block_parser.pl \\
  -m sep \\
  -i app.log \\
  -r '^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}' \\  # Match timestamp separator lines
  -f '(?i)error' \\                                   # Filter blocks with any error line
  -t 'error|Exception' \\                              # Extract all lines with error/Exception
  -o error_blocks.log \\
  -p "Error Block <id>" \\
  -x "End of Error Block <id>" \\
  -a \\
  -d

Example 3: Match literal special characters (e.g., lines with "file^1.txt")
perl block_parser.pl \\
  -m start \\
  -s 'file\\^\\d+\\.txt'  # Escape ^ (literal) and . (literal) - auto-matches full line
  -i data.txt \\
  -o literal_matches.txt \\
  -block-prefix "Matched Line Block <id>" \\
  -d
HELP
}
