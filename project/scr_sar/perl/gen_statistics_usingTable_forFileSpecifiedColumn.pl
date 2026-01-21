#!/usr/bin/perl
# --------------------------
# author    : sar song
# date      : 2026/01/21 16:18:55 Wednesday
# label     : format_sub
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Generate statistical table by reading numeric values from specified column of input file, classify data into intervals 
#             based on range boundaries, and output count and percentage for each interval
# return    : Hash reference containing {total_items => int, invalid_items => int, valid_items => int, counters => hash_ref} 
# ref       : link url
# --------------------------
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

my $input_file;
my $column_num;
my $ranges_str;
my $debug = 0;
my $help = 0;

GetOptions(
  'file|f=s'    => \$input_file,
  'column|c=i'  => \$column_num,
  'ranges|r=s'  => \$ranges_str,
  'debug|d'     => \$debug,
  'help|h'      => \$help,
) or pod2usage(2);

if ($help) {
  show_help();
  exit(0);
}

# Validate required parameters
if (!defined $input_file) {
  error("Error: Input file is required. Use --file or -f option.");
}
if (!defined $column_num) {
  error("Error: Column number is required. Use --column or -c option.");
}
if (!defined $ranges_str) {
  error("Error: Ranges are required. Use --ranges or -r option.");
}

# Parse ranges string into array
my @ranges = parse_ranges($ranges_str);

# Generate statistical table
generate_stat_table($input_file, $column_num, \@ranges, $debug);

exit(0);

sub parse_ranges {
  my ($ranges_str) = @_;

  my @ranges = split(/[\s,]+/, $ranges_str);

  my @valid_ranges = ();
  foreach my $val (@ranges) {
    if ($val eq '') {
      next;
    }
    if (!is_number($val)) {
      error("Error: Range value '$val' is not a valid number");
    }
    push @valid_ranges, $val + 0;
  }

  if (scalar(@valid_ranges) == 0) {
    error("Error: Ranges must be a non-empty list of numbers");
  }

  # Sort ranges in ascending order and remove duplicates
  my %seen = ();
  my @sorted_ranges = ();
  foreach my $val (sort { $a <=> $b } @valid_ranges) {
    if (!exists $seen{$val}) {
      $seen{$val} = 1;
      push @sorted_ranges, $val;
    }
  }

  if ($debug) {
    print "DEBUG: Sorted unique ranges: " . join(", ", @sorted_ranges) . "\n";
  }

  return @sorted_ranges;
}

sub is_number {
  my ($val) = @_;
  return $val =~ /^-?\d+\.?\d*$/ || $val =~ /^-?\d*\.?\d+$/;
}

sub generate_stat_table {
  my ($input_file, $column_num, $ranges_ref, $debug) = @_;

  my @ranges = @$ranges_ref;

  # Validate input file existence
  if (!-e $input_file) {
    error("Error: Input file '$input_file' does not exist");
  }

  # Validate input file is readable
  if (!-r $input_file) {
    error("Error: Input file '$input_file' is not readable");
  }

  # Validate column number is a positive integer
  if ($column_num <= 0) {
    error("Error: Column number must be a positive integer, got '$column_num'");
  }

  # Create range intervals
  my @intervals = ();
  my $prev_val = "-inf";
  foreach my $curr_val (@ranges) {
    push @intervals, [$prev_val, $curr_val];
    $prev_val = $curr_val;
  }
  push @intervals, [$prev_val, "+inf"];

  if ($debug) {
    print "DEBUG: Created intervals: ";
    foreach my $interval (@intervals) {
      print "[$interval->[0], $interval->[1]) ";
    }
    print "\n";
  }

  # Initialize counters
  my %counters = ();
  foreach my $interval (@intervals) {
    my $key = $interval->[0] . "," . $interval->[1];
    $counters{$key} = 0;
  }

  # Process input file
  my $total_items = 0;
  my $invalid_items = 0;

  open(my $fh, '<', $input_file) or error("Error: Cannot open file '$input_file': $!");

  while (my $line = <$fh>) {
    chomp($line);
    $total_items++;

    # Skip empty lines
    if ($line =~ /^\s*$/) {
      if ($debug) {
        print "DEBUG: Skipping empty line\n";
      }
      next;
    }

    # Split line into fields
    my @fields = split(/\s+/, $line);
    my $num_fields = scalar(@fields);

    # Check if line has enough columns
    if ($num_fields < $column_num) {
      if ($debug) {
        print "DEBUG: Line has only $num_fields fields, need $column_num: $line\n";
      }
      $invalid_items++;
      next;
    }

    # Extract target column value (column_num is 1-based)
    my $target_val = $fields[$column_num - 1];

    # Check if target value is a number
    if (!is_number($target_val)) {
      if ($debug) {
        print "DEBUG: Column $column_num value '$target_val' is not a number: $line\n";
      }
      $invalid_items++;
      next;
    }

    # Convert to double for comparison
    $target_val = $target_val + 0.0;

    # Count in appropriate interval
    foreach my $interval (@intervals) {
      my $low = $interval->[0];
      my $high = $interval->[1];

      my $in_range = 0;
      if ($low eq "-inf") {
        if ($target_val < $high) {
          $in_range = 1;
        }
      } elsif ($high eq "+inf") {
        if ($target_val >= $low) {
          $in_range = 1;
        }
      } else {
        if ($target_val >= $low && $target_val < $high) {
          $in_range = 1;
        }
      }

      if ($in_range) {
        my $key = $low . "," . $high;
        $counters{$key}++;
        last;
      }
    }
  }
  close($fh);

  if ($debug) {
    print "DEBUG: Total items processed: $total_items\n";
    print "DEBUG: Invalid items skipped: $invalid_items\n";
    print "DEBUG: Raw counters: ";
    foreach my $key (keys %counters) {
      print "$key=$counters{$key} ";
    }
    print "\n";
  }

  # Generate statistical table
  print "\n=== Statistical Table ===\n";
  print "Input File: $input_file\n";
  print "Column: $column_num\n";
  print "Ranges: " . join(", ", @ranges) . "\n";
  print "Total Items: $total_items\n";
  print "Invalid Items: $invalid_items\n";
  print "\n";

  # Calculate column widths dynamically
  my $total_valid = $total_items - $invalid_items;
  my $total_percent = 0.0;

  # Collect all data for width calculation
  my @table_data = ();
  my $max_range_width = length("Range");
  my $max_count_width = length("Count");
  my $max_percent_width = length("Percentage");

  foreach my $interval (@intervals) {
    my $low = $interval->[0];
    my $high = $interval->[1];
    my $key = $low . "," . $high;
    my $count = $counters{$key};

    # Calculate percentage
    my $percent = 0.0;
    if ($total_valid > 0) {
      $percent = ($count * 100.0) / $total_valid;
    }

    # Format range string
    my $range_str;
    if ($low eq "-inf") {
      $range_str = sprintf("< %g", $high);
    } elsif ($high eq "+inf") {
      $range_str = sprintf(">= %g", $low);
    } else {
      $range_str = sprintf("[%g, %g)", $low, $high);
    }

    # Store data for later printing
    push @table_data, {
      range_str => $range_str,
      count => $count,
      percent => $percent,
    };

    # Update max widths
    $max_range_width = length($range_str) if length($range_str) > $max_range_width;
    $max_count_width = length($count) if length($count) > $max_count_width;
    my $percent_str = sprintf("%.2f%%", $percent);
    $max_percent_width = length($percent_str) if length($percent_str) > $max_percent_width;
  }

  # Add minimum width for headers
  $max_range_width = length("Range") if length("Range") > $max_range_width;
  $max_count_width = length("Count") if length("Count") > $max_count_width;
  $max_percent_width = length("Percentage") if length("Percentage") > $max_percent_width;

  # Add padding for visual aesthetics
  $max_range_width += 2;
  $max_count_width += 2;
  $max_percent_width += 2;

  # Print header
  my $separator = "-" x ($max_range_width + $max_count_width + $max_percent_width + 6);
  printf "%-${max_range_width}s | %${max_count_width}s | %${max_percent_width}s\n", "Range", "Count", "Percentage";
  print "$separator\n";

  # Print each interval
  foreach my $row (@table_data) {
    my $range_str = $row->{range_str};
    my $count = $row->{count};
    my $percent = $row->{percent};
    $total_percent += $percent;

    printf "%-${max_range_width}s | %${max_count_width}d | %${max_percent_width}.2f%%\n", $range_str, $count, $percent;
  }

  # Print total
  print "$separator\n";
  printf "%-${max_range_width}s | %${max_count_width}d | %${max_percent_width}.2f%%\n", "Total", $total_valid, $total_percent;
  print "\n";

  return {
    total_items => $total_items,
    invalid_items => $invalid_items,
    valid_items => $total_valid,
    counters => \%counters,
  };
}

sub show_help {
  print <<'END_HELP';
Usage: perl stat_table.pl [OPTIONS]

Generate a statistical table based on numeric ranges from a specified column in an input file.

OPTIONS:
  -f, --file FILE      Input file path (required)
  -c, --column NUM     Column number to analyze (1-based, required)
  -r, --ranges RANGES  Range boundaries separated by spaces or commas (required)
                       Example: "10,50,100" or "10 50 100"
  -d, --debug          Enable debug mode for detailed output
  -h, --help           Display this help message

DESCRIPTION:
  This script reads an input file and generates a statistical table based on numeric
  values from a specified column. The ranges parameter defines the boundaries that
  divide the number line into intervals.

  For example, with ranges "10,50,100", the number line is divided into:
    - (-inf, 10): values less than 10
    - [10, 50): values from 10 to less than 50
    - [50, 100): values from 50 to less than 100
    - [100, +inf): values greater than or equal to 100

  The script counts how many values fall into each interval and calculates the
  percentage distribution.

EXAMPLES:
  # Basic usage
  perl stat_table.pl -f data.txt -c 3 -r "10,50,100"

  # Using short options
  perl stat_table.pl -f data.txt -c 2 -r "0.5 1.0 1.5"

  # With debug mode
  perl stat_table.pl --file data.txt --column 3 --ranges "10,50,100" --debug

  # Mixed short and long options
  perl stat_table.pl -f data.txt --column 2 -r "0,100,200" -d

ERROR HANDLING:
  The script will report errors and exit with a non-zero status if:
    - Input file does not exist or is not readable
    - Column number is not a positive integer
    - Ranges are not valid numbers
    - Specified column contains non-numeric values

NOTES:
    - Empty lines are skipped
    - Lines with insufficient columns are counted as invalid
    - Non-numeric values in the target column are counted as invalid
    - Range boundaries are automatically sorted and duplicates are removed

END_HELP
}

sub error {
  my ($message) = @_;
  print STDERR "$message\n";
  exit(1);
}
