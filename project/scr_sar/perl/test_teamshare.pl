#!/usr/bin/perl -w
# --------------------------
# author    : sar song
# date      : 2025/09/04 11:06:30 Thursday
# label     : misc_sub
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub|misc_sub)
# descrip   : A Perl script enabling team members to share text messages through sequentially numbered files in a shared directory using --push (to add) 
#             and --pop (to retrieve) commands, with automatic cycling after reaching ID 999 and tracking the latest ID via a .latest_id file.
#             Added note feature for path annotations and search scope control for --find.
# usage     : Write the following two lines into .cshrc or .bashrc, and then you can conveniently use this Perl script with push or pop:
#               alias push "perl ($script_dir)/teamshare.pl --push"
#               alias pop  "perl ($script_dir)/teamshare.pl --pop"
#             then source .cshrc/.bashrc
#             you can run: push "this is a message", to get a id to retrieve message.
#             run: pop 231, to get message combined with this id.
#             run: push "path" --note "annotation" to add path with note.
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
my $msg = "";                  # Message content for --push
my $note = "";                 # Annotation content for --note (attached to --push)
my $id;                        # Temporary ID variable
my $popid = "x";               # Target ID for --pop
my $line_limit = 20;           # Max lines to display in --pop (truncates beyond this)
my $dir = "/home/cricy/.teamshare";  # Shared directory path
my $latest_id_file = "$dir/.latest_id";  # File to track latest ID
my $debug = 0;                 # Debug mode (0=disabled, 1=enabled)
my $list = 0;                  # Trigger --list function
my $find_pattern = "";         # Regex pattern for --find
my $search_scope = "both";     # Default search scope: both (only effective for --find)
my $search_scope_specified = 0;# Mark if user actively specified --search-scope

# Parse command line options
GetOptions(
  "push=s" => \$msg,
  "note=s" => \$note,
  "pop=s" => \$popid,
  "list" => \$list,
  "find=s" => \$find_pattern,
  "search-scope=s" => sub {
    $search_scope = $_[1];
    $search_scope_specified = 1;
  },
  "help" => \$help,
  "h" => \$help,
  "debug" => \$debug
) or die "perl teamshare: Error in command line arguments. Use -h or --help for usage.\n";

# Display detailed help page if -h/--help is triggered
if ($help) {
  print "=============================================================\n";
  print "Teamshare Perl Script - Share Text Messages/Paths Among Team Members\n";
  print "=============================================================\n";
  print "\nUSAGE: $0 [OPTIONS]\n";
  print "\nOPTIONS:\n";
  print "  --push \"CONTENT\"   Add new content (path/message) to shared directory.\n";
  print "                      - CONTENT: Quoted string (supports multi-line via \\n).\n";
  print "                      - Auto-generates 3-digit ID (000-999) for retrieval.\n";
  print "                      - Optional: Use --note to add annotation.\n";
  print "\n  --note \"ANNOTATION\"  Add annotation for --push (optional).\n";
  print "                      - ANNOTATION: Quoted string (brief description).\n";
  print "                      - Only valid with --push (ignored with other options).\n";
  print "                      - Stored as \"NOTE:ANNOTATION\" in file's last line.\n";
  print "\n  --pop ID           Retrieve content + annotation (if exists) by 3-digit ID.\n";
  print "                      - ID: Exact 3-digit number (e.g., 005, 123; no quotes).\n";
  print "                      - Truncates content to $line_limit lines (shows total lines if truncated).\n";
  print "                      - Annotations are never truncated.\n";
  print "\n  --list             List all entries (compact mode, sorted by ID).\n";
  print "                      - No annotation: [ID]: [content] (one line per entry).\n";
  print "                      - With annotation: [ID]: NOTE: [annotation]\n";
  print "                                          [indented content] (two lines).\n";
  print "                      - Multi-line content merged into one line.\n";
  print "                      - Skips unreadable files and shows warnings.\n";
  print "\n  --find PATTERN      Search entries by Perl regex (compact mode).\n";
  print "                      - PATTERN: Quoted regex string (follows Perl syntax).\n";
  print "                      - Results sorted by ID (same format as --list).\n";
  print "                      - Uses --search-scope (default: both) to control range.\n";
  print "\n  --search-scope SCOPE  Define search range for --find (only effective with --find).\n";
  print "                      - Options: content-only / note-only / both (default).\n";
  print "                      - Ignored if --find is not used.\n";
  print "\n  -h / --help        Show this help page.\n";
  print "\n  --debug            Enable debug mode (prints detailed runtime info).\n";
  print "                      - Default: Disabled (set \$debug=1 to enable by default).\n";
  print "\n=============================================================\n";
  print "EXAMPLES:\n";
  print "=============================================================\n";
  print "1. Push content without annotation:\n";
  print "   \$ perl teamshare.pl --push /test/path/file.tcl\n";
  print "\n2. Push content with annotation:\n";
  print "   \$ perl teamshare.pl --push /test/path/file.tcl --note \"Urgent fix for PR #123\"\n";
  print "\n3. Pop entry with annotation (ID 002):\n";
  print "   \$ perl teamshare.pl --pop 002\n";
  print "   # Output:\n";
  print "   # Content for ID 002:\n";
  print "   # /test/path/file.tcl\n";
  print "   # note: Urgent fix for PR #123\n";
  print "\n4. List entries (with/without annotations):\n";
  print "   \$ perl teamshare.pl --list\n";
  print "\n5. Find entries matching content (path starts with /test):\n";
  print "   \$ perl teamshare.pl --find '^/test' --search-scope content-only\n";
  print "\n6. Find entries with annotation containing 'PR':\n";
  print "   \$ perl teamshare.pl --find 'PR' --search-scope note-only\n";
  print "\n7. Find entries matching content/annotation (default scope):\n";
  print "   \$ perl teamshare.pl --find 'urgent'\n";
  print "\n=============================================================\n";
  print "IMPORTANT NOTES:\n";
  print "=============================================================\n";
  print "1. Shared Directory: Auto-creates \$dir ($dir) with 0777 permissions if missing.\n";
  print "2. ID Cycling: IDs 000-999, resets to 000 after 999 (overwrites old file).\n";
  print "3. Script Copy Warning: Do NOT copy to local paths (causes UID mismatch).\n";
  print "4. Permission Control: Only script owner can set 0777 permissions for pushed files.\n";
  print "5. ID Recovery: Auto-recovers latest ID from directory if .latest_id is corrupted.\n";
  print "6. Line Truncation: --pop truncates content to $line_limit lines (annotations intact).\n";
  print "7. Regex Search: Escape special chars (., *, ?, +) with backslash. Use modifiers like (?i) for case-insensitive.\n";
  print "8. Annotation Rules: --note only works with --push. Avoid \"NOTE:\" in content's last line.\n";
  print "9. --search-scope: Only effective with --find. Defaults to 'both' if not specified.\n";
  exit 0;
}

# --------------------------
# Validation: Option Dependencies & Mutual Exclusivity
# --------------------------
# 1. --note only valid with --push
if (length($note) && $msg eq "") {
  die "perl teamshare: Error: --note can only be used with --push (provide content via --push).\n";
}
# 2. --search-scope only valid with --find (only if user actively specified)
if ($search_scope_specified && $find_pattern eq "") {
  die "perl teamshare: Error: --search-scope can only be used with --find (provide pattern via --find).\n";
}
# 3. Validate --search-scope values (only if using --find)
my %valid_scopes = ( "content-only" => 1, "note-only" => 1, "both" => 1 );
if (length($find_pattern) && !exists $valid_scopes{$search_scope}) {
  die "perl teamshare: Error: Invalid --search-scope value. Use 'content-only', 'note-only', or 'both'.\n";
}
# 4. Mutual exclusivity: --push vs --pop/--list/--find
if ( ($popid ne "x" || $list || length($find_pattern)) && $msg ne "" ) {
  die "perl teamshare: Error: --push (with optional --note) cannot be used with --pop, --list, or --find. Use only one option.\n";
}
# 5. Mutual exclusivity: --pop/--list/--find
my $active_options = 0;
$active_options++ if $popid ne "x";
$active_options++ if $list;
$active_options++ if length($find_pattern);
if ($active_options > 1) {
  die "perl teamshare: Error: --pop, --list, and --find are mutually exclusive. Use only one option.\n";
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
  print "Retrieve with: perl $0 --pop $new_id_str\n";
}

# --------------------------
# Pop Function (no empty lines, no horizontal lines)
# --------------------------
if ($popid ne "x") {
  unless ($popid =~ /^\d{3}$/) {
    die "perl teamshare: Error: Invalid ID format. Use a 3-digit number (e.g., 005, 123).\n";
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
  print "[DEBUG] Starting --list function: Scanning $dir for 3-digit files...\n" if $debug;
  
  my @files = glob("$dir/[0-9][0-9][0-9]");
  my @ids;
  foreach my $file (@files) {
    my $basename = basename($file);
    if ($basename =~ /^(\d{3})$/) {
      push @ids, int($1);
      print "[DEBUG] Found valid entry file: $file (ID: $1)\n" if $debug;
    }
  }
  
  @ids = sort { $a <=> $b } @ids;
  print "[DEBUG] Sorted entry IDs: " . (join(", ", @ids) || "None") . "\n" if $debug;
  
  unless (@ids) {
    print "No stored entries found in shared directory ($dir)\n";
    print "[DEBUG] --list completed: No entries available\n" if $debug;
    exit 0;
  }
  
  # Optimized output: only one empty line before header, no horizontal lines
  print "\n[Compact Entry List (sorted by ID)]\n";
  foreach my $id (@ids) {
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
  
  # Optimized output: only one empty line before total
  print "\nTotal stored entries: " . scalar(@ids) . "\n";
  print "[DEBUG] --list function completed successfully\n" if $debug;
  exit 0;
}

# --------------------------
# Find Function (only empty lines for header/total, no horizontal lines)
# --------------------------
if (length($find_pattern)) {
  print "[DEBUG] Starting --find function: Pattern='$find_pattern', Scope='$search_scope', Scanning $dir...\n" if $debug;
  
  eval { "" =~ /$find_pattern/ };
  if ($@) {
    die "perl teamshare: Error: Invalid regex pattern '$find_pattern': $@\n";
  }
  
  my @files = glob("$dir/[0-9][0-9][0-9]");
  my @matched_entries;
  
  foreach my $file (@files) {
    my $basename = basename($file);
    if ($basename =~ /^(\d{3})$/) {
      my $id = int($1);
      my $id_str = $basename;
      print "[DEBUG] Checking entry ID $id_str (file: $file)\n" if $debug;
      
      unless (-r $file) {
        print "[WARNING] No permission to read entry ID $id_str (file: $file)\n";
        print "[DEBUG] Skipping unreadable file: $file\n" if $debug;
        next;
      }
      
      open $fh, '<', $file or do {
        print "[WARNING] Failed to open entry ID $id_str: $!\n";
        print "[DEBUG] Failed to open $file: $!\n" if $debug;
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
  }
  
  @matched_entries = sort { $a->{id} <=> $b->{id} } @matched_entries;
  print "[DEBUG] Sorted matched IDs: " . (join(", ", map { $_->{id_str} } @matched_entries) || "None") . "\n" if $debug;
  
  unless (@matched_entries) {
    print "No entries matched regex pattern '$find_pattern' (scope: $search_scope) in shared directory ($dir)\n";
    print "[DEBUG] --find completed: No matching entries\n" if $debug;
    exit 0;
  }
  
  # Optimized output: only one empty line before header, no horizontal lines
  print "\n[Matched Entries (Pattern: '$find_pattern', Scope: '$search_scope', sorted by ID)]\n";
  foreach my $entry (@matched_entries) {
    if (defined $entry->{note}) {
      print "$entry->{id_str}: NOTE: $entry->{note}\n";
      print "        $entry->{content}\n";
    } else {
      print "$entry->{id_str}: $entry->{content}\n";
    }
  }
  
  # Optimized output: only one empty line before total
  print "\nTotal matched entries: " . scalar(@matched_entries) . "\n";
  print "[DEBUG] --find function completed successfully\n" if $debug;
  exit 0;
}
