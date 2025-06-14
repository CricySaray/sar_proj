#!/usr/bin/perl
# clocks
$status_command_list{"create_clock"}						= "pass";
$status_command_list{"create_generated_clock"}	= "pass";
$status_command_list{"set_clock_transition"}		= "comment";
$status_command_list{"set_clock_latency"}				= "comment";
$status_command_list{"set_clock_uncertainty"}		= "pass";
$status_command_list{"set_clock_groups"}				= "pass";
# interface
$status_command_list{"set_driving_cell"}				= "pass";
$status_command_list{"set_input_delay"}					= "pass";
$status_command_list{"set_input_transition"}		= "pass";
$status_command_list{"set_output_delay"}				= "pass";
$status_command_list{"set_load"}								= "pass";
# exception
$status_command_list{"set_case_analysis"}				= "pass";
$status_command_list{"set_multicycle_path"}			= "pass";
$status_command_list{"set_false_path"}					= "pass";
$status_command_list{"set_clock_sense"}					= "pass";
$status_command_list{"set_disable_timing"}			= "pass";
$status_command_list{"set_sense"}								= "pass";
$status_command_list{"set_clock_sense"}					= "pass";
# DRV
$status_command_list{"set_max_transition"}			= "pass";
$status_command_list{"set_max_fanout"}					= "pass";
$status_command_list{"set_max_capacitance"}			= "comment";
$status_command_list{"set_min_capacitance"}			= "comment"
# forbidden
$status_command_list{"set_ideal_network"}				= "comment";
$status_command_list{"set_ideal_net"}						= "comment";
$status_command_list{"set_ideal_transition"}		= "comment";
$status_command_list{"set"}											= "pass";
$status_command_list{"set_units"}								= "comment";
$status_command_list{"current_design"}					= "comment";
$status_command_list{"set_timing_derate"}				= "comment";
$status_command_list{"set_dont_use"}						= "comment";
$status_command_list{"set_dont_touch"}					= "comment";
$status_command_list{"set_dont_touch_network"}	= "comment";
$status_command_list{"group_path"}							= "comment";
$status_command_list{"set_clock_gating_check"}	= "comment";
$status_command_list{"set_fanout_load"}					= "comment";
$status_command_list{"set_port_fanout_number"}	= "comment";
$status_command_list{"set_voltage"}							= "comment";
$status_command_list{"set_operating_conditions"}= "comment";

my $wrapper_cmd = 0;
my $sdc_txt;
open(F,"$ARGV[0]");
while(<F>) {
	chomp if /\\$/;
	s/\\$//g;
	$sdc_txt .= $_;
}
close F;
my %exist_command_list;
my @sdc_cmds =split/\n/,$sdc_txt;
foreach my $cmd ( @sdc_cmds ) {
	next if $cmd =~ /^\s*$/;
	next if $cmd =~ /^\s*#/;
	my @cmd_list = split/\s+/,$cmd;
	$exist_command_list{$cmd_list[0]}++;
	if ($status_command_list{$cmd_list[0]} eq "comment") {
		if ($wrapper_cmd) {
			my $new_cmd = "# ";
			foreach my $xx (split/\s+/,$cmd) {$new_cmd .= "$xx \\\n";}	
			$new_cmd =~ s/\\$//g;
		}	
	} else {
		if ($wrapper_cmd) {
			my $new_cmd = " ";
			foreach my $xx (split/\s+/,$cmd) {$new_cmd .= "$xx \\\n";}	
			$new_cmd =~ s/\\$//g;
		}
	}
}
open(F,"$ARGV[0]");
open(N,">new.sdc");
while(<F>) {
	my $line = $_;
	my $key = (split/\s+/.$line)[0];
	if ($status_command_list{$key} eq "comment") {
		#debug# print "KEY=#$key,$status_command_list{$key}#\n";
		$line =~ s/$key/#$key/g;	
	}
	print N $line;
}
close F;
