#!/bin/perl
# --------------------------
# author    : sar song
# date      : 2026/02/08 00:28:58 Sunday
# label     : getInfo_sub
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check|drc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This Perl script extracts text blocks from a file or STDIN using four extraction methods (start, separator, end, start_end) 
#             and classifies these blocks based on multi-line regex rules defined in a rule file. It writes classified blocks to category-specific 
#             output files with customizable naming and formatting options, supports case sensitivity toggling, empty block control, and provides 
#             a statistics summary of processed blocks.
# return    : splited files according to file of classification rules
# ref       : link url
# --------------------------
use strict;
# use warnings;
use Getopt::Long;
use File::Basename;
use File::Spec;
use IO::Uncompress::AnyUncompress qw($AnyUncompressError);  # 新增：引入压缩文件解压模块

# ==============================
# DEFAULT CONFIGURATION (显眼的默认参数定义)
# ==============================
our $METHOD = 'start_end';                  # Block extraction method (start/separator/end/start_end)
our $INPUT_FILE = '';                   # Input file path (reads from STDIN if empty)
our $START_PATTERN = 'Startpoint';      # Regex for block start line (line-wise match)
our $SEPARATOR_PATTERN = '';            # Regex for block separator line (line-wise match)
our $END_PATTERN = 'slack \(VIOLATED\)';                  # Regex for block end line (line-wise match)
our $RULE_FILE = 'classification.rules';# Classification rule file path
our $OUTPUT_PREFIX = 'split_path_';                # Prefix for output category files
our $OUTPUT_SUFFIX = '';                # Suffix for output category files
our $OUTPUT_EXT = 'rpt';                # Extension for output category files
our $BLOCK_SEPARATOR = '';              # Separator between output blocks (auto-newline)
our $BLOCK_PREFIX = 'songpath <id>:';      # Prefix for each output block (auto-newline)
our $BLOCK_SUFFIX = '';                 # Suffix for each output block (auto-newline)
our $DEBUG = 0;                         # Enable debug mode (0=disabled, 1=enabled)
our $ALLOW_EMPTY = 1;                   # Allow empty blocks (0=disable, 1=enable)
our $DEFAULT_CATEGORY = 'other';      # Default category for unmatched blocks
our $CASE_SENSITIVE = 0;                # Case sensitivity (1=sensitive, 0=ignore case)
our $OUTPUT_DIR = '';                   # Output directory (current dir if empty)
my $show_help = 0;                      # Flag for help command
my @category_order;                     # Preserve category order from rule file (priority)

# ==============================
# Command Line Option Parsing
# ==============================
# Ensure GetOptions correctly handles short/long options (critical fix)
GetOptions(
  'method|m=s'        => \$METHOD,
  'input|i=s'         => \$INPUT_FILE,
  'start|s=s'         => \$START_PATTERN,
  'separator|r=s'     => \$SEPARATOR_PATTERN,
  'end|e=s'           => \$END_PATTERN,
  'rule-file|u=s'     => \$RULE_FILE,
  'output-prefix|k=s' => \$OUTPUT_PREFIX,
  'output-suffix|z=s' => \$OUTPUT_SUFFIX,
  'output-ext|c=s'    => \$OUTPUT_EXT,
  'outputDir|o=s'     => \$OUTPUT_DIR,
  'block-sep|b=s'     => \$BLOCK_SEPARATOR,
  'block-prefix|p=s'  => \$BLOCK_PREFIX,
  'block-suffix|x=s'  => \$BLOCK_SUFFIX,
  'allow-empty|a!'    => \$ALLOW_EMPTY,   # Explicit boolean type for short option
  'case-sensitive|C!' => \$CASE_SENSITIVE,# Explicit boolean type
  'ignore-case'     => sub { $CASE_SENSITIVE = 0; },
  'debug|d!'          => \$DEBUG,         # Explicit boolean type
  'help|h!'           => \$show_help      # Explicit boolean type
) or do {
  print STDERR "Error in command line arguments. Use --help (-h) for usage instructions.\n";
  exit 1;
};

# Show help and exit
if ($show_help) {
  &help;
  exit 0;
}

# ==============================
# Preprocess Formatting Options (escape sequences)
# ==============================
# 正确解析转义序列（\n, \t, \r 等）
eval {
  # 使用双引号解析转义，同时保留原始字符（通过qq{}实现）
  $BLOCK_SEPARATOR = $BLOCK_SEPARATOR =~ s/\\n/\n/gr =~ s/\\t/\t/gr =~ s/\\r/\r/gr;
  $BLOCK_PREFIX = $BLOCK_PREFIX =~ s/\\n/\n/gr =~ s/\\t/\t/gr =~ s/\\r/\r/gr;
  $BLOCK_SUFFIX = $BLOCK_SUFFIX =~ s/\\n/\n/gr =~ s/\\t/\t/gr =~ s/\\r/\r/gr;
};
if ($@) {
  die "Invalid escape sequence in formatting option: $@\n";
}

# ==============================
# Validate Input Files
# ==============================
# Validate input file (if provided)
if ($INPUT_FILE) {
  unless (-e $INPUT_FILE) { die "ERROR: Input file '$INPUT_FILE' does not exist\n"; }
  unless (-r $INPUT_FILE) { die "ERROR: Input file '$INPUT_FILE' is not readable\n"; }
  unless (-f $INPUT_FILE) { die "ERROR: '$INPUT_FILE' is not a regular file\n"; }
  $DEBUG && print "DEBUG: Input file validated - '$INPUT_FILE'\n";
}

# Validate rule file
unless (-e $RULE_FILE) { die "ERROR: Rule file '$RULE_FILE' does not exist\n"; }
unless (-r $RULE_FILE) { die "ERROR: Rule file '$RULE_FILE' is not readable\n"; }
unless (-f $RULE_FILE) { die "ERROR: '$RULE_FILE' is not a regular file\n"; }
$DEBUG && print "DEBUG: Rule file validated - '$RULE_FILE'\n";

# ==============================
# Validate and Prepare Output Directory
# ==============================
if ($OUTPUT_DIR) {
  # Create directory if not exists (recursive)
  unless (-d $OUTPUT_DIR) {
    require File::Path;
    File::Path::make_path($OUTPUT_DIR, { error => \my $err });
    if (@$err) {
      die "ERROR: Failed to create output directory '$OUTPUT_DIR': " . join(', ', map { "$_->{file}: $_->{message}" } @$err) . "\n";
    }
    $DEBUG && print "DEBUG: Created output directory '$OUTPUT_DIR'\n";
  }
  unless (-w $OUTPUT_DIR) {
    die "ERROR: Output directory '$OUTPUT_DIR' is not writable\n";
  }
}
$DEBUG && print "DEBUG: Output directory set to - '" . ($OUTPUT_DIR || 'current directory') . "'\n";

# ==============================
# Validate Extraction Method
# ==============================
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
unless (exists $method_map{lc $METHOD}) {
  die "Invalid method '$METHOD'. Valid methods: start (s), separator (sep/r), end (e), start_end (se/b).\n";
}
my $standard_method = $method_map{lc $METHOD};
$DEBUG && print "DEBUG: Using extraction method - $standard_method\n";

# Validate required patterns for method
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

# ==============================
# Parse Classification Rules File
# ==============================
my (%category_rules, %category_handles, %category_block_ids, %category_block_count);
&parse_rule_file($RULE_FILE);
$DEBUG && print "DEBUG: Parsed " . scalar(keys %category_rules) . " classification rules (order preserved)\n";

# ==============================
# Core Block Processing Variables
# ==============================
my $in_block = 0;
my @current_block;
my $total_blocks_processed = 0;

# ==============================
# Open Input Stream (File/STDIN) - Support Compressed Files
# ==============================
my $in_fh;
if ($INPUT_FILE) {
  # 新增逻辑：使用AnyUncompress打开压缩/普通文件（支持gzip/tar/bzip2等主流压缩格式）
  $in_fh = IO::Uncompress::AnyUncompress->new($INPUT_FILE) 
    or die "ERROR: Cannot open/compress input file '$INPUT_FILE' - $AnyUncompressError\n";
} else {
  # 保持原有逻辑：从STDIN读取（不处理压缩的STDIN，保证兼容性）
  open $in_fh, '<', \*STDIN or die "ERROR: Cannot read from STDIN - $!\n";
}
$DEBUG && print "DEBUG: Started line-by-line input processing (compressed file support enabled)\n";

# ==============================
# Line-by-Line Block Extraction
# ==============================
while (my $line = <$in_fh>) {
  chomp $line;
  $DEBUG && print "DEBUG: Processing line - '$line'\n";

  # Handle block start/end based on selected method
  if ($standard_method eq 'start') {
    if ($line =~ /$START_PATTERN/) {
      $DEBUG && print "DEBUG: Found start pattern - starting new block\n";
      if ($in_block) {
        &process_block(\@current_block);
        @current_block = ();
      }
      $in_block = 1;
      push @current_block, $line;
    } elsif ($in_block) {
      push @current_block, $line;
    }
  } elsif ($standard_method eq 'separator') {
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
    if ($in_block) {
      push @current_block, $line;
      if ($line =~ /$END_PATTERN/) {
        $DEBUG && print "DEBUG: Found end pattern - ending block\n";
        &process_block(\@current_block);
        @current_block = ();
        $in_block = 0;
      }
    } else {
      push @current_block, $line;
      $in_block = 1;
    }
  } elsif ($standard_method eq 'start_end') {
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

# Process remaining block after EOF
if ($in_block && @current_block) {
  $DEBUG && print "DEBUG: Processing remaining block after EOF\n";
  &process_block(\@current_block);
}

# ==============================
# Cleanup Output Handles
# ==============================
foreach my $cat (keys %category_handles) {
  close $category_handles{$cat} or die "ERROR: Failed to close output for category '$cat' - $!\n";
  $DEBUG && print "DEBUG: Closed output file for category '$cat'\n";
}

# ==============================
# Final Summary & Beautiful Table
# ==============================
$DEBUG && print "DEBUG: Processing completed - total blocks processed: $total_blocks_processed\n";
if ($total_blocks_processed == 0) {
  print "WARNING: No valid blocks were processed (check method/pattern/rule settings)\n";
} else {
  print "INFO: Successfully processed $total_blocks_processed blocks.\n";
  # Print beautiful statistics table (preserve category order)
  &print_statistics_table(\%category_block_count);
  
  print "\nOutput files (in rule file order):\n";
  foreach my $cat (@category_order, $DEFAULT_CATEGORY) {
    next unless exists $category_rules{$cat}; # Skip if default already in order
    my $out_file = &get_category_filename($cat);
    print "  - $cat: $out_file\n";
  }
}

exit 0;

# ==============================
# Subroutine: Parse Classification Rule File
# ==============================
sub parse_rule_file {
  my ($rule_file) = @_;
  my $current_cat = '';
  open my $rfh, '<', $rule_file or die "ERROR: Cannot open rule file '$rule_file' - $!\n";
  
  while (my $line = <$rfh>) {
    chomp $line;
    # Skip comments and empty lines
    next if $line =~ /^\s*#/ || $line =~ /^\s*$/;
    
    # Match category header (e.g., [SR_HP_LATCH])
    if ($line =~ /^\s*\[(.*?)\]\s*$/) {
      $current_cat = $1;
      # Only add new categories (avoid duplicates)
      unless (exists $category_rules{$current_cat}) {
        push @category_order, $current_cat; # Preserve order from rule file
        $category_rules{$current_cat} = [];  # Array to store regex rules
        $category_block_count{$current_cat} = 0;  # Initialize block count
        $DEBUG && print "DEBUG: Found category (priority " . scalar(@category_order) . ") - '$current_cat'\n";
      }
      next;
    }
    
    # Match regex rule line (single-quoted, e.g., '^\s+Endpoint:.*(sr_hp|sr_base)')
    if ($current_cat && $line =~ /^\s*'([^']+)'/) {
      my $raw_regex = $1;
      my $negate = 0;
      
      # Check if rule is negated (starts with !)
      if ($raw_regex =~ /^!(.+)/) {
        $negate = 1;
        $raw_regex = $1;
      }
      
      # Validate regex syntax
      eval { '' =~ /$raw_regex/ };
      if ($@) {
        die "ERROR: Invalid regex for category '$current_cat' (raw: '$raw_regex'): $@\n";
      }
      
      push @{$category_rules{$current_cat}}, {
        regex  => $raw_regex,
        negate => $negate
      };
      $DEBUG && print "DEBUG: Added rule for '$current_cat' - " . 
                     ($negate ? "NOT " : "") . "regex: '$raw_regex'\n";
    }
  }
  close $rfh or die "ERROR: Failed to close rule file - $!\n";
  
  # Ensure default category exists (matches all unmatched blocks)
  unless (exists $category_rules{$DEFAULT_CATEGORY}) {
    $category_rules{$DEFAULT_CATEGORY} = [];
    $category_block_count{$DEFAULT_CATEGORY} = 0;
    $DEBUG && print "DEBUG: Added default category '$DEFAULT_CATEGORY' (matches all unmatched blocks)\n";
  }
}

# ==============================
# Subroutine: Match Block Against Category Rules
# ==============================
sub match_category_rules {
  my ($block_lines, $category_rules) = @_;
  my $match = 1;
  my $modifier = $CASE_SENSITIVE ? '' : 'i';  # Case modifier (/i for ignore case)
  
  foreach my $rule (@$category_rules) {
    my $regex = $rule->{regex};
    my $negate = $rule->{negate};
    my $line_matched = 0;
    
    # Check each line in block for regex match
    foreach my $line (@$block_lines) {
      if ($modifier) {
        if ($line =~ /$regex/i) { $line_matched = 1; last; }
      } else {
        if ($line =~ /$regex/) { $line_matched = 1; last; }
      }
    }
    
    # Apply negation and check match status
    if ($negate) {
      if ($line_matched) { $match = 0; last; }  # Negated rule matched → category not matched
    } else {
      unless ($line_matched) { $match = 0; last; }  # Required rule not matched → category not matched
    }
  }
  
  return $match;
}

# ==============================
# Subroutine: Process Single Block (Classify + Write)
# ==============================
sub process_block {
  my ($block_ref) = @_;
  my @block = @$block_ref;  # 保留整个块的所有行
  $total_blocks_processed++;
  $DEBUG && print "DEBUG: Processing block #$total_blocks_processed with " . scalar(@block) . " lines\n";
  
  # Step 1: Classify the block (match FIRST non-default category in rule file order)
  my $matched_cat = $DEFAULT_CATEGORY;
  # Iterate in rule file order (preserve priority) - CRITICAL FIX
  foreach my $cat (@category_order) {
    # Skip if category has no rules (only default should have empty rules)
    next unless @{$category_rules{$cat}};
    
    if (&match_category_rules(\@block, $category_rules{$cat})) {
      $matched_cat = $cat;
      $DEBUG && print "DEBUG: Block #$total_blocks_processed matched category '$cat' (priority match)\n";
      last; # Stop at first match (critical for priority)
    }
  }
  $DEBUG && print "DEBUG: Block #$total_blocks_processed assigned to category '$matched_cat'\n";
  
  # Increment block count for matched category
  $category_block_count{$matched_cat}++;
  
  # Step 2: Handle empty blocks (保留原始逻辑，仅控制是否写入空块)
  my @retained_lines = @block;  # 直接复制整个块的所有行，不做过滤
  if (!@retained_lines) {
    if ($ALLOW_EMPTY) {
      $DEBUG && print "DEBUG: Adding empty block to '$matched_cat' (--allow-empty enabled)\n";
      @retained_lines = ('');
    } else {
      $DEBUG && print "DEBUG: Skipping empty block for '$matched_cat' (--allow-empty disabled)\n";
      return;
    }
  }
  my $entry = join "\n", @retained_lines;  # 拼接整个块的所有行
  
  # Step 3: Get or create output handle for category
  my $out_file = &get_category_filename($matched_cat);
  unless (exists $category_handles{$matched_cat}) {
    open my $fh, '>', $out_file or die "ERROR: Cannot open output file '$out_file' - $!\n";
    $category_handles{$matched_cat} = $fh;
    $category_block_ids{$matched_cat} = 1;
    $DEBUG && print "DEBUG: Created output file '$out_file' for category '$matched_cat'\n";
  }
  my $fh = $category_handles{$matched_cat};
  my $block_id = $category_block_ids{$matched_cat};
  
  # Step 4: Write block to output (with formatting)
  my $is_first = ($block_id == 1) ? 1 : 0;
  
  # Write block separator (skip first block)
  unless ($is_first) {
    print $fh $BLOCK_SEPARATOR . "\n" if defined $BLOCK_SEPARATOR && length $BLOCK_SEPARATOR;
  }
  
  # Write block prefix (replace <id> with block number)
  if (defined $BLOCK_PREFIX && length $BLOCK_PREFIX) {
    my $prefix = $BLOCK_PREFIX;
    $prefix =~ s/<id>/$block_id/gs;
    print $fh $prefix . "\n";
  }
  
  # Write entire block content (无过滤，全部写入)
  print $fh $entry . "\n" if defined $entry && length $entry;
  
  # Write block suffix (支持转义序列，如\n\n)
  if (defined $BLOCK_SUFFIX && length $BLOCK_SUFFIX) {
    my $suffix = $BLOCK_SUFFIX;
    $suffix =~ s/<id>/$block_id/gs;
    print $fh $suffix;  # 不再额外加\n，因为转义序列已包含所需换行
  }
  
  # Increment block ID for category
  $category_block_ids{$matched_cat}++;
}

# ==============================
# Subroutine: Generate Category Output Filename
# ==============================
sub get_category_filename {
  my ($cat) = @_;
  my $ext = $OUTPUT_EXT =~ /^\s*$/ ? '' : ($OUTPUT_EXT =~ /^\./ ? $OUTPUT_EXT : ".$OUTPUT_EXT");
  my $filename = $OUTPUT_PREFIX . $cat . $OUTPUT_SUFFIX . $ext;
  # Prepend output directory if specified
  if ($OUTPUT_DIR) {
    $filename = File::Spec->catfile($OUTPUT_DIR, $filename);
  }
  return $filename;
}

# ==============================
# Subroutine: Print Beautiful Statistics Table
# ==============================
sub print_statistics_table {
  my ($count_ref) = @_;
  my %count = %$count_ref;
  
  # Calculate maximum column widths (adaptive)
  my $max_cat_len = 0;
  my $max_count_len = length('Block Count');  # Header length
  # Check all categories (including default)
  foreach my $cat (keys %count) {
    $max_cat_len = length($cat) if length($cat) > $max_cat_len;
    $max_count_len = length($count{$cat}) if length($count{$cat}) > $max_count_len;
  }
  # Add padding for aesthetics
  $max_cat_len += 2;
  $max_count_len += 2;
  
  # Table header
  my $header_cat = sprintf("%-${max_cat_len}s", 'Category');
  my $header_count = sprintf("%${max_count_len}s", 'Block Count');
  my $separator = '-' x ($max_cat_len + $max_count_len + 1);
  
  print "\n" . $separator . "\n";
  print "| $header_cat | $header_count |\n";
  print $separator . "\n";
  
  # Table rows (in rule file order + default)
  foreach my $cat (@category_order, $DEFAULT_CATEGORY) {
    next unless exists $count{$cat};
    my $cat_str = sprintf("%-${max_cat_len}s", $cat);
    my $count_str = sprintf("%${max_count_len}s", $count{$cat});
    print "| $cat_str | $count_str |\n";
  }
  
  # Table footer
  print $separator . "\n";
}

# ==============================
# Subroutine: Help Message
# ==============================
sub help {
  my $display_start = $START_PATTERN;
  my $display_sep = $SEPARATOR_PATTERN;
  my $display_end = $END_PATTERN;
  my $display_block_sep = $BLOCK_SEPARATOR;
  my $display_block_prefix = $BLOCK_PREFIX;
  my $display_block_suffix = $BLOCK_SUFFIX;
  my $display_output_dir = $OUTPUT_DIR;

  # 转义显示特殊字符，方便用户理解
  $display_block_sep =~ s/\n/\\n/g;
  $display_block_sep =~ s/\t/\\t/g;
  $display_block_prefix =~ s/\n/\\n/g;
  $display_block_prefix =~ s/\t/\\t/g;
  $display_block_suffix =~ s/\n/\\n/g;
  $display_block_suffix =~ s/\t/\\t/g;

  print <<HELP;
Usage: perl block_classifier.pl [OPTIONS]
A line-by-line text block parser with classification based on multi-line regex rules.

Core Features:
  - 4 block extraction methods (start/separator/end/start_end)
  - Block classification via multi-line regex rules (AND relationship between lines)
  - Case sensitivity toggle (--case-sensitive/--ignore-case)
  - Per-category output files with customizable naming (prefix/suffix/extension)
  - Block numbering in output files
  - Customizable block formatting (separator/prefix/suffix) with escape sequence support
  - Full block content preservation (no line filtering)
  - Category priority (first match in rule file order)
  - Debug mode for visibility
  - Beautiful statistics table with adaptive column widths
  - Input from file or STDIN
  - Cross-OS compatibility
  - Support for compressed input files (gzip/tar/bzip2 etc.)  # 新增：帮助信息中补充压缩文件支持说明
  - Customizable output directory (auto-create if not exists)

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
                   Example: -i data.txt, --input /path/to/logs.gz  # 新增：示例补充压缩文件
                   Note: Supports compressed files (gzip/tar/bzip2 etc.)

  --start|-s       Regex for block start line (start/start_end methods)
                   Default: '$display_start'
                   Example: -s '^Path \\d+:', --start '^## Chapter'
                   Note: ^ = line start, \$ = line end (native support)

  --separator|-r   Regex for block separator line (separator method)
                   Default: '$display_sep'
                   Example: -r '-----+', --separator '^\\d{4}-\\d{2}-\\d{2}'
                   Note: Matches entire separator lines (skipped in output)

  --end|-e         Regex for block end line (end/start_end methods)
                   Default: '$display_end'
                   Example: -e '^1\\s*$', --end '^## End'
                   Note: ^ = line start, \$ = line end (native support)

  --rule-file|-u   Classification rule file path
                   Default: '$RULE_FILE'
                   Example: -u my_rules.rules, --rule-file /path/to/classification.rules

  --output-prefix|-k Prefix for category output files
                   Default: '$OUTPUT_PREFIX'
                   Example: -k 'output_', --output-prefix 'category_'

  --output-suffix|-z Suffix for category output files
                   Default: '$OUTPUT_SUFFIX'
                   Example: -z '_v1', --output-suffix '_2024'

  --output-ext|-c  Extension for category output files (no leading . needed)
                   Default: '$OUTPUT_EXT'
                   Example: -c 'txt', --output-ext 'log'

  --outputDir|-o   Output directory for split files (current dir if empty)
                   Default: '$display_output_dir' (current directory)
                   Example: -o ./output, --outputDir /tmp/classified_blocks
                   Note: Directory will be created recursively if it does not exist

  --block-sep|-b   Separator between output blocks (supports escape sequences)
                   Default: '$display_block_sep'
                   Example: -b "--- Next Block ---", --block-sep '\\n===\\n'

  --block-prefix|-p Prefix for each output block (replaces <id> with number, supports escapes)
                   Default: '$display_block_prefix'
                   Example: -p 'Block <id>:', --block-prefix '\\nCategory Block <id>\\n'

  --block-suffix|-x Suffix for each output block (supports escape sequences)
                   Default: '$display_block_suffix'
                   Example: -x '\\n\\n', --block-suffix 'End of Block <id>'

  --allow-empty|-a  Allow empty blocks in output (toggle)
                   Default: @{[$ALLOW_EMPTY ? 'Enabled' : 'Disabled']}
                   Example: -a (enable), --no-allow-empty (disable)

  --case-sensitive|-C Enable case-sensitive matching (default, toggle)
                   Default: Enabled
                   Example: -C (enable), --no-case-sensitive (disable)
  --ignore-case|-I   Disable case-sensitive matching (ignore case)
                   Default: Disabled
                   Example: -I (same as --no-case-sensitive)

  --debug|-d       Enable debug mode (toggle)
                   Default: @{[$DEBUG ? 'Enabled' : 'Disabled']}
                   Example: -d (enable), --no-debug (disable)

  --help|-h        Show this help message and exit
                   Example: -h, --help

Rule File Format (Critical):
  The rule file defines classification categories and their multi-line regex rules.
  Format specifications:
    1. Comments: Lines starting with # are ignored
    2. Category Header: [CategoryName] (brackets required, no spaces in name)
    3. Regex Rule Lines: Each line is a single-quoted regex (AND relationship between lines)
       - Normal rule: 'regex_pattern' (block must have at least one line matching this regex)
       - Negated rule: '!regex_pattern' (block must NOT have any line matching this regex)
    4. Category Priority: First matching category in file order is used (one block → one category)
    5. No extra operators needed - multi-line rules are automatically ANDed

  Rule File Example (priority order matters):
    # Classification Rules for Path Blocks (priority: SR_HP_LATCH > OTHER_LATCH > NO_LATCH)
    [SR_HP_LATCH]          # Highest priority
    '^\s+Endpoint:.*(sr_hp|sr_base)'
    '^\s+Startpoint:.*latch$'
    [OTHER_LATCH]          # Medium priority
    '^\s+Startpoint:.*latch$'
    '!^\s+Endpoint:.*(sr_hp|sr_base)'
    [NO_LATCH]             # Lowest priority
    '!^\s+Startpoint:.*latch$'

Important Notes:
  1. Regex rules: Uses full Perl regex syntax; ^/\$ work for line start/end.
  2. Case sensitivity: Controlled by --case-sensitive/--ignore-case (applies to all rules).
  3. Rule relationship: Multiple lines under a category are ANDed (all must be satisfied).
  4. Block content: Entire block content is preserved (no line filtering) in output files.
  5. Escape sequences: --block-sep/--block-prefix/--block-suffix support \\n (newline), \\t (tab), \\r (carriage return).
  6. Category priority: Blocks match the FIRST category in rule file order (one block → one category).
  7. Output filenames: <prefix><category><suffix>.<ext> (e.g., output_SR_HP_LATCH_v1.rpt)
  8. Empty blocks: Controlled by --allow-empty (only affects empty retained blocks).
  9. Default category: Automatically added (matches all unmatched blocks).
  10. Statistics table: Adaptive column widths, displayed in rule file order.
  11. Parameter override: Command line options (short/long) override default values.
  12. Short options: All long options have corresponding short aliases (e.g., -i = --input, -m = --method).
  13. Compressed files: --input supports gzip/tar/bzip2 etc. (powered by IO::Uncompress::AnyUncompress)  # 新增：补充压缩文件说明
  14. Output directory: --outputDir supports relative/absolute paths; auto-created recursively (cross-OS compatible via File::Spec)

Usage Examples:
Example 1: Case-insensitive classification with custom block suffix (two empty lines)
perl block_classifier.pl \\
  -m se \\               # Short option for --method start_end
  -i input.txt.gz \\     # 新增：示例使用压缩文件
  -s '^Path \\d+:' \\    # Short option for --start
  -e '^1\\s*$' \\        # Short option for --end
  -u my_rules.rules \\   # Short option for --rule-file
  -k 'output_' \\        # Short option for --output-prefix
  -z '_2024' \\          # Short option for --output-suffix
  -c 'txt' \\            # Short option for --output-ext
  -o ./classified_output \\ # Short option for --outputDir
  -b "--- Next Block ---" \\ # Short option for --block-sep
  -p "Block <id>:" \\    # Short option for --block-prefix
  -x "\\n\\n" \\         # Short option for --block-suffix
  -I \\                  # Short option for --ignore-case
  -d                     # Short option for --debug

Example 2: Separator-based extraction with case-sensitive matching
perl block_classifier.pl \\
  -m sep \\              # Short option for --method separator
  -i app.log.tar \\      # 新增：示例使用tar压缩文件
  -r '^\\d{4}-\\d{2}-\\d{2}' \\ # Short option for --separator
  -u log_rules.rules \\  # Short option for --rule-file
  -k 'log_' \\           # Short option for --output-prefix
  -c 'log' \\            # Short option for --output-ext
  -o /tmp/log_classification \\ # Short option for --outputDir
  -C \\                  # Short option for --case-sensitive
  -a \\                  # Short option for --allow-empty
  -d                     # Short option for --debug
HELP
}
