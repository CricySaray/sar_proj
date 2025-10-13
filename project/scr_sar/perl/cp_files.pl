#!/usr/bin/perl
# --------------------------
# author    : sar song
# date      : 2025/10/11 16:49:11 Saturday
# label     : perl_task
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc
#             |report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : Copies files from multiple source directories to a single target directory, adding a path component as prefix or suffix to 
#             filenames to prevent overwriting.
# update    : 2025/10/13 14:39:05 Monday
#             (U001) When adding a suffix, automatically recognize the file's extension so that adding the suffix does not affect the recognition 
#                   of the file's extension.
# return    : /
# ref       : link url
# --------------------------
use strict;
use warnings;
use File::Copy;
use File::Basename;
use File::Path qw(make_path);
use Getopt::Long;
use Cwd 'abs_path';

# Initialize variables
my $debug = 0;
my $target_dir;
my $position = 'suffix';  # 'prefix' or 'suffix'
my $path_level = 1;       # Level for path component (positive: left to right, negative: right to left)
my $file_pattern = '.';   # Default: match all files
my $help = 0;
my @source_dirs;
my @copy_queue;           # Queue to store all files to copy (source_path, target_path)

# Define compression extensions (sorted by length descending to match longest first)
my @COMPRESSION_EXTS = qw(
  tar.gz tar.bz2 tar.xz tar.Z tar.bz tar.lz4 tar.lzma
  gz bz2 xz Z bz lz4 lzma zip rar 7z
);

# Define valid file extensions (mainstream languages/tools, sorted by length descending)
my @VALID_EXTS = qw(
  pl tcl rpt list txt py html csv java c cpp cxx cc h hpp hxx
  js jsx ts tsx php php7 rb ruby go rust swift kotlin scala
  json xml yaml yml ini conf sh bash ksh zsh sql md markdown
  pdf doc docx xls xlsx ppt pptx odt ods odp
  exe dll so a jar war ear class
);

# Parse command line options with short formats
GetOptions(
  'debug|d' => \$debug,
  'target|t=s' => \$target_dir,
  'position|p=s' => \$position,
  'level|l=i' => \$path_level,
  'pattern|r=s' => \$file_pattern,
  'help|h' => \$help,
) or die "Error in command line arguments. Use --help or -h for usage information.\n";

# Display help and exit if requested
if ($help) {
  print_help();
  exit 0;
}

# Validate required parameters
unless (defined $target_dir) {
  die "Error: Target directory is required.\n" .
      "Use --help or -h for usage information.\n";
}

@source_dirs = @ARGV;
unless (@source_dirs) {
  die "Error: At least one source directory is required.\n" .
      "Use --help or -h for usage information.\n";
}

# Validate position parameter with short forms
if ($position =~ /^p(refix)?$/) {
  $position = 'prefix';
} elsif ($position =~ /^s(uffix)?$/) {
  $position = 'suffix';
} else {
  die "Error: Invalid position value: '$position'.\n" .
      "Must be 'prefix' (or 'p') or 'suffix' (or 's').\n" .
      "Use --help or -h for usage information.\n";
}

# Validate regular expression
eval { qr/$file_pattern/ };
if ($@) {
  die "Error: Invalid regular expression pattern: '$file_pattern'\n" .
      "Details: $@" .
      "Use --help or -h for usage information.\n";
}

# Validate level parameter (can't be zero)
if ($path_level == 0) {
  die "Error: Level cannot be zero.\n" .
      "Please use positive values (left to right traversal) or negative values (right to left traversal).\n" .
      "Use --help or -h for usage information.\n";
}

# Validate and prepare target directory
if (-e $target_dir && !-d $target_dir) {
  die "Error: Target path '$target_dir' exists but is not a directory.\n" .
      "Please choose a different target path or remove the existing file.\n";
}

if (-d $target_dir) {
  debug_print("Target directory exists: $target_dir");
  
  # Check if target directory is writable
  unless (-w $target_dir) {
    die "Error: Target directory '$target_dir' is not writable.\n" .
        "Possible reasons: Insufficient permissions, directory is read-only.\n" .
        "Solution: Check directory permissions with 'ls -ld $target_dir' and adjust if necessary.\n";
  }
} else {
  debug_print("Target directory does not exist, creating: $target_dir");
  eval {
    make_path($target_dir, { error => \my $err });
    if (@$err) {
      my @errors;
      for my $e (@$err) {
        my ($file, $message) = %$e;
        push @errors, "$file: $message";
      }
      die "Error creating target directory: " . join('; ', @errors) . "\n";
    }
  };
  if ($@) {
    die "Error: Failed to create target directory '$target_dir'\n" .
        "Details: $@" .
        "Possible reasons: Parent directory doesn't exist, insufficient permissions.\n" .
        "Solution: Check if parent directory exists and you have write permissions there.\n";
  }
}

# --------------------------
# Step 1: Scan all source directories and collect files to copy
# --------------------------
debug_print("\n=== Starting directory scan ===");
foreach my $source_dir (@source_dirs) {
  # Validate source directory exists
  unless (-e $source_dir) {
    warn "Warning: Source path '$source_dir' does not exist - skipping.\n" .
         "Check if the path is correct and the directory exists.\n";
    next;
  }
  
  # Validate it's a directory
  unless (-d $source_dir) {
    warn "Warning: Source path '$source_dir' is not a directory - skipping.\n" .
         "The script only processes directories, not individual files.\n";
    next;
  }
  
  # Check if directory is readable and executable
  unless (-r $source_dir && -x $source_dir) {
    warn "Warning: Source directory '$source_dir' is not accessible (read/exec permissions required) - skipping.\n" .
         "Solution: Check permissions with 'ls -ld $source_dir' and adjust if necessary.\n";
    next;
  }
  
  debug_print("\nScanning source directory: $source_dir");
  
  # Open directory and get matching files
  opendir(my $dh, $source_dir) or do {
    warn "Warning: Failed to open directory '$source_dir': $! - skipping.\n" .
         "Possible reasons: Permissions changed after initial check, directory was removed.\n";
    next;
  };
  
  # Filter files: not hidden, is regular file, matches pattern
  my @files = grep { 
    !/^\./ && 
    -f "$source_dir/$_" && 
    /$file_pattern/ 
  } readdir($dh);
  closedir($dh);
  
  my $file_count = scalar(@files);
  debug_print("Found $file_count matching files in $source_dir");
  
  next if $file_count == 0;
  
  # Process each file (collect to queue, no copy yet)
  foreach my $file (@files) {
    my $source_path = "$source_dir/$file";
    debug_print("\nProcessing file (queueing): $source_path");
    
    # Get path component for naming
    my $path_component = get_path_component($source_dir, $path_level);
    unless (defined $path_component) {
      warn "Warning: Could not extract path component from '$source_dir' with level $path_level - skipping file '$file'\n" .
           "Possible reasons: Level is larger than number of path components.\n" .
           "Solution: Use a smaller level number or check the source directory path.\n";
      next;
    }
    debug_print("Using path component for naming: $path_component");
    
    # Parse filename into parts (base, valid_ext, compression_ext)
    my ($base_name, $valid_ext, $compression_ext) = parse_filename($file);
    debug_print(sprintf(
      "Parsed filename: base='%s', valid_ext='%s', compression_ext='%s'",
      $base_name, $valid_ext // '', $compression_ext // ''
    ));
    
    # Build target filename
    my $target_file;
    if ($position eq 'prefix') {
      # Prefix: path_component + _ + base + valid_ext + compression_ext
      $target_file = $path_component . '_' . $base_name;
      $target_file .= $valid_ext if defined $valid_ext;
      $target_file .= $compression_ext if defined $compression_ext;
    } else {
      # Suffix: base + _ + path_component + valid_ext + compression_ext
      $target_file = $base_name . '_' . $path_component;
      $target_file .= $valid_ext if defined $valid_ext;
      $target_file .= $compression_ext if defined $compression_ext;
    }
    
    my $target_path = "$target_dir/$target_file";
    debug_print("Queued for copy: $source_path -> $target_path");
    
    # Check if target file already exists (prevent overwriting)
    if (-e $target_path) {
      warn "Warning: Target file '$target_path' already exists - skipping to avoid overwriting.\n" .
           "Solution: Remove the existing file or use a different level/position to generate unique filenames.\n";
      next;
    }
    
    # Add to copy queue
    push @copy_queue, {
      source => $source_path,
      target => $target_path
    };
  }
}

# --------------------------
# Step 2: Execute copy for all queued files
# --------------------------
my $queue_size = scalar(@copy_queue);
debug_print("\n=== Starting copy process ===");
debug_print("Total files to copy: $queue_size");

if ($queue_size == 0) {
  print "No files to copy. Exiting.\n";
  exit 0;
}

# Check target directory writability one last time before copy
unless (-w $target_dir) {
  die "Error: Target directory '$target_dir' is not writable - cannot proceed with copy.\n" .
      "Possible reasons: Permissions changed during directory scan.\n" .
      "Solution: Check directory permissions and re-run the script.\n";
}

# Process copy queue
foreach my $item (@copy_queue) {
  my $source = $item->{source};
  my $target = $item->{target};
  
  debug_print("\nCopying file: $source -> $target");
  
  # Final check for source file readability
  unless (-r $source) {
    warn "Warning: Source file '$source' is no longer readable - skipping.\n" .
         "Possible reasons: File was deleted or permissions changed after scan.\n";
    next;
  }
  
  # Copy the file
  my $success = copy($source, $target);
  if ($success) {
    print "Copied: $source -> $target\n";
  } else {
    warn "Warning: Failed to copy '$source' to '$target': $!\n" .
         "Possible reasons: File is locked, insufficient disk space, or permission issues.\n" .
         "Solution: Check if the file is in use, verify disk space, and check permissions.\n";
  }
}

debug_print("\n=== Copy process completed ===");

# --------------------------
# Subroutines
# --------------------------

# Extract specified level component from path
sub get_path_component {
  my ($path, $level) = @_;
  
  # Normalize path: resolve relative paths and remove trailing slashes
  my $normalized;
  eval {
    $normalized = abs_path($path);
  };
  if ($@ || !defined $normalized) {
    debug_print("Failed to normalize path: $path. Error: $@");
    return undef;
  }
  
  $normalized =~ s/\/+$//;  # Remove trailing slashes
  
  debug_print("Normalized path: $normalized");
  
  # Split into components and filter out empty strings
  my @components = grep { length $_ } split(/\//, $normalized);
  
  # Handle root path case (unlikely for source directories)
  unless (@components) {
    debug_print("Path is root directory, no components available");
    return undef;
  }
  
  # Validate level against component count
  my $abs_level = abs($level);
  if ($abs_level > scalar(@components)) {
    debug_print("Level $level exceeds number of path components (" . scalar(@components) . ") in $path");
    return undef;
  }
  
  # Get correct index based on level sign
  my $index;
  if ($level > 0) {
    $index = $level - 1;  # Convert to 0-based index (left to right)
  } else {
    $index = $level;  # Negative index (right to left)
  }
  
  debug_print("Path components: " . join(', ', @components) . " (index: $index)");
  return $components[$index];
}

# Parse filename into base name, valid extension, and compression extension
sub parse_filename {
  my ($filename) = @_;
  my $original = $filename;
  my ($compression_ext, $valid_ext, $base_name) = (undef, undef, $filename);
  
  # Step 1: Remove compression extensions (longest match first)
  foreach my $ext (@COMPRESSION_EXTS) {
    if ($filename =~ /\.(\Q$ext\E)$/i) {
      $compression_ext = '.' . lc($ext);  # Preserve lowercase for consistency
      $filename =~ s/\.\Q$ext\E$//i;
      debug_print("Extracted compression extension: $compression_ext (remaining: $filename)");
      last;  # Stop after first match (longest extension)
    }
  }
  
  # Step 2: Check for valid extension (longest match first)
  foreach my $ext (@VALID_EXTS) {
    if ($filename =~ /\.(\Q$ext\E)$/i) {
      $valid_ext = '.' . lc($ext);  # Preserve lowercase for consistency
      $base_name = $filename;
      $base_name =~ s/\.\Q$ext\E$//i;
      debug_print("Extracted valid extension: $valid_ext (base name: $base_name)");
      last;  # Stop after first match (longest extension)
    }
  }
  
  # If no valid extension found, base name remains the processed filename
  if (!defined $valid_ext) {
    $base_name = $filename;
    debug_print("No valid extension found for '$original' (base name: $base_name)");
  }
  
  return ($base_name, $valid_ext, $compression_ext);
}

# Debug printing function
sub debug_print {
  my ($message) = @_;
  print "DEBUG: $message\n" if $debug;
}

# Help documentation
sub print_help {
  my $script_name = basename($0);
  print <<"HELP";
Usage: $script_name [OPTIONS] SOURCE_DIRS...

Description:
  Scans multiple source directories first to collect all matching files, then copies them
  to a single target directory. Adds a path component as prefix/suffix to filenames (before
  valid extension, ignoring compression extensions) to prevent overwriting.

Options:
  --target|-t DIR       Required. Target directory where files will be copied.
                        Creates the directory if it doesn't exist.
  
  --position|-p POS     Optional. Whether to use path component as prefix or suffix.
                        Values: 'prefix'/'p' (prefix), 'suffix'/'s' (suffix, default).
  
  --level|-l NUM        Optional. Which level of source directory path to use for naming:
                        - Positive NUM: Count from left (1-based, e.g., 2 = second component)
                        - Negative NUM: Count from right (1-based, e.g., -1 = last component)
                        Cannot be zero. Default: 1.
  
  --pattern|-r REGEX    Optional. Regular expression to filter files for copying.
                        Default: '.' (matches all non-hidden files).
  
  --debug|-d            Optional. Enable debug mode (shows detailed scanning/copying info).
  
  --help|-h             Optional. Display this help message and exit.

Key Features:
  1. Filename Handling Rules:
     - Ignores compression extensions (e.g., .gz, .tar.gz) when adding suffix/prefix
     - Adds suffix/prefix before valid extension (e.g., .tcl, .py)
     - Preserves original compression/valid extensions
  
  2. Supported Extensions:
     - Compression: tar.gz, tar.bz2, tar.xz, gz, bz2, xz, zip, rar, 7z, etc.
     - Valid (programming/docs): pl, tcl, rpt, list, txt, py, html, csv, java, c, cpp,
       js, ts, php, rb, go, rust, swift, kotlin, sql, md, pdf, docx, xlsx, etc.

Usage Examples:
  1. Basic copy (all files, last path component as suffix):
     $script_name -t ./output /data/logs/2023 /data/logs/2024
     # Copies /data/logs/2023/file.txt → ./output/file_2023.txt
     # Copies /data/logs/2024/report.pdf → ./output/report_2024.pdf

  2. Copy .tcl files with prefix (2nd path component from left):
     $script_name -t ./tcl_scripts -p p -l 2 -r '\\.tcl$' /home/user/projects/projA /home/user/projects/projB
     # Copies /home/user/projects/projA/code.tcl → ./tcl_scripts/projects_code.tcl
     # Copies /home/user/projects/projB/utils.tcl → ./tcl_scripts/projects_utils.tcl

  3. Copy compressed .txt.gz files (ignore .gz, add suffix before .txt):
     $script_name -t ./backup -l -2 -r '\\.txt\\.gz$' /archive/old/2023
     # Path: /archive/old/2023/data.txt.gz → level -2 = 'old'
     # Copies to ./backup/data_old.txt.gz

  4. Debug mode (see scanning/copying details):
     $script_name -d -t ./test -p s -l -1 ./docs ./src
     # Shows debug info for each file scanned and copied

HELP
}

exit 0;
