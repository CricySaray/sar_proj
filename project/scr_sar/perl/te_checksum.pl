#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Find;
use File::Basename;
use File::Spec;

# Default configuration
my $DEFAULT_SUM_COMMAND = 'md5sum';
my $DEFAULT_OUTPUT_FILE = 'checksums.txt';
my $DEFAULT_FORMAT      = 'tree,full';
my $DEFAULT_DEBUG       = 0;
my $DEFAULT_INCLUDE_HIDDEN = 0;

# Initialize variables
my ($sum_command, $output_file, $format, $debug, $help, $include_hidden);
my @sources;  # Populated from command line arguments
($sum_command, $output_file, $format, $debug, $help, $include_hidden) = 
  ($DEFAULT_SUM_COMMAND, $DEFAULT_OUTPUT_FILE, $DEFAULT_FORMAT, $DEFAULT_DEBUG, 0, $DEFAULT_INCLUDE_HIDDEN);

# Parse command line options
GetOptions(
  'sum-command=s' => \$sum_command,
  'output=s'      => \$output_file,
  'format=s'      => \$format,
  'debug'         => \$debug,
  'help'          => \$help,
  'include-hidden' => \$include_hidden,
  # Short options
  'c=s'           => \$sum_command,
  'o=s'           => \$output_file,
  'f=s'           => \$format,
  'd'             => \$debug,
  'h'             => \$help,
  'i'             => \$include_hidden,
) or die "Error in command line arguments. Use -h for help.\n";

# Populate sources from remaining command line arguments
@sources = @ARGV;

# Display help
if ($help) {
  print_help();
  exit 0;
}

# Validate sources
unless (@sources) {
  die "No source paths specified. Provide files/directories as arguments. Use -h for help.\n";
}
foreach my $src (@sources) {
  unless (-e $src) {
    die "Source path '$src' does not exist.\n";
  }
}

# Validate sum command
unless ($sum_command eq 'md5sum' || $sum_command eq 'cksum') {
  die "Invalid sum command: $sum_command. Must be 'md5sum' or 'cksum'.\n";
}

# Validate format
my @formats = split(/,/, $format);
foreach my $f (@formats) {
  unless ($f eq 'tree' || $f eq 'full') {
    die "Invalid format: $f. Must be 'tree' or 'full'.\n";
  }
}

# Debug info
if ($debug) {
  print "Debug mode enabled\n";
  print "Sum command: $sum_command\n";
  print "Output file: $output_file\n";
  print "Formats: " . join(', ', @formats) . "\n";
  print "Include hidden: " . ($include_hidden ? "Yes" : "No") . "\n";
  print "Sources: " . join(', ', @sources) . "\n";
}

# Preprocess sources: separate files and dirs
my (@source_files, @source_dirs, %source_dirs_abs);
foreach my $src (@sources) {
  my $abs_path = File::Spec->rel2abs($src);
  my $name = basename($src);
  
  # Skip hidden sources if flag is off
  if (!$include_hidden && $name =~ /^\./) {
    warn "Skipping hidden source: $src (use -i to include)\n" if $debug;
    next;
  }
  
  my $info = {
    original => $src,
    absolute => $abs_path,
    rel_path => $src
  };
  
  if (-f $abs_path) {
    push @source_files, $info;
  } elsif (-d $abs_path) {
    push @source_dirs, $info;
    $source_dirs_abs{$abs_path} = 1;
  } else {
    warn "Skipping $src: not file/directory\n" if $debug;
  }
}

# Sort sources by ASCII order
@source_files = sort { $a->{original} cmp $b->{original} } @source_files;
@source_dirs = sort { $a->{original} cmp $b->{original} } @source_dirs;

# Data structures for processing
my %file_info;        # Key: abs path, Value: {sum_info, rel_path, is_source_file}
my %dir_tree;         # Directory structure data
my ($total_dirs, $total_files, $source_files_count) = (0, 0, 0);

# Process source files first
foreach my $file_info (@source_files) {
  my $abs_path = $file_info->{absolute};
  my $rel_path = $file_info->{rel_path};
  my $name = basename($abs_path);
  
  if (!$include_hidden && $name =~ /^\./) {
    warn "Skipping hidden source file: $rel_path\n" if $debug;
    next;
  }
  
  process_file($abs_path, $rel_path, 1);
}

# Process directories
foreach my $dir_info (@source_dirs) {
  my $path = $dir_info->{absolute};
  my $orig_path = $dir_info->{original};
  
  find({ wanted => sub {
    my $current_path = $File::Find::name;
    my $name = basename($current_path);
    my $rel_path = get_relative_path($current_path, $orig_path, $path);
    
    # Skip hidden items if flag is off
    if (!$include_hidden && $name =~ /^\./) {
      warn "Skipping hidden item: $rel_path\n" if $debug;
      $File::Find::prune = 1 if -d $current_path;
      return;
    }
    
    if (-d $current_path) {
      add_dir_to_tree($current_path, $rel_path, $dir_info);
    } elsif (-f $current_path) {
      process_file($current_path, $rel_path, 0);
    }
  }, no_chdir => 1 }, $path);
  
  add_dir_to_tree($path, $orig_path, $dir_info);
}

# Calculate directory statistics
calculate_dir_statistics();

# Generate output
open(my $out_fh, '>', $output_file) or die "Cannot open $output_file: $!";

foreach my $f (@formats) {
  if ($f eq 'full') {
    print $out_fh "=== Full Path Format ===\n" if @formats > 1;
    print_full_format($out_fh, \%file_info, \@source_dirs);
    print $out_fh "\n" if @formats > 1;
  } elsif ($f eq 'tree') {
    print $out_fh "=== Tree Format ===\n" if @formats > 1;
    print_tree_format($out_fh, \%dir_tree, \@source_files, \@source_dirs);
    print $out_fh "\n" if @formats > 1;
  }
}

close($out_fh);

print "Results written to $output_file\n" unless $debug;

# Calculate relative path
sub get_relative_path {
  my ($abs_path, $orig_dir, $abs_dir) = @_;
  
  if ($abs_path =~ /^$abs_dir/) {
    my $rel_part = substr($abs_path, length($abs_dir));
    $rel_part =~ s{^/}{} if $rel_part;
    return $rel_part ? "$orig_dir/$rel_part" : $orig_dir;
  }
  
  warn "Warning: No path match for $abs_path\n" if $debug;
  return $abs_path;
}

# Process a single file
sub process_file {
  my ($abs_path, $rel_path, $is_source_file) = @_;
  
  my $sum_info = get_sum_info($abs_path);
  return unless defined $sum_info;
  
  $file_info{$abs_path} = {
    sum_info => $sum_info,
    rel_path => $rel_path,
    is_source_file => $is_source_file
  };
  
  $total_files++;
  $source_files_count++ if $is_source_file;
  
  my $file_name = basename($abs_path);
  my $dir_abs = dirname($abs_path);
  
  $dir_tree{$dir_abs}{files}{$file_name} = {
    sum_info => $sum_info,
    rel_name => $file_name
  } if exists $dir_tree{$dir_abs};
}

# Add directory to tree
sub add_dir_to_tree {
  my ($abs_path, $rel_path, $source_dir_info) = @_;
  
  return if exists $dir_tree{$abs_path}{exists};
  
  my $dir_name = basename($abs_path) || $abs_path;
  my $parent_abs = dirname($abs_path);
  my $parent_rel = dirname($rel_path);
  my $is_source_dir = ($abs_path eq $source_dir_info->{absolute}) ? 1 : 0;
  
  # Count only directories under source dirs
  my $count_dir = 0;
  if ($is_source_dir) {
    $count_dir = 1;
  } else {
    foreach my $src_abs (keys %source_dirs_abs) {
      if ($abs_path =~ /^$src_abs/) {
        $count_dir = 1;
        last;
      }
    }
  }
  
  $dir_tree{$abs_path} = {
    exists        => 1,
    rel_path      => $rel_path,
    dir_name      => $dir_name,
    subdirs       => {},
    files         => {},
    subdir_count  => 0,
    file_count    => 0,
    is_source_dir => $is_source_dir,
    count_dir     => $count_dir
  };
  
  $total_dirs++ if $count_dir;
  
  # Add parent dir recursively
  unless ($parent_abs eq $abs_path) {
    add_dir_to_tree($parent_abs, $parent_rel, $source_dir_info) unless exists $dir_tree{$parent_abs}{exists};
    $dir_tree{$parent_abs}{subdirs}{$dir_name} = $abs_path;
  }
}

# Calculate dir statistics
sub calculate_dir_statistics {
  foreach my $dir_abs (keys %dir_tree) {
    my $dir_data = $dir_tree{$dir_abs};
    $dir_data->{subdir_count} = scalar keys %{$dir_data->{subdirs}};
    $dir_data->{file_count} = scalar keys %{$dir_data->{files}};
  }
}

# Get sum information
sub get_sum_info {
  my ($file) = @_;
  
  my $sum_line;
  if ($sum_command eq 'md5sum') {
    $sum_line = `md5sum "$file" 2>/dev/null`;
  } elsif ($sum_command eq 'cksum') {
    $sum_line = `cksum "$file" 2>/dev/null`;
  }
  
  chomp $sum_line;
  
  if ($? != 0) {
    warn "Error calculating $sum_command for $file\n" if $debug;
    return undef;
  }
  
  return $sum_line;
}

# Print full path format with statistics
sub print_full_format {
  my ($fh, $file_info_ref, $source_dirs_ref) = @_;
  my $has_directories = @$source_dirs_ref > 0;
  
  # Print source files
  my @source_files = sort { $a->{rel_path} cmp $b->{rel_path} }
                     grep { $_->{is_source_file} }
                     values %$file_info_ref;
  
  foreach my $file_data (@source_files) {
    my $sum_line = $file_data->{sum_info};
    my $rel_path = $file_data->{rel_path};
    
    if ($sum_command eq 'md5sum') {
      my ($md5, $original_path) = split(/\s+/, $sum_line, 2);
      print $fh "$md5 $rel_path\n";
    } else {
      my ($checksum, $size, $original_path) = split(/\s+/, $sum_line, 3);
      print $fh "$checksum $size $rel_path\n";
    }
  }
  
  # Source files count
  print $fh "\n$source_files_count source files with checksum\n" if $source_files_count > 0;
  
  # Print directory files
  my @dir_files = sort { $a->{rel_path} cmp $b->{rel_path} }
                  grep { !$_->{is_source_file} }
                  values %$file_info_ref;
  my $dir_files_count = scalar @dir_files;
  
  foreach my $file_data (@dir_files) {
    my $sum_line = $file_data->{sum_info};
    my $rel_path = $file_data->{rel_path};
    
    if ($sum_command eq 'md5sum') {
      my ($md5, $original_path) = split(/\s+/, $sum_line, 2);
      print $fh "$md5 $rel_path\n";
    } else {
      my ($checksum, $size, $original_path) = split(/\s+/, $sum_line, 3);
      print $fh "$checksum $size $rel_path\n";
    }
  }
  
  # Total statistics (always show when there are directories)
  if ($has_directories) {
    print $fh "\nTotal processed: $total_files files, $total_dirs directories\n";
  } elsif ($dir_files_count == 0 && $source_files_count > 0) {
    # Only source files, no directories
    print $fh "\nTotal processed: $total_files files (no directories)\n";
  }
}

# Print tree format with statistics
sub print_tree_format {
  my ($fh, $dir_tree_ref, $source_files_ref, $source_dirs_ref) = @_;
  my $has_directories = @$source_dirs_ref > 0;
  
  # Print source files
  if (@$source_files_ref > 0) {
    print $fh "Source files:\n";
    foreach my $file_info (sort { $a->{original} cmp $b->{original} } @$source_files_ref) {
      my $abs_path = $file_info->{absolute};
      next unless exists $file_info{$abs_path};
      
      my $file_data = $file_info{$abs_path};
      my $sum_line = $file_data->{sum_info};
      my $file_name = basename($file_info->{original});
      
      my $sum_info;
      if ($sum_command eq 'md5sum') {
        ($sum_info) = split(/\s+/, $sum_line, 2);
      } else {
        ($sum_info) = split(/\s+/, $sum_line, 3);
        $sum_info = join(' ', (split(/\s+/, $sum_line, 3))[0,1]);
      }
      
      print $fh "└── $sum_info $file_name\n";
    }
    print $fh "\n$source_files_count source files with checksum\n\n";
  }
  
  # Print directories
  if ($has_directories) {
    print $fh "Directories:\n";
    foreach my $i (0..$#$source_dirs_ref) {
      my $dir_info = $source_dirs_ref->[$i];
      my $root_abs = $dir_info->{absolute};
      my $root_orig = $dir_info->{original};
      my $is_last_root = ($i == $#$source_dirs_ref);
      
      next unless exists $dir_tree_ref->{$root_abs};
      
      my $root_data = $dir_tree_ref->{$root_abs};
      my $root_name = basename($root_orig) || $root_orig;
      print $fh "$root_name/ ($root_data->{subdir_count} subdirs, $root_data->{file_count} files)\n";
      
      print_tree_contents($fh, $dir_tree_ref, $root_abs, '', $is_last_root);
    }
    
    # Total statistics
    print $fh "\nTotal processed: $total_files files, $total_dirs directories\n";
  }
}

# Print directory contents in tree format (recursive)
sub print_tree_contents {
  my ($fh, $dir_tree_ref, $current_abs, $prefix, $is_last_parent) = @_;
  
  return unless exists $dir_tree_ref->{$current_abs};
  
  my $dir_data = $dir_tree_ref->{$current_abs};
  my %subdirs = %{$dir_data->{subdirs}};
  my %files = %{$dir_data->{files}};
  
  # Sort entries: directories first, then files (both ASCII order)
  my @sorted_subdirs = sort { $a cmp $b } keys %subdirs;
  my @sorted_files = sort { $a cmp $b } keys %files;
  my @sorted_entries = (@sorted_subdirs, @sorted_files);
  
  my $entry_count = scalar @sorted_entries;
  my $entry_index = 0;
  
  foreach my $entry (@sorted_entries) {
    $entry_index++;
    my $is_last_entry = ($entry_index == $entry_count);
    
    if (exists $subdirs{$entry}) {
      # It's a subdirectory
      my $subdir_abs = $subdirs{$entry};
      my $subdir_data = $dir_tree_ref->{$subdir_abs};
      
      print $fh $prefix;
      print $fh $is_last_entry ? '└── ' : '├── ';
      print $fh "$entry/ ($subdir_data->{subdir_count} subdirs, $subdir_data->{file_count} files)\n";
      
      # Prepare prefix for subdirectory contents
      my $new_prefix = $prefix . ($is_last_entry ? '    ' : '│   ');
      
      # Recursively print subdirectory contents
      print_tree_contents($fh, $dir_tree_ref, $subdir_abs, $new_prefix, $is_last_entry);
    } else {
      # It's a file
      my $file_data = $files{$entry};
      my $sum_line = $file_data->{sum_info};
      next unless defined $sum_line;
      
      my $sum_info;
      if ($sum_command eq 'md5sum') {
        ($sum_info) = split(/\s+/, $sum_line, 2);
      } else {
        ($sum_info) = split(/\s+/, $sum_line, 3);
        $sum_info = join(' ', (split(/\s+/, $sum_line, 3))[0,1]);
      }
      
      print $fh $prefix;
      print $fh $is_last_entry ? '└── ' : '├── ';
      print $fh "$sum_info $entry\n";
    }
  }
}

# Print help information
sub print_help {
  print <<'HELP';
Usage: checksum_calculator.pl [options] <path1> [<path2> ...]

Calculates MD5 or checksum values for files and directories, outputting results
in tree format, full path format, or both. Both formats show total counts of
processed files and directories when sources include folders.

Options:
  -c, --sum-command   Specify sum command (default: md5sum)
                      Valid values: md5sum, cksum
  
  -o, --output        Output file name (default: checksums.txt)
  
  -f, --format        Output format(s) (default: tree,full)
                      Valid values: tree, full, or tree,full
  
  -i, --include-hidden Include hidden files/directories (default: off)
                      Hidden items start with a dot (.)
  
  -d, --debug         Enable debug mode (default: off)
  
  -h, --help          Display this help message

Examples:
  1. Basic usage with directory statistics
     perl checksum_calculator.pl ./documents/
  
  2. Full format with directory and file counts
     perl checksum_calculator.pl -f full ./project/ -o results.txt
  
  3. Mixed sources with statistics
     perl checksum_calculator.pl ./data/ notes.txt reports/

Special Notes:
  - Both full and tree formats display total counts of processed files and directories
  - Statistics include all files (source files + directory files) and all subdirectories
  - When no directories are processed, only file counts are shown
  - Hidden items are excluded by default (use -i to include them)
  - All items are sorted by ASCII order of their names
HELP
}

