#!/usr/bin/perl
# --------------------------
# author    : sar song
# date      : 2025/10/12 19:46:07 Sunday
# label     : flow_perl
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This Perl script recursively replicates the directory structure of a specified source folder to a target location, creating all 
#             subdirectories while ignoring files. It supports custom naming for the main target directory, forced overwrites of existing 
#             directories, and debug mode for detailed operation tracking.
# return    : A folder with the same file structure as created based on the source folder structure
# ref       : link url
# --------------------------
#!/usr/bin/perl
use strict;
use warnings;
use File::Find;
use File::Path qw(make_path remove_tree);
use Getopt::Long;
use File::Basename;

# Default configuration - Users can modify these values
my $default_debug = 0;           # Disable debug mode by default
my $default_force_rebuild = 0;   # Do not force rebuild by default
my $default_merge = 0;           # Do not merge by default
my $default_new_name = undef;    # No custom name by default

# Initialize variables
my $debug = $default_debug;
my $force_rebuild = $default_force_rebuild;  # Delete and rebuild entire structure
my $merge = $default_merge;                  # Merge with existing structure (add/modify only)
my $new_name = $default_new_name;
my ($source_dir, $dest_parent_dir);
my $help = 0;
my @subdirectories;  # Store all subdirectory paths first

# Parse command line options
GetOptions(
  'debug|d' => \$debug,                # Short: -d, Long: --debug
  'force-rebuild|f' => \$force_rebuild, # Short: -f, Long: --force-rebuild (delete then recreate)
  'merge|m' => \$merge,                 # Short: -m, Long: --merge (add/modify only)
  'name|n=s' => \$new_name,            # Short: -n, Long: --name
  'source|s=s' => \$source_dir,        # Short: -s, Long: --source
  'target-parent|t=s' => \$dest_parent_dir,  # Short: -t, Long: --target-parent
  'help|h' => \$help                   # Short: -h, Long: --help
) or die "Error: Failed to parse options. Use --help for usage.\n";

# Display help information
if ($help) {
  print_help();
  exit 0;
}

# Check for conflicting options
if ($force_rebuild && $merge) {
  die "Error: --force-rebuild and --merge cannot be used together.\n";
}

# Check required options
unless (defined $source_dir && defined $dest_parent_dir) {
  print "Error: Both source directory and target parent directory must be provided.\n";
  print "Use --help for detailed usage information.\n";
  exit 1;
}

# Validate source directory
debug_print("Validating source directory: $source_dir");
unless (-e $source_dir) {
  die "Error: Source directory '$source_dir' does not exist.\n";
}
unless (-d $source_dir) {
  die "Error: '$source_dir' is not a directory.\n";
}
unless (-r $source_dir) {
  die "Error: No read permission for source directory '$source_dir'.\n";
}

# Remove trailing slash from source directory path to ensure consistent length calculation
$source_dir =~ s/\/$//;

# Validate destination parent directory
debug_print("Validating destination parent directory: $dest_parent_dir");
unless (-e $dest_parent_dir) {
  die "Error: Destination parent directory '$dest_parent_dir' does not exist.\n";
}
unless (-d $dest_parent_dir) {
  die "Error: '$dest_parent_dir' is not a directory.\n";
}
unless (-w $dest_parent_dir) {
  die "Error: No write permission in destination parent directory '$dest_parent_dir'.\n";
}

# Determine main directory names
my $source_basename = basename($source_dir);
my $target_main_dir = $new_name || $source_basename;
debug_print("Source main directory name: $source_basename");
debug_print("Target main directory name: $target_main_dir");

# Build full destination path
my $full_dest_dir = "$dest_parent_dir/$target_main_dir";
debug_print("Full destination path: $full_dest_dir");

# Handle existing destination directory based on selected mode
if (-e $full_dest_dir) {
  if (-d $full_dest_dir) {
    debug_print("Target directory '$full_dest_dir' already exists");
    
    if ($force_rebuild) {
      debug_print("Force rebuild enabled - deleting existing directory before recreation");
      my $error;
      remove_tree($full_dest_dir, { error => \$error });
      
      if (@$error) {
        my $error_msg = join(', ', map { "$_->{file}: $_->{message}" } @$error);
        die "Error: Failed to delete existing directory: $error_msg\n";
      }
      debug_print("Successfully deleted existing directory: $full_dest_dir");
      
      # Create fresh main directory after deletion
      my $create_error;
      make_path($full_dest_dir, { error => \$create_error });
      if (@$create_error) {
        my $error_msg = join(', ', map { "$_->{file}: $_->{message}" } @$create_error);
        die "Error: Failed to create main target directory: $error_msg\n";
      }
    }
    elsif ($merge) {
      debug_print("Merge mode enabled - preserving existing directory, will add missing subdirectories");
      # No deletion - existing structure will be preserved
    }
    else {
      die "Error: Target directory '$full_dest_dir' exists. Use --force-rebuild to replace it or --merge to add missing subdirectories.\n";
    }
  } else {
    die "Error: '$full_dest_dir' exists but is not a directory. Cannot create structure.\n";
  }
}
else {
  # Create main target directory if it doesn't exist
  debug_print("Creating main target directory: $full_dest_dir");
  my $error;
  make_path($full_dest_dir, { error => \$error });
  
  if (@$error) {
    my $error_msg = join(', ', map { "$_->{file}: $_->{message}" } @$error);
    die "Error: Failed to create main target directory: $error_msg\n";
  }
}

# First pass: recursively scan all subdirectories and store their paths
debug_print("Starting recursive scan of source directory structure");
find({ wanted => \&collect_subdirectories, no_chdir => 1 }, $source_dir);

# Second pass: create all collected subdirectories after full scan completes
debug_print("Starting creation of collected directory structure");
foreach my $relative_path (@subdirectories) {
  my $dest_path = "$full_dest_dir/$relative_path";
  
  unless (-d $dest_path) {
    debug_print("Creating subdirectory: $dest_path");
    my $sub_error;
    make_path($dest_path, { error => \$sub_error });
    
    if (@$sub_error) {
      my $error_msg = join(', ', map { "$_->{file}: $_->{message}" } @$sub_error);
      print "Warning: Failed to create directory '$dest_path': $error_msg\n";
    }
  } else {
    debug_print("Directory already exists" . ($merge ? " (preserved in merge mode)" : "") . ": $dest_path");
  }
}

print "Success: Directory structure " . 
      ($force_rebuild ? "rebuilt" : ($merge ? "merged" : "created")) . 
      " in '$full_dest_dir'\n";
exit 0;

# Collect subdirectory paths during first pass scan
sub collect_subdirectories {
  my $current_path = $File::Find::name;
  
  # Only process directories, skip files
  return unless -d $current_path;
  
  # Skip source directory itself
  return if $current_path eq $source_dir;
  
  # Calculate path relative to source directory
  my $relative_path = substr($current_path, length($source_dir) + 1);
  debug_print("Found subdirectory: $relative_path");
  
  # Store relative path for later creation
  push @subdirectories, $relative_path;
}

# Print debug information
sub debug_print {
  my ($message) = @_;
  print "Debug: $message\n" if $debug;
}

# Print help information
sub print_help {
  my $script_name = basename($0);
  print "Usage: $script_name [options]\n";
  print "Recursively copies directory structure from source to target location without copying files.\n\n";
  print "Operation modes (choose at most one):\n";
  print "  --force-rebuild (-f)  Delete existing target directory first, then recreate entire structure\n";
  print "                        (This will remove any extra directories not present in source)\n";
  print "  --merge (-m)          Preserve existing directory structure, only add missing subdirectories\n";
  print "                        (Existing directories remain, new ones from source are added)\n";
  print "  (default)             Abort if target directory exists (no changes made)\n\n";
  print "Required options:\n";
  print "  -s, --source DIR       Source directory to scan for structure, NOTICE: Only one folder name is allowed to be entered. (required)\n";
  print "  -t, --target-parent DIR Parent directory where new structure will be created (required)\n\n";
  print "Other options:\n";
  print "  -d, --debug            Enable debug mode - shows detailed operation information\n";
  print "  -n, --name NAME        Specify custom name for the main target directory\n";
  print "                         (default: same as source directory name)\n";
  print "  -h, --help             Display this help message and exit\n\n";
  print "Examples:\n";
  print "1. Create new structure (fails if exists):\n";
  print "   $script_name --source ~/projects/docs --target-parent ~/backups\n\n";
  print "2. Replace existing structure with source's structure:\n";
  print "   $script_name -f --source ~/pics/photos -t ~/archive -n images_2023\n\n";
  print "3. Add missing subdirectories to existing structure:\n";
  print "   $script_name -m --source ~/work/latest_reports -t ~/public/reports\n\n";
  print "4. Debug mode with merge operation:\n";
  print "   $script_name -d -m -s ./data -t ./backup\n";
}

