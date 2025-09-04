#!/bin/perl
# --------------------------
# author    : sar song
# date      : 2025/09/04 10:15:27 Thursday
# label     : format_sub
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : A Perl subroutine that generates formatted bordered tables with a title, supports multiple input formats, allows setting column widths 
#             (with automatic text wrapping for overflow content), and includes comprehensive error checking.
# input     : Accepts either: 
#             1) a hashref with 'title' (string), 'headers' (array of column names), 'rows' (array of row arrays), and optional 'col_widths' 
#               (single int or array of ints for column limits); 
#             or 
#             2) separate arguments in order: title, headers, rows, and optional col_widths. All columns in rows must match header count.
# return    : A formatted string containing the complete table with title, borders, and data, ready to print directly.
# ref       : link url
# --------------------------
sub gen_table {
  my ($title, $headers, $rows, $col_widths_spec);
  my $arg_count = @_;
  
  # Validate and parse input arguments
  if ($arg_count == 1) {
    # Single hash reference argument
    unless (ref $_[0] eq 'HASH') {
      die "sub gen_table: Invalid argument: Expected hash reference when providing single argument";
    }
    my $data = shift;
    
    # Check for required keys in hash reference
    my @required_keys = qw(title headers rows);
    foreach my $key (@required_keys) {
      unless (exists $data->{$key}) {
        die "sub gen_table: Missing required key in hash reference: '$key'";
      }
    }
    
    $title = $data->{title};
    $headers = $data->{headers};
    $rows = $data->{rows};
    $col_widths_spec = exists $data->{col_widths} ? $data->{col_widths} : 0;
  } elsif ($arg_count == 3 || $arg_count == 4) {
    # Separate arguments: title, headers, rows, [col_widths]
    ($title, $headers, $rows, $col_widths_spec) = @_;
    $col_widths_spec //= 0;  # Default to no width restriction
  } else {
    die "sub gen_table: Invalid number of arguments (got $arg_count, expected 1, 3 or 4)";
  }
  
  # Validate title
  unless (defined $title) {
    die "sub gen_table: Title is undefined";
  }
  unless (length($title) > 0) {
    die "sub gen_table: Title cannot be empty";
  }
  unless (!ref $title) {
    die "sub gen_table: Title must be a string, not a " . ref($title);
  }
  
  # Validate headers and convert to array reference if needed
  unless (defined $headers) {
    die "sub gen_table: Headers are undefined";
  }
  if (ref $headers ne 'ARRAY') {
    $headers = [$headers];
    warn "Headers were not an array reference - automatically wrapped in array";
  }
  unless (@$headers > 0) {
    die "sub gen_table: Headers array cannot be empty";
  }
  # Check each header is a defined non-reference
  foreach my $i (0 .. $#$headers) {
    my $header = $headers->[$i];
    unless (defined $header) {
      die "sub gen_table: Header at index $i is undefined";
    }
    unless (!ref $header) {
      die "sub gen_table: Header at index $i is a " . ref($header) . ", expected scalar value";
    }
  }
  my $header_count = scalar @$headers;
  
  # Validate rows and convert to array reference if needed
  unless (defined $rows) {
    die "sub gen_table: Rows are undefined";
  }
  if (ref $rows ne 'ARRAY') {
    $rows = [$rows];
    warn "Rows were not an array reference - automatically wrapped in array";
  }
  # Check each row is a valid array reference with matching column count
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
    unless ($row_col_count == $header_count) {
      die "sub gen_table: Row $row_idx has $row_col_count columns, but headers have $header_count columns";
    }
    
    foreach my $col_idx (0 .. $#$row) {
      my $cell = $row->[$col_idx];
      if (!defined $cell) {
        warn "Cell at row $row_idx, column $col_idx is undefined";
        $row->[$col_idx] = '';
      } elsif (ref $cell) {
        die "sub gen_table: Cell at row $row_idx, column $col_idx is a " . ref($cell) . ", expected scalar value";
      }
    }
  }
  
  # Validate and process column width specifications
  my @col_widths_spec;
  if (ref $col_widths_spec eq 'ARRAY') {
    # Array of width specifications
    unless (@$col_widths_spec == $header_count) {
      die "sub gen_table: Column width array has " . scalar(@$col_widths_spec) . 
          " elements, but there are $header_count columns";
    }
    foreach my $i (0 .. $#$col_widths_spec) {
      my $width = $col_widths_spec->[$i];
      unless (defined $width && $width =~ /^\d+$/ && $width >= 0) {
        die "sub gen_table: Invalid column width '$width' at index $i - must be non-negative integer";
      }
      push @col_widths_spec, $width;
    }
  } else {
    # Single width specification for all columns
    unless (defined $col_widths_spec && $col_widths_spec =~ /^\d+$/ && $col_widths_spec >= 0) {
      die "sub gen_table: Invalid column width specification '$col_widths_spec' - must be non-negative integer";
    }
    @col_widths_spec = ($col_widths_spec) x $header_count;
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
  
  # Prepare wrapped content for headers and rows
  my @wrapped_headers;
  my @wrapped_rows;
  
  # Process headers
  for my $i (0 .. $#$headers) {
    my $width = $col_widths_spec[$i];
    $wrapped_headers[$i] = [wrap_text($headers->[$i], $width)];
  }
  
  # Process rows
  for my $row_idx (0 .. $#$rows) {
    my $row = $rows->[$row_idx];
    my @wrapped_row;
    for my $i (0 .. $#$row) {
      my $width = $col_widths_spec[$i];
      $wrapped_row[$i] = [wrap_text($row->[$i], $width)];
    }
    push @wrapped_rows, \@wrapped_row;
  }
  
  # Calculate actual column widths based on wrapped content and width specs
  my @col_widths;
  for my $i (0 .. $#$headers) {
    my $spec_width = $col_widths_spec[$i];
    my $max_width = 0;
    
    # Check header width
    foreach my $line (@{$wrapped_headers[$i]}) {
      my $len = length $line;
      $max_width = $len if $len > $max_width;
    }
    
    # Check row widths
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
  $total_width += $#col_widths;  # '+' characters between columns
  
  # Build table content string
  my $table_output = '';
  
  # Add centered title above the table
  my $title_padded = $title;
  if (length($title) < $total_width) {
    my $pad = int(($total_width - length($title)) / 2);
    $title_padded = (' ' x $pad) . $title . 
                    (' ' x ($total_width - length($title) - $pad));
  }
  $table_output .= "$title_padded\n\n";
  
  # Create separator line (+-+ format)
  my $separator = '+';
  $separator .= '-' x ($_ + 2) . '+' for @col_widths;
  
  # Add table header with wrapping support
  $table_output .= "$separator\n";
  my $max_header_lines = 0;
  $max_header_lines = scalar(@$_) > $max_header_lines ? scalar(@$_) : $max_header_lines for @wrapped_headers;
  
  for my $line_idx (0 .. $max_header_lines - 1) {
    my $header_line = '|';
    for my $i (0 .. $#$headers) {
      my $content = $line_idx < @{$wrapped_headers[$i]} ? $wrapped_headers[$i][$line_idx] : '';
      $header_line .= sprintf(" %-*s |", $col_widths[$i], $content);
    }
    $table_output .= "$header_line\n";
  }
  $table_output .= "$separator\n";
  
  # Add table rows with wrapping support
  for my $row (@wrapped_rows) {
    my $max_line_count = 0;
    $max_line_count = scalar(@$_) > $max_line_count ? scalar(@$_) : $max_line_count for @$row;
    
    for my $line_idx (0 .. $max_line_count - 1) {
      my $data_line = '|';
      for my $i (0 .. $#$row) {
        my $content = $line_idx < @{$row->[$i]} ? $row->[$i][$line_idx] : '';
        $data_line .= sprintf(" %-*s |", $col_widths[$i], $content);
      }
      $table_output .= "$data_line\n";
    }
    $table_output .= "$separator\n";
  }
  
  $table_output .= "\n";  # Add a blank line after table
  
  return $table_output;
}

if (0) {
# Example usage 1: Single column width for all columns (10 characters)
  my $employee_table = gen_table(
    "Employee Information (10 char width)",
    ['ID', 'Name', 'Department', 'Salary'],
    [
      [101, 'John Smith', 'Engineering', 75000],
      [102, 'Jane Doe', 'Marketing', 68000],
      [103, 'Robert Johnson', 'Sales Department', 62000],  # Will wrap
    ],
    10  # All columns limited to 10 characters
  );
  print $employee_table;

# Example usage 2: Different widths for each column using hash reference
  my $product_table = gen_table({
    title => "Product Inventory (custom widths)",
    headers => ['SKU', 'Product', 'Quantity', 'Price'],
    rows => [
      ['PRD001', 'High Performance Laptop', 15, 999.99],  # Will wrap
      ['PRD002', 'Smartphone', 30, 499.99],
      ['PRD003', 'Tablet Computer', 25, 299.99],  # Will wrap
    ],
    col_widths => [6, 12, 8, 6]  # Different width for each column
  });
  print $product_table;

# Example usage 3: No width restrictions (default behavior)
  my $unrestricted_table = gen_table(
    "Unrestricted Width Table",
    ['Short', 'Longer Header', 'Very Long Header Column'],
    [
      ['Data', 'More data here', 'This is a very long piece of data that would wrap if we set a width'],
    ],
    0  # No width restrictions
  );
  print $unrestricted_table;

}
