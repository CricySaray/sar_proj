#!/usr/bin/perl
# --------------------------
# author    : sar song
# date      : 2025/10/27 23:58:07 Monday
# label     : 
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : This Perl script recursively searches for a specified regex pattern in files referenced by user-defined prefix words 
#							(default: '-s', 'source'). It handles relative paths, avoids infinite loops, and reports matches with filenames and 
#							line numbers, with options for case insensitivity and debug output.
# return    : /
# ref       : link url
# --------------------------
use strict;
use warnings;
use Getopt::Long;
use File::Spec;

# Configuration variables - modify these defaults as needed
my $input_file     = undef;       # Required: Initial file to process (no default)
my @prefix_words   = ('-s', 'source');  # Default prefix words to identify file references
my $search_pattern = undef;       # Required: Regex pattern to search (no default)
my $ignore_case    = 0;           # Default: Case-sensitive search
my $debug          = 0;           # Default: Debug mode disabled
my $help           = 0;           # Default: Help message disabled

# Command line options (override defaults)
GetOptions(
  'file=s'         => \$input_file,
  'f=s'            => \$input_file,
  'prefix=s'       => \@prefix_words,
  'p=s'            => \@prefix_words,
  'pattern=s'      => \$search_pattern,
  'r=s'            => \$search_pattern,
  'ignore-case'    => \$ignore_case,
  'i'              => \$ignore_case,
  'debug'          => \$debug,
  'd'              => \$debug,
  'help'           => \$help,
  'h'              => \$help,
) or die "Error in command line arguments. Use -h for help.\n";

# Print help and exit if requested
if ($help) {
  print <<'HELP';
Usage: $0 [options]

Recursively searches files referenced by one or more prefix words (or all non-empty strings) for a regex pattern.

Required options:
  --file <path>, -f <path>      Initial file to start processing
  --pattern <regex>, -r <regex> Regex pattern to search in files (e.g., '^\.GLOBAL')

Optional options:
  --prefix <word>, -p <word>    Prefix word to identify referenced files (supports special characters like '-s';
                                can be used multiple times for multiple prefixes; default: '-s', 'source')
  --ignore-case, -i             Make search case-insensitive (default: disabled)
  --debug, -d                   Print debugging information during processing (default: disabled)
  --help, -h                    Show this help message

Examples:
1. Use default prefixes: Search for '.GLOBAL' in files referenced by '-s' or 'source' in main.txt
   $0 -f main.txt -r '^\.GLOBAL'

2. Override default prefixes: Search with 'include' and 'require' prefixes
   $0 --file config.txt -p 'include' -p 'require' --pattern 'import'

3. Debug mode with custom prefixes:
   $0 -f project.txt -p 'load' -r 'module' -i -d
HELP
  exit 0;
}

# Check required parameters
die "Missing required arguments! Use -h for help.\n"
  unless defined $input_file && defined $search_pattern;

# Check if initial file exists and is readable
die "Initial file '$input_file' does not exist\n" unless -e $input_file;
die "Initial file '$input_file' exists but is unreadable\n" unless -r $input_file;
die "Initial file '$input_file' is not a regular file\n" unless -f $input_file;

print "Debug mode enabled\n" if $debug;

# Convert to absolute path to handle relative paths correctly
my $abs_initial_file = File::Spec->rel2abs($input_file);
print "Initial file (absolute path): $abs_initial_file\n" if $debug;

# Arrays and hashes for file processing
my @files_to_process = ($abs_initial_file);
my %processed_files;
my %file_sources;  # Track which file referenced each path
$file_sources{$abs_initial_file} = 'command line';  # Initial file comes from CLI

# Recursively collect all related files
print "Starting recursive file collection...\n" if $debug;
while (@files_to_process) {
  my $current_file = shift @files_to_process;
  
  # Skip if already processed
  if (exists $processed_files{$current_file}) {
    print "Skipping already processed file: $current_file\n" if $debug;
    next;
  }
  $processed_files{$current_file} = 1;
  print "Processing file: $current_file (referenced from: $file_sources{$current_file})\n" if $debug;
  
  # Open current file
  open my $fh, '<', $current_file or do {
    my $source = $file_sources{$current_file} // 'unknown source';
    warn "Warning: Cannot open file '$current_file' (referenced from $source): $!\n";
    next;
  };
  
  # Get directory of current file for relative path handling
  my ($vol, $dir, $fname) = File::Spec->splitpath($current_file);
  
  # Determine path matching regex (with multiple prefixes or without)
  my $path_regex;
  if (@prefix_words) {
    # Escape each prefix and join with | for OR matching
    my $prefixes_re = join('|', map { "\Q$_" } @prefix_words);
    $path_regex = qr/($prefixes_re)\s+(\S+)/;  # Any prefix + spaces + path
    print "Using multi-prefix path matching: /($prefixes_re)\\s+(\\S+)/\n" if $debug;
  } else {
    $path_regex = qr/(\S+)/;  # Match any non-empty string as path
    print "Using prefix-less path matching: /(\\S+)/\n" if $debug;
  }
  
  # Search for paths and collect new files
  while (my $line = <$fh>) {
    if ($line =~ $path_regex) {
      my $matched_prefix = @prefix_words ? $1 : undef;  # Only relevant if prefixes are used
      my $new_path = @prefix_words ? $2 : $1;  # Adjust capture group based on prefix mode
      
      # Debug info for matched prefix (if applicable)
      if (@prefix_words && $debug) {
        print "Found path '$new_path' via prefix '$matched_prefix' in $current_file\n";
      } else {
        print "Found potential path '$new_path' in $current_file\n" if $debug;
      }
      
      # Resolve relative paths
      unless (File::Spec->file_name_is_absolute($new_path)) {
        $new_path = File::Spec->catpath($vol, $dir, $new_path);
        print "Resolved relative path to: $new_path\n" if $debug;
      }
      
      # Convert to absolute path
      my $abs_new_path = File::Spec->rel2abs($new_path);
      print "Absolute path: $abs_new_path\n" if $debug;
      
      # Add to processing list if not already processed
      if (!exists $processed_files{$abs_new_path}) {
        push @files_to_process, $abs_new_path;
        $file_sources{$abs_new_path} = $current_file;  # Record reference source
        print "Added to processing list: $abs_new_path (referenced from $current_file)\n" if $debug;
      } else {
        print "Already in processing list: $abs_new_path (referenced from $current_file)\n" if $debug;
      }
    }
  }
  
  close $fh;
}

# Separate valid and invalid files
my (@valid_files, @invalid_files);
print "Checking file validity...\n" if $debug;
foreach my $file (keys %processed_files) {
  my $source = $file_sources{$file} // 'unknown source';
  if (-f $file) {
    if (-r $file) {
      push @valid_files, $file;
      print "Valid readable file: $file (referenced from $source)\n" if $debug;
    } else {
      push @invalid_files, { file => $file, source => $source, reason => 'unreadable' };
      print "Invalid file (unreadable): $file (referenced from $source)\n" if $debug;
    }
  } else {
    push @invalid_files, { file => $file, source => $source, reason => 'non-existent' };
    print "Invalid file (non-existent): $file (referenced from $source)\n" if $debug;
  }
}

# Report invalid files with sources
if (@invalid_files) {
  warn "Warning: The following files are invalid or unreadable:\n";
  foreach my $entry (@invalid_files) {
    my $reason = $entry->{reason} eq 'unreadable' ? 'exists but is unreadable' : 'does not exist';
    warn "  $entry->{file} ($reason, referenced from: $entry->{source})\n";
  }
}

# Prepare regex pattern with case sensitivity option
my $regex = $ignore_case ? qr/$search_pattern/i : qr/$search_pattern/;
print "Using regex pattern: " . ($ignore_case ? "(case-insensitive) $search_pattern" : "$search_pattern") . "\n" if $debug;

# Search through valid files and print results
print "Starting content search...\n" if $debug;
foreach my $file (@valid_files) {
  my $source = $file_sources{$file} // 'unknown source';
  open my $fh, '<', $file or do {
    warn "Warning: Unexpected error opening readable file '$file' (referenced from $source): $!\n";
    next;
  };
  
  my $line_number = 0;
  while (my $line = <$fh>) {
    $line_number++;
    if ($line =~ $regex) {
      chomp $line;
      print "$file:$line_number: $line\n";
    }
  }
  
  close $fh;
}

print "Processing complete\n" if $debug;
exit 0;
