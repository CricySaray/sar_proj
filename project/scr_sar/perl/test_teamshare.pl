#!/usr/bin/perl -w
# --------------------------
# author    : sar song
# date      : 2025/09/04 11:06:30 Thursday
# label     : misc_sub
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub|misc_sub)
# descrip   : A Perl script enabling team members to share text messages through sequentially numbered files in a shared directory using --push (to add) 
#             and --pop (to retrieve) commands, with automatic cycling after reaching ID 999 and tracking the latest ID via a .latest_id file.
# usage     : Write the following two lines into .cshrc or .bashrc, and then you can conveniently use this Perl script with push or pop:
#               alias push "perl ($script_dir)/teamshare.pl --push"
#               alias pop  "perl ($script_dir)/teamshare.pl --pop"
#             then source .cshrc/.bashrc
#             you can run: push "this is a message", to get a id to retrieve message.
#             run: pop 231, to get message combined with this id.
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
my $id;                        # Temporary ID variable
my $popid = "x";               # Target ID for --pop
my $line_limit = 20;           # Max lines to display in --pop (truncates beyond this)
my $dir = "/home/cricy/.teamshare";  # Shared directory path
my $latest_id_file = "$dir/.latest_id";  # File to track latest message ID
my $debug = 0;                 # Debug mode (0=disabled, 1=enabled; user can modify default here)
my $list = 0;                  # Trigger --list function (show all messages sorted by ID)

# Parse command line options
GetOptions(
  "push=s" => \$msg,           # Push a new message (required: quoted string)
  "pop=s" => \$popid,          # Pop a message by 3-digit ID
  "list" => \$list,            # List all stored messages (compact mode: ID: content)
  "help" => \$help,            # Show detailed help (long option)
  "h" => \$help,               # Show detailed help (short option)
  "debug" => \$debug           # Enable debug mode (flag, no value needed)
) or die "perl teamshare: Error in command line arguments. Use -h or --help for usage.\n";

# Display detailed help page if -h/--help is triggered
if ($help) {
  print "=============================================================\n";
  print "Teamshare Perl Script - Share Text Messages Among Team Members\n";
  print "=============================================================\n";
  print "\nUSAGE: $0 [OPTIONS]\n";
  print "\nOPTIONS:\n";
  print "  --push \"MESSAGE\"   Add a new message to the shared directory.\n";
  print "                      - MESSAGE: Quoted string (supports multi-line via \\n).\n";
  print "                      - Auto-generates a 3-digit ID (000-999) for retrieval.\n";
  print "\n  --pop ID           Retrieve and display a message by its 3-digit ID.\n";
  print "                      - ID: Exact 3-digit number (e.g., 005, 123, 999; no quotes).\n";
  print "                      - Truncates output to $line_limit lines (shows total lines if truncated).\n";
  print "\n  --list             List all stored messages (compact mode, sorted by ID ascending).\n";
  print "                      - Format: [3-digit ID]: [message content] (one entry per line).\n";
  print "                      - Multi-line messages are merged into one line (\\n replaced with space).\n";
  print "                      - Skips unreadable files and shows a warning for each.\n";
  print "                      - Shows total message count at the end.\n";
  print "\n  -h / --help        Show this help page (you're viewing it now).\n";
  print "\n  --debug            Enable debug mode (prints detailed runtime info).\n";
  print "                      - Default: Disabled (set \$debug=1 in script to enable by default).\n";
  print "\n=============================================================\n";
  print "EXAMPLES:\n";
  print "=============================================================\n";
  print "1. Push a simple message:\n";
  print "   \$ perl teamshare.pl --push \"Weekly sync: Tomorrow 10 AM (Conference Room B)\"\n";
  print "   # Output: Message pushed successfully + 3-digit ID (e.g., 042)\n";
  print "   # Use 'perl teamshare.pl --pop 042' to retrieve later.\n";
  print "\n2. Push a multi-line message (use \\n for line breaks):\n";
  print "   \$ perl teamshare.pl --push \"Task Update:\\n- Finish report by EOD\\n- Review PR #123\"\n";
  print "\n3. Pop a message by ID (e.g., retrieve ID 042) with debug mode:\n";
  print "   \$ perl teamshare.pl --pop 042 --debug\n";
  print "   # Output: Debug logs (e.g., file path checks) + full message (truncated if >20 lines).\n";
  print "\n4. List all messages (compact mode) with debug mode:\n";
  print "   \$ perl teamshare.pl --list --debug\n";
  print "   # Output: Debug logs + compact entries (e.g., 042: Weekly sync: Tomorrow 10 AM...).\n";
  print "\n=============================================================\n";
  print "IMPORTANT NOTES:\n";
  print "=============================================================\n";
  print "1. Shared Directory: The script auto-creates \$dir ($dir) with 0777 permissions if it doesn't exist.\n";
  print "2. ID Cycling: IDs range from 000 to 999. After 999, it resets to 000 (overwrites old 000 file).\n";
  print "3. Script Copy Warning: Do NOT manually copy this script to local paths! This causes UID mismatch between the script owner and executor,\n";
  print "   leading to failed permission setup (chmod) or unnecessary warnings.\n";
  print "4. Permission Control: Only the script's original owner can set 0777 permissions for pushed files. Other users skip this step to avoid errors.\n";
  print "5. ID Recovery: If \$latest_id_file is corrupted/lost, the script auto-recovers by scanning 3-digit files in \$dir to find the latest ID.\n";
  print "6. Line Truncation: --pop truncates output to $line_limit lines. A warning is shown if the message has more lines.\n";
  exit 0;
}

# Check mutual exclusivity of --push, --pop, and --list (only one allowed at once)
if ( ($popid ne "x" || $list) && $msg ne "" ) {
  die "perl teamshare: Error: --push cannot be used with --pop or --list. Use only one option.\n";
}
if ( $popid ne "x" && $list ) {
  die "perl teamshare: Error: --pop and --list are mutually exclusive. Use only one option.\n";
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

# Get current latest ID (auto-initialize/recover if .latest_id is missing/corrupted)
sub get_current_id {
  my $current_id = 0;
  
  # Step 1: Check if .latest_id exists and is valid
  if (-e $latest_id_file) {
    print "[DEBUG] Attempting to read latest ID from: $latest_id_file\n" if $debug;
    unless (open $fh, '<', $latest_id_file) {
      die "perl teamshare: Error: Could not read latest ID file $latest_id_file: $!\n";
    }
    my $content = <$fh>;
    close $fh;
    
    if (defined $content && $content =~ /^\d+$/) {
      $current_id = int($content);
      # Boundary check: Ensure ID is between 0 and 999
      $current_id = 0 if $current_id < 0 || $current_id > 999;
      print "[DEBUG] Valid ID found in $latest_id_file: $current_id\n" if $debug;
      return $current_id;
    } else {
      print "[WARNING] Invalid content in $latest_id_file. Recovering from directory scan.\n" if $debug;
      print "Warning: Invalid content in $latest_id_file. Recovering from directory scan.\n";
      # Delete corrupted file (ignore error if delete fails)
      unlink $latest_id_file or warn "Warning: Could not delete corrupted $latest_id_file: $!\n";
    }
  }
  
  # Step 2: Initialize from directory scan (if .latest_id is missing/corrupted)
  print "[DEBUG] $latest_id_file not found/corrupted. Scanning $dir for 3-digit files...\n" if $debug;
  print "Notice: $latest_id_file not found or corrupted. Initializing from directory contents.\n";
  
  # Get all 3-digit files (e.g., 001, 123) in the shared directory
  my @files = glob("$dir/[0-9][0-9][0-9]");
  my @ids;
  
  foreach my $file (@files) {
    my $basename = basename($file);
    if ($basename =~ /^(\d{3})$/) {
      push @ids, int($1);
      print "[DEBUG] Found valid message file: $file (ID: $1)\n" if $debug;
    }
  }
  
  # Determine latest ID from scanned files
  if (@ids) {
    $current_id = (sort { $b <=> $a } @ids)[0];  # Get max ID
    print "[DEBUG] Latest ID from directory scan: $current_id\n" if $debug;
    print "Notice: Found existing files. Latest ID is $current_id\n";
  } else {
    $current_id = 0;  # Start from 0 if no files exist
    print "[DEBUG] No existing message files. Starting from ID 0\n" if $debug;
    print "Notice: No existing files found. Starting from ID 0\n";
  }
  
  # Update .latest_id with recovered ID
  update_latest_id($current_id);
  return $current_id;
}

# Update .latest_id file with the new latest ID
sub update_latest_id {
  my ($id) = @_;
  
  print "[DEBUG] Updating $latest_id_file to ID: $id\n" if $debug;
  unless (open $fh, '>', $latest_id_file) {
    die "perl teamshare: Error: Could not write to latest ID file $latest_id_file: $!\n";
  }
  print $fh "$id\n";
  close $fh;
  
  # Set 0666 permissions for .latest_id (allow all users to read/write)
  unless (chmod 0666, $latest_id_file) {
    warn "Warning: Could not set permissions on $latest_id_file: $!\n";
  }
}

# --------------------------
# Push Function: Add new message to shared directory
# --------------------------
if (length($msg)) {
  my $current_id = get_current_id();
  my $new_id = $current_id + 1;
  # Cycle ID back to 000 after 999
  $new_id = 0 if $new_id > 999;
  my $new_id_str = sprintf("%03d", $new_id);  # Format to 3-digit string (e.g., 5 → 005)
  my $file_path = "$dir/$new_id_str";
  
  print "[DEBUG] Preparing to push message to: $file_path\n" if $debug;
  # Write message to new file (overwrites if ID is recycled)
  unless (open $fh, '>', $file_path) {
    die "perl teamshare: Error: Could not open $file_path for writing: $!\n";
  }
  print $fh "$msg";
  close $fh;
  print "[DEBUG] Message written to $file_path successfully\n" if $debug;
  
  # --------------------------
  # Permission Setup: Only allow script owner to set 0777 permissions
  # WARNING: Do NOT manually copy this script to local paths! This causes UID mismatch between
  # the script's original owner and the executor, leading to permission warnings or failures.
  # --------------------------
  my $current_script_path = $0;  # Path of the currently running script
  my $script_file_stat = stat($current_script_path) or do {
    warn "[WARNING] Failed to get status of script $current_script_path: $!\n" if $debug;
    warn "Warning: Failed to get status of script $current_script_path: $!\n";
    goto SKIP_PERMISSION_SETUP;  # Skip permission setup if script status is unreadable
  };
  my $script_owner_uid = $script_file_stat->uid;  # UID of the script's original owner
  my $current_executor_uid = $<;  # UID of the current user (Perl built-in variable)

  # Only execute chmod if current user is the script owner
  if ($current_executor_uid == $script_owner_uid) {
    print "[DEBUG] Current user is script owner. Setting 0777 permissions on $file_path\n" if $debug;
    unless (chmod 0777, $file_path) {
      warn "Warning: Could not set permissions on $file_path: $!\n";
    }
  } else {
    print "[DEBUG] Current user is not script owner. Skipping permission setup for $file_path\n" if $debug;
  }
SKIP_PERMISSION_SETUP:  # Label to skip permission setup safely
  
  # Update latest ID after push
  update_latest_id($new_id);
  
  # Print success message
  print "\nMessage pushed successfully:\n";
  print "---------------------------\n";
  print "$msg\n";
  print "---------------------------\n";
  print "Retrieve with: perl $0 --pop $new_id_str\n\n";
}

# --------------------------
# Pop Function: Retrieve message by 3-digit ID
# --------------------------
if ($popid ne "x") {
  # Validate ID format (must be 3 digits)
  unless ($popid =~ /^\d{3}$/) {
    die "perl teamshare: Error: Invalid ID format. Use a 3-digit number (e.g., 005, 123).\n";
  }
  
  my $file_path = "$dir/$popid";
  print "[DEBUG] Attempting to pop message from: $file_path\n" if $debug;
  
  # Check if target file exists
  unless (-e $file_path) {
    die "perl teamshare: Error: ID $popid does not exist in teamshare directory ($dir).\n";
  }
  
  # Check if current user has read permission
  unless (-r $file_path) {
    die "perl teamshare: Error: No permission to read ID $popid (file: $file_path).\n";
  }
  
  # Count total lines in the message file (for truncation warning)
  my $total_lines = 0;
  if (open $fh, '<', $file_path) {
    $total_lines++ while <$fh>;
    close $fh;
  } else {
    die "perl teamshare: Error: Could not read $file_path to count lines: $!\n";
  }
  print "[DEBUG] Total lines in $file_path: $total_lines\n" if $debug;
  
  # Read and display message (truncate if over line_limit)
  print "\nMessage for ID $popid:\n";
  print "---------------------------\n";
  my $displayed_lines = 0;
  open $fh, '<', $file_path or die "perl teamshare: Error: Could not open $file_path for reading: $!\n";
  while (my $line = <$fh>) {
    chomp $line;
    print "$line\n";
    $displayed_lines++;
    
    # Stop if line limit is reached
    if ($displayed_lines >= $line_limit) {
      print "[WARNING] Truncated at $line_limit lines (total lines: $total_lines)\n";
      last;
    }
  }
  close $fh;
  print "---------------------------\n\n";
  print "[DEBUG] Finished displaying message for ID $popid\n" if $debug;
}

# --------------------------
# List Function: Compact mode (ID: content, one line per entry)
# --------------------------
if ($list) {
  print "[DEBUG] Starting --list function (compact mode): Scanning $dir for 3-digit message files...\n" if $debug;
  
  # Step 1: Scan shared directory for valid 3-digit message files
  my @files = glob("$dir/[0-9][0-9][0-9]");
  my @ids;
  foreach my $file (@files) {
    my $basename = basename($file);
    if ($basename =~ /^(\d{3})$/) {  # Only keep strict 3-digit files
      push @ids, int($1);
      print "[DEBUG] Found valid message file: $file (ID: $1)\n" if $debug;
    }
  }
  
  # Step 2: Sort IDs in numerical ascending order (000 → 001 → ... → 999)
  @ids = sort { $a <=> $b } @ids;
  print "[DEBUG] Sorted message IDs: " . (join(", ", @ids) || "None") . "\n" if $debug;
  
  # Step 3: Handle case with no stored messages
  unless (@ids) {
    print "No stored messages found in shared directory ($dir)\n";
    print "[DEBUG] --list completed: No messages available\n" if $debug;
    exit 0;
  }
  
  # Step 4: Compact display (one line per ID: ID: content)
  print "\n[Compact Message List (sorted by ID)]\n";
  foreach my $id (@ids) {
    my $id_str = sprintf("%03d", $id);  # Format to 3-digit string (e.g., 5 → 005)
    my $file_path = "$dir/$id_str";
    
    # Skip unreadable files (show warning)
    unless (-r $file_path) {
      print "[WARNING] No permission to read message ID $id_str (file: $file_path)\n";
      print "[DEBUG] Skipping unreadable file: $file_path\n" if $debug;
      next;
    }
    
    # Read message content and merge into one line (replace \n with space)
    open $fh, '<', $file_path or do {
      print "[WARNING] Failed to open message ID $id_str: $!\n";
      print "[DEBUG] Failed to open $file_path: $!\n" if $debug;
      next;
    };
    my $content = do { local $/; <$fh> };  # Read entire file at once
    close $fh;
    
    # Clean content: replace newlines with space, remove extra whitespace
    $content =~ s/\n/ /g;  # Multi-line → single line
    $content =~ s/\s+/ /g;  # Collapse multiple spaces
    $content =~ s/^\s+|\s+$//g;  # Trim leading/trailing spaces
    
    # Compact output format
    print "$id_str: $content\n";
  }
  
  # Step 5: Summary
  print "\nTotal stored messages: " . scalar(@ids) . "\n";
  print "[DEBUG] --list function (compact mode) completed successfully\n" if $debug;
  exit 0;
}
