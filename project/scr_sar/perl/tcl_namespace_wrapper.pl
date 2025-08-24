#!/usr/bin/perl
# --------------------------
# author    : sar song
# date      : 2025/08/23 18:50:35 Saturday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : This Perl script wraps all procs in a specified TCL file into a user-defined namespace, automatically processes 
#             and removes alias commands, and updates internal proc calls (including both original and alias names) to ensure 
#             code functionality. It also supports optional prefixes/suffixes for proc names (with a toggle to apply them to 
#             aliased names), generates multi-line namespace exports, and produces a properly indented, package-ready TCL output file.
# return    : A TCL output script that has been wrapped in a namespace
# detail info of options: 
#   - `--namespace NAME, -s NAME`   : Specifies the target namespace name to wrap all TCL procedures into. This is a required option. Usage: `--namespace MyNamespace` or `-s MyNamespace`. 
#                                     Note: The namespace name must be a valid TCL identifier (avoid spaces or special characters unless properly escaped).
#   - `--export, --no-export`       : Controls whether wrapped procedures are exported from the namespace. `--export` (default) allows procedures to be accessed outside the namespace without 
#                                     full qualification; `--no-export` restricts access to qualified names only. Usage: Include `--export` or `--no-export` in the command.
#   - `--prefix STRING`             : Adds a specified prefix to all procedure names (including aliased procedures if `--modify-aliases` is enabled). Usage: `--prefix "util_"` (prepends "util_" to 
#                                     each procedure name). Note: Use only valid TCL identifier characters (alphanumerics, underscores) to avoid syntax errors.
#   - `--suffix STRING`             : Adds a specified suffix to all procedure names (including aliased procedures if `--modify-aliases` is enabled). Usage: `--suffix "_v2"` (appends "_v2" to each 
#                                     procedure name). Note: Same character restrictions as `--prefix` apply.
#   - `--modify-aliases`            : Enables applying `--prefix` and `--suffix` to procedure names that were replaced by `alias` commands in the input file. Disabled by default. Usage: Include `--modify-aliases` 
#                                     in the command. Note: Only affects procedures renamed via `alias` statements (e.g., `alias newname "oldname"`).
#   - `--conditional-procs LIST`    : Specifies a comma-separated list of procedure names (original or alias names) that require replacement only when preceded by a specific prefix. Must be used 
#                                     with `--prefix-condition`. Usage: `--conditional-procs "init,cleanup"`. Note: Do not include spaces in the list; names are case-sensitive and must match exactly.
#   - `--prefix-condition STRING`   : Defines a literal prefix that must immediately precede the procedures listed in `--conditional-procs` to trigger replacement. Must be used with `--conditional-procs`. 
#                                     Usage: `--prefix-condition "::"` (replaces listed procedures only if they follow "::"). Note: Special characters (e.g., `.`, `*`) are treated as literals, not regex operators.
#   - `--exclude-prefix CHARS`      : Specifies characters that, if immediately preceding a procedure name, prevent replacement. Default: `'-\\w('` (hyphen, word characters, opening parenthesis). 
#                                     Usage: `--exclude-prefix "-$"` (adds `$` to excluded prefixes). Note: Place hyphens (`-`) at the start or end of CHARS to avoid being interpreted as a range 
#                                     operator (e.g., use `"-abc"` instead of `"a-bc"`).
#   - `--exclude-suffix CHARS`      : Specifies characters that, if immediately following a procedure name, prevent replacement. Default: `'('` (opening parenthesis). Usage: `--exclude-suffix '(,;'` (prevents 
#                                     replacement if followed by `(`, `,`, or `;`). Note: Characters are treated as literals; ensure compatibility with TCL syntax.
#   - `--conditional-suffix-procs LIST`: Specifies a comma-separated list of procedure names that require replacement only when followed by a specific suffix. Must be used with `--suffix-condition`. 
#                                     Usage: `--conditional-suffix-procs "calc,sum"`. Note: Same formatting rules as `--conditional-procs` (no spaces, case-sensitive).
#   - `--suffix-condition STRING`   : Defines a literal suffix that must immediately follow the procedures listed in `--conditional-suffix-procs` to trigger replacement. Must be used with `--conditional-suffix-procs`. 
#                                     Usage: `--suffix-condition ";"` (replaces listed procedures only if they are followed by `;`). Note: Treated as a literal string; special characters do not act as regex operators.
#   - `--output FILE, -o FILE`      : Specifies the path and filename for the processed output TCL file. If omitted, defaults to `wn_<input_filename>` in the same directory as the input file. Usage: `--output ./results/output.tcl` 
#                                     or `-o ./results/output.tcl`. Note: Existing files will be overwritten; ensure the target directory is writable.
#   - `--verbose, -v`               : Enables detailed logging during processing, including procedure mappings, alias handling, and configuration details. Usage: Include `--verbose` or `-v` in the command. 
#                                     Note: Useful for debugging replacement logic or verifying correct processing.
#   - `--help, -h`                  : Displays a help message summarizing all options, their usage, and key notes. Usage: `--help` or `-h`. Note: Execution stops after displaying the help message.
# --------------------------
use strict;
use warnings;
use Getopt::Long;
use File::Basename;

# Default values for options
my $namespace = 'song';
my $export = 0;
my $prefix = 'proc_sar_';
my $suffix = '';
my $modify_aliases = 1;
my $conditional_procs = 'init,process,get_id,get_string,clear,size,get_max_length,set_max_length,get_all';  # Procs that need conditional replacement
my $prefix_condition = '::';
my $exclude_prefix = '-\\w(';
my $exclude_suffix = '(';
my $conditional_suffix_procs = '';
my $suffix_condition = '';
my $output_file = '';
my $help = 0;
my $verbose = 1;

# Parse command line options
GetOptions(
  'namespace=s'      => \$namespace,
  's=s'              => \$namespace,
  'export!'          => \$export,
  'prefix=s'         => \$prefix,
  'suffix=s'         => \$suffix,
  'modify-aliases'   => \$modify_aliases,
  'conditional-procs=s' => \$conditional_procs,
  'prefix-condition=s' => \$prefix_condition,
  'exclude-prefix=s' => \$exclude_prefix,
  'exclude-suffix=s' => \$exclude_suffix,
  'conditional-suffix-procs=s' => \$conditional_suffix_procs,
  'suffix-condition=s' => \$suffix_condition,
  'output=s'         => \$output_file,
  'o=s'              => \$output_file,
  'verbose'          => \$verbose,
  'v'                => \$verbose,
  'help'             => \$help,
  'h'                => \$help,
) or die "Error in command line arguments\n";

# Show help and exit if requested
if ($help) {
  print_help();
  exit 0;
}

# Validate required options and input file
my $input_file = $ARGV[0];
unless ($namespace && $input_file) {
  print "Error: Both --namespace (or -s) and input file are required\n\n";
  print_help();
  exit 1;
}

# Validate conditional options
if(($conditional_procs && !$prefix_condition) || (!$conditional_procs && $prefix_condition)) {
  print "Error: Both --conditional-procs and --prefix-condition must be specified together\n\n";
  print_help();
  exit 1;
}

if(($conditional_suffix_procs && !$suffix_condition) || (!$conditional_suffix_procs && $suffix_condition)) {
  print "Error: Both --conditional-suffix-procs and --suffix-condition must be specified together\n\n";
  print_help();
  exit 1;
}

unless (-f $input_file && -r $input_file) {
  die "Error: Input file '$input_file' does not exist or is not readable\n";
}

# Process conditional procs list
my %conditional_procs;
if ($conditional_procs) {
  %conditional_procs = map { $_ => 1 } split(/,/, $conditional_procs);
  print "Applying conditional replacement to procs: " . join(', ', keys %conditional_procs) . "\n" if $verbose;
  print "Required prefix for conditional replacement: '$prefix_condition'\n" if $verbose;
}

# Process conditional suffix procs list
my %conditional_suffix_procs;
if ($conditional_suffix_procs) {
  %conditional_suffix_procs = map { $_ => 1 } split(/,/, $conditional_suffix_procs);
  print "Applying suffix conditional replacement to procs: " . join(', ', keys %conditional_suffix_procs) . "\n" if $verbose;
  print "Required suffix for conditional replacement: '$suffix_condition'\n" if $verbose;
}

print "Using excluded prefix characters: '$exclude_prefix'\n" if $verbose;
print "Using excluded suffix characters: '$exclude_suffix'\n" if $verbose;

# Determine output file name if not provided
unless ($output_file) {
  my ($name, $path, $ext) = fileparse($input_file, qr/\.[^.]*/);
  $output_file = $path . 'wn_' . $name . $ext;
  print "Output file not specified, using: $output_file\n" if $verbose;
}

# Read input file content
my $content;
eval {
  open(my $fh, '<', $input_file) or die $!;
  local $/;
  $content = <$fh>;
  close($fh);
};
if ($@) {
  die "Error reading input file: $@";
}

# Step 1: Collect all original proc names (case-sensitive)
my %original_procs;
my @proc_definitions = split(/\n/, $content);
foreach my $line (@proc_definitions) {
  if ($line =~ /^\s*proc\s+(\w+)\s+/) {
    $original_procs{$1} = 1;
  }
}
print "Found " . scalar(keys %original_procs) . " original procs\n" if $verbose;

# Step 2: Process alias commands to find proc name mappings (case-sensitive)
my %alias_mapping;
my %alias_lines_to_remove;

foreach my $i (0 .. $#proc_definitions) {
  my $line = $proc_definitions[$i];
  if ($line =~ /^\s*alias\s+(\w+)\s+"([^"]+)"\s*/) {
    my $alias_name = $1;
    my $target_proc = $2;
    
    if (exists $original_procs{$target_proc}) {
      $alias_mapping{$target_proc} = $alias_name;
      $alias_lines_to_remove{$i} = 1;
      print "Found alias: $alias_name -> $target_proc (will be removed)\n" if $verbose;
    } elsif ($verbose) {
      print "Warning: Alias $alias_name references unknown proc $target_proc\n";
    }
  }
}

# Step 3: Create complete mapping of original and alias names to new proc names
my %name_mapping;
foreach my $original_name (keys %original_procs) {
  my $new_name;
  
  if (exists $alias_mapping{$original_name}) {
    my $alias_name = $alias_mapping{$original_name};
    $new_name = $alias_name;
    
    if ($modify_aliases) {
      $new_name = $prefix . $new_name . $suffix;
    }
    
    $name_mapping{$original_name} = $new_name;
    $name_mapping{$alias_name} = $new_name;
    print "Mapping: $original_name -> $new_name (with alias $alias_name)\n" if $verbose;
  } else {
    $new_name = $prefix . $original_name . $suffix;
    $name_mapping{$original_name} = $new_name;
    print "Mapping: $original_name -> $new_name\n" if $verbose;
  }
}

# Step 4: Process each line - precisely replace all call formats
my @proc_names;
my @new_content_lines;

foreach my $i (0 .. $#proc_definitions) {
  next if exists $alias_lines_to_remove{$i};
  
  my $line = $proc_definitions[$i];
  
  # Check if we're in a proc parameter list
  my $in_param_list = 0;
  if ($line =~ /^\s*proc\s+\w+\s+{/) {
    $in_param_list = 1 if ($line =~ /{[^}]*$/);
  }
  
  if ($line =~ /^\s*(proc)\s+(\w+)\s+(.*)$/) {
    my $proc_keyword = $1;
    my $original_name = $2;
    my $new_name = $name_mapping{$original_name};
    
    push @proc_names, { original => $original_name, new => $new_name };
    my $rest_of_line = $3;
    $rest_of_line = update_internal_calls($rest_of_line, \%name_mapping, \%conditional_procs, $prefix_condition, $exclude_prefix, \%conditional_suffix_procs, $suffix_condition, $exclude_suffix, $in_param_list);
    push @new_content_lines, "$proc_keyword $new_name $rest_of_line";
  } else {
    my $processed_line = update_internal_calls($line, \%name_mapping, \%conditional_procs, $prefix_condition, $exclude_prefix, \%conditional_suffix_procs, $suffix_condition, $exclude_suffix, $in_param_list);
    push @new_content_lines, $processed_line;
  }
}

# Step 5: Add indentation to namespace content
my @content_lines = @new_content_lines;
@content_lines = map { "  $_" } @content_lines;
my $indented_content = join("\n", @content_lines);

# Step 6: Create namespace wrapper with multi-line export
my $namespace_declaration = "namespace eval $namespace {\n";

if ($export && @proc_names) {
  my @export_names = map { $_->{new} } @proc_names;
  $namespace_declaration .= "  namespace export \\\n";
  
  my $last_idx = $#export_names;
  for my $i (0 .. $last_idx) {
    my $line = "    $export_names[$i]";
    $line .= " \\" unless $i == $last_idx;
    $namespace_declaration .= "$line\n";
  }
  $namespace_declaration .= "\n";
}

my $wrapped_content = $namespace_declaration . $indented_content . "\n}";
$wrapped_content .= "\n\npackage provide $namespace 1.0";

# Write output file
eval {
  open(my $fh, '>', $output_file) or die $!;
  print $fh $wrapped_content;
  close($fh);
};
if ($@) {
  die "Error writing output file: $@";
}

# Verbose output
if ($verbose) {
  print "Successfully processed file:\n";
  print "Namespace: $namespace\n";
  print "Procs processed: " . scalar(@proc_names) . "\n";
  print "Aliases processed and removed: " . scalar(keys %alias_mapping) . "\n";
  print "Modify aliases with prefix/suffix: " . ($modify_aliases ? "yes" : "no") . "\n";
  print "Export enabled: " . ($export ? "yes" : "no") . "\n";
  print "Prefix: " . ($prefix ? $prefix : "none") . "\n";
  print "Suffix: " . ($suffix ? $suffix : "none") . "\n";
  print "Output written to: $output_file\n";
} else {
  print "Processing complete. Output written to: $output_file\n";
}

# Subroutine to update internal proc calls with enhanced conditions
sub update_internal_calls {
  my ($line, $name_mapping_ref, $conditional_procs_ref, $prefix_condition, $exclude_prefix, $conditional_suffix_procs_ref, $suffix_condition, $exclude_suffix, $in_param_list) = @_;
  my %name_mapping = %$name_mapping_ref;
  my %conditional_procs = %$conditional_procs_ref;
  my %conditional_suffix_procs = %$conditional_suffix_procs_ref;
  
  my @all_names = keys %name_mapping;
  return $line unless @all_names;
  
  # Process each name individually to apply specific conditions
  foreach my $name (sort { length($b) <=> length($a) } @all_names) {
    my $new_name = $name_mapping{$name};
    my $pattern;
    
    # Skip replacement if in parameter list
    next if $in_param_list;
    
    if (exists $conditional_procs{$name}) {
      # Handle prefix conditional procs
      my $escaped_condition = quotemeta($prefix_condition);
      # Add (?<!set ) to exclude variables defined with set command
      $pattern = qr/(?<!set )(?<!\$)(?<=$escaped_condition)(?<![$exclude_prefix])\Q$name\E(?![$exclude_suffix])(?!\w)/;
    } elsif (exists $conditional_suffix_procs{$name}) {
      # Handle suffix conditional procs
      my $escaped_condition = quotemeta($suffix_condition);
      # Add (?<!set ) to exclude variables defined with set command
      $pattern = qr/(?<!set )(?<!\$)(?<![$exclude_prefix])\Q$name\E(?=$escaped_condition)(?![$exclude_suffix])/;
    } else {
      # Regular procs with enhanced conditions
      # Add (?<!set ) to exclude variables defined with set command
      $pattern = qr/(?<!set )(?<!\$)(?<![$exclude_prefix])\Q$name\E(?![$exclude_suffix])(?!\w)/;
    }
    
    $line =~ s/$pattern/$new_name/g;
  }
  
  return $line;
}

# Help information subroutine
sub print_help {
  print "Usage: $0 [options] input_file.tcl\n";
  print "Wraps all TCL procs in a specified namespace with optional modifications\n\n";
  print "Options:\n";
  print "  --namespace NAME, -s NAME   Specify the namespace name (required)\n";
  print "  --export, --no-export       Control whether procs are exported (default: export)\n";
  print "  --prefix STRING             Add prefix to all proc names\n";
  print "  --suffix STRING             Add suffix to all proc names\n";
  print "  --modify-aliases            Apply prefix/suffix to alias-replaced proc names (default: no)\n";
  print "  --conditional-procs LIST    Comma-separated list of procs needing prefix conditional replacement\n";
  print "  --prefix-condition STRING   Required prefix that triggers replacement for conditional procs\n";
  print "  --exclude-prefix CHARS      Characters that prevent replacement when preceding proc names\n";
  print "                              (default: '-\\w(' - hyphen, word chars, and opening parenthesis)\n";
  print "                              Note: Place hyphens at the start/end to avoid range interpretation\n";
  print "  --exclude-suffix CHARS      Characters that prevent replacement when following proc names\n";
  print "                              (default: '(' - opening parenthesis)\n";
  print "  --conditional-suffix-procs LIST  Comma-separated list of procs needing suffix conditional replacement\n";
  print "  --suffix-condition STRING   Required suffix that triggers replacement for conditional-suffix-procs\n";
  print "  --output FILE, -o FILE      Specify output file name (default: wn_inputfile.tcl)\n";
  print "  --verbose, -v               Show detailed processing information\n";
  print "  --help, -h                  Show this help message\n";
  print "Note: Proc names will not be replaced if:\n";
  print "      - They appear in parameter lists\n";
  print "      - They are prefixed with \$ (variable references)\n";
  print "      - They follow the 'set ' command (variable definitions)\n";
}

