#!/bin/perl
# --------------------------
# author    : sar song
# date      : 2025/09/04 10:15:27 Thursday
# label     : format_sub
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : A Perl subroutine that generates formatted bordered tables. Header information in first row of rows.
#             Supports title (optional), column alignment (left/right/center), column widths, text wrapping, and error checking.
# input     : Accepts either: 
#             1) a hashref with 'title' (string, optional), 'rows' (array of row arrays, required), 'align' (string/array, optional, default left),
#                and 'col_widths' (single int/array, optional); 
#             or 
#             2) separate arguments: title (optional), rows (required), align (optional, default left), col_widths (optional).
# update    : 2025/09/20 13:56:11 Saturday
#             The use of the header parameter has been removed, simplifying the parameter list of the subroutine. Column alignment for data has been added, which 
#             can be specified either uniformly using a single string or for each column individually using an array. The specified values must be from the 
#             enumeration list: left, right, center.
#             NOTICE : The only parameter that users must specify when calling is rows; all other parameters have default values.
# return    : Formatted table string with borders, title (if provided), and proper alignment.
# ref       : link url
# --------------------------
sub gen_table {
  my ($title, $rows, $align_spec, $col_widths_spec);
  my $arg_count = @_;
  
  # Validate and parse input arguments
  if ($arg_count == 1) {
    # Single hash reference argument
    unless (ref $_[0] eq 'HASH') {
      die "sub gen_table: Invalid argument: Expected hash reference when providing single argument";
    }
    my $data = shift;
    
    # Check for required key (rows)
    unless (exists $data->{rows}) {
      die "sub gen_table: Missing required key in hash reference: 'rows'";
    }
    # Extract parameters with defaults
    $title = exists $data->{title} ? $data->{title} : '';
    $rows = $data->{rows};
    $align_spec = exists $data->{align} ? $data->{align} : 'left';
    $col_widths_spec = exists $data->{col_widths} ? $data->{col_widths} : 0;
  } elsif ($arg_count >= 2 && $arg_count <= 4) {
    # Separate arguments: title (optional), rows (required), align (optional), col_widths (optional)
    ($title, $rows, $align_spec, $col_widths_spec) = @_;
    # Set defaults for optional arguments
    $title //= '';
    $align_spec //= 'left';
    $col_widths_spec //= 0;
  } else {
    die "sub gen_table: Invalid number of arguments (got $arg_count, expected 1, 2, 3 or 4)";
  }
  
  # Validate title (must be string)
  unless (defined $title) {
    die "sub gen_table: Title is undefined";
  }
  unless (!ref $title) {
    die "sub gen_table: Title must be a string, not a " . ref($title);
  }
  
  # Validate rows (must be non-empty array)
  unless (defined $rows) {
    die "sub gen_table: Rows are undefined";
  }
  if (ref $rows ne 'ARRAY') {
    $rows = [$rows];
    warn "Rows were not an array reference - automatically wrapped in array";
  }
  unless (@$rows > 0) {
    die "sub gen_table: Rows array cannot be empty";
  }
  
  # Get column count from first row
  my $first_row = $rows->[0];
  if (ref $first_row ne 'ARRAY') {
    $first_row = [$first_row];
    $rows->[0] = $first_row;
    warn "First row was not an array reference - automatically wrapped in array";
  }
  my $column_count = scalar @$first_row;
  unless ($column_count > 0) {
    die "sub gen_table: First row cannot be empty";
  }
  
  # Validate all rows have matching column count
  foreach my $row_idx (0 .. $#$rows) {
    my $row = $rows->[$row_idx];
    
    unless (defined $row) {
      die "sub gen_table: Row at index $row_idx is undefined";
    }
    if (ref $row ne 'ARRAY') {
      $row = [$row];
      $rows->[$row_idx] = $row;
      warn "Row at index $row_idx is not an array reference - automatically wrapped in array";
    }
    
    my $row_col_count = scalar @$row;
    unless ($row_col_count == $column_count) {
      die "sub gen_table: Row $row_idx has $row_col_count columns, expected $column_count (from first row)";
    }
    
    # Validate cell contents
    foreach my $col_idx (0 .. $#$row) {
      my $cell = $row->[$col_idx];
      if (!defined $cell) {
        warn "Cell at row $row_idx, column $col_idx is undefined";
        $row->[$col_idx] = '';
      } elsif (ref $cell) {
        die "sub gen_table: Cell at row $row_idx, column $col_idx is a " . ref($cell) . ", expected scalar";
      }
    }
  }
  
  # Validate alignment specifications
  my @alignments;
  my %valid_align = map { $_ => 1 } qw(left right center);
  
  if (ref $align_spec eq 'ARRAY') {
    unless (@$align_spec == $column_count) {
      die "sub gen_table: Alignment array has " . scalar(@$align_spec) . 
          " elements, but table has $column_count columns";
    }
    foreach my $i (0 .. $#$align_spec) {
      my $align = $align_spec->[$i];
      unless (defined $align && $valid_align{lc $align}) {
        die "sub gen_table: Invalid alignment '$align' at index $i - must be left, right, or center";
      }
      push @alignments, lc $align;
    }
  } else {
    unless (defined $align_spec && $valid_align{lc $align_spec}) {
      die "sub gen_table: Invalid alignment specification '$align_spec' - must be left, right, or center";
    }
    @alignments = (lc $align_spec) x $column_count;
  }
  
  # Validate column width specifications
  my @col_widths_spec;
  if (ref $col_widths_spec eq 'ARRAY') {
    unless (@$col_widths_spec == $column_count) {
      die "sub gen_table: Column width array has " . scalar(@$col_widths_spec) . 
          " elements, but table has $column_count columns";
    }
    foreach my $i (0 .. $#$col_widths_spec) {
      my $width = $col_widths_spec->[$i];
      unless (defined $width && $width =~ /^\d+$/ && $width >= 0) {
        die "sub gen_table: Invalid column width '$width' at index $i - must be non-negative integer";
      }
      push @col_widths_spec, $width;
    }
  } else {
    unless (defined $col_widths_spec && $col_widths_spec =~ /^\d+$/ && $col_widths_spec >= 0) {
      die "sub gen_table: Invalid column width specification '$col_widths_spec' - must be non-negative integer";
    }
    @col_widths_spec = ($col_widths_spec) x $column_count;
  }
  
  # Helper function to wrap text to specified width
  sub wrap_text {
    my ($text, $width) = @_;
    return ($text) if $width == 0;  # No wrapping if width is 0
    
    my @lines;
    my $len = length $text;
    my $pos = 0;
    
    while ($pos < $len) {
      my $remaining = $len - $pos;
      my $take = $remaining < $width ? $remaining : $width;
      push @lines, substr($text, $pos, $take);
      $pos += $take;
    }
    
    return @lines;
  }
  
  # Prepare wrapped content for header (first row) and data rows
  my $header_row = $rows->[0];
  my @wrapped_header;
  for my $i (0 .. $#$header_row) {
    my $width = $col_widths_spec[$i];
    $wrapped_header[$i] = [wrap_text($header_row->[$i], $width)];
  }
  
  my @wrapped_rows;
  for my $row_idx (1 .. $#$rows) {  # Start from 1 since 0 is header
    my $row = $rows->[$row_idx];
    my @wrapped_row;
    for my $i (0 .. $#$row) {
      my $width = $col_widths_spec[$i];
      $wrapped_row[$i] = [wrap_text($row->[$i], $width)];
    }
    push @wrapped_rows, \@wrapped_row;
  }
  
  # Calculate actual column widths based on content and specs
  my @col_widths;
  for my $i (0 .. $column_count - 1) {
    my $spec_width = $col_widths_spec[$i];
    my $max_width = 0;
    
    # Check header width
    foreach my $line (@{$wrapped_header[$i]}) {
      my $len = length $line;
      $max_width = $len if $len > $max_width;
    }
    
    # Check data row widths
    foreach my $row (@wrapped_rows) {
      foreach my $line (@{$row->[$i]}) {
        my $len = length $line;
        $max_width = $len if $len > $max_width;
      }
    }
    
    # Apply width restriction if specified
    $col_widths[$i] = ($spec_width > 0 && $spec_width < $max_width) ? $spec_width : $max_width;
  }
  
  # Calculate total table width for title formatting
  my $total_width = 1;  # Starting '+' character
  $total_width += $_ + 2 for @col_widths;  # Column width plus padding spaces
  $total_width += $column_count - 1;  # '+' characters between columns
  
  # Build table content string
  my $table_output = '';
  
  # Add centered title if not empty
  if (length($title) > 0) {
    my $title_padded = $title;
    if (length($title) < $total_width) {
      my $pad = int(($total_width - length($title)) / 2);
      $title_padded = (' ' x $pad) . $title . 
                      (' ' x ($total_width - length($title) - $pad));
    }
    $table_output .= "$title_padded\n\n";
  }
  
  # Create separator line (+-+ format)
  my $separator = '+';
  $separator .= '-' x ($_ + 2) . '+' for @col_widths;
  
  # Add top border
  $table_output .= "$separator\n";
  
  # Add header row with alignment
  my $max_header_lines = 0;
  $max_header_lines = scalar(@$_) > $max_header_lines ? scalar(@$_) : $max_header_lines for @wrapped_header;
  
  for my $line_idx (0 .. $max_header_lines - 1) {
    my $header_line = '|';
    for my $i (0 .. $#wrapped_header) {
      my $content = $line_idx < @{$wrapped_header[$i]} ? $wrapped_header[$i][$line_idx] : '';
      my $width = $col_widths[$i];
      my $formatted;
      
      # Apply alignment
      if ($alignments[$i] eq 'left') {
        $formatted = sprintf(" %-*s ", $width, $content);
      } elsif ($alignments[$i] eq 'right') {
        $formatted = sprintf(" %*s ", $width, $content);
      } else {  # center
        my $pad = $width - length($content);
        my $left_pad = int($pad / 2);
        my $right_pad = $pad - $left_pad;
        $formatted = ' ' . (' ' x $left_pad) . $content . (' ' x $right_pad) . ' ';
      }
      
      $header_line .= $formatted . '|';
    }
    $table_output .= "$header_line\n";
  }
  $table_output .= "$separator\n";
  
  # Add data rows with alignment
  for my $row (@wrapped_rows) {
    my $max_line_count = 0;
    $max_line_count = scalar(@$_) > $max_line_count ? scalar(@$_) : $max_line_count for @$row;
    
    for my $line_idx (0 .. $max_line_count - 1) {
      my $data_line = '|';
      for my $i (0 .. $column_count - 1) {
        my $content = $line_idx < @{$row->[$i]} ? $row->[$i][$line_idx] : '';
        my $width = $col_widths[$i];
        my $formatted;
        
        # Apply alignment
        if ($alignments[$i] eq 'left') {
          $formatted = sprintf(" %-*s ", $width, $content);
        } elsif ($alignments[$i] eq 'right') {
          $formatted = sprintf(" %*s ", $width, $content);
        } else {  # center
          my $pad = $width - length($content);
          my $left_pad = int($pad / 2);
          my $right_pad = $pad - $left_pad;
          $formatted = ' ' . (' ' x $left_pad) . $content . (' ' x $right_pad) . ' ';
        }
        
        $data_line .= $formatted . '|';
      }
      $table_output .= "$data_line\n";
    }
    $table_output .= "$separator\n";
  }
  
  $table_output .= "\n";  # Add a blank line after table
  
  return $table_output;
}
if (0) {
# Example usage 1: Different alignments for each column
  my $aligned_table = gen_table(
    "Employee Data",
    [
      ['ID', 'Name', 'Department', 'Salary'],
      [101, 'John Smith', 'Engineering', 75000],
      [102, 'Jane Doe', 'Marketing', 68000],
      [103, 'Bob Johnson', 'Finance', 82000],
    ],
    ['right', 'left', 'left', 'right'],  # Alignment for each column
    15  # Column width
  );
  print $aligned_table;

# Example usage 2: Center alignment for all columns (hashref format)
  my $centered_table = gen_table({
    title => "Product Inventory",
    rows => [
      ['SKU', 'Product', 'In Stock'],
      ['PRD001', 'Laptop', 15],
      ['PRD002', 'Smartphone', 30],
      ['PRD003', 'Tablet', 25],
    ],
    align => 'center',  # All columns centered
    col_widths => [8, 15, 8]
  });
  print $centered_table;

# Example usage 3: Invalid alignment (will trigger die error)
   # my $invalid_align = gen_table(
   #   "Test",
   #   [['A', 'B']],
   #   'middle',  # Invalid alignment
   #   10
   # );
   # print $invalid_align;
}
1;

