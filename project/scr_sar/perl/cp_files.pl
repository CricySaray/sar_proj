#!/usr/bin/perl
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

# Process each source directory
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
  
  # Check if directory is readable
  unless (-r $source_dir) {
    warn "Warning: Source directory '$source_dir' is not readable - skipping.\n" .
         "Possible reasons: Insufficient permissions.\n" .
         "Solution: Check permissions with 'ls -ld $source_dir' and adjust if necessary.\n";
    next;
  }
  
  # Check if directory is executable (needed to list contents)
  unless (-x $source_dir) {
    warn "Warning: Source directory '$source_dir' is not executable - skipping.\n" .
         "This usually means you don't have permission to access its contents.\n" .
         "Solution: Check permissions with 'ls -ld $source_dir' and adjust if necessary.\n";
    next;
  }
  
  debug_print("\nProcessing source directory: $source_dir");
  
  # Get all files in source directory matching pattern
  opendir(my $dh, $source_dir) or do {
    warn "Warning: Failed to open directory '$source_dir': $! - skipping.\n" .
         "Possible reasons: Permissions changed after initial check, directory was removed.\n";
    next;
  };
  
  # Filter files: not hidden, is file, matches pattern
  my @files = grep { 
    !/^\./ && 
    -f "$source_dir/$_" && 
    /$file_pattern/ 
  } readdir($dh);
  closedir($dh);
  
  debug_print("Found " . scalar(@files) . " matching files in $source_dir");
  
  if (!@files) {
    debug_print("No files found matching pattern '$file_pattern' in $source_dir");
    next;
  }
  
  # Process each file
  foreach my $file (@files) {
    my $source_path = "$source_dir/$file";
    debug_print("\nProcessing file: $source_path");
    
    # Check if source file is readable
    unless (-r $source_path) {
      warn "Warning: Source file '$source_path' is not readable - skipping.\n" .
           "Possible reasons: Insufficient permissions.\n" .
           "Solution: Check file permissions with 'ls -l $source_path' and adjust if necessary.\n";
      next;
    }
    
    # Check if it's a regular file (not a special file)
    unless (-f $source_path) {
      warn "Warning: '$source_path' is not a regular file - skipping.\n" .
           "The script only copies regular files, not special files or symlinks.\n";
      next;
    }
    
    # Get path component for naming
    my $path_component = get_path_component($source_dir, $path_level);
    unless (defined $path_component) {
      warn "Warning: Could not extract path component from '$source_dir' with level $path_level - skipping file '$file'\n" .
           "Possible reasons: Level is larger than number of path components.\n" .
           "Solution: Use a smaller level number or check the source directory path.\n";
      next;
    }
    debug_print("Using path component for naming: $path_component");
    
    # Construct target filename with underscore separator
    my $target_file;
    if ($position eq 'prefix') {
      $target_file = "$path_component\_$file";
    } else {
      $target_file = "$file\_$path_component";
    }
    
    my $target_path = "$target_dir/$target_file";
    debug_print("Target path: $target_path");
    
    # Check for existing target file
    if (-e $target_path) {
      warn "Warning: Target file '$target_path' already exists - skipping to avoid overwriting.\n" .
           "Solution: Remove the existing file or use a different level/position to generate unique filenames.\n";
      next;
    }
    
    # Check if we can write to target directory (final check)
    unless (-w $target_dir) {
      warn "Warning: Target directory '$target_dir' is no longer writable - skipping remaining files in '$source_dir'.\n" .
           "Possible reasons: Permissions changed during script execution.\n" .
           "Solution: Check directory permissions and re-run the script.\n";
      last;  # Skip remaining files in this directory
    }
    
    # Copy the file
    my $success = copy($source_path, $target_path);
    if ($success) {
      print "Copied: $source_path -> $target_path\n";
    } else {
      warn "Warning: Failed to copy '$source_path' to '$target_path': $!\n" .
           "Possible reasons: File is locked, insufficient disk space, or permission issues.\n" .
           "Solution: Check if the file is in use, verify disk space, and check permissions.\n";
    }
  }
}

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
  Copies files from multiple source directories to a single target directory,
  adding a path component as prefix or suffix to filenames to prevent overwriting.

Options:
  --target|-t DIR       Specifies the target directory where files will be copied.
                        This option is required.
  
  --position|-p POS     Specifies whether to use the path component as prefix or suffix.
                        Possible values:
                          'prefix' or 'p' - Use path component as prefix
                          'suffix' or 's' - Use path component as suffix (default)
  
  --level|-l NUM        Specifies which level of the source directory path to use
                        for the prefix/suffix:
                          Positive numbers: Count from left to right (1-based)
                          Negative numbers: Count from right to left (1-based)
                        Cannot be zero. Default value: 1
  
  --pattern|-r REGEX    Regular expression to match files that should be copied.
                        Default: '.' (matches all files)
  
  --debug|-d            Enable debug mode, showing detailed processing information.
  
  --help|-h             Display this help message and exit.

Path Component Examples:
  For absolute path: /home/user/documents/reports/
    Level 1  → "home" (first component from left)
    Level 3  → "documents" (third component from left)
    Level -1 → "reports" (last component)
    Level -2 → "documents" (second from last)
  
  For relative path: ./projects/2023/july/
    Level 1  → "projects" (first component from left)
    Level 3  → "july" (third component from left)
    Level -1 → "july" (last component)
    Level -3 → "projects" (third from last)

Usage Examples:
  1. Basic usage - copy all files from two directories to 'output' directory,
     using the last component of each source directory as suffix:
     $script_name -t output /data/source1 /data/source2
  
  2. Copy only .txt files, using the first component as prefix:
     $script_name -t output -p p -r '\\.txt$' /data/2023/reports /data/2024/reports
  
  3. Copy .jpg files, using the second component from left as suffix:
     $script_name -t images -l 2 -r '\\.jpg$' ./photos/summer ./photos/winter
  
  4. Debug mode - see detailed processing information:
     $script_name -d -t backup -p suffix -l -2 /docs/important /docs/personal

  5. combined with 'find'
     find /path/to/source/dirs/ -type d -name 'dir_regexp_need_matched' -exec perl $script_name -t ./ -l -1 -p p -r 'regexp_need_match' {} +

HELP
}

exit 0;

