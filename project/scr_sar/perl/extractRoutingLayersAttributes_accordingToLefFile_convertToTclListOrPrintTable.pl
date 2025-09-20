#!/bin/perl
# --------------------------
# author    : sar song
# date      : 2025/09/20 10:28:19 Saturday
# label     : perl_task
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|misc_proc)
#   perl -> (format_sub|perl_task)
# descrip   : Pass in the absolute path of the techlef file. You can use the `type` variable to select how to process the data. If the type is `list`, the Perl script 
#             will return a value in the form of a list in Tcl. You can use a Tcl command to retrieve this string, and then use the `{*}` format to expand it, which 
#             allows it to be used as the value of a list. If the type is `table`, Perl will print a table on the screen to display the retrieved information.
# return    : list string of tcl format
#           or
#             print table in window
# ref       : link url
# --------------------------
require ./sub_toTclList_fromPerlDataType.pl; # to_tcl_list
require ./sub_extractRoutingLayersAttributes_accordingToLefFile.pl; # extract_routing_layers
require ./sub_gen_table.pl; # gen_table
use warnings;
use strict;
use Getopt::Long;  
my $type_ofPrintTableOrConvertToTclList;
my $techlef_file;
my $debug;
GetOptions(
    'type=s'  => \$type_ofPrintTableOrConvertToTclList,   
    'file=s'  => \$techlef_file,
    'debug'   => \$debug,
) or die "check your input: \n\tusage format: $0 -type <string> -file <string> [-debug]\n";
die "perl program $0: must input techlef filename" unless defined $techlef_file;

$type_ofPrintTableOrConvertToTclList //= "list"; # list|table
$debug //= 0;
die "perl program $0: type value must be one of between 'list' and 'table' !!!" unless grep {$type_ofPrintTableOrConvertToTclList eq $_} qw/list table/;
my $routingLayersInfoRef = extract_routing_layers($techlef_file, $debug);
if ($type_ofPrintTableOrConvertToTclList eq "list") {
  my $toListString = to_tcl_list($routingLayersInfoRef, 0, $debug);
  print "$toListString\n";
} elsif ($type_ofPrintTableOrConvertToTclList eq "table") {
  print gen_table("", $routingLayersInfoRef);
} 
