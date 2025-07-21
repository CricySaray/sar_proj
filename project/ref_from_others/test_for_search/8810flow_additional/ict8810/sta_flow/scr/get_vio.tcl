#! /usr/bin/tclsh 
set file "$REPORTS_DIR/${DESIGN_NAME}_dmsa_report_global_timing_${check}.${VIEW}.pba.report"
if {[file exists $file]} {
set file_id_r [open $file r]
set r2r_wns "0.000"
set io_wns "0.000"
set r2r_tns "0.000"
set io_tns "0.000"
set r2r_num "0"
set io_num "0"

while {[gets $file_id_r line] != "-1"} {
	
	if {[regexp {^WNS(\s+)(\S*)(\s+)(\S*)(\s+)(\S*)(\s+)(\S*)(\s+)(\S*)} $line full_line temp1 total temp2 r2r temp3 i2r temp4 r2o temp5 i2o] ==1} {
	set r2r_wns $r2r
	if {$i2r > $r2o} {
	set io_wns $r2o
	} else {
	set io_wns $i2r
	}
	if {$i2o < $io_wns } {
	set io_wns $i2o
	}
	
} elseif {[regexp {^TNS(\s+)(\S*)(\s+)(\S*)(\s+)(\S*)(\s+)(\S*)(\s+)(\S*)} $line full_line temp1 total temp2 r2r temp3 i2r temp4 r2o temp5 i2o] ==1} {
	
	set r2r_tns $r2r
	set io_tns [expr $i2r + $r2o + $i2o]
} elseif {[regexp {^NUM(\s+)(\S*)(\s+)(\S*)(\s+)(\S*)(\s+)(\S*)(\s+)(\S*)} $line full_line temp1 total temp2 r2r temp3 i2r temp4 r2o temp5 i2o] ==1} {
	set r2r_num $r2r
	set io_num [expr $i2r + $r2o + $i2o]
	break
}
}
 close $file_id_r
}
set dltype_r2r_wns $r2r_wns
set dltype_r2r_tns $r2r_tns
set dltype_r2r_num $r2r_num
set dltype_io_wns  $io_wns
set dltype_io_tns $io_tns
set dltype_io_num $io_num
#puts "r2r setup vio: $r2r_wns/$r2r_tns ($r2r_num)"
#puts "io setup vio: $io_wns/$io_tns ($io_num)"


set file  "$REPORTS_DIR/${DESIGN_NAME}_report_constrain.${VIEW}.report"
if {[file exist $file ]} {
set count 0
set slack 0
set slack_max 0
set cap_found 0
set file_id_r [open $file r]
while {[gets $file_id_r line ] != "-1"} {
if {[regexp {(\s+)max_capacitance} $line full_line temp1 count11 tempt2 wns] == "1"} {
set cap_found 1
break
}
}
if { $cap_found } {
while {[gets $file_id_r line] != "-1"} {
if {[regexp {\-\-\-\-\-\-\-\-\-\-} $line] ==1} {break}
}


while {[gets $file_id_r line] != "-1"} {
if {[regexp {(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)\(VIOLATED} $line full_line path temp1 req temp2 act temp3 slack] ==1} {
if {$count == 0} {set slack_max $slack}
set  count [expr $count + 1]
} else {break}
}
}
close $file_id_r
#puts "max_cap vio: $slack_max /  $count"
set cap_max_slack $slack_max
set cap_vio_num $count
}




set file  "$REPORTS_DIR/${DESIGN_NAME}_report_constrain.${VIEW}.report"
if {[file exist $file ]} {
set count 0
set slack 0
set slack_max 0
set trans_found 0
set file_id_r [open $file r]
while {[gets $file_id_r line ] != "-1"} {
if {[regexp {(\s+)max_transition} $line full_line temp1 count11 tempt2 wns] == "1"} {
set trans_found 1
break
}
}

if {$trans_found} {
while {[gets $file_id_r line] != "-1"} {
if {[regexp {\-\-\-\-\-\-\-\-\-\-} $line] ==1} {break}
}

while {[gets $file_id_r line] != "-1"} {
if {[regexp {(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)\(VIOLATED} $line full_line path temp1 req temp2 act temp3 slack] ==1} {
if {$count == 0} {set slack_max $slack}
set  count [expr $count + 1]
} else {break}
}
}
close $file_id_r
#puts "max_trans vio: $slack_max /  $count"
set trans_max_slack $slack_max
set trans_vio_num $count
}



set file  "$REPORTS_DIR/${DESIGN_NAME}_report_constrain.${VIEW}.report"
if {[file exist $file ]} {
set count 0
set slack 0
set slack_max 0
set min_perid_found 0
set file_id_r [open $file r]
while {[gets $file_id_r line ] != "-1"} {
if {[regexp {(\s+)sequential_clock_min_period} $line full_line temp1 count11 tempt2 wns] == "1"} {
set min_perid_found 1
break
}
}

if {$min_perid_found} {
while {[gets $file_id_r line] != "-1"} {
if {[regexp {\-\-\-\-\-\-\-\-\-\-} $line] ==1} {break}
}

while {[gets $file_id_r line] != "-1"} {
if {[regexp {(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)\(VIOLATED} $line full_line path temp1 req temp2 act temp3 slack] ==1} {
if {$count == 0} {set slack_max $slack}
set  count [expr $count + 1]
} else {break}
}
}
close $file_id_r
#puts "min_period vio: $slack_max /  $count"
set min_perid_vio $slack_max
set min_perid_num $count
}




set file  "$REPORTS_DIR/${DESIGN_NAME}_report_constrain.${VIEW}.report"
if {[file exist $file ]} {
set count 0
set slack 0
set slack_max 0
set min_pulse_found 0
set file_id_r [open $file r]
while {[gets $file_id_r line ] != "-1"} {
if {[regexp {(\s+)clock_tree_pulse_width} $line full_line temp1 count11 tempt2 wns] == "1"}  {
set min_pulse_found 1
break
}
}
if {$min_pulse_found} {
while {[gets $file_id_r line] != "-1"} {
if {[regexp {\-\-\-\-\-\-\-\-\-\-} $line] ==1} {break}
}

while {[gets $file_id_r line] != "-1"} {
if {[regexp {(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)\(VIOLATED} $line full_line path temp1 req temp2 act temp3 slack] ==1} {

if {$count == 0} {set slack_max $slack}
set  count [expr $count + 1]
} else {break}
}
}
close $file_id_r
#puts "min_pulse_width vio: $slack_max /  $count"
set min_pulse_slack $slack_max
set min_pulse_num $count
}


set file  "$REPORTS_DIR/${DESIGN_NAME}_report_constrain.${VIEW}.report"
if {[file exist $file ]} {
set count 0
set slack 0
set slack_max 0
set sequential_clock_pulse_width_found 0
set file_id_r [open $file r]
while {[gets $file_id_r line ] != "-1"} {
if {[regexp {(\s+)sequential_clock_pulse_width} $line full_line temp    1 count11 tempt2 wns] == "1"}   {
set sequential_clock_pulse_width_found 1
break
}
}
if {$sequential_clock_pulse_width_found} {
while {[gets $file_id_r line] != "-1"} {
if {[regexp {\-\-\-\-\-\-\-\-\-\-} $line] ==1} {break}
}

while {[gets $file_id_r line] != "-1"} {
if {[regexp {(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)\(VIOLATED} $line full_line path temp1 req temp2 act temp3 slack] ==1} {

if {$count == 0} {set slack_max $slack}
set  count [expr $count + 1]
} else {break}
}
}
close $file_id_r
#puts "sequential_clock_pulse_width_found vio: $slack_max /  $count"
set sequential_clock_pulse_slack $slack_max
set sequential_clock_pulse_num $count
}





set file  "$REPORTS_DIR/${DESIGN_NAME}_report_noise_all_viol.${VIEW}.report"
if {[file exist $file ]} {
set count 0
set slack 0
set file_id_r [open $file r]
set max_slack 0



while {[gets $file_id_r line ] != "-1"} {
if {[regexp {^\s(\S+)\s\((\S+)\)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)$} $line full_line temp1 tempt2 temp3 temp4 temp5 temp6 temp7  slack] == "1"} {
if {$max_slack > $slack} {set max_slack  $slack}
incr count
}
}
close $file_id_r
#puts "noise_vio: $max_slack  / $count" 
set noise_slack $max_slack
set noise_num $count
}

################ double switching si ##########
set file  "$REPORTS_DIR/${DESIGN_NAME}_report_si_double_switching.${VIEW}.report"
if {[file exist $file ]} {
set count 0
set slack 0
set file_id_r [open $file r]
set max_slack 0

while {[gets $file_id_r line ] != "-1"} {
if {[regexp {^\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+\((\S+)\)$} $line full_line temp1 tempt2 temp3 temp4   slack] == "1"} {
if {$max_slack > $slack} {set max_slack  $slack}
incr count
}
}
close $file_id_r
#puts "noise_vio: $max_slack  / $count" 
set si_double_switching $max_slack
set si_double_switching_num $count
}
#############


echo  "${mode}_${corner}_${check}  r2r: $dltype_r2r_wns / $dltype_r2r_tns / $dltype_r2r_num ---  io: $dltype_io_wns / $dltype_io_tns / $dltype_io_num --- max cap: $cap_max_slack / $cap_vio_num --- max trans: $trans_max_slack / $trans_vio_num --- min period: $min_perid_vio / $min_perid_num  --- min_pulse: $min_pulse_slack / $min_pulse_num --- sequential_clock_pulse: $sequential_clock_pulse_slack / $sequential_clock_pulse_num ---noise: $noise_slack / $noise_num  ---- si_double_switching: $si_double_switching / $si_double_switching_num "
