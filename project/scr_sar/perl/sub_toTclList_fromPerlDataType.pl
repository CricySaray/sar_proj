#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

# Main function: convert Perl data structure to Tcl list format
# Parameters: data to convert, indent level (optional), debug flag (optional), error count ref (optional)
sub to_tcl_list {
  my ($data, $indent, $debug, $error_count) = @_;
  $indent //= 0;  # Default indentation level
  $debug //= 0;   # Default debug off
  $error_count //= { count => 0 };  # Error counter reference
  
  my $indent_str = '  ' x $indent;  # Indentation string for debug output
  
  # Debug: show current data type being processed
  if ($debug) {
    my $type = ref($data) || 'scalar';
    print STDERR "${indent_str}Processing $type: ";
    # Limit debug output length for deep data structures
    print STDERR (defined $data ? substr(Dumper($data), 0, 100) : 'undef') . "\n" 
      if $indent < 4;
  }
  
  # Error check: undefined value
  unless (defined $data) {
    _log_error("Undefined value encountered", $indent, $debug);
    $error_count->{count}++;
    return "{}";  # Represent undefined as empty list in Tcl
  }
  
  # Process scalar values
  unless (ref($data)) {
    my $value = $data;
    
    # Escape Tcl special characters
    $value =~ s/\\/\\\\/g;  # Escape backslashes
    $value =~ s/\{/\\\{/g;  # Escape left braces
    $value =~ s/\}/\\\}/g;  # Escape right braces
    $value =~ s/\$/\\\$/g;  # Escape dollar signs
    $value =~ s/\[/\\\[/g;  # Escape left brackets
    $value =~ s/\]/\\\]/g;  # Escape right brackets
    
    # Enclose in braces if contains spaces or special characters
    if ($value =~ /\s|[\$\[\]]/) {
      return "{$value}";
    }
    return $value;
  }
  
  # Process array references
  if (ref($data) eq 'ARRAY') {
    # Handle empty array
    if (@$data == 0) {
      return "{}";  # Empty list in Tcl
    }
    
    my @elements;
    foreach my $i (0 .. $#$data) {
      my $elem = $data->[$i];
      push @elements, to_tcl_list($elem, $indent + 1, $debug, $error_count);
    }
    
    my $result = "{ " . join(' ', @elements) . " }";
    
    # Debug: show conversion result
    _log_debug("Array converted to: $result", $indent, $debug) if $debug;
    
    return $result;
  }
  
  # Process hash references
  if (ref($data) eq 'HASH') {
    # Handle empty hash
    if (keys %$data == 0) {
      return "{}";  # Empty list in Tcl
    }
    
    my @elements;
    # Sort keys to ensure consistent output order
    foreach my $key (sort keys %$data) {
      my $value = $data->{$key};
      push @elements, to_tcl_list($key, $indent + 1, $debug, $error_count);
      push @elements, to_tcl_list($value, $indent + 1, $debug, $error_count);
    }
    
    my $result = "{ " . join(' ', @elements) . " }";
    
    # Debug: show conversion result
    _log_debug("Hash converted to: $result", $indent, $debug) if $debug;
    
    return $result;
  }
  
  # Handle unsupported reference types
  _log_error("Unsupported reference type: " . ref($data), $indent, $debug);
  $error_count->{count}++;
  return "{ unsupported_type:" . ref($data) . " }";
}

# Error logging function (auxiliary sub with underscore prefix)
sub _log_error {
  my ($message, $indent, $debug) = @_;
  return unless $debug;  # Only log errors if debug is enabled
  
  $indent //= 0;
  my $indent_str = '  ' x $indent;
  warn "${indent_str}ERROR: $message\n";
}

# Debug logging function (auxiliary sub with underscore prefix)
sub _log_debug {
  my ($message, $indent, $debug) = @_;
  return unless $debug;  # Only log debug if enabled
  
  $indent //= 0;
  my $indent_str = '  ' x $indent;
  print STDERR "${indent_str}DEBUG: $message\n";
}

# Example usage
if (0) {
  if ($0 eq __FILE__) {
    # Parse command line arguments for debug mode
    my $debug = grep { $_ eq '--debug' } @ARGV ? 1 : 0;
    my $error_count = { count => 0 };
    
    # Sample data structure
    my $sample_data = [
      "simple_value",
      "value with spaces",
      [1, 2, 3, "four"],
      {
        name => "Test",
        numbers => [10, 20, 30],
        flags => { active => 1, enabled => 0 }
      },
      undef,  # Test undefined value handling
      sub { return 1; },  # Test unsupported reference type
    ];
    
    # Convert and output
    my $tcl_output = to_tcl_list($sample_data, 0, $debug, $error_count);
    print "$tcl_output\n";
    
    # Show error statistics in debug mode
    if ($debug) {
      print STDERR "\nConversion complete. Total errors: $error_count->{count}\n";
    }
    
    # Exit with non-zero code if errors occurred
    exit $error_count->{count} > 0 ? 1 : 0;
  }
}

1;

