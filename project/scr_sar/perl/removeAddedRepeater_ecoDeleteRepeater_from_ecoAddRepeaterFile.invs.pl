#!/usr/bin/perl
# --------------------------
# author    : sar song (modified)
# date      : 2025/07/23 15:30:00 Wednesday
# label     : eco_name_extractor
# descrip   : Extract -name parameter values from ecoAddRepeater commands in ECO scripts and generate TCL scripts
# update    : 2025/07/23 - Modified to extract -name parameters and generate TCL deletion commands
# ref       : Based on original gui_proc script
# --------------------------
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

# Initialize option variables
my $help = 0;

# Process command-line options
GetOptions(
    'help|h'   => \$help
) or pod2usage(2);

# Display help information
pod2usage(1) if $help;

# Check positional arguments
my $input_file = shift @ARGV || pod2usage("Input filename is required for conversion\n");
my $output_file = shift @ARGV || "eco_name_extractor_${input_file}";

# Output option values
print "Input File: $input_file\n";
print "Output File: $output_file\n";

# Open files
open(my $in_fh, '<', $input_file) or die "Cannot open input file: '$input_file': $!";
open(my $out_fh, '>', $output_file) or die "Cannot open output file: '$output_file': $!";

# Output the beginning of the TCL variable definition
print $out_fh "set insts_name {\n";

# Process file content
while (my $line = <$in_fh>) {
    chomp $line;
    next if $line =~ /^\s*#/;  # Skip comment lines
    
    # Only process lines containing ecoAddRepeater
    if ($line =~ /ecoAddRepeater/) {
        # Extract the value after the -name parameter
        if ($line =~ /-name\s+(\S+)/) {
            my $content = $1;
            print $out_fh "$content\n";
        }
    }
}

# Output the end of the TCL variable definition and processing logic
print $out_fh "}\n";
print $out_fh <<'TCL_CODE';

proc pw {{fileId ""} {message ""}} {
  puts $message
  puts $fileId $message
}

set testOrRun "test"
foreach name $insts_name {
  set instGets [dbget top.insts.name *${name} -e]
  if { $instGets != ""} {
    if { [llength $instGets] > 1} {
      #puts "### -> name ($name) is not only one inst!!!"
      lappend notOnlyOneList "*$name"
    } elseif {[llength $instGets] == 1} {
      set cmd "ecoDeleteRepeater -inst $instGets"
      pw $cmd
      if {$testOrRun == "run"} {
        eval $cmd
      }
    }
  } else {
    lappend cantFindList "*$name"
  }
}
pw "##############################"
pw "# cant find - list"
pw [join $cantFindList \n]
pw "##############################"
pw "# not only one inst - list"
pw [join $notOnlyOneList \n]

TCL_CODE

close($in_fh);
close($out_fh);

print "Success! Please view the generated TCL script: $output_file\n";
print "This script contains -name parameter values extracted from ecoAddRepeater commands in the ECO file\n";

__END__

=head1 NAME

script.pl - Extract -name parameters from ECO scripts and generate TCL deletion commands

=head1 SYNOPSIS

script.pl [options] input_file [output_file]

  Options:
    --help, -h    Display this help message

=head1 DESCRIPTION

This script processes ECO scripts and generates TCL commands to identify and delete instances 
that match the -name parameters defined in ecoAddRepeater commands.

=head1 OPTIONS

=over 4

=item B<--help, -h>

Display help information and exit.

=back

=head1 ARGUMENTS

=over 4

=item B<input_file>

Required. Input ECO script file.

=item B<output_file>

Optional. Output TCL script file. Defaults to "eco_name_extractor_<input_file>".

=back

=cut
    
