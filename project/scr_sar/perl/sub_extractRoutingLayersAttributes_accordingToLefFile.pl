#!/bin/perl
# --------------------------
# author    : sar song
# date      : 2025/09/20 12:24:35 Saturday
# label     : getInfo_sub
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : Extract information for each metal layer from the techlef file, focusing solely on the attribute information of routable layers—such as layer name, routing 
#             direction, pitch value, minimum width, and minimum spacing. Subsequently, return this information in the form of a nested array, which facilitates conversion 
#             into list-format data usable in Tcl.
# return    : Array reference  : \@arrayReference
# ref       : link url
# --------------------------
sub extract_routing_layers {
  my ($techlef_file, $debug) = @_;
  
  # Initialize debug flag with default value
  $debug = 0 unless defined $debug;
  if ($debug !~ /^[01]$/) {
    die "Error: Invalid debug value (must be 0 or 1)\n";
  }
  
  # Result array with header: layerName, direction, pitch, width, spacing
  my @result = ( 
    [ "layerName", "direction", "pitch", "width", "spacing" ] 
  );
  
  if ($debug) {
    print "Debug mode enabled. Processing file: $techlef_file\n";
  }
  
  # Check if file exists (fatal error if not)
  unless (-e $techlef_file) {
    die "Error: File $techlef_file not found!\n";
  }
  
  # Check if file is readable (fatal error if not)
  unless (-r $techlef_file) {
    die "Error: File $techlef_file is not readable!\n";
  }
  
  # Read file content with error handling (fatal on failure)
  my $content;
  if ($debug) {
    print "Attempting to read file content...\n";
  }
  
  eval {
    open my $fh, '<', $techlef_file or die "Cannot open file: $!";
    local $/;  # Slurp mode to read entire file
    $content = <$fh>;
    close $fh or die "Error closing file: $!";
  };
  
  if ($@) {
    die "Fatal error reading file: $@";
  }
  
  if ($debug) {
    my $length = length $content;
    print "Successfully read file content (size: $length bytes)\n";
  }
  
  # Check for empty file (fatal error)
  if ($content =~ /^\s*$/) {
    die "Error: File $techlef_file is empty!\n";
  }
  
  # Extract all layer definitions using robust regex
  my @layers;
  my $offset = 0;
  my $content_len = length $content;
  
  # Regex pattern components:
  # - Match LAYER declaration line and capture layer name
  # - Capture all content between LAYER and END
  # - Match END line with corresponding layer name
  my $layer_pattern = qr/
    ^\s*LAYER\s+(\S+)\s*$
    (.*?)
    ^\s*END\s+\1\s*$
  /xms;
  
  # Iterate to find all layer definitions
  while ($offset < $content_len) {
    if ($content =~ /$layer_pattern/gc) {
      my $layer_name = $1;
      my $layer_content = $2;
      push @layers, {
        full_match => $&,
        name => $layer_name,
        content => $layer_content
      };
      $offset = pos $content;
      if ($debug) {
        print "Found layer definition: $layer_name\n";
      }
    } else {
      last;
    }
  }
  
  # Fatal error if no layers found (valid LEF should have layers)
  if (!@layers) {
    die "Fatal error: No valid layer definitions found in $techlef_file\n";
  }
  
  my $total_layers = scalar @layers;
  my $routing_layer_count = 0;
  
  if ($debug) {
    print "Found $total_layers total layer definitions to process\n";
  }
  
  # Process each layer
  foreach my $layer (@layers) {
    my $layer_name = $layer->{name};
    my $layer_content = $layer->{content};
    
    if ($debug) {
      print "\nProcessing layer: $layer_name\n";
      my $snippet = substr($layer_content, 0, 100);
      $snippet =~ s/\n/ /g;
      print "Layer content snippet: $snippet...\n";
    }
    
    # Check if this is a routing layer
    if ($layer_content =~ /^\s*TYPE\s+ROUTING\s*;/im) {
      $routing_layer_count++;
      
      if ($debug) {
        print "Confirmed as ROUTING layer\n";
      }
      
      # Extract required properties using helper subroutine
      # Use "/" for any missing properties
      my $direction = _get_property($layer_content, "DIRECTION", $debug) // "/";
      my $pitch = _get_property($layer_content, "PITCH", $debug) // "/";
      my $width = _get_property($layer_content, "WIDTH", $debug) // "/";
      my $spacing = _get_property($layer_content, "SPACING", $debug) // "/";
      
      # Always add the routing layer, even if all properties are missing
      push @result, [ $layer_name, $direction, $pitch, $width, $spacing ];
      
      if ($debug) {
        my @missing;
        push @missing, "DIRECTION" if $direction eq "/";
        push @missing, "PITCH" if $pitch eq "/";
        push @missing, "WIDTH" if $width eq "/";
        push @missing, "SPACING" if $spacing eq "/";
        
        if (@missing) {
          print "Warning: Layer $layer_name has missing properties: " . join(", ", @missing) . "\n";
        } else {
          print "Successfully added complete layer data to results\n";
        }
      }
    } elsif ($debug) {
      print "Not a ROUTING layer, skipping\n";
    }
  }
  
  # Fatal error if no routing layers found
  if ($routing_layer_count == 0) {
    die "Fatal error: No routing layers found in the file. Please check if this is a valid techlef file.\n";
  }
  
  if ($debug) {
    print "\nExtraction complete. Found $routing_layer_count routing layers out of $total_layers total layers\n";
  }
  
  return \@result;
}

# Helper subroutine to extract specific properties
# Parameters: layer content string, property name, debug flag
# Returns: property value if found and valid, undef otherwise
sub _get_property {
  my ($layer_content, $property_name, $debug) = @_;
  
  # Regex pattern with word boundaries for precise matching
  # Looks for property name followed by value and semicolon
  my $pattern = qr/^\s*\b$property_name\b\s+(\S+)\s*;/im;
  
  if ($debug) {
    print "Searching for property: $property_name with pattern: $pattern\n";
  }
  
  if ($layer_content =~ $pattern) {
    my $value = $1;
    
    # Validate based on property type
    if ($property_name eq "DIRECTION") {
      # Direction must be VERTICAL or HORIZONTAL (case-insensitive)
      if ($value =~ /^VERTICAL$/i) {
        $value = "VERTICAL";  # Normalize to uppercase
        if ($debug) {
          print "Successfully extracted $property_name: $value\n";
        }
        return $value;
      } elsif ($value =~ /^HORIZONTAL$/i) {
        $value = "HORIZONTAL";  # Normalize to uppercase
        if ($debug) {
          print "Successfully extracted $property_name: $value\n";
        }
        return $value;
      } else {
        if ($debug) {
          print "Invalid value for $property_name: $value (must be VERTICAL or HORIZONTAL)\n";
        }
        return undef;
      }
    } else {
      # Numeric validation for other properties (PITCH, WIDTH, SPACING)
      if ($value =~ /^[+-]?\d+(\.\d+)?$/) {
        if ($debug) {
          print "Successfully extracted $property_name: $value\n";
        }
        return $value;
      } else {
        if ($debug) {
          print "Invalid numeric value for $property_name: $value\n";
        }
        return undef;
      }
    }
  }
  
  if ($debug) {
    print "Property $property_name not found\n";
  }
  return undef;
}
1;
