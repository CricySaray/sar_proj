#!/usr/bin/perl
# --------------------------
# author    : sar song
# date      : 2025/10/10 17:15:04 Friday
# label     : perl_task
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : This Perl script archives multiple files and directories (including subdirectories) into a single archive file while 
#             preserving their directory structure. It can also extract the archive to reconstruct the original files and folder 
#             hierarchy exactly as they were. Supports merge mode for extraction to existing directories.
# return    : output file or output dir
# ref       : link url
# --------------------------
use strict;
use warnings;
use File::Find;
use File::Path qw(make_path remove_tree);
use File::Basename;
use File::Spec;
use MIME::Base64;
use Getopt::Long;

# Configuration and variable initialization
my $debug = 1;
my $archive_file = '';  # Default archive file
my @source_paths;                  # Multiple source paths
my $target_dir = './';# Default target directory
my $mode = 'a';                          # 'archive' (or 'a') or 'extract' (or 'e')
my $overwrite = 'merge';            # Overwrite mode: 'none'|'replace'|'merge' (default: 'none')
my $help = 0;                      # Show help?
my $VERSION = '2.1.3';
my $MAGIC_HEADER = "FILE_ARCHIVER_V2";

# Parse command line options with short forms
GetOptions(
  'debug|d' => \$debug,
  'archive|a=s' => \$archive_file,
  'source|s=s' => \@source_paths,  # Allows multiple -s options
  'target|t=s' => \$target_dir,
  'mode|m=s' => \$mode,
  'overwrite|o:s' => \$overwrite,  # Accepts optional value (none/replace/merge)
  'help|h' => \$help,              # Help option with short form
) or die "Error in command line arguments. Use --help for usage information.\n";

# Handle overwrite option defaults and validation
if (!defined $overwrite) {
  # If -o is used without value, set to 'replace' (backward compatibility)
  $overwrite = 'replace';
} elsif ($overwrite eq '') {
  # Handle case where -o is specified with empty value (same as 'replace')
  $overwrite = 'replace';
} else {
  # Validate overwrite mode
  unless ($overwrite =~ /^(none|replace|merge)$/i) {
    die "Invalid overwrite mode '$overwrite'. Valid options: none, replace, merge\n";
  }
  $overwrite = lc($overwrite);  # Normalize to lowercase
}

# Show help and exit if requested
if ($help) {
  print_help();
  exit 0;
}

# Validate and process arguments
validate_arguments();

# Execute appropriate operation based on mode
if ($mode eq 'archive' || $mode eq 'a') {
  debug_print("Starting archiving process... (overwrite mode: $overwrite)");
  archive_paths();
  debug_print("Archiving completed successfully");
} elsif ($mode eq 'extract' || $mode eq 'e') {
  debug_print("Starting extraction process... (overwrite mode: $overwrite)");
  extract_archive();
  debug_print("Extraction completed successfully");
}

# Print help information with dynamic default values
sub print_help {
  # Determine default source paths for display
  my $default_sources = @source_paths ? join(', ', @source_paths) : '.';
  
  print <<"HELP";
Usage: file_archiver.pl [options]

Description:
  A Perl script to archive multiple files and directories into a single archive file,
  and to extract them back to their original structure. Supports both files and 
  directories with recursive processing.

Modes:
  -m, --mode      Operation mode (required):
                  'archive' (or 'a') - Create archive from source paths
                  'extract' (or 'e') - Extract files from archive to target directory

Options by Mode:
  All modes:
    -a, --archive   Archive file path (default: $archive_file)
    -d, --debug     Enable debug output
    -h, --help      Show this help message
    -o, --overwrite Overwrite mode (optional value, default: none):
                    'none'    - Abort if target exists (default)
                    'replace' - Delete and recreate target directory (backward compatible with -o)
                    'merge'   - Preserve existing content, overwrite conflicting files

  Archive mode only:
    -s, --source    Source file/directory path (can specify multiple times)
                    (default: $default_sources)

  Extract mode only:
    -t, --target    Target directory for extraction (default: $target_dir)

Examples:
  Archive current directory to default archive:
    file_archiver.pl -m a
  
  Archive multiple sources with overwrite:
    file_archiver.pl -m archive -s docs/ -s images/ -a backup.dat -o replace
  
  Extract with merging (preserve existing content):
    file_archiver.pl -m e -a backup.dat -t ./ -o merge
  
  Extract with full replacement (delete existing target first):
    file_archiver.pl -m e -a backup.dat -t restore_dir -o
  
  Extract without overwriting (abort if target exists):
    file_archiver.pl -m e -a backup.dat -t restore_dir
HELP
}

# Validate command line arguments
sub validate_arguments {
  # Check mode is specified and valid
  unless (defined $mode && ($mode eq 'archive' || $mode eq 'a' || $mode eq 'extract' || $mode eq 'e')) {
    die "You must specify mode as 'archive' (or 'a') or 'extract' (or 'e') (use -m option)\n";
  }
  unless ($archive_file ne "") {
    die "You must specify option 'archive_file', (now this is empty)!!! \n" 
  }
  
  # Validate archive file
  if ($mode eq 'archive' || $mode eq 'a') {
    # Check if archive exists and overwrite is not enabled
    if (-e $archive_file) {
      if ($overwrite eq 'none') {
        die "Archive file '$archive_file' already exists. Use --overwrite=replace to overwrite.\n";
      } elsif ($overwrite eq 'replace') {
        debug_print("Overwriting existing archive file: $archive_file");
      } elsif ($overwrite eq 'merge') {
        die "Merge mode is not supported for archive creation. Use --overwrite=replace instead.\n";
      }
    }
    
    # Set default source if none provided
    @source_paths = ('.') unless @source_paths;
    
    # Validate all source paths
    foreach my $path (@source_paths) {
      unless (-e $path) {
        die "Source path '$path' does not exist\n";
      }
    }
  } else {
    # For extract mode
    unless (-f $archive_file) {
      die "Archive file '$archive_file' does not exist or is not a file\n";
    }
    
    # Check target directory
    if (-e $target_dir) {
      if ($overwrite eq 'none') {
        die "Target directory '$target_dir' already exists. Use --overwrite=replace or --overwrite=merge\n";
      } elsif ($overwrite eq 'replace') {
        # Remove existing target if replace mode is enabled
        if (-d $target_dir) {
          debug_print("Removing existing target directory (replace mode): $target_dir");
          remove_tree($target_dir) or die "Failed to remove existing target directory '$target_dir': $!\n";
        } else {
          debug_print("Removing existing file with target name (replace mode): $target_dir");
          unlink($target_dir) or die "Failed to remove existing file '$target_dir': $!\n";
        }
      } elsif ($overwrite eq 'merge') {
        # Merge mode: preserve existing content, just verify target is a directory
        unless (-d $target_dir) {
          die "Target '$target_dir' exists but is not a directory. Cannot use merge mode.\n";
        }
        debug_print("Using merge mode - preserving existing content in: $target_dir");
      }
    }
  }
}

# Archive multiple paths
sub archive_paths {
  my @all_files;
  
  # Process each source path
  foreach my $source_path (@source_paths) {
    my $canonical_source = File::Spec->rel2abs($source_path);
    debug_print("Processing source: $canonical_source");
    
    # Check if it's a file or directory
    if (-f $canonical_source) {
      # Handle individual file
      push @all_files, $canonical_source;
      debug_print("Added file: $canonical_source");
    } elsif (-d $canonical_source) {
      # Recursively find all files in directory
      find({ wanted => sub {
        return unless -f $_;  # Only process files
        my $full_path = $File::Find::name;
        push @all_files, $full_path;
        debug_print("Found file: $full_path");
      }, no_chdir => 1 }, $canonical_source);
    } else {
      warn "Warning: '$source_path' is not a regular file or directory - skipping\n";
      next;
    }
  }
  
  # Open archive file
  open my $archive_fh, '>', $archive_file or die "Cannot open archive file '$archive_file' for writing: $!";
  
  # Write magic header
  print $archive_fh "$MAGIC_HEADER\n";
  
  # Write source count and sources
  my $source_count = scalar @source_paths;
  print $archive_fh "SOURCES:$source_count\n";
  foreach my $source (@source_paths) {
    my $rel_source = File::Spec->abs2rel($source);
    print $archive_fh "SOURCE:$rel_source\n";
  }
  
  # Write file count
  my $file_count = scalar @all_files;
  print $archive_fh "FILES:$file_count\n";
  debug_print("Found $file_count files to archive from $source_count sources");
  
  # Process each file
  foreach my $file_path (@all_files) {
    # Get relative path from current working directory
    my $relative_path = File::Spec->abs2rel($file_path);
    
    # Read file content
    open my $file_fh, '<', $file_path or do {
      warn "Warning: Cannot open file '$file_path' for reading: $! - skipping\n";
      next;
    };
    binmode $file_fh;
    local $/;
    my $content = <$file_fh>;
    close $file_fh;
    
    # Calculate content length
    my $content_length = length($content);
    
    # Encode content
    my $encoded_content = encode_base64($content);
    
    # Write file information to archive
    print $archive_fh "FILE_START\n";
    print $archive_fh "PATH:$relative_path\n";
    print $archive_fh "SIZE:$content_length\n";
    print $archive_fh "CONTENT:\n$encoded_content";
    print $archive_fh "FILE_END\n";
    
    debug_print("Archived: $relative_path (size: $content_length bytes)");
  }
  
  close $archive_fh;
}

# Extract from archive
sub extract_archive {
  # Open archive file
  open my $archive_fh, '<', $archive_file or die "Cannot open archive file '$archive_file' for reading: $!";
  
  # Verify magic header
  my $header = <$archive_fh>;
  chomp $header;
  unless ($header eq $MAGIC_HEADER) {
    die "Invalid archive file - incorrect header. Expected '$MAGIC_HEADER', got '$header'\n";
  }
  
  # Read source count (not used in extraction but good to verify)
  my $source_count_line = <$archive_fh>;
  die "Unexpected end of archive while reading source count" unless defined $source_count_line;
  chomp $source_count_line;
  die "Invalid source count line: $source_count_line" unless $source_count_line =~ /^SOURCES:(\d+)$/;
  my $source_count = $1;
  
  # Read and verify source paths (not used in extraction)
  for (my $i = 0; $i < $source_count; $i++) {
    my $source_line = <$archive_fh>;
    die "Unexpected end of archive while reading source $i" unless defined $source_line;
    chomp $source_line;
    die "Invalid source line: $source_line" unless $source_line =~ /^SOURCE:(.*)$/;
    debug_print("Original source: $1");
  }
  
  # Read file count
  my $file_count_line = <$archive_fh>;
  die "Unexpected end of archive while reading file count" unless defined $file_count_line;
  chomp $file_count_line;
  die "Invalid file count line: $file_count_line" unless $file_count_line =~ /^FILES:(\d+)$/;
  my $file_count = $1;
  debug_print("Found $file_count files in archive");
  
  # Create target directory if it doesn't exist
  unless (-d $target_dir) {
    debug_print("Creating target directory: $target_dir");
    make_path($target_dir) or die "Cannot create target directory '$target_dir': $!";
  }
  
  # Process each file
  for (my $i = 0; $i < $file_count; $i++) {
    # Find file start marker
    my $line;
    do {
      $line = <$archive_fh>;
      last unless defined $line;  # End of file
      chomp $line;
    } while ($line ne 'FILE_START');
    
    die "Unexpected end of archive while looking for FILE_START" unless defined $line;
    
    # Read file path
    my $path_line = <$archive_fh>;
    die "Unexpected end of archive while reading path" unless defined $path_line;
    chomp $path_line;
    die "Invalid path line: $path_line" unless $path_line =~ /^PATH:(.*)$/;
    my $relative_path = $1;
    
    # Read file size
    my $size_line = <$archive_fh>;
    die "Unexpected end of archive while reading size" unless defined $size_line;
    chomp $size_line;
    die "Invalid size line: $size_line" unless $size_line =~ /^SIZE:(\d+)$/;
    my $content_length = $1;
    
    # Read content marker
    my $content_line = <$archive_fh>;
    die "Unexpected end of archive while reading content marker" unless defined $content_line;
    chomp $content_line;
    die "Expected CONTENT: marker, got: $content_line" unless $content_line eq 'CONTENT:';
    
    # Read encoded content until FILE_END
    my $encoded_content = '';
    while (my $content_part = <$archive_fh>) {
      chomp $content_part;
      last if $content_part eq 'FILE_END';
      $encoded_content .= "$content_part\n";
    }
    
    # Decode content
    my $content = decode_base64($encoded_content);
    
    # Verify content size
    if (length($content) != $content_length) {
      warn "Warning: Content size mismatch for '$relative_path' - expected $content_length, got " . length($content) . " - skipping\n";
      next;
    }
    
    # Build full path
    my $full_path = File::Spec->catfile($target_dir, $relative_path);
    my $directory = dirname($full_path);
    
    # Create directory if needed
    unless (-d $directory) {
      debug_print("Creating directory: $directory");
      make_path($directory) or do {
        warn "Warning: Cannot create directory '$directory': $! - skipping file '$relative_path'\n";
        next;
      };
    }
    
    # Check if file exists and handle based on overwrite mode
    if (-e $full_path) {
      if ($overwrite eq 'none') {
        warn "Warning: File '$full_path' already exists - skipping (overwrite mode: none)\n";
        next;
      } elsif ($overwrite eq 'replace' || $overwrite eq 'merge') {
        debug_print("Overwriting existing file: $full_path (overwrite mode: $overwrite)");
      }
    }
    
    # Write file
    open my $file_fh, '>', $full_path or do {
      warn "Warning: Cannot open file '$full_path' for writing: $! - skipping\n";
      next;
    };
    binmode $file_fh;
    print $file_fh $content;
    close $file_fh;
    
    debug_print("Extracted: $full_path (size: $content_length bytes)");
  }
  
  close $archive_fh;
}

# Debug print function
sub debug_print {
  my ($message) = @_;
  print "DEBUG: $message\n" if $debug;
}

exit 0;
