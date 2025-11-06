#!/usr/bin/perl -w
# --------------------------
# author    : sar song
# date      : 2025/09/04 11:06:30 Thursday
# label     : misc_sub
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub|misc_sub)
# descrip   : A Perl script enabling team members to share text messages through sequentially numbered files in a shared directory using --push (to add) 
#             and --pop (to retrieve) commands, with automatic cycling after reaching ID 999 and tracking the latest ID via a .latest_id file.
#             Added note feature for path annotations, search scope control for --find, and ID range filter for --list/--find.
# usage     : Write the following two lines into .cshrc or .bashrc, and then you can conveniently use this Perl script with push or pop:
#               alias push "perl ($script_dir)/teamshare.pl --push"
#               alias pop  "perl ($script_dir)/teamshare.pl --pop"
#               alias plist  "perl ($script_dir)/teamshare.pl --list"
#               alias pfind  "perl ($script_dir)/teamshare.pl --find"
#               alias phelp  "perl ($script_dir)/teamshare.pl -h"
#             then source .cshrc/.bashrc
#             you can run: push "this is a message", to get a id to retrieve message.
#             run: pop 231, to get message combined with this id.
#             run: push "path" --note "annotation" to add path with note.
#             run: plist to list all content of ids
#             run: pfind "regexp" to find the matched expression from content of ids.
#             run: plist --range ',10' to show first 10 entries; find 'test' --range '-5,' to search last 5 entries.
# ref       : link url
# --------------------------
use strict;
use Cwd;
use Getopt::Long;
use File::Basename;
use File::stat;  # For checking script owner UID

# State global file handle
our $fh;

# Initialize variables (configurable by user)
my $help = 0;                  # Trigger help page (-h/--help)
my $msg = "";                  # Message content for --push (-p)
my $note = "";                 # Annotation content for --note (-n)
my $id;                        # Temporary ID variable
my $popid = "x";               # Target ID for --pop (-o)
my $line_limit = 20;           # Max lines to display in --pop (truncates beyond this)
my $dir = "/home/cricy/.teamshare";  # Shared directory path
my $latest_id_file = "$dir/.latest_id";  # File to track latest ID
my $debug = 0;                 # Debug mode (-d/--debug)
my $list = 0;                  # Trigger --list (-l) function
my $find_pattern = "";         # Regex pattern for --find (-f)
my $search_scope = "both";     # Default search scope: both (only effective for --find)
my $search_scope_specified = 0;# Mark if user actively specified --search-scope (-s)
my $range = ',';               # Default range: all entries (equivalent to '^,$') (-r/--range)

# Parse command line options (add short format aliases)
GetOptions(
  "push|p=s" => \$msg,
  "note|n=s" => \$note,
  "pop|o=s" => \$popid,
  "list|l" => \$list,
  "find|f=s" => \$find_pattern,
  "search-scope|s=s" => sub {
    $search_scope = $_[1];
    $search_scope_specified = 1;
  },
  "range|r=s" => \$range,
  "help|h" => \$help,  # Keep existing -h as short for --help
  "debug|d" => \$debug
) or die "perl teamshare: Error in command line arguments. Use -h or --help for usage.\n";

# Display detailed help page if -h/--help is triggered
if ($help) {
  print "=============================================================\n";
  print "Teamshare Perl Script - Share Text Messages/Paths Among Team Members\n";
  print "=============================================================\n";
  print "\nUSAGE: $0 [OPTIONS]\n";
  print "\nOPTIONS:\n";
  print "  --push \"CONTENT\" (-p)   Add new content (path/message) to shared directory.\n";
  print "                      - CONTENT: Quoted string (supports multi-line via \\n).\n";
  print "                      - Auto-generates 3-digit ID (000-999) for retrieval.\n";
  print "                      - Optional: Use --note (-n) to add annotation.\n";
  print "\n  --note \"ANNOTATION\" (-n)  Add annotation for --push (-p) (optional).\n";
  print "                      - ANNOTATION: Quoted string (brief description).\n";
  print "                      - Only valid with --push (-p) (ignored with other options).\n";
  print "                      - Stored as \"NOTE:ANNOTATION\" in file's last line.\n";
  print "\n  --pop ID (-o)           Retrieve content + annotation (if exists) by 3-digit ID.\n";
  print "                      - ID: Exact 3-digit number (e.g., 005, 123; no quotes).\n";
  print "                      - Truncates content to $line_limit lines (shows total lines if truncated).\n";
  print "                      - Annotations are never truncated.\n";
  print "\n  --list (-l)             List entries (compact mode, sorted by ID).\n";
  print "                      - No annotation: [ID]: [content] (one line per entry).\n";
  print "                      - With annotation: [ID]: NOTE: [annotation]\n";
  print "                                          [indented content] (two lines).\n";
  print "                      - Multi-line content merged into one line.\n";
  print "                      - Skips unreadable files and shows warnings.\n";
  print "                      - Use --range (-r) to limit display scope.\n";
  print "\n  --find PATTERN (-f)      Search entries by Perl regex (compact mode).\n";
  print "                      - PATTERN: Quoted regex string (follows Perl syntax).\n";
  print "                      - Results sorted by ID (same format as --list (-l)).\n";
  print "                      - Uses --search-scope (-s) (default: both) to control range.\n";
  print "                      - Use --range (-r) to limit search scope to specific IDs.\n";
  print "\n  --search-scope SCOPE (-s)  Define search range for --find (-f) (only effective with --find).\n";
  print "                      - Options: content-only / note-only / both (default).\n";
  print "                      - Ignored if --find (-f) is not used.\n";
  print "\n  --range RANGE (-r)       Limit entries for --list (-l)/--find (-f) (ID-based range filter).\n";
  print "                      - RANGE: Required comma-separated values (e.g., ',10', '30,', '5,-3').\n";
  print "                      - Special symbols:\n";
  print "                        ^: First entry (sorted by ID ascending)\n";
  print "                        \$: Last entry (sorted by ID ascending)\n";
  print "                        Positive number: 1-based index from start (e.g., 3 = 3rd entry)\n";
  print "                        Negative number: 1-based index from end (e.g., -1 = last entry)\n";
  print "                      - Valid formats:\n";
  print "                        ','        : All entries (default, equivalent to '^,\$')\n";
  print "                        ',10'      : First to 10th entry (omitted ^ → '^,10')\n";
  print "                        '30,'      : 30th entry to last (omitted \$ → '30,\$')\n";
  print "                        '^,10'     : First to 10th entry (explicit start)\n";
  print "                        '5,-3'     : 5th entry to 3rd from last\n";
  print "                        '-10,\$'   : 10th from last to last (explicit end)\n";
  print "                      - Ignored with --push (-p)/--pop (-o).\n";
  print "\n  -h / --help              Show this help page.\n";
  print "\n  --debug (-d)            Enable debug mode (prints detailed runtime info).\n";
  print "                      - Default: Disabled (set \$debug=1 to enable by default).\n";
  print "\n=============================================================\n";
  print "EXAMPLES:\n";
  print "=============================================================\n";
  print "1. Push content without annotation (long/short option):\n";
  print "   \$ perl teamshare.pl --push /test/path/file.tcl\n";
  print "   \$ perl teamshare.pl -p /test/path/file.tcl\n";
  print "\n2. Push content with annotation (long/short option):\n";
  print "   \$ perl teamshare.pl --push /test/path/file.tcl --note \"Urgent fix for PR #123\"\n";
  print "   \$ perl teamshare.pl -p /test/path/file.tcl -n \"Urgent fix for PR #123\"\n";
  print "\n3. Pop entry with annotation (ID 002) (long/short option):\n";
  print "   \$ perl teamshare.pl --pop 002\n";
  print "   \$ perl teamshare.pl -o 002\n";
  print "   # Output:\n";
  print "   # Content for ID 002:\n";
  print "   # /test/path/file.tcl\n";
  print "   # note: Urgent fix for PR #123\n";
  print "\n4. List all entries (long/short option):\n";
  print "   \$ perl teamshare.pl --list\n";
  print "   \$ perl teamshare.pl -l\n";
  print "\n5. List first 5 entries (long/short option):\n";
  print "   \$ perl teamshare.pl --list --range ',5'\n";
  print "   \$ perl teamshare.pl -l -r ',5'\n";
  print "\n6. List 10th to 20th entries (long/short option):\n";
  print "   \$ perl teamshare.pl --list --range '10,20'\n";
  print "   \$ perl teamshare.pl -l -r '10,20'\n";
  print "\n7. List last 3 entries (long/short option):\n";
  print "   \$ perl teamshare.pl --list --range '-3,'\n";
  print "   \$ perl teamshare.pl -l -r '-3,'\n";
  print "\n8. Find entries containing 'test' in first 10 entries (long/short option):\n";
  print "   \$ perl teamshare.pl --find 'test' --range ',10'\n";
  print "   \$ perl teamshare.pl -f 'test' -r ',10'\n";
  print "\n9. Find entries with 'PR' in annotations (last 5 entries) (long/short option):\n";
  print "   \$ perl teamshare.pl --find 'PR' --search-scope note-only --range '-5,'\n";
  print "   \$ perl teamshare.pl -f 'PR' -s note-only -r '-5,'\n";
  print "\n10. Find entries matching 'urgent' (5th to 3rd from last) (long/short option):\n";
  print "    \$ perl teamshare.pl --find 'urgent' --range '5,-3'\n";
  print "    \$ perl teamshare.pl -f 'urgent' -r '5,-3'\n";
  print "\n11. Enable debug mode with any command (long/short option):\n";
  print "    \$ perl teamshare.pl -l -r ',5' --debug\n";
  print "    \$ perl teamshare.pl -f 'test' -d\n";
  print "\n=============================================================\n";
  print "IMPORTANT NOTES:\n";
  print "=============================================================\n";
  print "1. Shared Directory: Auto-creates \$dir ($dir) with 0777 permissions if missing.\n";
  print "2. ID Cycling: IDs 000-999, resets to 000 after 999 (overwrites old file).\n";
  print "3. Script Copy Warning: Do NOT copy to local paths (causes UID mismatch).\n";
  print "4. Permission Control: Only script owner can set 0777 permissions for pushed files.\n";
  print "5. ID Recovery: Auto-recovers latest ID from directory if .latest_id is corrupted.\n";
  print "6. Line Truncation: --pop (-o) truncates content to $line_limit lines (annotations intact).\n";
  print "7. Regex Search: Escape special chars (., *, ?, +) with backslash. Use modifiers like (?i) for case-insensitive.\n";
  print "8. Annotation Rules: --note (-n) only works with --push (-p). Avoid \"NOTE:\" in content's last line.\n";
  print "9. --search-scope (-s): Only effective with --find (-f). Defaults to 'both' if not specified.\n";
  print "10. --range (-r): Only effective with --list (-l)/--find (-f). Uses 1-based indexing; out-of-bounds values auto-adjust to valid range.\n";
  print "11. --range (-r) Format: Comma is mandatory. Invalid formats (e.g., '10-20', 'abc') will throw errors.\n";
  print "12. Short/Long Options: All short options are aliases for long options; functionality is identical.\n";
  exit 0;
}

# --------------------------
# Validation: Option Dependencies & Mutual Exclusivity
# --------------------------
# 1. --note (-n) only valid with --push (-p)
if (length($note) && $msg eq "") {
  die "perl teamshare: Error: --note (-n) can only be used with --push (-p) (provide content via --push (-p)).\n";
}
# 2. --search-scope (-s) only valid with --find (-f) (only if user actively specified)
if ($search_scope_specified && $find_pattern eq "") {
  die "perl teamshare: Error: --search-scope (-s) can only be used with --find (-f) (provide pattern via --find (-f)).\n";
}
# 3. Validate --search-scope (-s) values (only if using --find (-f))
my %valid_scopes = ( "content-only" => 1, "note-only" => 1, "both" => 1 );
if (length($find_pattern) && !exists $valid_scopes{$search_scope}) {
  die "perl teamshare: Error: Invalid --search-scope (-s) value. Use 'content-only', 'note-only', or 'both'.\n";
}
# 4. Mutual exclusivity: --push (-p) vs --pop (-o)/--list (-l)/--find (-f)
if ( ($popid ne "x" || $list || length($find_pattern)) && $msg ne "" ) {
  die "perl teamshare: Error: --push (-p) (with optional --note (-n)) cannot be used with --pop (-o), --list (-l), or --find (-f). Use only one option.\n";
}
# 5. Mutual exclusivity: --pop (-o)/--list (-l)/--find (-f)
my $active_options = 0;
$active_options++ if $popid ne "x";
$active_options++ if $list;
$active_options++ if length($find_pattern);
if ($active_options > 1) {
  die "perl teamshare: Error: --pop (-o), --list (-l), and --find (-f) are mutually exclusive. Use only one option.\n";
}
# 6. Validate --range (-r) format (only for --list (-l)/--find (-f))
if (($list || length($find_pattern)) && $range !~ /,/) {
  die "perl teamshare: Error: --range (-r) must contain a comma (valid formats: ',10', '30,', '5,-3', ',').\n";
}

# Validate shared directory (create if missing)
unless (-d $dir) {
  if (mkdir($dir, 0777)) {
    print "[NOTICE] Created teamshare directory at: $dir\n" if $debug;
    print "Notice: Created teamshare directory at $dir\n";
  } else {
    die "perl teamshare: Error: Teamshare directory $dir does not exist and could not be created: $!\n";
  }
}

# --------------------------
# Helper Sub: Parse Content + Note from File
# --------------------------
sub parse_content_note {
  my ($raw_content) = @_;
  my @lines = split(/\n/, $raw_content);
  my $note = undef;
  my @original;

  if (@lines && $lines[-1] =~ /^NOTE:(.*)/) {
    $note = $1;
    $note =~ s/^\s+|\s+$//g;
    @original = @lines[0 .. $#lines - 1];
    print "[DEBUG] Found annotation: '$note'\n" if $debug;
  } else {
    @original = @lines;
    print "[DEBUG] No annotation found in content\n" if $debug;
  }

  return {
    original => \@original,
    note => $note
  };
}

# --------------------------
# Helper Sub: Parse --range (-r) and Filter Sorted IDs
# Input: range string, reference to sorted ID list (ascending)
# Output: filtered ID list (ascending)
# --------------------------
sub parse_range {
  my ($range_str, $sorted_ids_ref) = @_;
  my @sorted_ids = @$sorted_ids_ref;
  my $total_entries = scalar(@sorted_ids);
  
  # Return empty if no entries
  return () if $total_entries == 0;

  # Process shorthand formats (omitted ^/$)
  my ($start, $end) = split(/,/, $range_str, 2);  # Split into two parts at first comma
  $start = '^' unless defined $start && $start ne '';  # ',x' → '^,x'
  $end = '$' unless defined $end && $end ne '';        # 'x,' → 'x,$'

  # Calculate start index (0-based)
  my $start_idx;
  if ($start eq '^') {
    $start_idx = 0;
  } elsif ($start eq '$') {
    $start_idx = $total_entries - 1;
  } elsif ($start =~ /^[+-]?\d+$/) {
    if ($start > 0) {
      $start_idx = $start - 1;  # Positive: 1-based → 0-based
    } else {
      $start_idx = $total_entries + $start;  # Negative: -1 → last entry, -2 → second last
    }
  } else {
    die "perl teamshare: Error: Invalid start value '$start' in --range (-r) (use ^, \$, or number).\n";
  }

  # Calculate end index (0-based)
  my $end_idx;
  if ($end eq '^') {
    $end_idx = 0;
  } elsif ($end eq '$') {
    $end_idx = $total_entries - 1;
  } elsif ($end =~ /^[+-]?\d+$/) {
    if ($end > 0) {
      $end_idx = $end - 1;  # Positive: 1-based → 0-based
    } else {
      $end_idx = $total_entries + $end;  # Negative: -1 → last entry, -2 → second last
    }
  } else {
    die "perl teamshare: Error: Invalid end value '$end' in --range (-r) (use ^, \$, or number).\n";
  }

  # Adjust to valid bounds (prevent out-of-range)
  $start_idx = 0 if $start_idx < 0;
  $end_idx = $total_entries - 1 if $end_idx >= $total_entries;

  # Validate start <= end
  if ($start_idx > $end_idx) {
    die "perl teamshare: Error: Start index ($start_idx + 1) exceeds end index ($end_idx + 1) in --range (-r).\n";
  }

  # Return filtered IDs (preserve ascending order)
  my @filtered_ids = @sorted_ids[$start_idx .. $end_idx];
  print "[DEBUG] Parsed --range (-r) '$range_str' → start_idx=$start_idx, end_idx=$end_idx, filtered_ids=" . join(",", @filtered_ids) . "\n" if $debug;
  return @filtered_ids;
}

# --------------------------
# Sub: Get Current Latest ID
# --------------------------
sub get_current_id {
  my $current_id = 0;
  
  if (-e $latest_id_file) {
    print "[DEBUG] Attempting to read latest ID from: $latest_id_file\n" if $debug;
    unless (open $fh, '<', $latest_id_file) {
      die "perl teamshare: Error: Could not read latest ID file $latest_id_file: $!\n";
    }
    my $content = <$fh>;
    close $fh;
    
    if (defined $content && $content =~ /^\d+$/) {
      $current_id = int($content);
      $current_id = 0 if $current_id < 0 || $current_id > 999;
      print "[DEBUG] Valid ID found in $latest_id_file: $current_id\n" if $debug;
      return $current_id;
    } else {
      print "[WARNING] Invalid content in $latest_id_file. Recovering from directory scan.\n" if $debug;
      print "Warning: Invalid content in $latest_id_file. Recovering from directory scan.\n";
      unlink $latest_id_file or warn "Warning: Could not delete corrupted $latest_id_file: $!\n";
    }
  }
  
  print "[DEBUG] $latest_id_file not found/corrupted. Scanning $dir for 3-digit files...\n" if $debug;
  print "Notice: $latest_id_file not found or corrupted. Initializing from directory contents.\n";
  
  my @files = glob("$dir/[0-9][0-9][0-9]");
  my @ids;
  
  foreach my $file (@files) {
    my $basename = basename($file);
    if ($basename =~ /^(\d{3})$/) {
      push @ids, int($1);
      print "[DEBUG] Found valid message file: $file (ID: $1)\n" if $debug;
    }
  }
  
  if (@ids) {
    $current_id = (sort { $b <=> $a } @ids)[0];
    print "[DEBUG] Latest ID from directory scan: $current_id\n" if $debug;
    print "Notice: Found existing files. Latest ID is $current_id\n";
  } else {
    $current_id = 0;
    print "[DEBUG] No existing message files. Starting from ID 0\n" if $debug;
    print "Notice: No existing files found. Starting from ID 0\n";
  }
  
  update_latest_id($current_id);
  return $current_id;
}

# --------------------------
# Sub: Update Latest ID File
# --------------------------
sub update_latest_id {
  my ($id) = @_;
  
  print "[DEBUG] Updating $latest_id_file to ID: $id\n" if $debug;
  unless (open $fh, '>', $latest_id_file) {
    die "perl teamshare: Error: Could not write to latest ID file $latest_id_file: $!\n";
  }
  print $fh "$id\n";
  close $fh;
  
  unless (chmod 0666, $latest_id_file) {
    warn "Warning: Could not set permissions on $latest_id_file: $!\n";
  }
}

# --------------------------
# Push Function (no empty lines, no horizontal lines)
# --------------------------
if (length($msg)) {
  my $current_id = get_current_id();
  my $new_id = $current_id + 1;
  $new_id = 0 if $new_id > 999;
  my $new_id_str = sprintf("%03d", $new_id);
  my $file_path = "$dir/$new_id_str";
  
  print "[DEBUG] Preparing to push content to: $file_path\n" if $debug;
  print "[DEBUG] Push content: '$msg'\n" if $debug;
  print "[DEBUG] Optional note: " . (length($note) ? "'$note'" : "none") . "\n" if $debug;
  
  unless (open $fh, '>', $file_path) {
    die "perl teamshare: Error: Could not open $file_path for writing: $!\n";
  }
  print $fh "$msg";
  if (length($note)) {
    print $fh "\nNOTE:$note";
  }
  close $fh;
  print "[DEBUG] Content (with optional note) written to $file_path successfully\n" if $debug;
  
  # Permission Setup
  my $current_script_path = $0;
  my $script_file_stat = stat($current_script_path) or do {
    warn "[WARNING] Failed to get status of script $current_script_path: $!\n" if $debug;
    warn "Warning: Failed to get status of script $current_script_path: $!\n";
    goto SKIP_PERMISSION_SETUP;
  };
  my $script_owner_uid = $script_file_stat->uid;
  my $current_executor_uid = $<;

  if ($current_executor_uid == $script_owner_uid) {
    print "[DEBUG] Current user is script owner. Setting 0777 permissions on $file_path\n" if $debug;
    unless (chmod 0777, $file_path) {
      warn "Warning: Could not set permissions on $file_path: $!\n";
    }
  } else {
    print "[DEBUG] Current user is not script owner. Skipping permission setup for $file_path\n" if $debug;
  }
SKIP_PERMISSION_SETUP:
  
  update_latest_id($new_id);
  
  # Optimized output: no empty lines, no horizontal lines
  print "Content pushed successfully:\n";
  print "$msg\n";
  if (length($note)) {
    print "NOTE: $note\n";
  }
  print "Retrieve with: perl $0 --pop $new_id_str (or -o $new_id_str)\n";
}

# --------------------------
# Pop Function (no empty lines, no horizontal lines)
# --------------------------
if ($popid ne "x") {
  unless ($popid =~ /^\d{3}$/) {
    die "perl teamshare: Error: Invalid ID format. Use a 3-digit number (e.g., 005, 123; no quotes).\n";
  }
  
  my $file_path = "$dir/$popid";
  print "[DEBUG] Attempting to pop entry from: $file_path\n" if $debug;
  
  unless (-e $file_path) {
    die "perl teamshare: Error: ID $popid does not exist in teamshare directory ($dir).\n";
  }
  unless (-r $file_path) {
    die "perl teamshare: Error: No permission to read ID $popid (file: $file_path).\n";
  }
  
  open $fh, '<', $file_path or die "perl teamshare: Error: Could not open $file_path for reading: $!\n";
  my $raw_content = do { local $/; <$fh> };
  close $fh;
  my $parsed = parse_content_note($raw_content);
  my $original_ref = $parsed->{original};
  my $note = $parsed->{note};
  my $total_lines = scalar(@$original_ref);
  
  print "[DEBUG] Total lines in content (excluding note): $total_lines\n" if $debug;
  
  # Optimized output: no empty lines, no horizontal lines
  print "Content for ID $popid:\n";
  my $displayed_lines = 0;
  foreach my $line (@$original_ref) {
    print "$line\n";
    $displayed_lines++;
    if ($displayed_lines >= $line_limit) {
      print "[WARNING] Truncated at $line_limit lines (total lines: $total_lines)\n";
      last;
    }
  }
  
  if (defined $note) {
    print "note: $note\n";
  }
}

# --------------------------
# List Function (only empty lines for header/total, no horizontal lines)
# --------------------------
if ($list) {
  print "[DEBUG] Starting --list (-l) function: Scanning $dir for 3-digit files...\n" if $debug;
  
  # Step 1: Collect all valid IDs and sort ascending
  my @files = glob("$dir/[0-9][0-9][0-9]");
  my @all_ids;
  foreach my $file (@files) {
    my $basename = basename($file);
    if ($basename =~ /^(\d{3})$/) {
      push @all_ids, int($1);
      print "[DEBUG] Found valid entry file: $file (ID: $1)\n" if $debug;
    }
  }
  @all_ids = sort { $a <=> $b } @all_ids;
  print "[DEBUG] All sorted IDs: " . (join(", ", @all_ids) || "None") . "\n" if $debug;
  
  # Step 2: Apply --range (-r) filter
  my @selected_ids = parse_range($range, \@all_ids);
  unless (@selected_ids) {
    print "No entries in specified range '$range' (shared directory: $dir)\n";
    print "[DEBUG] --list (-l) completed: No entries in range\n" if $debug;
    exit 0;
  }
  
  # Step 3: Display filtered entries
  print "\n[Compact Entry List (range: '$range', sorted by ID)]\n";
  foreach my $id (@selected_ids) {
    my $id_str = sprintf("%03d", $id);
    my $file_path = "$dir/$id_str";
    
    unless (-r $file_path) {
      print "[WARNING] No permission to read entry ID $id_str (file: $file_path)\n";
      print "[DEBUG] Skipping unreadable file: $file_path\n" if $debug;
      next;
    }
    
    open $fh, '<', $file_path or do {
      print "[WARNING] Failed to open entry ID $id_str: $!\n";
      print "[DEBUG] Failed to open $file_path: $!\n" if $debug;
      next;
    };
    my $raw_content = do { local $/; <$fh> };
    close $fh;
    my $parsed = parse_content_note($raw_content);
    my $original_ref = $parsed->{original};
    my $note = $parsed->{note};
    
    my $content = join(" ", @$original_ref);
    $content =~ s/\s+/ /g;
    $content =~ s/^\s+|\s+$//g;
    
    if (defined $note) {
      print "$id_str: NOTE: $note\n";
      print "        $content\n";
    } else {
      print "$id_str: $content\n";
    }
  }
  
  print "\nTotal entries in range '$range': " . scalar(@selected_ids) . "\n";
  print "[DEBUG] --list (-l) function completed successfully\n" if $debug;
  exit 0;
}

# --------------------------
# Find Function (only empty lines for header/total, no horizontal lines)
# --------------------------
if (length($find_pattern)) {
  print "[DEBUG] Starting --find (-f) function: Pattern='$find_pattern', Scope='$search_scope', Range='$range', Scanning $dir...\n" if $debug;
  
  # Validate regex pattern
  eval { "" =~ /$find_pattern/ };
  if ($@) {
    die "perl teamshare: Error: Invalid regex pattern '$find_pattern': $@\n";
  }
  
  # Step 1: Collect all valid IDs, sort ascending, apply --range (-r) filter
  my @all_files = glob("$dir/[0-9][0-9][0-9]");
  my @all_ids;
  foreach my $file (@all_files) {
    my $basename = basename($file);
    if ($basename =~ /^(\d{3})$/) {
      push @all_ids, int($1);
    }
  }
  @all_ids = sort { $a <=> $b } @all_ids;
  print "[DEBUG] All sorted IDs: " . (join(", ", @all_ids) || "None") . "\n" if $debug;
  
  my @selected_ids = parse_range($range, \@all_ids);
  unless (@selected_ids) {
    print "No entries in specified range '$range' (shared directory: $dir)\n";
    print "[DEBUG] --find (-f) completed: No entries in range\n" if $debug;
    exit 0;
  }
  
  # Step 2: Search only in filtered IDs
  my @matched_entries;
  foreach my $id (@selected_ids) {
    my $id_str = sprintf("%03d", $id);
    my $file_path = "$dir/$id_str";
    print "[DEBUG] Checking entry ID $id_str (file: $file_path)\n" if $debug;
    
    unless (-r $file_path) {
      print "[WARNING] No permission to read entry ID $id_str (file: $file_path)\n";
      print "[DEBUG] Skipping unreadable file: $file_path\n" if $debug;
      next;
    }
    
    open $fh, '<', $file_path or do {
      print "[WARNING] Failed to open entry ID $id_str: $!\n";
      print "[DEBUG] Failed to open $file_path: $!\n" if $debug;
      next;
    };
    my $raw_content = do { local $/; <$fh> };
    close $fh;
    my $parsed = parse_content_note($raw_content);
    my $original_ref = $parsed->{original};
    my $note = $parsed->{note};
    
    my $content = join(" ", @$original_ref);
    $content =~ s/\s+/ /g;
    $content =~ s/^\s+|\s+$//g;
    
    # Match based on search scope
    my $is_match = 0;
    if ($search_scope eq "content-only") {
      $is_match = 1 if $content =~ /$find_pattern/;
      print "[DEBUG] ID $id_str: Content match check: " . ($is_match ? "yes" : "no") . "\n" if $debug;
    } elsif ($search_scope eq "note-only") {
      $is_match = 1 if (defined $note && $note =~ /$find_pattern/);
      print "[DEBUG] ID $id_str: Note match check: " . ($is_match ? "yes" : "no") . "\n" if $debug;
    } elsif ($search_scope eq "both") {
      $is_match = 1 if ($content =~ /$find_pattern/) || (defined $note && $note =~ /$find_pattern/);
      print "[DEBUG] ID $id_str: Content/note match check: " . ($is_match ? "yes" : "no") . "\n" if $debug;
    }
    
    if ($is_match) {
      push @matched_entries, {
        id => $id,
        id_str => $id_str,
        content => $content,
        note => $note
      };
      print "[DEBUG] ID $id_str: Added to matched entries\n" if $debug;
    }
  }
  
  # Step 3: Display results
  @matched_entries = sort { $a->{id} <=> $b->{id} } @matched_entries;
  print "[DEBUG] Sorted matched IDs: " . (join(", ", map { $_->{id_str} } @matched_entries) || "None") . "\n" if $debug;
  
  unless (@matched_entries) {
    print "No entries matched regex pattern '$find_pattern' (scope: $search_scope, range: '$range') in shared directory ($dir)\n";
    print "[DEBUG] --find (-f) completed: No matching entries\n" if $debug;
    exit 0;
  }
  
  print "\n[Matched Entries (Pattern: '$find_pattern', Scope: '$search_scope', Range: '$range', sorted by ID)]\n";
  foreach my $entry (@matched_entries) {
    if (defined $entry->{note}) {
      print "$entry->{id_str}: NOTE: $entry->{note}\n";
      print "        $entry->{content}\n";
    } else {
      print "$entry->{id_str}: $entry->{content}\n";
    }
  }
  
  print "\nTotal matched entries in range '$range': " . scalar(@matched_entries) . "\n";
  print "[DEBUG] --find (-f) function completed successfully\n" if $debug;
  exit 0;
}
