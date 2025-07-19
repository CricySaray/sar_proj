#!/usr/bin/perl
## write_changes -format icc2tcl -out eco.icc2.tcl
## icc22invs.pt.tcl eco.icc2.tcl > eco.invs.tcl
## source -e eco.invs.tcl in innovus ECO step 
$invs_orient{FN} = "MY";
$invs_orient{FS} = "MX";
$invs_orient{S}  = "R180";
$invs_orient{N}	 = "R0";

while (<>) {
	chomp;
	$line = $_;
	if ($line =~ /^current_instance$/) {
		$hinst = "";	
	}
	if ($line =~ /^current_instance\s+\{(\S+)\}/) {
		$hinst = $1."/";	
	}
	if ($line =~ /^size_cell\s+\{(\S+)\}\s+\{(\S+)\}/) {
		$inst = $hinst.$1;
		$cell = $2;
		print "ecoChangeCell -inst \{$inst\} -cell $cell\n";
	}
	if ($line =~ /^remove_buffer\s+\[get_cells\s+\{(\S+)\}\]$/) {
		$inst = $hinst.$1;
		print "ecoDeleteRepeater -inst \{$inst\}\n";	
	}
	if ($line =~ /^set_cell_location/) {
		@lines = split " ", $line;
		$x = $lines[2];
		$x =~ s;\{;;g;
		$y = $lines[3];
		$y =~ s;\};;g;
		$orient = $lines[5];
		$inst = $lines[7];
		$inst =~ s;^\{;;g;
		$inst =~ s;\]$;;g;
		$inst =~ s;\}$;;g;
		$inst =~ s?.*\/??g;
		$inst = $hinst.$inst;
		print "placeInstance \{$inst\} $x $y $invs_orient{$orient} -placed\n";
	}
	if ($line =~ /^add_buffer_on_route/) {
		$line =~ /^add_buffer_on_route \[get_net -of \{(\S+)\}\] -user_specified_buffers \{ (.*)\} -no_legalize/;
		$pin = $hinst.$1;
		$buffer_pattern = $2;
		@buffer_patterns = split " ", $buffer_pattern;
		#multi buffer case
		$i = 0;
		foreach (@buffer_patterns) {
			if ($i%5 == "0") { $new_inst = $_; }
			if ($i%5 == "1") { $cell = $_; }
			if ($i%5 == "2") { $x = $_; }
			if ($i%5 == "3") { $y = $_; }
			if ($i%5 == "4") {
				$hinstGuide = $hinst;
				$hinstGuide =~ s;/$;;g;
				print "ecoAddRepeater -net [join [dbget [dbget -p top.insts.instTerms.name \{$pin\}].net.name]] -cell $cell -name $new_inst -hinstGuide \{$hinstGuide\} -loc \{$x $y\}\n";
			}	
			$i++;
		}	
	}

	if ($line =~ /^insert_buffer/) {
		@lines = split " ", $line;
		$pin = $lines[2];
		$cell = $lines[3];
		$new_net = $lines[5];
		$new_inst = $lines[7];
		if ($#lines == "7") {
			$eco_type = "logic";	
		}	
		if ($#lines == "10") {
			$eco_type = "logic";
			$new_net = "{$lines[6] $lines[7]}";
			$new_inst = "{$lines[9] $lines[10]}";	
		}
		if ($#lines == "12") {
			$eco_type = "physical";	
		}
		if ($eco_type =~ "physical") {
			$x = $lines[9];
			$y = $lines[10];
			$orient = $lines[12];
			$x =~ s;^{;;g;
			$y =~ s;}$;;g;	
		}
		$pin =~ s;^{;;g;
		$pin =~ s;\}\]$;;g;
		$pin = $hinst.$pin;
		$new_net =~ s;^{;;g;
		$new_net =~ s;}$;;g;
		$new_inst =~ s;^{;;g;
		$new_inst =~ s;}$;;g;
		if ($#lines == "10") {
			$new_net = "$lines[6] $lines[7]";
			$new_inst = "$lines[9] $lines[10]";	
		}
		$hinstGuide = $hinst;
		$hinstGuide =~ s;/$;;g;
		if ($eco_type =~ "logic") {
			print "ecoAddRepeater -term \{$pin\} -cell $cell -hinstGuide \{$hinstGuide\} -name $new_inst -newNetName $new_net -loc [dbget [dbget -p top.insts.instTerms.name \{$pin\}].pt]\n";	
		}
		if ($eco_type =~ "physical") {
			if (defined($orient)) {
				print "ecoAddRepeater -term \{$pin\} -cell $cell -hinstGuide \{$hinstGuide\} -name $new_inst -newNetName $new_net -loc \{$x $y\} -bufOrient $invs_orient{$orient}\n";	
			}	else {
				print "ecoAddRepeater -term \{$pin\} -cell $cell -hinstGuide \{$hinstGuide\} -name $new_inst -newNetName $new_net -loc \{$x $y\}\n";	
			}
		}
	}
}
