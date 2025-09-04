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

# state global file var
our $fh;

# Initialize variables
my $help = 0;
my $msg = "";
my $id;
my $popid = "x";
my $line_limit = 20;
my $dir = "/home/cricy/.teamshare";
my $latest_id_file = "$dir/.latest_id";  # File to record the latest ID

# Parse command line options
GetOptions(
  "push=s" => \$msg,
  "pop=s" => \$popid,
  "help" => \$help,
) or die "perl teamshare: Error in command line arguments. Use --help for usage.\n";

# Display help information
if ($help) {
  print "Usage: $0 [OPTIONS]\n";
  print "  --push \"message\"   Push a new message to teamshare\n";
  print "  --pop ID           Pop message with specified 3-digit ID\n";
  print "  --help             Show this help message\n";
  exit;
}

# Check mutual exclusivity of -push and -pop
if ($popid ne "x" && $msg ne "") {
  die "perl teamshare: Error: -push and -pop are mutually exclusive. Use only one.\n";
}

# Basic error check: public directory
unless (-d $dir) {
  if (mkdir($dir, 0777)) {
    print "Notice: Created teamshare directory at $dir\n";
  } else {
    die "perl teamshare: Error: Teamshare directory $dir does not exist and could not be created: $!\n";
  }
}

# Get the latest ID with automatic .latest_id initialization
sub get_current_id {
  my $current_id = 0;
  
  # Check if record file exists
  if (-e $latest_id_file) {
    unless (open $fh, '<', $latest_id_file) {
      die "perl teamshare: Error: Could not read latest ID file $latest_id_file: $!\n";
    }
    my $content = <$fh>;
    close $fh;
    
    if (defined $content && $content =~ /^\d+$/) {
      $current_id = int($content);
      $current_id = 0 if $current_id < 0 || $current_id > 999;  # Boundary check
      return $current_id;
    } else {
      print "Warning: Invalid content in $latest_id_file. Recovering from directory scan.\n";
      unlink $latest_id_file or warn "Warning: Could not delete corrupted $latest_id_file: $!\n";
    }
  }
  
  # File doesn't exist or was corrupted - initialize from directory scan
  print "Notice: $latest_id_file not found or corrupted. Initializing from directory contents.\n";
  
  # Get maximum ID from directory scan
  my @files = glob("$dir/[0-9][0-9][0-9]");  # Only match 3-digit files
  my @ids;
  
  foreach my $file (@files) {
    my $basename = basename($file);
    if ($basename =~ /^(\d{3})$/) {
      push @ids, int($1);
    }
  }
  
  if (@ids) {
    $current_id = (sort { $b <=> $a } @ids)[0];  # Get maximum ID
    print "Notice: Found existing files. Latest ID is $current_id\n";
  } else {
    $current_id = 0;  # Start from 0 if no files exist
    print "Notice: No existing files found. Starting from ID 0\n";
  }
  
  # Create or update record file with initialized value
  update_latest_id($current_id);
  return $current_id;
}

# Update latest ID record file
sub update_latest_id {
  my ($id) = @_;
  
  unless (open $fh, '>', $latest_id_file) {
    die "perl teamshare: Error: Could not write to latest ID file $latest_id_file: $!\n";
  }
  print $fh "$id\n";
  close $fh;
  
  # Ensure correct permissions
  unless (chmod 0666, $latest_id_file) {
    warn "Warning: Could not set permissions on $latest_id_file: $!\n";
  }
}

# Push function: create files sequentially
if (length($msg)) {
  my $current_id = get_current_id();
  my $new_id = $current_id + 1;
  $new_id = 0 if $new_id > 999;  # Cycle back to 000
  
  my $new_id_str = sprintf("%03d", $new_id);
  my $file_path = "$dir/$new_id_str";
  
  # Write new content (overwrite existing file)
  unless (open $fh, '>', $file_path) {
    die "perl teamshare: Error: Could not open $file_path for writing: $!\n";
  }
  print $fh "$msg";
  close $fh;
  
  # Set permissions
  unless (chmod 0777, $file_path) {
    warn "Warning: Could not set permissions on $file_path: $!\n";
  }
  
  # Update latest ID record
  update_latest_id($new_id);
  
  # Output results
  print "Message pushed successfully:\n";
  print "$msg\n";
  print "Use 'teamshare --pop $new_id_str' to retrieve it\n";
}

# Pop function: read file with specified ID
if ($popid ne "x") {
  # Validate ID format (3-digit number)
  unless ($popid =~ /^\d{3}$/) {
    die "perl teamshare: Error: Invalid ID format. Please use a 3-digit number (e.g., 005).\n";
  }
  
  my $file_path = "$dir/$popid";
  
  # Check if file exists
  unless (-e $file_path) {
    die "perl teamshare: Error: ID $popid does not exist in teamshare.\n";
  }
  
  # Check if file is readable
  unless (-r $file_path) {
    die "perl teamshare: Error: No permission to read ID $popid.\n";
  }
  
  # Get total number of lines in file
  my $tline = 0;
  if (open $fh, '<', $file_path) {
    $tline++ while <$fh>;
    close $fh;
  } else {
    die "perl teamshare: Error: Could not read $file_path: $!\n";
  }
  
  # Read and display content (limit to 20 lines)
  my $line_count = 0;
  open $fh, '<', $file_path or die "perl teamshare: Error: Could not open $file_path: $!\n";
  while (my $line = <$fh>) {
    chomp $line;
    print "$line\n";
    $line_count++;
    
    if ($line_count >= $line_limit) {
      print "Warning: Truncated at $line_limit lines (total $tline lines)\n";
      last;
    }
  }
  close $fh;
}

