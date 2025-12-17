#!/usr/bin/perl
use strict;
use warnings;
use File::Find;
use Getopt::Long qw(:config bundling no_ignore_case auto_abbrev);  # Add Getopt config to fix parameter parsing
use Cwd qw(abs_path realpath);
use File::Basename qw(basename dirname);

# Global configuration and data storage (follow tree's default values)
my $show_hidden = 0;          # Default: do not show hidden files (tree's -a off)
my $target_dir = '.';         # Default target directory: current dir (tree's default)
my $debug_mode = 0;           # Custom: debug mode (--debug)
my $max_level = 0;            # Default: unlimited depth (tree's -L 0 off)
my $follow_symlink = 0;       # Default: do not follow symlinks (tree's -l off)
my $dirs_only = 0;            # -d/--dirs-only: only show directories (no files)
my $root_dir;                 # Normalized absolute root directory path
my $root_realpath;            # Canonical real path of root (resolve symlinks)
my %visited_realpaths;        # Track canonical paths to avoid infinite loops
# Optimized tree data structure: key=dir path, value={ dirs => [], files => [] }
my %tree_data;                # Store tree structure: dir -> subdirs + files

# Parse command line options (follow tree's long/short option naming strictly)
my $options_ok = GetOptions(
  'a'             => \$show_hidden,  # -a (--all): show hidden files
  'all'           => \$show_hidden,
  'L=i'           => \$max_level,    # -L N (--level=N): max traversal depth
  'level=i'       => \$max_level,
  'l'             => \$follow_symlink,# -l (--follow): follow symbolic links
  'follow'        => \$follow_symlink,
  'd'             => \$dirs_only,    # -d/--dirs-only: only show directories
  'dirs-only'     => \$dirs_only,
  'debug'         => \$debug_mode,   # --debug: enable debug mode
  'h'             => \&print_help,    # -h (--help): show help message
  'help'          => \&print_help,
);
# Force help print if options parsing failed (more robust)
print_help(1) unless $options_ok;

# Handle tree's positional directory argument (tree [options] [dir])
# Ensure target_dir is set to the first positional arg (or default to .)
# Fix: Only shift if @ARGV has elements (avoids misinterpreting option params as dir)
$target_dir = shift @ARGV if @ARGV;
# Fallback to default if target_dir is not set (defensive check)
$target_dir = '.' unless defined $target_dir;

# Validate and normalize the target directory
unless (-e $target_dir) {
  die "Error: Directory '$target_dir' does not exist!\n";
}
unless (-d $target_dir) {
  die "Error: '$target_dir' is not a valid directory!\n";
}

# Get absolute path and canonical real path (resolve symlinks)
$root_dir = abs_path($target_dir);
$root_dir =~ s/\/$// if $root_dir ne '/';
$root_realpath = eval { realpath($root_dir) } || $root_dir;
$root_realpath =~ s/\/$// if $root_realpath ne '/';

# Check read/execute permission
unless (-r $root_dir && -x $root_dir) {
  die "Error: No read/execute permission for directory '$root_dir'!\n";
}

# Output initial debug information (sync with latest changes)
debug_print("Root directory (absolute): $root_dir");
debug_print("Root directory (canonical real path): $root_realpath");
debug_print("Configuration: show_hidden=$show_hidden, max_level=$max_level, follow_symlink=$follow_symlink, dirs_only=$dirs_only");

# Configure File::Find for directory traversal (simplified)
my %find_opts = (
  wanted      => \&process_entry,
  preprocess  => \&filter_entries,
  no_chdir    => 1,
);
if ($follow_symlink) {
  $find_opts{follow} = 1;
  $find_opts{follow_skip} = 2;
}

# Initialize root directory in tree data (ensure root is in the tree)
$tree_data{$root_dir} = { dirs => [], files => [] };

# Start recursive directory traversal
find(\%find_opts, $root_dir);

# Print root directory and generate tree structure
print "$root_dir\n";
# Fix: Pass root depth as 0 (align with depth calculation in process_entry)
generate_tree($root_dir, '', 0);

# Calculate and print total counts
my ($dir_count, $file_count) = count_total();
# Adjust output based on dirs_only
if ($dirs_only) {
  print "\n$dir_count directories\n";
} else {
  print "\n$dir_count directories, $file_count files\n";
}

# -------------------------- Subroutines --------------------------

# Print help message (rich with option explanations and examples)
sub print_help {
  my ($is_error) = @_;
  my $script_name = basename($0);
  my $help_text = <<"HELP";
Usage: $script_name [OPTIONS] [DIRECTORY]

Description:
  A Perl implementation of the 'tree' command, which recursively lists the contents of a directory
  in a tree-like format, with support for common tree options and custom debug mode.

Options:
  -a, --all          Show hidden files and directories (files starting with '.').
                     Default: Disabled (only show non-hidden entries).
  -L N, --level=N    Set the maximum depth of the directory traversal (N is a non-negative integer).
                     Default: 0 (unlimited depth, traverse all levels).
                     Note: N=0 means no limit, N=1 means only root directory, N=2 means root + 1 level subdirs, etc.
  -l, --follow       Follow symbolic links as if they were regular directories/files.
                     Default: Disabled (do not follow symlinks).
  -d, --dirs-only    Only show directories (suppress file output).
                     Default: Disabled (show both directories and files).
  --debug            Enable debug mode to show detailed processing information (with timestamps).
                     Default: Disabled.
  -h, --help         Show this help message and exit.

Examples:
  1. Basic usage (list current directory in tree format):
     $script_name

  2. List /home/user directory with hidden files and max depth of 2:
     $script_name -a -L 2 /home/user

  3. List only directories in /var, follow symlinks, and enable debug mode:
     $script_name -d -l --debug /var

  4. Limit traversal to 1 level (only root directory) in current path:
     $script_name -L 1
HELP
  if ($is_error) {
    print STDERR $help_text;
    exit 1;
  } else {
    print $help_text;
    exit 0;
  }
}

# Debug print function (sync with latest processing steps)
sub debug_print {
  my ($message) = @_;
  if ($debug_mode) {
    my $timestamp = localtime();
    print "[DEBUG] $timestamp - $message\n";
  }
}

# Process each file/directory entry (rewritten: simple collect + filter + store)
sub process_entry {
  my $full_path = $File::Find::name;
  my $parent_dir = $File::Find::dir;

  # Skip root directory (already initialized) to avoid duplicate processing
  return if $full_path eq $root_dir;

  # Step 1: Resolve canonical real path (core anti-infinite loop)
  my $real_path = eval { realpath($full_path) } || $full_path;
  $real_path =~ s/\/$// if $real_path ne '/';
  debug_print("Processing entry: $full_path (canonical: $real_path)");

  # Step 2: Filter 1 - Skip if canonical path is already visited
  if (exists $visited_realpaths{$real_path}) {
    debug_print("Skip: $full_path (canonical path already visited)");
    return;
  }
  $visited_realpaths{$real_path} = 1;

  # Step 3: Calculate current depth (relative to root: root = 0, subdir = 1, etc.)
  my @root_parts = grep { length } split(/\//, $root_realpath);
  my @real_parts = grep { length } split(/\//, $real_path);
  my $current_depth = scalar(@real_parts) - scalar(@root_parts);
  debug_print("Entry depth: $current_depth (root depth: " . scalar(@root_parts) . ")");

  # Step 4: Filter 2 - Skip if exceeding max level (0 = unlimited)
  # Fix: Max level check uses current_depth (root=0) to align with tree's behavior
  if ($max_level > 0 && $current_depth > $max_level) {
    debug_print("Skip: $full_path (exceeds max level $max_level)");
    return;
  }

  # Step 5: Filter 3 - Skip hidden entries unless --all is enabled
  my $entry_name = basename($full_path);
  unless ($show_hidden) {
    if ($entry_name =~ /^\./) {
      debug_print("Skip: $full_path (hidden entry, --all is disabled)");
      return;
    }
  }

  # Step 6: Classify entry as directory or file and store in tree data
  if (-d $full_path) {
    # Add to parent's dirs list (ensure parent exists in tree data)
    $tree_data{$parent_dir} ||= { dirs => [], files => [] };
    push @{$tree_data{$parent_dir}->{dirs}}, $full_path;
    # Initialize current dir in tree data (for its children)
    $tree_data{$full_path} ||= { dirs => [], files => [] };
    debug_print("Add directory: $full_path (parent: $parent_dir)");
  } else {
    # Skip files if dirs_only is enabled
    if ($dirs_only) {
      debug_print("Skip: $full_path (dirs_only enabled, suppress files)");
      return;
    }
    # Add to parent's files list
    $tree_data{$parent_dir} ||= { dirs => [], files => [] };
    push @{$tree_data{$parent_dir}->{files}}, $full_path;
    debug_print("Add file: $full_path (parent: $parent_dir)");
  }
}

# Filter entries before processing (sort: dirs first, then files; case-insensitive)
sub filter_entries {
  my @entries = @_;
  my $current_dir = $File::Find::dir;
  debug_print("Original entries in $current_dir: " . join(', ', @entries));

  # Sort entries: directories first, then files (case-insensitive alphabetical)
  @entries = sort {
    my $a_path = "$current_dir/$a";
    my $b_path = "$current_dir/$b";
    my $a_is_dir = -d $a_path;
    my $b_is_dir = -d $b_path;
    $a_is_dir <=> $b_is_dir || lc($a) cmp lc($b);
  } @entries;
  debug_print("Sorted entries in $current_dir: " . join(', ', @entries));

  return @entries;
}

# Recursively generate tree structure (adapt to new tree data format + fix level limit)
sub generate_tree {
  my ($current_dir, $prefix, $current_depth) = @_;
  debug_print("Generating tree for $current_dir (depth: $current_depth, prefix: '$prefix')");

  # Return if no children or exceeding max level (align with process_entry's depth)
  return unless exists $tree_data{$current_dir};
  if ($max_level > 0 && $current_depth > $max_level) {
    return;
  }

  # Prepare children: only dirs if dirs_only is enabled, else dirs + files
  my @children;
  if ($dirs_only) {
    @children = @{$tree_data{$current_dir}->{dirs}};
  } else {
    @children = (@{$tree_data{$current_dir}->{dirs}}, @{$tree_data{$current_dir}->{files}});
  }
  my $total_children = scalar(@children);
  my $index = 0;

  foreach my $child (@children) {
    $index++;
    my $is_last = ($index == $total_children);
    my $child_name = basename($child);

    # Add symlink target if it's a symbolic link
    if (-l $child) {
      my $link_target = readlink($child);
      $child_name .= " -> $link_target";
      debug_print("Symlink $child points to $link_target");
    }

    # Print branch symbols (tree style)
    print $prefix;
    print $is_last ? '└── ' : '├── ';
    print "$child_name\n";

    # Recursively process child directories (skip files)
    if (-d $child) {
      # Calculate next depth (current_depth + 1)
      my $new_depth = $current_depth + 1;
      my $new_prefix = $prefix . ($is_last ? '  ' : '│ ');
      generate_tree($child, $new_prefix, $new_depth);
    }
  }
}

# Count total directories and files (traverse tree data + adapt to dirs_only)
sub count_total {
  my ($dir_count, $file_count) = (0, 0);
  foreach my $dir (keys %tree_data) {
    $dir_count++;  # Each key in tree_data is a directory
    unless ($dirs_only) {
      $file_count += scalar(@{$tree_data{$dir}->{files}});
    }
  }
  return ($dir_count, $file_count);
}
