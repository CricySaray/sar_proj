#################################################
# Description : Common proc
# Auther      : David
# Versiont    : 1.0.0 2024/12/1
#################################################
# report head
proc reportHead {args} {
	parse_proc_arguments -args $args results

	if {[info exists results(-file)]} {
		set report $results(-file)
	}
	if {[info exists results(-item)]} {
		set Items $results(-item)
	}

	set rpt [open $report w]
	puts $rpt "[string repeat # 100]"
	puts $rpt "# Date :      [exec date]"
	puts $rpt "# Design:     [get_object_name [get_designs]]"
	puts $rpt "# Items:      $Items"
	puts $rpt "# Auther:     Seeman"
	puts $rpt "[string repeat # 100]"
	close $rpt
}
define_proc_attributes reportHead \
	-info "specify the report head information" \
	-define_args {
		{-item "Specify the check item." "" "string" optional} \
        {-file "Specify the report file name." "" "string" optional} \
}

# run time
proc runTime {stage start} {
	set seconds    0
	set minutes    0
	set hours      0
	set days       0

	set run_time      [expr [clock seconds] - $start]
	set days          [expr $run_time / 86400]
	set total_seconds [expr $run_time % 86400]

	set hours         [expr $total_seconds / 3600]
	set total_seconds [expr $total_seconds % 3600]

	set minutes       [expr $total_seconds / 60]
	set total_seconds [expr $total_seconds % 60]

	set seconds       $total_seconds

	set summary   [format "%-40s%-d days, %-02d:%-02d:%-02d" $stage $days $hours $minutes $seconds]
	puts $summary 
}
proc get_drivePin {pinName} {
    set drivePin   [get_attr [get_pins -of [get_nets -of [get_pins $pinName]] -leaf -q -filter "direction == out"] full_name]
    if {$drivePin == ""} {
        set drivePin outPut
    }
    return $drivePin
}
proc report_cell_info {ptn} {
    set cell_list [get_cells -quiet -hier * -filter "$ptn"]
    set all_cell_num [sizeof [get_cells -quiet -hier * -filter "is_hierarchical == false"]]
    set num 0
    set area 0
    set ratio 0
    if {$cell_list != ""} {
        set num [sizeof $cell_list]
        set area [expr [join [get_attribute $cell_list area] {+}]]
        set ratio [format "%5.2f" [expr $num *100.0/$all_cell_num]]
    }
    return [list $num $area $ratio]
}
proc get_all_clk_info_dict {} {
	set all_clk_dict ""
	foreach clk [get_attr [all_clocks] full_name] {
        set clkInfo_dict ""
        set source_point [get_attr [get_attribute [get_clocks $clk] sources] full_name]
        if {$source_point == ""} {
            set load_num 0
            #puts "[get_object_name [get_clocks $clk]] is a virtual clock"
            set clockAttr                          "virtual"
            set source_point "NA"
        } else {
            set load_num [sizeof_collection [all_fanout -from  [get_attribute [get_clocks $clk] sources] -flat -end]]
            set clockAttr                          "real"
        }
        if {[get_attribute [get_clocks $clk] period] == ""} {
            set period 0
            set frequency 0
            set setup_margin [get_attribute [get_clocks $clk] setup_uncertainty]
            set setup_margin [format "%.3f" $setup_margin]
            set setup_ratio 0
            set setup_uncertainty 0
            if {$setup_margin==0} {
                incr setup_uncertainty_flag 1
            }
            set hold_margin  [get_attribute [get_clocks $clk] hold_uncertainty]
            set hold_margin [format "%.3f" $hold_margin]
            set hold_ratio 0
            set hold_uncertainty 0
        } else {
            set period [get_attribute [get_clocks $clk] period]
            set period [format "%.3f" $period]
            set frequency [format "%.0fM" [expr 1000/$period]]
            set setup_margin [get_attribute [get_clocks $clk] setup_uncertainty]
            set setup_margin [format "%.3f" $setup_margin]
            set setup_ratio [format "%.2f" [expr $setup_margin*100.0/$period]]
            set setup_uncertainty "$setup_margin (${setup_ratio}%)"
            if {$setup_margin==0} {
                incr setup_uncertainty_flag 1
            }
            set hold_margin  [get_attribute [get_clocks $clk] hold_uncertainty]
            set hold_margin [format "%.3f" $hold_margin]
            set hold_ratio [format "%.2f" [expr $hold_margin*100.0/$period] ]
            set hold_uncertainty "$hold_margin (${hold_ratio}%)"
        }
        if {$hold_margin==0} {
            incr hold_uncertainty_flag 1
        }
        set trans_margin_r [get_attribute [get_clocks $clk] max_transition_clock_path_rise]
        if {$trans_margin_r == ""} {set trans_margin_r 0}
        set trans_margin_r [format "%.3f" $trans_margin_r]
        if {$trans_margin_r==0} {incr rise_transition_flag 1}
        set trans_margin_f [get_attribute [get_clocks $clk] max_transition_clock_path_fall]
        if {$trans_margin_f == ""} {set trans_margin_f 0}
        set trans_margin_f [format "%.3f" $trans_margin_f]
        if {$trans_margin_f==0} {incr fall_transition_flag 1}
        set clock_transition "$trans_margin_r/$trans_margin_f"
        set is_generated [get_attr [get_clocks $clk] is_generated]
        if {$is_generated == "true"} {set clock_type G } else {set clock_type M}
        #-------------------------------------------------------------------------------------------------------------------------------
        dict lappend clkInfo_dict  clock_transition          $clock_transition
        dict lappend clkInfo_dict  clock_type                $clock_type
        dict lappend clkInfo_dict  hold_uncertainty          $hold_uncertainty
        dict lappend clkInfo_dict  setup_uncertainty         $setup_uncertainty
        dict lappend clkInfo_dict  frequency                 $frequency
        dict lappend clkInfo_dict  period                    $period
        dict lappend clkInfo_dict  clockAttr                 $clockAttr
        dict lappend clkInfo_dict  loadNum                   $load_num
        dict lappend clkInfo_dict  sourcePoint               $source_point
        dict  append all_clk_dict  $clk                      $clkInfo_dict
        #-------------------------------------------------------------------------------------------------------------------------------
    }
    return $all_clk_dict
}

proc check_generated_clock {clockName} {
	set all_clk_dict [get_all_clk_info_dict]
    if { [sizeof_collection [get_attribute [get_clocks $clockName  ]  generated_clocks -quiet]] != 0  } {
        foreach generated_clock [get_attr [get_attribute [get_clocks $clockName  ]  generated_clocks] full_name] {
            set temp_dict ""
            set temp_dict [dict get [dict filter $all_clk_dict value *real*] $generated_clock]
            set freq               [dict get $temp_dict frequency]
            set nu_sink            [dict get $temp_dict loadNum]
            set setup_uncer        [dict get $temp_dict setup_uncertainty]
            set hold_uncer         [dict get $temp_dict hold_uncertainty]
            set soucePoint         [dict get $temp_dict sourcePoint]
            set period             [dict get $temp_dict period]
            set clock_transition   [dict get $temp_dict clock_transition]
            puts [format "  %-48s %-15s %-15s %-15s %-25s %-25s %-25s %-30s" G:$generated_clock $period $freq $nu_sink $setup_uncer $hold_uncer $clock_transition $soucePoint] 
        check_generated_clock $generated_clock
        }
    }
}
proc read_blkGen_file {fileName} {
    set filelines ""
    set fp [open $fileName r]
    while {![eof $fp]} {
        gets $fp line
        if {$line != "" && ![regexp Error|error_info|Warning $line]} {
            lappend filelines $line
        }
    }
    close $fp
    return $filelines
}
proc get_hierPin_arrival_time {hierPin temp_tp} {
	set arrival_time_list [get_attr [get_attr $temp_tp points] arrival]
	set hierPin_list [get_attr [get_attr [get_attr $temp_tp points] object] full_name]
	set pin_loc [getloc_list2list $hierPin $hierPin_list]
	set pinArrival_time [lindex $arrival_time_list $pin_loc]
	return $pinArrival_time
	if {$hierPin == ""} {return NA}
}
proc getloc_list2list {lista listb} {
    foreach a $lista {
        set loc [lsearch -exact $listb $a]
        if {$loc != "-1"} {
            return $loc
        }
    }
}
proc RandomRange {min max} {
    set rd [expr rand()]
    set result [format %.4f [expr $rd * ($max - $min) + $min]]
    return $result
}
proc get_ioDelay_top {top_temp_tp hierPortname hierPort_direction} {
    set net_driverPin [get_attr [get_pins -of [get_nets -of [get_pins $hierPortname] -boundary_type both -q] -leaf -filter "direction == out" -q] -q full_name]
    set net_loadPin [get_attr [get_pins -of [get_nets -of [get_pins $hierPortname ] -boundary_type both -q] -leaf -filter "direction == in" -q] full_name]
    set net_loadPin ""
    set loadpinTime [get_hierPin_arrival_time $net_loadPin $top_temp_tp]
    set driverpinTime [get_hierPin_arrival_time $net_driverPin $top_temp_tp]
    set arrival_time [lindex [get_attr  [get_attr $top_temp_tp points] arrival ] end]

    if {$net_driverPin != "" && $net_loadPin != ""} {
            set hierPort_arrival_time [expr ($loadpinTime + $driverpinTime) * 0.5]
    } elseif {$net_driverPin == "" && $net_loadPin != ""} {
            set hierPort_arrival_time $loadpinTime
    } elseif {$net_driverPin != "" && $net_loadPin == ""} {
            set hierPort_arrival_time $driverpinTime
    } else {
            set hierPort_arrival_time NA
    }
    if {$hierPort_direction == "in"}  {set ioDelay $hierPort_arrival_time}
    if {$hierPort_direction == "out"}  {set ioDelay [expr $arrival_time - $hierPort_arrival_time]}
    if {$hierPort_arrival_time == "NA"} {set ioDelay NA}
    return $ioDelay
}

namespace eval design:: {
	#############################################
	# Description    : Check Cross Clock
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
    #  check_timing -include {clock_crossing} -exclude {no_clock no_input_delay unconstrained_endpoints generic latch_fanout loops generated_clocks data_check_multiple_clock no_driving_cell unexpandable_clocks partial_input_delay pulse_clock_non_pulse_clock_merge pll_configuration} -verbose > xxx
	proc check_timing_cross_clock {args} {
		parse_proc_arguments -args $args results

		set TOP   [get_object_name [get_designs]]
		if {[info exists results(-save_dir)]} {
			set rpt_dir $results(-save_dir)
		} else {
			set rpt_dir [pwd]
		}
    	#if {![info exists DesignInfo_DF]} {global array set DesignInfo_DF}
		if {[file exist ${rpt_dir}/check_timing_cross_clock]} {
			sh rm -rf ${rpt_dir}/check_timing_cross_clock
		}
		sh mkdir -p ${rpt_dir}/check_timing_cross_clock
		sh mkdir -p ${rpt_dir}/check_timing_cross_clock/detail_rpt
		echo "#" > ${rpt_dir}/check_timing_cross_clock/check_cross_clk_summary.rpt

		proc get_clockSource {clockName} {
			while {[get_attr [get_clocks $clockName] master_clock -q] != ""} {
				set clockName [get_attr [get_attr [get_clocks $clockName] master_clock ] full_name]
			}
			return $clockName
		}
		set fileName ${rpt_dir}/check_timing_cross_clock.rpt
		set f [open $fileName r]
		set flag 0
		while {![eof $f]} {
			gets $f line
            puts $line
			if {$flag == "0"} {set flag [ regexp "\-\-\-\-\-\-\-\-" $line]}
			if {$flag == "1"} {if {[ regexp "voltage_level" $line]} {set flag 0} }
			if {$flag == "1"} {if {[ regexp "check_timing succeeded" $line]} {set flag 0}}
			if {$flag == 1} {
				if {[regexp "\-\-\-" $line]} {continue}
				if {"" == $line} {continue}
				set from_clk [lrange $line 0 0]
				set from_clk_master [get_clockSource $from_clk]
				if {$from_clk_master == ""} {set from_clk_master $from_clk}
				set cross_clk_master ""
				set cross_clk [lrange $line 1 end]
				set ac_clk  ""
				set dif_clk ""
				set tru_clk ""
				foreach clk $cross_clk {
					set reg [regexp {\*|\#|\#,|\*,} $clk]
					if {$reg == 0} {
						set clk [regsub , $clk ""] ;lappend ac_clk $clk
						set master_clock [get_clockSource $clk]
						set reg1 [regexp $from_clk_master|$from_clk $master_clock]				
						if {$reg1 == 0} { lappend dif_clk $clk}
						if {$reg1 == 1} { lappend tru_clk $clk}
					}
				}
				if {[llength $dif_clk] != 0} {
					echo "[format "%-90s %-10s" "$from_clk" "$dif_clk"]" >> ${rpt_dir}/check_timing_cross_clock/check.rpt
				}
		
				if {[llength $tru_clk] != 0} {
					echo "[format "%-90s %-10s" "$from_clk" "$tru_clk"]" >> ${rpt_dir}/check_timing_cross_clock/check_cross_clk_summary_warning.rpt
				}
			}
		}
		close $f
		set fileName ${rpt_dir}/check_timing_cross_clock/check.rpt
		if {[file exists $fileName]} {
			echo "<fromClk> (freq:fromClk) (sourceClkName:freq)" >> ${rpt_dir}/check_timing_cross_clock/check_cross_clk_summary.rpt
			echo "<toClk> (freq:toClk) (wns:tns:num_vio:num_all) (sourceClkName:freq)" >> ${rpt_dir}/check_timing_cross_clock/check_cross_clk_summary.rpt
			echo "# INFO: details" > ${rpt_dir}/check_timing_cross_clock/cross_clock_report_timing.rpt 
			set check_timing_cross_clock_num 0
			set f [open $fileName r]
			while {![eof $f]} {
				gets $f line
				if {$line == ""} {continue}
				set from_clk [lrange $line 0 0]
				if {[get_attr [get_clocks $from_clk ] sources ] == ""} {continue}
				set cross_clk [lrange $line 1 end]
				set cross_clk_num [llength $cross_clk]
				if {$cross_clk_num != 0} { 
					set from_per [get_attribute [get_clocks $from_clk] period -q ]
					set from_fre [expr 1 / $from_per]
					set from_clk_sou [get_clockSource $from_clk]
					set from_clk_sou_per [get_attribute [get_clocks $from_clk_sou] period]
					set from_clk_sou_fre [expr 1 /$from_clk_sou_per]
					echo "[format "%-10s %-10s %-10s %-10s" "< $cross_clk_num" "$from_clk" "(freq:$from_fre)" "($from_clk_sou :$from_clk_sou_fre)"]" >> ${rpt_dir}/check_timing_cross_clock/check_cross_clk_summary.rpt
					foreach clk $cross_clk {
						if {[get_attr [get_clocks $clk ] sources ] == ""} {continue}
						set to_per   [get_attribute [get_clocks $clk] period]
						set to_fre [expr 1 / $to_per]
						set to_clk_sou [get_clockSource $clk]	
						set to_clk_sou_per [get_attribute [get_clocks $to_clk_sou] period]
						set to_clk_sou_fre [expr 1/ $to_clk_sou_per]
						set qw [get_timing_paths -from [get_clocks $from_clk] -to [get_clocks $clk]  -max_paths 99999 -slack_lesser_than 0]
						set qw_all [get_timing_paths -from [get_clocks $from_clk] -to [get_clocks $clk] -max_paths 99999 -slack_lesser_than 1000]
						set num_vio [sizeof_collection $qw]
						set num_all [ sizeof_collection $qw_all]
						if {$num_vio == 0} {set wns 0 ;set tns 0 }
						if {$num_vio != 0} {
							set slack [get_attribute $qw slack]
							set wns [lindex $slack 0]
							set tns [expr [join $slack +]]
						}
						echo "[format "%-10s %-10s %-10s %-10s" "           $clk" "(freq:$to_fre)" "($wns:$tns:$num_vio:$num_all)" "($to_clk_sou:$to_clk_sou_fre)" ]"	>> ${rpt_dir}/check_timing_cross_clock/check_cross_clk_summary.rpt
						echo "set_false_path -from  \[get_clocks $from_clk\] -to \[get_clocks $clk\]" >> ${rpt_dir}/check_timing_cross_clock/set_cross_clk_false_path.tcl
            			echo "# report_timing -nosplit -path_type full_clock_ex  -input_pins  -include_hierarchical_pins -from $from_clk -to $clk " >> ${rpt_dir}/check_timing_cross_clock/cross_clock_report_timing.rpt
            			report_timing -nosplit -path_type full_clock_ex  -input_pins  -include_hierarchical_pins -from $from_clk -to $clk >> ${rpt_dir}/check_timing_cross_clock/cross_clock_report_timing.rpt
					}
					echo "          " >> ${rpt_dir}/check_timing_cross_clock/check_cross_clk_summary.rpt
				}
			}
			close $f
		}
	}
	define_proc_attributes check_timing_cross_clock \
    -info "Check cross clock  in primetime." \
    -define_args {
       {-save_dir "Specify the report direction." "" "string" optional} \
    }
	#############################################
	# Description    : Check hier file of sub block
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc check_hier_file_of_sub_block {args} {
        parse_proc_arguments -args $args results

		set TOP  [get_object_name [get_designs]]
        if {[info exists results(-file)]} {
            set outFile $results(-file)
        } else {
			set outFile "[pwd]/${TOP}.check_hier_file_of_sub_block.rpt"
		}
        if {[info exists results(-hier_file)]} {
            set hier_file $results(-hier_file)
        }
		set f2 [open $hier_file r]
		set all_blocks ""
        while {[gets $f2 line] >=0 } {
         	set block_name [lindex $line 0 ]
			lappend all_blocks $block_name
        }
		set all_blocks [lsort -unique $all_blocks]
        reportHead -item "Check Hier file of Sub Block." -file $outFile
		set f1 [open $outFile a]
		foreach block $all_blocks {
			set result [get_attr [get_cells $block  -q ] is_hierarchical]
			if {$result == "true"} {
				puts $f1 "INFO: read verilog of $block"
			} else {
				if {[get_attr [get_cells $block  -q ] is_hierarchical] == "false" } {
					puts $f1 "INFO: Warning not flatten block $block (with library)"
				} else {
					puts $f1 "INFO: Warning not flatten block $block (without library)"
				}
			}
		}
		close $f1 
	}
	define_proc_attributes check_hier_file_of_sub_block \
    	-info "Check data path and clock path noise base on the timing violations in primetime." \
    	-define_args {
       		{-file "Specify the output file name. Default is current directory." "" "string" optional} \
       		{-hier_file "Specify sub block hier file." "" "string" required} \
    	}

	#############################################
	# Description    : Check min period
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc check_min_period_summary {args} {
		set file1 $args
		set f1 [open $file1 r]
		set f2 [open ${file1}.summary w]
		set f3 [open ${file1}.slack w]

		set vios_all_ref_name ""
		set all_vios_num 0
		puts $f2 "[format "%-30s %-10s %-10s %-10s %-200s " "#violation cell ref name" "cell num" "clk period" "clk unc" "Wrost violations"]"
		set min_period_wns 0 
		set vios_nums_incr 0
		while {[gets $f1 newline] != -1} {
			if {[regexp "VIOLATED" $newline]} {
				if {[lindex [split $newline " "] end-2] == "significant"} {
					puts $f3 "-0.000 [lindex $newline 0]"
				} else {
					puts $f3 "[lindex $newline  end-2] [lindex $newline  0]"
				}
				incr vios_nums_incr
				if {$vios_nums_incr == 1} {set min_period_wns [lindex $newline end-2]}

				set vios_full_name [lindex [split $newline " "] 3]
				set clocks         [lindex [split $newline " "] end]
				set clk_period     [get_attribute [get_clocks $clocks] period]
				set clk_uncer      [get_attribute [get_clocks $clocks] setup_uncertainty]
				set vios_ref_name  [get_attribute [get_cells -of $vios_full_name] ref_name ]
				if {[lsearch $vios_all_ref_name $vios_ref_name] == -1} {
					set vios_num       [sizeof_collection  [get_cells -hierarchical -filter "ref_name == $vios_ref_name" ]]
					set all_vios_num [expr $all_vios_num + $vios_num]
					puts $f2 "[format "%-30s %-10s %-10s %-10s %-200s " "$vios_ref_name " "$vios_num" "$clk_period" "$clk_uncer" "$newline"]"
					lappend vios_all_ref_name $vios_ref_name 
				}	
			}
		}
		puts $f2 "[format "%-30s %-10s" "[llength $vios_all_ref_name ]" "$all_vios_num"] "
		close $f1
		close $f2
		close $f3
	}
	#############################################
	# Description    : Check min pulse width
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc check_min_pulse_width_summary {args} {

		set file1 $args
		set f1 [open $file1 r]
		set f2 [open ${file1}.summary w]
		set f3 [open ${file1}.slack w]

		set vios_all_ref_name ""
		set all_vios_num 0
		puts $f2 "[format "%-30s %-10s %-10s %-10s %-200s " "#violation cell ref name" "cell num" "clk period" "clk unc" "Wrost violations"]"
		set min_period_wns 0 
		set vios_nums_incr 0
		while {[gets $f1 newline] != -1} {
			if {[regexp "VIOLATED" $newline]} {
				if {[lindex [split $newline " "] end-2] == "significant"} {
					puts $f3 "-0.000 [lindex $newline 0]"
				} else {
					puts $f3 "[lindex $newline end-2] [lindex $newline 0]"
				}
				incr vios_nums_incr
				if {$vios_nums_incr == 1} {set min_period_wns [lindex $newline end-2]}
				set vios_full_name [lindex [split $newline " "] 3]
				set clocks         [lindex [split $newline " "] end]
				set clk_period     [get_attribute [get_clocks $clocks] period]
				set clk_uncer      [get_attribute [get_clocks $clocks] setup_uncertainty]
				set vios_ref_name  [get_attribute [get_cells -of $vios_full_name] ref_name ]
				if {[lsearch $vios_all_ref_name $vios_ref_name] == -1} {
					set vios_num       [sizeof_collection  [get_cells -hierarchical -filter "ref_name == $vios_ref_name" ]]
					set all_vios_num [expr $all_vios_num + $vios_num]
					puts $f2 "[format "%-30s %-10s %-10s %-10s %-200s " "$vios_ref_name " "$vios_num" "$clk_period" "$clk_uncer" "$newline"]"
					lappend vios_all_ref_name $vios_ref_name 
				}
			}
		}
		puts $f2 "[format "%-30s %-10s" "[llength $vios_all_ref_name ]" "$all_vios_num"] "
		close $f1
		close $f2
		close $f3
	}
	#############################################
	# Description    : Check drv summary
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc check_drv {args} {
        global RPT_DIR TOP LOG_DIR DATA_DIR
        parse_proc_arguments -args $args results

		set TOP   [get_object_name [get_designs]]
        if {[info exists results(-file)]} {
            set outFile $results(-file)
        } else {
		    set outFile "[pwd]/${TOP}.check_drv.rpt"
		}
		#set reports1 "${RPT_DIR}/${TOP}.drv.rpt"
        if {[info exists results(-report)]} {
            set reports1 $results(-report)
        }

		set waive_list 0
        if {[info exists results(-waive)]} {
            set waive_report $results(-waive)
	    	set waive_list 1
        }

        set log_file [open  $reports1  r ]
		set drv_tran_clk_rpt [open $reports1.tran.clock w]
		set drv_tran_data_rpt [open $reports1.tran.data w]
		set drv_cap_rpt [open $reports1.cap w]
		set drv_fanout_rpt [open $reports1.fanout w]
		set clk_tran_num 0 
		set clk_tran_wns 0 
		set data_tran_num 0
		set data_tran_wns 0
		set tran_num 	0 
		set cap_num 	0 
		set fanout_num 	0
		set tran_wns 	0 
		set cap_wns 	0 
		set fanout_wns 	0
		set tran_cal 	0 
		set cap_cal 	0 
		set fanout_cal 	0
        while { [gets $log_file  log_line] != "-1" } {
            if {[regexp "Transition" $log_line]} {
				set tran_cal 1
				set cap_cal 0
				set fanout_cal 0
			}
			## transition 
			if {$tran_cal == 1 && [regexp "VIOLATED" $log_line]} {
				if {$waive_list == 0} {
					incr tran_num
					if {$tran_num == 1 } { set tran_wns [lindex  [regexp -inline -all -- {\S+} $log_line] end-1]}
					set vio_pin [lindex  [regexp -inline -all -- {\S+} $log_line] 0]
					set vio_slk [lindex  [regexp -inline -all -- {\S+} $log_line] 3]
					set require_value [lindex  [regexp -inline -all -- {\S+} $log_line] 1]
					set actual_value [lindex  [regexp -inline -all -- {\S+} $log_line] 2]
					#puts $vio_pin
					set check_pin [get_pins -q  $vio_pin]
					if {$check_pin == "" } {
						set check_pin [get_ports -q $vio_pin]
					}
				
					if {[get_attribute -quiet  $check_pin  clocks ] != ""} {
						set check_pin [get_pins -q  $vio_pin]
						if {$check_pin == "" } { 
							puts $drv_tran_clk_rpt "$vio_pin|$require_value|$actual_value|$vio_slk|outPut"
						} else {
							if {[get_attribute -q [get_pins -q $check_pin] direction] == "in"} {
								puts $drv_tran_clk_rpt "$vio_pin|$require_value|$actual_value|$vio_slk|[get_drivePin $check_pin]"
							} else {
								puts $drv_tran_clk_rpt "$vio_pin|$require_value|$actual_value|$vio_slk|outPut"
							}
						}
						incr clk_tran_num
						if {$vio_slk < $clk_tran_wns } {set clk_tran_wns $vio_slk}
					} else {
						set check_pin [get_pins -q  $vio_pin]
						if {$check_pin == "" } { 
							puts $drv_tran_data_rpt "$vio_pin|$require_value|$actual_value|$vio_slk|outPut"
						} else {
							if {[get_attribute -q [get_pins -q $check_pin] direction] == "in"} {
								puts $drv_tran_data_rpt "$vio_pin|$require_value|$actual_value|$vio_slk|[get_drivePin $check_pin]"
							} else {
								puts $drv_tran_data_rpt "$vio_pin|$require_value|$actual_value|$vio_slk|outPut"
							}
						}
						incr data_tran_num
						if {$vio_slk < $data_tran_wns } {set data_tran_wns $vio_slk }
					}
				} 
				if {$waive_list == 1} {
					set found_waive 0
					set waive_report_f1 [open $waive_report r]
					set vio_pin [lindex  [regexp -inline -all -- {\S+} $log_line] 0]
					while { [gets $waive_report_f1  waive_line] != "-1" } {
						if { ![regexp {^ *#} $waive_line] && $waive_line != ""} {
							set Tpye [lindex [split $waive_line ":"] 0]
							set Pin  [lindex [split $waive_line ":"] 1]
							if {$Tpye == "TRAN_WAIVE"} {
								if {[string equal $vio_pin $Pin]} {
									set found_waive 1
								}
							}
						}
					}
					if {$found_waive == 0} {
						incr tran_num
						if {$tran_num == 1 } { set tran_wns [lindex  [regexp -inline -all -- {\S+} $log_line] end-1]}
						set vio_pin [lindex  [regexp -inline -all -- {\S+} $log_line] 0]
						set require_value [lindex  [regexp -inline -all -- {\S+} $log_line] 1]
						set actual_value [lindex  [regexp -inline -all -- {\S+} $log_line] 2]
						set vio_slk [lindex  [regexp -inline -all -- {\S+} $log_line] 3]

						set check_pin [get_pins -q  $vio_pin]
						if {$check_pin == "" } {
							set check_pin [get_ports -q $vio_pin]
						}
						if {[get_attribute -quiet  $check_pin  clocks ] != ""} {
							set check_pin [get_pins -q  $vio_pin]
							if {$check_pin == "" } { 
								puts $drv_tran_clk_rpt "$vio_pin|$require_value|$actual_value|$vio_slk|outPut"
							} else {
								if {[get_attribute -q [get_pins $check_pin] direction] == "in"} {
									puts $drv_tran_clk_rpt "$vio_pin|$require_value|$actual_value|$vio_slk|[get_drivePin $check_pin]"
								} else {
									puts $drv_tran_clk_rpt "$vio_pin|$require_value|$actual_value|$vio_slk|outPut"
								}
							}
							incr clk_tran_num
							if {$vio_slk < $clk_tran_wns } {set clk_tran_wns $vio_slk}
						} else {
							set check_pin [get_pins -q  $vio_pin]
							if {$check_pin == "" } { 
								puts $drv_tran_data_rpt "$vio_pin|$require_value|$actual_value|$vio_slk|outPut"
							} else {
								if {[get_attribute  -q [get_pins $check_pin] direction] == "in"} {
									puts $drv_tran_data_rpt "$vio_pin|$require_value|$actual_value|$vio_slk|[get_drivePin $check_pin]"
								} else {
									puts $drv_tran_data_rpt "$vio_pin|$require_value|$actual_value|$vio_slk|outPut"
								}
							}
							incr data_tran_num
							if {$vio_slk < $data_tran_wns } {set data_tran_wns $vio_slk }
						}
					}
					close $waive_report_f1
				} 
			}
            if {[regexp "Fanout" $log_line]} {
				set tran_cal 0
				set cap_cal 0
				set fanout_cal 1
			}
			## fanout 
			if {$fanout_cal == 1 && [regexp "VIOLATED" $log_line]} {
				incr fanout_num
				if {$fanout_num == 1 } { set fanout_wns [lindex  [regexp -inline -all -- {\S+} $log_line] end-1]}

				if {$waive_list == 1} {
					set found_waive_fanout 0
					set waive_report_f1 [open $waive_report r]
					set vio_pin [lindex  [regexp -inline -all -- {\S+} $log_line] 0]
					while { [gets $waive_report_f1  waive_line] != "-1" } {
						if { ![regexp {^ *#} $waive_line] && $waive_line != ""} {
							set Tpye [lindex [split $waive_line ":"] 0]
							set Pin  [lindex [split $waive_line ":"] 1]
							if {$Tpye == "FANOUT_WAIVE"} {
								if {[string equal $vio_pin $Pin]} {
									set found_waive_fanout 1
								}
							}
						}
					}

					if {$found_waive_fanout == 0} {
						incr cap_num
						if {$cap_num == 1 } { set cap_wns [lindex  [regexp -inline -all -- {\S+} $log_line] end-1]}
						puts $drv_fanout_rpt "[lrange $log_line 0 3]"
					}

					close $waive_report_f1
				} else {
					puts $drv_fanout_rpt "[lrange $log_line 0 3]"
				}
			}
            if {[regexp "Capacitance" $log_line]} {
				set tran_cal 0
				set cap_cal 1
				set fanout_cal 0
			}
			if {$cap_cal == 1 && [regexp "VIOLATED" $log_line]} {
				if {$waive_list == 0} {
					incr cap_num
					if {$cap_num == 1 } { set cap_wns [lindex  [regexp -inline -all -- {\S+} $log_line] end-1]}
					puts $drv_cap_rpt "[join [lrange $log_line 0 3]]"
				}

				if {$waive_list == 1} {
					set found_waive_cap 0
					set waive_report_f1 [open $waive_report r]
					set vio_pin [lindex  [regexp -inline -all -- {\S+} $log_line] 0]
					while { [gets $waive_report_f1  waive_line] != "-1" } {
						if { ![regexp {^ *#} $waive_line] && $waive_line != ""} {
							set Tpye [lindex [split $waive_line ":"] 0]
							set Pin  [lindex [split $waive_line ":"] 1]
							if {$Tpye == "CAP_WAIVE"} {
								if {[string equal $vio_pin $Pin]} {
									set found_waive_cap 1
								}
							}
						}
					}

					if {$found_waive_cap == 0} {
						incr cap_num
						if {$cap_num == 1 } { set cap_wns [lindex  [regexp -inline -all -- {\S+} $log_line] end-1]}
						puts $drv_cap_rpt "[join [lrange $log_line 0 3]]"
					}
					close $waive_report_f1
				}
			}
        }
		close $log_file
		close $drv_tran_clk_rpt
		close $drv_tran_data_rpt
		close $drv_cap_rpt
		close $drv_fanout_rpt
	}

	define_proc_attributes check_drv \
    	-info "Check timing and drc summary in primetime." \
    	-define_args {
       		{-file "Specify the output file name. Default is current directory." "" "string" optional} \
       		{-report "Specify the input report file name." "" "string" optional} \
       		{-waive "Specify the input waive list file name." "" "string" optional} \
    	}
	#############################################
	# Description    : Check crosstalk
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc check_crosstalk {args} {
		global CHECK_TYPE RPT_DIR TOP corner
    	parse_proc_arguments -args $args results

    	if {[info exists results(-file)]} {
        	set outFile $results(-file)
    	} else {
			set outFile "[pwd]/${TOP}.check_crosstalk.rpt"
		}
		set f1 [open $outFile.data w]
		set f2 [open $outFile.clk w]
		# define crosstalk delay  #TODO ramon
		set setup_clock_max_crosstalk	0.03
		set setup_data_max_crosstalk 	0.20 

		set hold_clock_max_crosstalk 	-0.03
		set hold_data_max_crosstalk_wc	-0.20
		set hold_data_max_crosstalk_ml	-0.20	
	

		if {[regexp {max|setup} $CHECK_TYPE]} {
		# clock
	 		if { [ sizeof_collection  [get_nets -q  -top_net_of_hierarchical_group -filter "annotated_delay_delta_max > $setup_clock_max_crosstalk && is_clock_network == true "] ] > 0 } {
        		set crosstalk_num [ sizeof_collection  [get_nets -q  -top_net_of_hierarchical_group -filter "annotated_delay_delta_max > $setup_clock_max_crosstalk && is_clock_network == true "] ]
        		puts $f2 "DM::INFO: ERROR, check clock net crosstalk failed, violation num ($crosstalk_num)"
        		foreach_in_collection id [get_nets -q  -top_net_of_hierarchical_group -filter "annotated_delay_delta_max > $setup_clock_max_crosstalk && is_clock_network == true "] {
        			puts $f2 "[get_object_name $id] [ get_attribute [get_nets $id] annotated_delay_delta_max ] "
        		}
			} else {
        		puts $f2 "DM::INFO: PASS, check clock net crosstalk pass"
			}
		# data
 			if { [ sizeof_collection  [get_nets -q  -hierarchical -filter "annotated_delay_delta_max > $setup_data_max_crosstalk "  -top_net_of_hierarchical_group ] ] > 0 } {
        		set crosstalk_num [ sizeof_collection  [get_nets -q -hierarchical -filter "annotated_delay_delta_max > $setup_data_max_crosstalk " -top_net_of_hierarchical_group ] ]
        		puts $f1 "DM::INFO: ERROR, check data net crosstalk failed, violation num ($crosstalk_num)"
        		foreach_in_collection id  [get_nets -q -hierarchical -filter "annotated_delay_delta_max > $setup_data_max_crosstalk " -top_net_of_hierarchical_group ] {
        			puts $f1 "[get_object_name $id] [ get_attribute [get_nets $id] annotated_delay_delta_max ] " 
        		}
			} else {
        		puts $f1 "DM::INFO: PASS, check data net crosstalk pass" 
			}
		} elseif {[regexp {min|hold} $CHECK_TYPE]}  {
			if { [ sizeof_collection [get_nets  -q  -top_net_of_hierarchical_group -filter " annotated_delay_delta_min < $hold_clock_max_crosstalk && is_clock_network == true "] ] > 0 } {
    			set crosstalk_num  [ sizeof_collection [get_nets  -q  -top_net_of_hierarchical_group -filter " annotated_delay_delta_min < $hold_clock_max_crosstalk && is_clock_network == true "] ]
    			puts $f2 "DM::INFO: ERROR, check clock net crosstalk failed, violation num ($crosstalk_num)" 
        		foreach_in_collection id [get_nets  -q  -top_net_of_hierarchical_group -filter " annotated_delay_delta_min < $hold_clock_max_crosstalk && is_clock_network == true "] {
        			puts $f2 "[get_object_name $id] [ get_attribute [get_nets $id] annotated_delay_delta_min ] " 
        		}
			} else {
      			puts $f2 "DM::INFO: PASS, check clock net crosstalk pass" 
			}
			if  {[regexp {wc|wcz} $corner]}  {
				if { [ sizeof_collection [get_nets  -q  -hierarchical -filter " annotated_delay_delta_min < $hold_data_max_crosstalk_wc" -top_net_of_hierarchical_group ] ] > 0 } {
        			set crosstalk_num  [ sizeof_collection [get_nets  -q -hierarchical -filter " annotated_delay_delta_min < $hold_data_max_crosstalk_wc" -top_net_of_hierarchical_group ] ]
        			puts $f1 "DM::INFO: ERROR, check data net crosstalk failed, violation num ($crosstalk_num)" 
        			foreach_in_collection id  [get_nets -q -hierarchical -filter " annotated_delay_delta_min < $hold_data_max_crosstalk_wc" -top_net_of_hierarchical_group ] {    
        				puts $f1 "[get_object_name $id]  [ get_attribute [get_nets $id] annotated_delay_delta_min ]" 
        			}
				} else {
        			puts $f1 "DM::INFO: PASS, check data net crosstalk pass" 
				}
			} else {
				if { [ sizeof_collection [get_nets  -q  -hierarchical -filter " annotated_delay_delta_min < $hold_data_max_crosstalk_ml" -top_net_of_hierarchical_group ]] > 0 } {
       				set crosstalk_num  [ sizeof_collection [get_nets  -q -hierarchical -filter " annotated_delay_delta_min < $hold_data_max_crosstalk_ml" -top_net_of_hierarchical_group ] ]
       				puts $f1 "DM::INFO: ERROR, check data net crosstalk failed, violation num ($crosstalk_num)" 
        			foreach_in_collection id  [get_nets -q -hierarchical -filter " annotated_delay_delta_min < $hold_data_max_crosstalk_ml" -top_net_of_hierarchical_group ] {
        				puts $f1 "[get_object_name $id]  [ get_attribute [get_nets $id] annotated_delay_delta_min ]" 
        			}
				} else {
        			puts $f1 "DM::INFO: PASS, check data net crosstalk pass" 
				}

			}
		} else {
		}
		close $f1
		close $f2
	}
	define_proc_attributes check_crosstalk \
    	-info "Check crosstalk delay in primetime." \
    	-define_args {
       		{-file "Specify the output file name. Default is current directory." "" "string" optional} \
    	}
    #############################################
	# Description    : Check Dont Use Cell
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc check_dont_use_cell {args} {
		global sta_vars
		parse_proc_arguments -args $args results
		if {[info exist sta_vars(dont_use_cell)] && [llength $sta_vars(dont_use_cell)] > 1} {
			puts "User defined dont_use_cell: $sta_vars(dont_use_cell)"
    		set dont_use_lib_cells $sta_vars(dont_use_cell)
		} else {
			set dont_use_lib_cells [list "*D18" "DFKSR*" "DFSR*" "SDFKSR*" "SDFNSR*" "SDFSR*" "G*" "*D20*" "*D24*" "*D28*" "*D32*" "*D36*"  "*OPT*" "BUFT*" "SEDF*" "G*" "MB6*" "MB8*" "*ELVT*" "*CK*" "SDFSYN*"]
			set dont_use_lib_cells [list "*D20*" "*D24*" "*D28*" "*D36*"  "*OPT*" "BHD*" "BUFT*"  "SEDF*" "SEDM*"  "FILL*" "DCAP*" "G*" "MB6*" "MB8*"]
            set dont_use_lib_cells [list "INV*SGCAP* BUF*SGCAP* FRICG* DFF*QL_* DFF*QNL_* SDFF*QL_* SDFF*QNL_* SDFFQH* SDFFQNH* SDFFRPQH* SDFFRPQNH* SDFFSQH* SDFFSQNH* SDFFSRPQH* SDFFY* *DRFF* HEAD* FOOT* *X0* *DLY* SDFFX* XOR3* XNOR3* *ECO* *ZTL* *ZTEH* *ZTUH* *ZTUL* *ISO* *LVL* *G33* A    NTENNA* *AND*_X11* *AND*_X8* *AO21A1AI2_X8* *AOI21B_X8* *AOI21_X11* *AOI21_X8* *AOI22BB_X8* *AOI22_X11* *AOI22_X8* *AOI2XB1_X8* *AOI31_X8* *ENDCAP FILL* GP* MXGL* OA*_X8* OR*_X11* NOR*_X11* OR*_X8* NOR*_X8* *_X20* *QN* ICT_CDMSTD"
		}

    	if {[info exists results(-file)]} {
        	set outFile $results(-file)
    	}

		set f1 [open $outFile w]
		echo "INFO: Starting to initial check don't use cells"
		echo "-------------------------------------------------------------------"
		echo "INFO: don't_use inst list: $dont_use_lib_cells"
		echo "-------------------------------------------------------------------"
		set dont_use_num 0 
		set dont_use_error ""
		set check_results ""
		foreach id $dont_use_lib_cells {
	    	set a [sizeof_collection [get_cells -hier -filter "ref_name =~ $id && is_hierarchical == false" -q] ]
	    	if {$a > 0 } {
	    		incr dont_use_num
	    		foreach_in_collection ids  [get_cells -hier -filter "ref_name =~ $id && is_hierarchical == false" -q] {
	    			puts $f1 "[get_object_name $ids] [get_attribute [get_cells $ids] ref_name] "
	    		}
	    		echo "INFO: there are $a $id cells" 
	    		lappend check_results "INFO: there are $a $id cells"
	    		lappend dont_use_error "$a $id"
	    	}
		}
		echo "-------------------------------------------------------------------"
		puts $f1  "Check summary:" 
	
		foreach check_result $check_results {
	   		puts $f1 "$check_result"
		}
		if {[regexp primetime [get_app_var sh_tcllib_app_dirname]]} {
			if {$dont_use_num == 0} {
				puts $f1 "DM::INFO: PASS, check dont use ok. all dont use ($dont_use_lib_cells)"
			} else {
				puts $f1 "DM::INFO: ERROR, check dont use error($dont_use_error). all dont use ($dont_use_lib_cells)"
			}
		}
		echo "INFO: Finished to initial check don't use cells."
		echo "-------------------------------------------------------------------"
		close $f1 
	}
	define_proc_attributes check_dont_use_cell \
    	-info "Check dont use cell in primetime." \
    	-define_args {
       	{-file "Specify the output file name. Default is current directory." "" "string" optional} \
    	}
    #############################################
	# Description    : Check Clock Cell type
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc check_clock_cell_type {args} {
		global sta_vars

		# define vars
		parse_proc_arguments -args $args results
		set total_count 0
		set non_ulvt_num 0 
		set non_symmetricdcap_num 0 
		set weak_num 0 
		set to_gpio_pin_num 0 
		set to_data_pin_num 0 

		if {[info exists results(-file)]} {
			set outFile $results(-file)
		}
		set f1 [open $outFile w]
		set f2 [open $outFile.sum w]

		foreach_in_collection clock [ get_clocks -quiet * ] {
	    	foreach_in_collection source [ get_attribute -quiet $clock sources ] {
	      		############################################################################### define your design all cells from clock source #TODO
	      		set clock_cells [get_cells [ all_fanout -flat -from $source -only_cells -continue_trace generated_clock_source ] -filter $sta_vars(check_clock_filter_clock_cell) -q] 
	      		# exclude leaf flipflops
	      		set clock_cells [ remove_from_collection $clock_cells [ all_fanout -flat -from $source -only_cells -endpoints_only -continue_trace generated_clock_source] ]
	      		# inculde generated clock sources 
	      		if {  [get_attribute $clock is_generated ] && [sizeof_collection [get_cells -of $source  -quiet -filter $sta_vars(check_clock_filter_clock_cell)] ] != 0 } { 
	      			set clock_cells [ append_to_collection  clock_cells   [get_cells -of $source  -quiet -filter $sta_vars(check_clock_filter_clock_cell)] ]
	      		}
	     		########################################################################
	     		# check non-ulvt cells 1#TODO design ULVT clock cell
	     		#set non-ulvt_cells [ filter_collection -regexp $clock_cells "ref_name !~ .*BWP210H6P51CNODULVT" ]
	     		set non-ulvt_cells [ filter_collection -regexp $clock_cells $sta_vars(re_ulvt) ]
         		set non-ulvt_cells [ filter_collection ${non-ulvt_cells} $sta_vars(check_clock_filter_ip)]
		 		#set non-ulvt_cells [ filter_collection -regexp  ${non-ulvt_cells} "ref_name =~ zcms_r*"]
	     		#set non-ulvt_cells [filter_collection -regexp [ filter_collection -regexp $clock_cells "ref_name !~ .*BWP240H11P57PDULVT "]  "ref_name !~ PLLTS5FFPLAFRACN" ]
				
	     		set count [ sizeof_collection ${non-ulvt_cells} ]
	     		if { $count == 0 } {
	       			puts $f1 [ format "INFO: %d non-ulvt cells used in %s." $count [ get_attribute $clock full_name ] ]
	     		} else {
	       			puts $f1 [ format "WARNING: %d non-ulvt cells used in %s." $count [ get_attribute $clock full_name ] ]
	       			foreach_in_collection cell ${non-ulvt_cells} {
	       		 	########################################################################
	       		 		set pin [get_pins -q -of $cell -filter "direction==out"]
	       		 		set all_fanout_tmp [all_fanout -from $pin -endpoints_only -flat]
	       		 		set fanout_after_filter ""
	       		 		set fanout_after_filter [filter_collection $all_fanout_tmp "is_clock_pin || object_class == port"] 
			 			set to_IO_pin ""
			 			set to_IO_pin [filter_collection $fanout_after_filter "full_name=~GPIO_*"]
			 			set fanout_after_filter [filter_collection $fanout_after_filter "full_name!~GPIO_*"]
	
	       		 		if { [sizeof_collection $fanout_after_filter] != 0 } {
							if {[regexp "arm_macro/u_nr_arm_cluster_" [ get_attribute $cell full_name ]] && [regexp "BWP300H11P64PDULVT" [ get_attribute $cell ref_name ]]  } {
							} else {
								if {[regexp "u_nr_arm_cluster_" [ get_attribute $cell full_name ]] && [regexp "BWP300H11P64PDULVT" [ get_attribute $cell ref_name ]]  } {
								} else {
	       		  					puts $f1 "ERROR: [ format "%s (%s)" [ get_attribute $cell full_name ] [ get_attribute $cell ref_name ] ] (non-ulvt)"
									puts $f2 "ERROR: [ format "%s (%s)" [ get_attribute $cell full_name ] [ get_attribute $cell ref_name ] ] (non-ulvt)"
									incr non_ulvt_num
								}
							}
	       		 		} else {
							if {[sizeof_collection $to_IO_pin ] != 0} {
								puts $f1 "#To_GPIO_data_pin# [ format "%s (%s)" [ get_attribute $cell full_name ] [ get_attribute $cell ref_name ] ] (non-ulvt)"
								#puts $f2 "[ format "%s (%s)" [ get_attribute $cell full_name ] [ get_attribute $cell ref_name ] ] (non-ulvt)"
								incr to_gpio_pin_num
							}
	       		  			puts $f1 "#To_data_pin# [ format "%s (%s)" [ get_attribute $cell full_name ] [ get_attribute $cell ref_name ] ]"
							incr to_data_pin_num
	       		 		}
	       			}
	     		}
	      		########################################################################
	      		# check non-symmetricdcap cells
	      		# 2.TODO, define design non_symmetricdcap_cells
	      		set non_symmetricdcap_cells [ filter_collection $clock_cells $sta_vars(check_clock_filter_non_symmetricdcap)] 
	      		set count [ sizeof_collection $non_symmetricdcap_cells ]
	      		puts $f1 [ format "------------------------------------------------------------------------" ]
	      		if { $count == 0 } {
	        		puts $f1 [ format "INFO: %d non-symmetricdcap cells used in %s." $count [ get_attribute $clock full_name ] ]
	      		} else {
	        		puts $f1 [ format "WARNING: %d non-symmetricdcap cells used in %s." $count [ get_attribute $clock full_name ] ]
	        		foreach_in_collection cell $non_symmetricdcap_cells {
	       		 	########################################################################
	       		 		set pin [get_pins -q -of $cell -filter "direction==out"]
	       		 		set all_fanout_tmp [all_fanout -from $pin -endpoints_only -flat]
	       		 		set fanout_after_filter ""
	       		 		set fanout_after_filter [filter_collection $all_fanout_tmp "is_clock_pin || object_class == port "] 
			 			set to_IO_pin ""
			 			set to_IO_pin [filter_collection $fanout_after_filter "full_name=~GPIO_*"]
			 			set fanout_after_filter [filter_collection $fanout_after_filter "full_name!~GPIO_*"]
	       		 		if { [sizeof_collection $fanout_after_filter] != 0 } {
	       		  			puts $f1 "ERROR: [ format "%s (%s)" [ get_attribute $cell full_name ] [ get_attribute $cell ref_name ] ] (non-symmetric)"
	       		  			puts $f2 "ERROR: [ format "%s (%s)" [ get_attribute $cell full_name ] [ get_attribute $cell ref_name ] ] (non-symmetric)"
							incr non_symmetricdcap_num
	       		 		} else {
							if {[sizeof_collection $to_IO_pin ] != 0} {
								puts $f1 "#To_GPIO_data_pin# [ format "%s (%s)" [ get_attribute $cell full_name ] [ get_attribute $cell ref_name ] ] (non-symmetric)"
								#puts $f2 "[ format "%s (%s)" [ get_attribute $cell full_name ] [ get_attribute $cell ref_name ] ] (non-symmetric)"
								incr to_gpio_pin_num
							}
	       		  			puts $f1 "#To_data_pin# [ format "%s (%s)" [ get_attribute $cell full_name ] [ get_attribute $cell ref_name ] ]"
							incr to_data_pin_num
	       		 		}
	        		}
	      		}
	     		########################################################################
	     		# check weak clock cell  , x0, x0.*, x1 or x1.* 
	     		# 3.TODO, define design weak_cells
	     		set weak_cells [ filter_collection $clock_cells $sta_vars(check_clock_weak_cells)]
	     		set count [ sizeof_collection ${weak_cells} ]
	     		if { $count == 0 } {
	       			puts $f1 [ format "INFO: %d non-weak cells used in %s." $count [ get_attribute $clock full_name ] ]
	     		} else {
	       			puts $f1 [ format "WARNING: %d weak cells used in %s." $count [ get_attribute $clock full_name ] ]
	       			foreach_in_collection cell ${weak_cells} {
	       		 	########################################################################
	       		 		set pin [get_pins -q -of $cell -filter "direction==out"]
	       		 		set all_fanout_tmp [all_fanout -from $pin -endpoints_only -flat]
			 			set to_IO_pin ""
	       		 		set fanout_after_filter ""
	       		 		set fanout_after_filter [filter_collection $all_fanout_tmp "is_clock_pin || object_class == port "] 
			 			set to_IO_pin [filter_collection $fanout_after_filter "full_name=~GPIO_*"]
			 			set fanout_after_filter [filter_collection $fanout_after_filter "full_name !~ GPIO_*"]
	       		 		if { [sizeof_collection $fanout_after_filter] != 0 } {
	       		  			puts $f1 "ERROR: [ format "%s (%s)" [ get_attribute $cell full_name ] [ get_attribute $cell ref_name ] ] (weak)"
	       		  			puts $f2 "ERROR: [ format "%s (%s)" [ get_attribute $cell full_name ] [ get_attribute $cell ref_name ] ] (weak)"
							incr weak_num
	       		 		} else {
							if {[sizeof_collection $to_IO_pin ] != 0} {
								puts $f1 "#To_GPIO_data_pin# [ format "%s (%s)" [ get_attribute $cell full_name ] [ get_attribute $cell ref_name ] ] (weak)"
								#puts $f2 "ERROR: [ format "%s (%s)" [ get_attribute $cell full_name ] [ get_attribute $cell ref_name ] ] (weak)"
								incr to_gpio_pin_num
							}
	       		  			puts $f1 "#To_data_pin# [ format "%s (%s)" [ get_attribute $cell full_name ] [ get_attribute $cell ref_name ] ]"
							incr to_data_pin_num
	       		 		}
	       			}
	     		}
	    	}
		}

		if {$non_ulvt_num == 0 && $non_symmetricdcap_num == 0 && $weak_num == 0 && $to_gpio_pin_num == 0 } {
			puts $f1 "DM::INFO: PASS,  non-ulvt_num ($non_ulvt_num) non-symmetricdcap_num ($non_symmetricdcap_num) weak_num ($weak_num) to_gpio_pin cell ($to_gpio_pin_num) to-data-pin ($to_data_pin_num)"
		} else {
			puts $f1 "DM::INFO: ERROR, non-ulvt_num ($non_ulvt_num) non-symmetricdcap_num ($non_symmetricdcap_num) weak_num ($weak_num) to_gpio_pin cell ($to_gpio_pin_num) to-data-pin ($to_data_pin_num)"
		}
		close $f1
		close $f2
		sh sort -u $outFile.sum -o $outFile.sum
	}
define_proc_attributes check_clock_cell_type \
    -info "Check clock cell type in primetime." \
    -define_args {
       {-file "Specify the output file name. Default is current directory." "" "string" optional} \
    }
    #############################################
	# Description    : Check Clock mux type
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc check_clock_mux_type {args} { 
        global sta_vars
        parse_proc_arguments -args $args results
		#-------------------------------------------------------------------------------------------------------------------------------
		set total_violation_list  ""
		set blk_name [get_object_name [get_designs]]
        if {[info exists results(-file)]} {
            set outFile $results(-file)
        } else {
            set outFile "[pwd]/${blk_name}.check_clock_mux_cell_type.rpt"
        }
        reportHead -item "check clock cell type for MUX ; MXGL2 and MXT2" -file $outFile 
        set f1 [open $outFile a]

		foreach_in_collection clock [ get_clocks -quiet * ] {
			foreach_in_collection source [ get_attribute -quiet [get_clocks $clock ] sources ] {
			# all cells from clock source
				set all_clock_cells [get_cells [ all_fanout -flat -from $source -only_cells -continue_trace generated_clock_source] -filter $sta_vars(check_clock_for_mux)]
				set clock_cells [ remove_from_collection $all_clock_cells [ all_fanout -flat -from $source -only_cells -endpoints_only -continue_trace generated_clock_source] ]
 				########################################################################
 				# check mux cell MXGL2* MXT2* 
 				set non_req_mux_cells [ filter_collection -regexp $clock_cells $sta_vars(check_clock_mux_type) ]
				set count [sizeof_collection ${non_req_mux_cells}]
				if {$count != "0"} {
                    puts $f1 "## For [get_object_name $source]"
                    puts     "## For [get_object_name $source]"
                    foreach instName [get_object_name $non_req_mux_cells] {
                        puts $f1 "  $instName"
                        puts     "  $instName"
                        append total_violation_list $instName] " "
                    }
                }
			}
		}
		set total_violation_num [llength $total_violation_list]
		puts $f1 "#[string repeat - 66]"
		puts $f1 " "
		puts $f1 "Total Violation number is $total_violation_num"
        close $f1
	}
define_proc_attributes check_clock_mux_type \
    -info "Check clock cell mux type in primetime." \
    -define_args {
       {-file "Specify the output file name. Default is current directory." "" "string" optional} \
    }
    #############################################
	# Description    : Check module name length
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc check_module_name_length {args} {

    	parse_proc_arguments -args $args results 

		set TOP [get_object_name [get_design]]
        if {[info exists results(-file)]} {
            set outFile $results(-file)
        } else {
			set outFile "[pwd]/${TOP}.report_module_name_length.rpt"
		}

		set ref_name_vio_value 128
        if {[info exists results(-ref_name_vio_value)]} {
            set ref_name_vio_value $results(-ref_name_vio_value)
        }
        set full_name_vio_value 512
        if {[info exists results(-full_name_vio_value)]} {
            set full_name_vio_value $results(-full_name_vio_value)
        }
        set echo_pass_name 0
        if {[info exists results(-echo_pass_name)]} {
            set echo_pass_name $results(-echo_pass_name)
        }
		set ref_vio_num 0
		set ref_novio_num 0
		set full_vio_num 0
		set full_novio_num 0
	
		dict set ref_vio VVVV VVVV
		dict set full_vio VVVV VVVV
		foreach_in_collection a [get_cells -hierarchical -filter "is_hierarchical"] {
			set ref_name [get_attr $a ref_name]
			set full_name [get_attr $a full_name]
			set ref_num  [string bytelength $ref_name]
			set full_num [string bytelength $full_name]
			if {$ref_num > $ref_name_vio_value} {
				incr ref_vio_num
				dict set ref_vio $ref_name "$ref_num "
			} else {
				incr ref_novio_num
				dict set ref_novio $ref_name "$ref_num "
			}
	        if {$full_num > $full_name_vio_value} {
	            incr full_vio_num
	            dict set full_vio $full_name "$full_num "
	        } else {
	            incr full_novio_num
	            dict set full_novio $full_name "$full_num "
	        }
		}
		regsub VVVV [dict keys $ref_vio] "" ref_v
		regsub VVVV [dict keys $full_vio] "" full_v
		reportHead -item "Check module name length." -file $outFile
		set xixi [open $outFile a]
		if {$ref_vio_num > 0} {
			puts $xixi "## this vio is ref_name too long: (violation num: $ref_vio_num)"
			foreach aa $ref_v {
                puts $xixi [format "%-9s%-50s" num:[dict get $ref_vio $aa] name:$aa]
			}
			puts $xixi [string repeat # 150]
			puts $xixi "\n"
		}
        if {$full_vio_num > 0} {
            puts $xixi "## this vio is full_name too long: (violation num: $full_vio_num)"
            foreach aa $full_v {                 
                puts $xixi [format "%-9s%-50s" num:[dict get $full_vio $aa] name:$aa]
            }
			puts $xixi [string repeat # 150]
			puts $xixi "\n"
        }
		if {$echo_pass_name != 0} { 
			set ref_nv [dict keys $ref_novio]
			set full_nv [dict keys $full_novio]
			puts $xixi "## this ref_name is ok. (violation num: $ref_novio_num)"
	        foreach aa $ref_nv {
                puts $xixi [format "%-9s%-50s" num:[dict get $ref_novio $aa] name:$aa]
            }
			puts $xixi [string repeat # 150]
			puts $xixi "\n"
			puts $xixi "## this full_name is ok. (violation num: $full_novio_num)"
			foreach aa $full_nv {
                puts $xixi [format "%-9s%-50s" num:[dict get $full_novio $aa] name:$aa]
            }
			puts $xixi [string repeat # 150]
			set forHtml_check_results "WARN"
		} 
		close $xixi		
	}
	define_proc_attributes check_module_name_length \
        -info "check module name length ." \
        -define_args { 
            {-full_name_vio_value "Specify a value to check full_name length. (default:512)" "" "string" optional} \
            {-ref_name_vio_value "Specify a value to check ref_name length. (default:128)" "" "string" optional } \
            {-file "Specify a file name." "" "string" optional } \
            {-echo_pass_name "if set 0, no echo pass name, if set 1, echo pass name. (default:0)" "" "string" optional } \
		}
    #############################################
	# Description    : Check delay cell chain
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc check_delay_cell_chain {args} {
		global sta_vars TOP
		parse_proc_arguments -args $args results

		set TOP [get_object_name [get_design]]
		if {[info exists results(-file)]} {
			set outFile $results(-file)
		} else {
			set outFile "[pwd]/${TOP}.check_delay_cell_chain.rpt"
		}
		reportHead -item "Check delay cell chain." -file $outFile
		set f1 [open $outFile a]

		set fixed_buffer $results(-fixed_buffer)
		set delay_cell_type $sta_vars(delay_cell_type) 
		set delay_cells [get_cells -hierarchical -filter "ref_name =~ $delay_cell_type && is_hierarchical==false"]
		set delay_cell_input_pin [file tail [lsort -u [get_attr [get_lib_pins -of_objects [get_lib_cells */$delay_cell_type] -filter "direction == in"] full_name]]] 

		set delay_chain_num 0
		foreach_in_collection delay_cell $delay_cells {
			set drive_1_cell_ref ""
			set drive_2_cell_ref ""
			set drive_3_cell_ref ""
			set drive_4_cell_ref ""
			set drive_5_cell_ref ""

			set delay_cell_name [get_object_name $delay_cell]
			set delay_cell_ref [get_attribute $delay_cell ref_name]

			set drive_1_pin  [get_pins -q  -of_objects  [get_nets  -of_objects  [get_pins -q $delay_cell_name/$delay_cell_input_pin ]  ] -filter "direction==out" -leaf]
			set drive_1_pin_name [get_object_name $drive_1_pin]
			if { [regexp {/} $drive_1_pin_name] } {
				set drive_1_cell [get_cells -of $drive_1_pin]
				set drive_1_cell_name [get_object_name $drive_1_cell]
				set drive_1_cell_ref [get_attribute $drive_1_cell ref_name]

				if { [regexp {^DEL} $drive_1_cell_ref] } {
					set drive_2_pin [get_pins -q  -of_objects  [get_nets  -of_objects  [get_pins -q  $drive_1_cell_name/$delay_cell_input_pin ]  ] -filter "direction==out" -leaf]
					set drive_2_pin_name [get_object_name $drive_2_pin]
					if { [regexp {/} $drive_2_pin_name] } {
						set drive_2_cell [get_cells -of $drive_2_pin]
						set drive_2_cell_name [get_object_name $drive_2_cell]
						set drive_2_cell_ref [get_attribute $drive_2_cell ref_name]

						if { [regexp {^DEL} $drive_2_cell_ref] } {
							set drive_3_pin [get_pins -q  -of_objects  [get_nets  -of_objects  [get_pins -q  $drive_2_cell_name/$delay_cell_input_pin ]  ] -filter "direction==out" -leaf]
							set drive_3_pin_name [get_object_name $drive_3_pin]
							if { [regexp {/} $drive_3_pin_name] } {
								set drive_3_cell [get_cells -of $drive_3_pin]
								set drive_3_cell_name [get_object_name $drive_3_cell]
								set drive_3_cell_ref [get_attribute $drive_3_cell ref_name]
								if { [regexp {^DEL} $drive_3_cell_ref] } {
									set drive_4_pin [get_pins -q  -of_objects  [get_nets  -of_objects  [get_pins -q $drive_3_cell_name/$delay_cell_input_pin ]  ] -filter "direction==out" -leaf ]
									set drive_4_pin_name [get_object_name $drive_4_pin]
									if { [regexp {/} $drive_4_pin_name] } {
										set drive_4_cell [get_cells -of $drive_4_pin]
										set drive_4_cell_name [get_object_name $drive_4_cell]
										set drive_4_cell_ref [get_attribute $drive_4_cell ref_name]
										if { [regexp {^DEL} $drive_4_cell_ref] } {
											set drive_5_pin [get_pins -q  -of_objects  [get_nets  -of_objects  [get_pins -q  $drive_4_cell_name/$delay_cell_input_pin ]  ] -filter "direction==out" -leaf]
											set drive_5_pin_name [get_object_name $drive_5_pin]
											if { [regexp {/} $drive_5_pin_name] } {
												set drive_5_cell [get_cells -of $drive_5_pin]
												set drive_5_cell_name [get_object_name $drive_5_cell]
												set drive_5_cell_ref [get_attribute $drive_5_cell ref_name]
	
												if { [regexp {^DEL}  $drive_5_cell_ref] } {
													puts  $f1 "# ERROR: $drive_5_cell_ref -> $drive_4_cell_ref -> $drive_3_cell_ref -> $drive_2_cell_ref -> $drive_1_cell_ref -> $delay_cell_ref $delay_cell_name"
													incr delay_chain_num
													puts $f1 "insert_buffer $delay_cell_name/$delay_cell_input_pin  $fixed_buffer"
													#puts $file "$drive_5_cell_ref -> $drive_4_cell_ref -> $drive_3_cell_ref -> $drive_2_cell_ref -> $drive_1_cell_ref -> $delay_cell_ref $delay_cell_name"
												}
											}
										}
									}
								}
							}
						}
					} 
				}
			} else {
				#set drive_1_cell_ref ""
				#echo "Warning: $delay_cell_name  cell's driver is port"
				#puts $file "Warning: $delay_cell_name  cell's driver is port"
			}
    	}
   		# close $file
    	if {$delay_chain_num == 0} {
	    	puts $f1 "Summary::INFO check_delay_chain $delay_chain_num  PASS"
	    } else {
    		puts $f1 "Summary::INFO check_delay_chain $delay_chain_num ERROR"
    	}	
		close $f1
	}
	define_proc_attributes check_delay_cell_chain \
    	-info "Check delay cell chain number (>5) in primetime." \
    	-define_args {
       	{-file "Specify the output file name. Default is current directory." "" "string" optional} \
       	{-fixed_buffer "Specify the buffer cell type." "" "string" required} \
    	}

    #############################################
	# Description    : Check SDC quality
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc check_sdc_quality {args} {
    	parse_proc_arguments -args $args results

    	if {[info exists results(-file)]} {
       		set outFile $results(-file)
    	} else {
			set outFIle "[pwd]/[get_object_name [get_design]].check_sdc_quality.rpt"
		}
    	if {[info exists results(-sdc)]} {
	        set SDC_LIST $results(-sdc)
	    }

		reportHead -item "Check SDC quality in read sdc log." -file $outFile
		set f1 [open $outFile  a]
    	array set cons_sdc {
        	"set_ideal_network"             "please removed form sdc"
        	"set_ideal_net"                 "please removed form sdc"
        	"set_clock_latency"             "please removed form sdc"
        	"set_dont_touch_network"        "please removed form sdc"
        	"set_dont_touch"                "please removed form sdc"
        	"set_operating_conditions"      "please removed form sdc"
        	"set_wire_load_mode"            "please removed form sdc"
        	"set_wire_load_model"           "please removed form sdc"
        	"set_propagated_clock"          "please removed form sdc"
        	"set_dont_use"                  "please removed form sdc"
        	"set_timing_derate"             "please removed form sdc"
        	"set_ideal_transition"          "please removed form sdc"
        	"get_timing_path"               "please removed form sdc"
        	"all_fanin"                     "please removed form sdc"
        	"all_fanout"                    "please removed form sdc"
        	"set_resistance"                "please removed form sdc"
        	"get_attribute"                 "please removed form sdc, please check if exist error in invs init stage"
        	"set_clock_gating_check"        "please removed form sdc"
        	"set_path_margin"               "Please removed from sdc"
        	"allow_paths"                   "please removed form sdc"
        	"set_max_delay"                 "please confirm it and check the cmd are from different clock domain(for DDR)"
        	"set_size_only"                 "please removed form sdc, change cmd to invs cmd"
   		}
   		set check_pass 1
   		puts $f1 "check SDC"

   		foreach {content sugestion} [array get cons_sdc] {
   			set find_cons 0
   			set sdc_file [open  $SDC_LIST  r ]

   			while { [gets $sdc_file  sdc_line] != "-1" } {
           		if {![regexp {^ *#} $sdc_line] && [regexp "$content" $sdc_line] && [regexp "please removed form sdc" "$sugestion"]} {
                	set find_cons 1
                	set check_pass 0
           		}
   			}
   			close $sdc_file
   			if {$find_cons == 1} {
           		puts $f1 "$sugestion : $content"
           		lappend check_outlined "$sugestion : $content"
   			}
   		}
        if {$check_pass} {
            puts $f1 "SUMMARY: PASS."
        } else {
            puts $f1 "SUMMAYR: ERROR."
        } 
   		close $f1
	}
define_proc_attributes check_sdc_quality \
    -info "Check sdc quality and run logs in primetime." \
    -define_args {
       {-file "Specify the output file name. Default is current directory." "" "string" optional} \
       {-sdc  "Specify the sdc file name. Default is current directory." "" "string" optional} \
    }
    #############################################
	# Description    : Check Netlist
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc check_netlist {args} {
		parse_proc_arguments -args $args results

		set fanout_vth 32
		set open_input_nonet [get_pins -filter "(!defined(net)) && is_hierarchical==false && (direction ==in || direction ==inout)" -hierarchical -quiet]
		set withnet_inputpins [get_pins -filter "defined(net) && is_hierarchical==false && (direction ==in || direction ==inout)" -hierarchical -quiet]
		set open_input_withnet [get_pins -of_objects [get_nets -of_objects $withnet_inputpins -filter "number_of_leaf_drivers==0" -q] -leaf -q]
    	if {[info exists results(-file)]} {
        	set outFile $results(-file)
    	} else {
			set outFile "[pwd]/[get_object_name [get_design]].check_netlist.rpt"
		}
    	set waive_list 0
    	if {[info exists results(-waive)]} {
        	set waive_report $results(-waive)
        	set waive_list 1
    	}
		set gen_template 0
    	if {[info exists results(-template)]} {
        	set template_report $results(-template)
        	set gen_template 1
    	}
		set template_content {
		## Pin
		PIN:MPE_inst/VDD

		#NET
		NET:HBM_WRAP1_inst/m_sdram_sys_ref/p1500_wso[4]
		}
		if {$gen_template == 1} {
			set template_report_f1 [open $template_report w]
			puts $template_report_f1 "$template_content"
			close $template_report_f1	
			return
		}

		set waive_list_list_pins ""
		set waive_list_list_nets ""
		if {$waive_list == 1} {
			set waive_report_list [open $waive_report r]
			while { [gets $waive_report_list  waive_line] != "-1" } {
				set Type [lindex [split $waive_line ":"] 0]
				set Name [lindex [split $waive_line ":"] 1]
				if  {$Type == "PIN"} {
					lappend waive_list_list_pins $Name
				}
				if  {$Type == "NET"} {
					lappend waive_list_list_nets $Name
				}
			}
			close $waive_report_list
		}

	  	set report [open $outFile w]
	  	set nonet_withcase_count 0
	  	set nonet_notie_count 0
	  	set withnet_count 0
	  	set floatoutnonet_count 0
	  	set floatoutwithnet_count 0
	  	set multidriver_count 0
	  	set highfanout_count 0
	  	set nosink_count 0
	  	set open_pin_nonet_nocase_count 0
	  	set open_pin_withnet_nocase_count 0
	  	set withnet_withcase_count 0
	  	foreach_in_collection open_pin $open_input_nonet {
	    	set open_pin_name [get_attr $open_pin full_name]
			set found_waive 0
			if {$waive_list == 1} {
				foreach waive_list_list_pin $waive_list_list_pins {
					if {[string equal $waive_list_list_pin $open_pin_name]} {
						set found_waive 1
					}
				}
			}
	    	if {[sizeof_collection [filter_collection $open_pin "defined(user_case_value)"]] == 0 && [sizeof_collection [filter_collection $open_pin "defined(constant_value)"]] == 0} {
				if {$found_waive == 0 } {
		      		puts $report "Error PIN INFO: $open_pin_name (open input no case without net)"
		      		incr open_pin_nonet_nocase_count
				}
	    	}
	    	if {[sizeof_collection [filter_collection $open_pin "defined(constant_value)"]] != 0 } {
				if {$found_waive == 0 } {
	      			puts $report "Warning PIN INFO: $open_pin_name (open input no tie cell  without net)"
	      			incr nonet_notie_count	
				}
	    	} 
	    	if {[sizeof_collection [filter_collection $open_pin "defined(user_case_value)"]] != 0} {
				if {$found_waive == 0 } {
	      			incr nonet_withcase_count
	      			puts $report "Error PIN INFO: $open_pin_name (open input with case without net)"
				}
	    	}
	  	}
	  	foreach_in_collection open_pin_1 $open_input_withnet {
	    	incr withnet_count
	    	set open_pin_name [get_attr $open_pin_1 full_name]
			set found_waive 0
			if {$waive_list == 1} {
				foreach waive_list_list_pin $waive_list_list_pins {
					if {[string equal $waive_list_list_pin $open_pin_name]} {
						set found_waive 1
					}
				}
			}
			if {$found_waive == 0 } {
	    		if {[sizeof_collection [filter_collection $open_pin_1 "defined(case_value)"]] == 0} {
	      			puts $report "Error PIN INFO: $open_pin_name (open input no case with net)"
	      			incr open_pin_withnet_nocase_count
	    		} else {
	      			incr withnet_withcase_count
	      			puts $report "Warning PIN INFO: $open_pin_name (open input with case with net)"
	    		}
	    		#puts $report "Error PIN INFO: $open_pin_name (open input with net)"
			}
	  	}
		###########
	  	set float_output_nonet [get_pins -filter "(!defined(net)) && is_hierarchical==false && (direction ==out || direction ==inout)" -hierarchical -quiet]
	  	set withnet_outputpins [get_pins -filter "defined(net) && is_hierarchical==false && (direction ==out || direction ==inout)" -hierarchical -quiet]
	  	set float_output_withnet [get_pins -of_objects [get_nets -of_objects $withnet_outputpins -filter "number_of_leaf_loads==0" -q] -leaf -q]
	  	foreach_in_collection open_pin $float_output_nonet {
	    	incr floatoutnonet_count
	    	set open_pin_name [get_attr $open_pin full_name]
	   		# puts $report "PIN INFO: $open_pin_name (float output without net)"
	  	}
	  	foreach_in_collection open_pin $float_output_withnet {
	    	incr floatoutwithnet_count
	    	set open_pin_name [get_attr $open_pin full_name]
	    	# puts $report "PIN INFO: $open_pin_name (float output with net)"
	  	}
		##########
	  	set all_outpins [get_pins -filter "is_hierarchical ==false && (direction ==out||direction ==inout)" -hierarchical -quiet]
	  	set multidriver_net [get_nets -filter "number_of_leaf_drivers > 1" -of $all_outpins  -quiet]
	  	set highfanout_net [get_nets -filter "number_of_leaf_loads > $fanout_vth" -of $all_outpins -quiet] 
	  	set nosink_net [get_nets -filter "number_of_leaf_loads ==0 && number_of_leaf_drivers > 0" -of $all_outpins -quiet]
	  	foreach_in_collection net $multidriver_net {

	    	set net_name [get_attr $net full_name]
	    	set found_waive 0
	    	if {$waive_list == 1} {
				foreach waive_list_list_net $waive_list_list_nets {
					if {[string equal $waive_list_list_net $net_name]} { 
						set found_waive 1
					}
				}
	    	}
	    	if {$found_waive == 0} {
	    		incr multidriver_count
	    		puts $report "Error NET INFO: $net_name (Multi-driver net)"
	    	}
	  	}
	  	foreach_in_collection net $highfanout_net {
	    	set net_name [get_attr $net full_name]
	    	incr highfanout_count
	   		# puts $report "NET INFO: $net_name (high fanout net)"
	  	}
	  	foreach_in_collection net $nosink_net {
	    	set net_name [get_attr $net full_name]
	    	incr nosink_count
	   		# puts $report "NET INFO: $net_name (no sink net)"
		}
	   
	  	puts $report ""
	  	puts $report ""
	  	puts $report "################################ check netlist summary #############################"
	  	puts $report "##  Total open input with case without net pin NUM       (critical)   : $nonet_withcase_count"
	  	puts $report "##  Total open input with 1'b1 1'b0 without net pin NUM  (critical)   : $nonet_notie_count"
	  	puts $report "##  Total open input no case without net pin NUM         (critical)   : $open_pin_nonet_nocase_count"
	  	puts $report "##  Total open input with case with net pin NUM          (critical)   : $withnet_withcase_count"
	  	puts $report "##  Total open input no case with net pin NUM            (critical)   : $open_pin_withnet_nocase_count"
	  	puts $report "##  Total open input with net pin NUM                                 : $withnet_count"
	  	puts $report "##  Total open input with case pin NUM                   (critical)   : [expr $nonet_withcase_count + $withnet_withcase_count]"
	  	puts $report "##  Total open input pin NUM (above total)               (critical)   : [expr $nonet_withcase_count + $open_pin_nonet_nocase_count + $withnet_withcase_count + $open_pin_withnet_nocase_count + $nonet_notie_count]"
	  	puts $report "##  Total float output without net pin NUM               	          	: $floatoutnonet_count"
	  	puts $report "##  Total float output with net pin NUM                  	          	: $floatoutwithnet_count"
	  	puts $report "##  Total float output pin NUM                           	          	: [expr $floatoutnonet_count + $floatoutwithnet_count]"
	  	puts $report "##  Total Multi-driver net NUM                           (critical)   : $multidriver_count"
	  	puts $report "##  Total high fanout(>$fanout_vth) net NUM                           : $highfanout_count"
	  	puts $report "##  Total no sink net NUM                                             : $nosink_count"
	  	puts $report "####################################################################################"
	  	if {$nonet_withcase_count == 0 && $nonet_notie_count  == 0 && $open_pin_nonet_nocase_count == 0 && $withnet_withcase_count == 0 && $open_pin_withnet_nocase_count == 0 && $multidriver_count == 0} {
	  		puts $report "*DM::INFO:  PASS, Total open input no case without net pin NUM: ([expr $nonet_withcase_count + $open_pin_nonet_nocase_count + $withnet_withcase_count + $open_pin_withnet_nocase_count + $nonet_notie_count]).  Total Multi-driver net NUM: ($multidriver_count)\n\n"
	  	} else {
	  		puts $report "DM::INFO: ERROR, Total open input no case without net pin NUM: ([expr $nonet_withcase_count + $open_pin_nonet_nocase_count + $withnet_withcase_count + $open_pin_withnet_nocase_count + $nonet_notie_count]).  Total Multi-driver net NUM: ($multidriver_count)\n\n"
	  	}
	  	close $report
	}

	define_proc_attributes check_netlist \
    	-info "Check netlist in primetime." \
    	-define_args {
       	{-file "Specify the output file name. Default is current directory." "" "string" optional} \
       	{-waive "Specify the input waive list file name." "" "string" optional} \
       	{-template "Specify the template waive list file name." "" "string" optional} \
    }
    #############################################
	# Description    : Check VT ratio
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc check_vt_ratio {args} {
 
    	global sta_vars
    	foreach vt_group $sta_vars(vt_groups) {
    		set loc [lsearch $sta_vars(vt_groups) $vt_group]
    		if {![expr $loc%2]} {
        		set cell_vt_group($vt_group) [lindex $sta_vars(vt_groups) [expr $loc +1 ]]
    		}
    	}

        parse_proc_arguments -args $args results

        if {[info exists results(-file)]} {
            set outFile $results(-file)
        } else {
			set outFile "[pwd]/[get_object_name [get_deisgn]].check_vt_ratio.rpt"
		}

		reportHead -item "Check cell VT ratio." -file $outFile
    	set f1 [open $outFile a]
        set all_cell_num [sizeof [get_cells * -quiet -hier -filter "is_hierarchical==false && ref_name=~ $sta_vars(stdcell)"]]
        set all_cell_area [expr [join [get_attribute [get_cells * -quiet -hier -filter "is_hierarchical==false && ref_name=~ $sta_vars(stdcell)"] area] {+}]]
        array unset cell_count_result *
    	array unset cell_area_result *
    	foreach vtptn [array names cell_vt_group] {
        	foreach ptn $cell_vt_group($vtptn) {
            	set area 0
           		set num [sizeof [get_cells * -quiet -hierarchical -filter "ref_name=~*${ptn} && ref_name=~ $sta_vars(stdcell)"]]
            	if {$num>0} {
            		set area [expr [join [get_attribute [get_cells * -quiet -hierarchical -filter "ref_name=~*${ptn} && ref_name=~ $sta_vars(stdcell)"] area] {+}]]
            	}
            	lappend cell_count_result($vtptn) $num
            	lappend cell_area_result($vtptn) $area
        	}
    	}
    	set all_count_ratio 0
    	set all_area_ratio 0
    	set all_count 0
   		set all_area 0

    	set w1 20; set w2 30; set w3 30; set w4 30 ;set w5 30;
    	set splitline "+[string repeat - $w1]+[string repeat - $w2]+[string repeat - $w3]+[string repeat - $w4]+[string repeat - $w5]+"

    	puts $f1 "$splitline"
    	puts $f1 "[format "|%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s|%-${w5}s|" "VT Group" "Count" "Count Ratio(%)" "Area(um2)" "Area Ratio(%)"]"
    	puts $f1 "$splitline"
    	set vt_results ""
    	foreach vtptn [array names cell_vt_group] {
        	set total_area [expr [join $cell_area_result($vtptn) {+}]]
        	set total_num  [expr [join $cell_count_result($vtptn) {+}]]
        	set ratio_area [format "%.3f" [expr $total_area*100.0/$all_cell_area]]
        	set ratio_num  [format "%.3f" [expr $total_num*100.0/$all_cell_num]]
        	puts $f1 "[format "|%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s|%-${w5}s|" "$vtptn" "$total_num" "$ratio_num" "$total_area" "$ratio_area"]"
        	puts $f1 "$splitline"
        	append vt_results "$vtptn:$ratio_area%, "
        	set staCheckSummaryResults(DESIGN.CELL.VT.RATIO.$vtptn) "$ratio_area%"
    		set all_count_ratio [expr $all_count_ratio + $ratio_num]
    		set all_area_ratio   [expr $all_area_ratio  + $ratio_area]
    		set all_count [expr $all_count + $total_num]
    		set all_area  [expr $all_area  + $total_area]
    	}
    	puts $f1 [format "|%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s|%-${w5}s|" "Total" "$all_count" "$all_count_ratio" "$all_area" "$all_area_ratio"] ; puts $f1 "$splitline"
    	close $f1
	}
    define_proc_attributes check_vt_ratio \
        -info "Check cell vt ratio in primetime." \
        -define_args {
        {-file "Specify the output file name. Default is current directory." "" "string" optional} \
        }
    #############################################
	# Description    : Get timing path noise delay
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc get_timing_path_noise_delay {args} {
        parse_proc_arguments -args $args results
		set TOP [get_object_name [get_design]]
        if {[info exists results(-file)]} {
            set outFile $results(-file)
        } else {
			set outFile "[pwd]/${TOP}.get_timing_path_noise_delay.rpt"
		}
        if {[info exists results(-max_path)]} {
            set max_path $results(-max_path)
        }
		set pba_mode path 
        if {[info exists results(-pba_mode)]} {
            set pba_mode $results(-pba_mode)
        }
		set delay_type max 
        if {[info exists results(-delay_type)]} {
            set delay_type $results(-delay_type)
        }
		set clock_check 0
        if {[info exists results(-clock)]} {
            set clock_check $results(-clock)
        }
		set data_check 0
        if {[info exists results(-data)]} {
            set data_check $results(-data)
        }
		reportHead -item "Get timing path noise delay." -file $outFile
		set f1 [open $outFile a]
        puts $f1 [format "%-10s %-10s %-10s %-20s %-100s" "Nums" " Net_sort_noise_delay" "Thr_net_slack" "Driver_cell" "Net_sort"]
		if {$clock_check == 1} {
			## clock launch path nets
			set tps [get_timing_paths -max_paths $max_path -path_type full_clock_ex -pba_mode $pba_mode -delay_type $delay_type]
        	set launch_clock [get_attribute -q [get_attribute -q $tps launch_clock_paths] points]
	
  			set last_name {}
			set final_nets_list ""
 			foreach_in_collection p $launch_clock {
				if { [get_attribute [get_pins -q [get_object_name [get_attribute $p object]]]  direction] == "in"} {
    				set this_name [get_object_name [get_attribute $p object]]
    				if {$this_name eq $last_name} {continue}
    				set launch_clock_net [get_object_name [get_nets -q -of [get_attribute $p object]]]
    				set last_name $this_name
					lappend final_nets_list $launch_clock_net
				}
  			}
			set final_nets_list_sort [lsort -unique $final_nets_list]
     		puts "[llength $final_nets_list] [llength  $final_nets_list_sort]"
			set numbers 0
      		foreach net_sort $final_nets_list_sort {
				incr numbers
              	set net_sort_noise_delay [get_attribute [get_nets $net_sort] annotated_delay_delta_max]
              	#echo "[llength [lsearch -all $final_nets_list $net_sort ] ]    $net_sort_noise_delay     $net_sort"
	    		set nums [llength [lsearch -all $final_nets_list $net_sort ] ]
				if {$net_sort_noise_delay != 0.000 } {
	     			puts $f1 [format "%-10s %-10.3f %-100s" "$nums" " $net_sort_noise_delay" "$net_sort"]
				}
      		}
			puts "[llength  $final_nets_list_sort]($numbers)"
		}
		if {$data_check == 1} {
        	set tps [get_timing_paths -max_paths $max_path  -pba_mode $pba_mode -delay_type $delay_type]
        	set launch_data  [get_attribute -q $tps points]
        	set last_name {}
        	set final_nets_list ""
        	foreach_in_collection p $launch_data {
                if { [get_attribute [get_pins -q [get_object_name [get_attribute $p object]]]  direction] == "out"} {
                	set this_name [get_object_name [get_attribute $p object]]
                	if {$this_name eq $last_name} {continue}
                	set launch_data_net [get_object_name [get_nets -q -of [get_attribute $p object]]]
                	set last_name $this_name
                	lappend final_nets_list $launch_data_net
                }
        	}
        	set final_nets_list_sort [lsort -unique $final_nets_list]
        	puts $f1 "[llength $final_nets_list] [llength  $final_nets_list_sort]"
        	puts $f1 "## violation num , net_delta_delay , slack, noise net, driver cell "
        	foreach net_sort $final_nets_list_sort {
            	set net_sort_noise_delay [get_attribute [get_nets $net_sort] annotated_delay_delta_max]
                if {$net_sort_noise_delay > 0 } {
                	set nums [llength [lsearch -all $final_nets_list $net_sort ] ]
                	set thr_net_slack [get_attribute  [get_timing_paths  -pba_mode path -through $net_sort] slack]
                	set driver_cell [get_attribute [get_cells -of_objects  [filter_collection [get_pins -of_objects [get_nets $net_sort ]] "direction==out" ] ] ref_name]
                	puts $f1 [format "%-10s %-10.3f %-10.3f %-20s %-100s" "$nums" " $net_sort_noise_delay" "$thr_net_slack" "$driver_cell" "$net_sort"]
                }
        	}
		}
		close $f1
	}
	define_proc_attributes get_timing_path_noise_delay \
    -info "Check data path and clock path noise base on the timing violations in primetime." \
    -define_args {
       {-file "Specify the output file name. Default is current directory." "" "string" optional} \
       {-clock "Specify the check clock path 0 or 1." "" "string" required} \
       {-data "Specify the check data path 0 or 1." "" "string" required} \
       {-max_path "Specify the check timing path num ." "" "string" required} \
       {-pba_mode "Specify the check type ." "" "string" required} \
       {-delay_type  "Specify the check timing type ." "" "string" required} \
    }
    #############################################
	# Description    : report cell status
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc report_cell_status {args} {
    	global sta_vars

		parse_proc_arguments -args $args results
		if {[info exists results(-file)]} {
	    	set outFile $results(-file)
		} else {
			set outFile "report_cell_status.rpt"
		}
		reportHead -item "report cell status." -file $outFile
    	set f1 [open $outFile a]
    	set patterns(combinational)   "is_combinational == true && is_hierarchical == false && ref_name =~ $sta_vars(stdcell) && ref_name !~ $sta_vars(buffer_cell) && ref_name !~ $sta_vars(inverter_cell)"
    	set patterns(sequential)      "is_sequential == true && is_hierarchical == false && ref_name =~ $sta_vars(stdcell) && is_integrated_clock_gating_cell == false"
    	set patterns(buffers)         "ref_name =~ $sta_vars(buffer_cell) && is_hierarchical == false"
    	set patterns(inverters)       "ref_name =~ $sta_vars(inverter_cell) && is_hierarchical == false"
    	set patterns(mems)            "is_memory_cell"
    	set patterns(icg)             "is_integrated_clock_gating_cell&&is_hierarchical==false"
    	set patterns(macro)           "is_memory_cell==false&&is_hierarchical==false&&number_of_pins>25"
    	set patterns(pad_cell)        "is_pad_cell==true"
    	set patterns_list             [list combinational sequential buffers inverters mems icg macro pad_cell]
    	foreach ptn $patterns_list {
			set inst_num 	[lindex [report_cell_info $patterns($ptn)] 0]
			set inst_area 	[lindex [report_cell_info $patterns($ptn)] 1]
			set inst_ratio	[lindex [report_cell_info $patterns($ptn)] 2]%
    	}
    	set w1 20; set w2 30; set w3 30; set w4 30
    	set splitline "[string repeat - $w1]+[string repeat - $w2]+[string repeat - $w3]+[string repeat - $w4]"
    	array unset sumR *
    	set sumR(Count) 0
    	set sumR(Area)  0
    	set sumR(percentage) 0
    	puts $f1 "$splitline"
    	puts $f1  [format "%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s" "Type" "Count" "Area(um2)" "percentage (num%)"]
    	foreach ptn $patterns_list {
        	puts $f1 "$splitline"
        	puts $f1 [format "%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s" $ptn "[lindex [report_cell_info $patterns($ptn)] 0]" "[lindex [report_cell_info $patterns($ptn)] 1]" "[lindex [report_cell_info $patterns($ptn)] 2]"]
        	set sumR(Count) [expr $sumR(Count) + [lindex [report_cell_info $patterns($ptn)] 0]]
        	set sumR(Area)  [expr $sumR(Area)  + [lindex [report_cell_info $patterns($ptn)] 1]]
        	set sumR(percentage) [expr $sumR(percentage) + [lindex [report_cell_info $patterns($ptn)] 2]]
    	}
    	puts $f1 "$splitline"
    	puts $f1 [format "%-${w1}s|%-${w2}s|%-${w3}s|%-${w4}s"  "Total" "$sumR(Count)" "$sumR(Area)" "$sumR(percentage)"]
    	puts $f1 "$splitline"
		close $f1
}
define_proc_attributes report_cell_status \
    -info "report cells instance number." \
    -define_args {
       {-file "Specify the output file name. Default is current directory." "" "string" optional} \
    }
    #############################################
	# Description    : summary design
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc summary_design {args} {
		parse_proc_arguments -args $args results_pre

	    if {[info exists results(-file)]} {
	    	set outFile $results(-file)
	    } else {
            set outFile "[pwd]/[get_object_name [get_design]].pt_constraint.rpt"
        }
		if {! [info exists results_pre(-type)]} {
			set sth ""
		} else { set sth $results_pre(-type)}
			if {! [info exists results_pre(-objects)]} {
				set objects ""
			} else {set objects $results_pre(-objects)}
		if {$sth == ""} {
			puts "summary_design -type pt_constraint"
		}
        reportHead -item "Summary Design ---- pt-constraint" -file $outFile
        set f1 [open $outFile a]
		if {$sth == "pt_constraint"} {
			suppress_message ATTR-3
			suppress_message ATTR-1
			set clocks_name [lsort [get_attr [get_clocks *] full_name]]
			puts $f1 "[format "%-50s %-20s %-20s %-20s %-20s %-20s %-20s %-20s %-20s" "Clock |" "Period |" "Freq |" "Setup_Un |" "Hold_Un |" "Max_tran_clock_fall |" "Max_tran_clock_rise |" "Max_tran_data_fall |" "Max_tran_data_rise"]"

			foreach clock $clocks_name {
				set max_transition_clock_path_fall [get_attr [get_clocks $clock] max_transition_clock_path_fall]
				set max_transition_clock_path_rise [get_attr [get_clocks $clock] max_transition_clock_path_rise]
				set max_transition_data_path_fall [get_attr [get_clocks $clock] max_transition_data_path_fall]
				if {$max_transition_data_path_fall == ""} {set max_transition_data_path_fall [get_attr [current_design] max_transition]}
				set max_transition_data_path_rise [get_attr [get_clocks $clock] max_transition_data_path_rise]
				if {$max_transition_data_path_rise == ""} {set max_transition_data_path_rise [get_attr [current_design] max_transition]}
				set hold_uncertainty [get_attr [get_clocks $clock] hold_uncertainty]
				set setup_uncertainty [get_attr [get_clocks $clock] setup_uncertainty]
				set period [get_attr [get_clocks $clock] period]
				if {$period != ""} {
					set freq [expr 1/$period]
				} else {
					set freq "NA"
				}
				puts $f1 "[format "%-50s %-20s %-20s %-20s %-20s %-20s %-20s %-20s %-20s" "$clock |" "$period |" "$freq |" "$setup_uncertainty |" "$hold_uncertainty |" "$max_transition_clock_path_fall |" "$max_transition_clock_path_rise |" "$max_transition_data_path_fall |" "$max_transition_data_path_rise"]"
			}
		}
        close $f1
	}
	define_proc_attributes summary_design \
	-info "Summary Design" \
	-define_args { \
		{"-type"   "Specify check Design type " "" string optional }
		{"-objects"   "Specify check objects" "" string optional }
        {-file "Specify the report file name." "" "string" optional} \
	}
    #############################################
	# Description    : timing budget 
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc timing_budget_blkGen {args} {

        parse_proc_arguments -args $args results

        set outFile "timing_budget_blkGen.rpt"
        if {[info exists results(-file)]} {
            set outFile $results(-file)
        }
		set check_type setup 
        if {[info exists results(-check_type)]} {
            set check_type $results(-check_type)
        }
		set delay_type max
		if {$check_type == "hold"}  {set delay_type min}
		if {$check_type == "setup"} {set delay_type max}

		set f1 [open $outFile w]

		puts $f1 "[format "%-5s %-20s %-25s %-20s %-20s %-20s %-40s %-20s %-20s" "#Dir" "IOdelay" "timingpathType" "slack" "dataPath" "maxIodelay" "clockName" "clkPeriod" "portName"]"

		foreach portName [get_attr [get_ports * -filter "is_clock_source == false && is_clock_network == false && is_clock_source_network == false"] full_name] {
			set portDirection [get_attr [get_ports $portName] port_direction]
			set temp_tp [get_timing_paths -delay_type $delay_type -through $portName]
			set delay NA ; set slack NA  ; set clockName NA ; set clkPeriod NA ; set dataPath NA ; set maxIodelay NA
			if {$temp_tp == ""} {
				set timingpathType NoPaths
				puts $f1 "[format "%-5s %-20s %-25s %-20s %-20s %-20s %-40s %-20s %-20s" "$portDirection" "$delay" "$timingpathType" "$slack" "$dataPath" "$maxIodelay" "$clockName" "$clkPeriod" "$portName"]"
			} else {
				set slack [get_attr $temp_tp slack] ; if {$slack == "INFINITY"} {set slack NA}
				set timingpathType [get_attr $temp_tp dominant_exception -q] ; 
				if {$timingpathType == "" && $slack == "NA"} {set timingpathType unconstrained} 
				if {$timingpathType == "" && $slack != "NA"} {set timingpathType timingPath}
				if {$portDirection == "in"} {
					set delay [get_attr $temp_tp startpoint_input_delay_value -q]
					set clockName [get_attr [get_attr $temp_tp startpoint_clock -q] full_name]
				}
				if {$portDirection == "out"} {
					set delay [get_attr $temp_tp endpoint_output_delay_value -q]
					set clockName [get_attr [get_attr $temp_tp endpoint_clock -q] full_name]
				}
				if {$portDirection == "inout"} {
					set delay [get_attr $temp_tp endpoint_output_delay_value -q]
					set clockName [get_attr [get_attr $temp_tp endpoint_clock -q] full_name]
					if {$clockName == ""} {set clockName NA}
					if {$delay == ""} {set delay NA}
				}
				set dataPath [lindex [get_attr  [get_attr $temp_tp points -q] arrival ] end]
				if {$dataPath == ""} {set dataPath NA}
				if {$clockName != "" && $clockName != "NA"} {set clkPeriod [get_attr [get_clocks $clockName -q] period]} else {set clockName NA ; set clkPeriod NA}
				if {$delay == ""} {set delay NA}
				if {$clkPeriod == "NA" || $dataPath == "NA"} {
					set maxIodelay NA 
				} else { set maxIodelay [expr $clkPeriod - $dataPath]}
				if {$timingpathType == "multicycle_path"} {
					if {[get_attr $temp_tp endpoint_clock_open_edge_value -q] != "" && $clkPeriod != "NA"} {
						set timingpathType multicycle_path([expr [get_attr $temp_tp endpoint_clock_open_edge_value -q] / $clkPeriod])
						set maxIodelay [expr [get_attr $temp_tp endpoint_clock_open_edge_value -q] - $dataPath]
					} else {
						set timingpathType multicycle_path(noClk) ; set maxIodelay NA
					}
				}
				if {$clkPeriod != "NA"} {
					puts $f1  "[format "%-5s %-20s %-25s %-20s %-20s %-20s %-40s %-20s %-20s" "$portDirection" "$delay" "$timingpathType" "$slack" "$dataPath" "$maxIodelay" "$clockName" "[format %.3f $clkPeriod]" "$portName"]"
				} else {
					puts $f1  "[format "%-5s %-20s %-25s %-20s %-20s %-20s %-40s %-20s %-20s" "$portDirection" "$delay" "$timingpathType" "$slack" "$dataPath" "$maxIodelay" "$clockName" "$clkPeriod" "$portName"]"
				}
				#	puts $f1  "[format "%-20s %-20s %-25s %-20s %-20s %-20s %-40s %-20s %-20s" "#INFO# $portDirection\(portDirection\)" "$delay\(ioDelay\)" "$timingpathType\(timingpathType\)" "$slack\(slack\)" "$dataPath\(dataPath\)" "$maxIodelay\(maxIodelay\)" "$clockName\(clockName\)" "$clkPeriod\(clkPeriod\)" "$portName\(portName\)"]"
			}
		}
 		close $f1
	}
	define_proc_attributes timing_budget_blkGen \
    -info "Generate timing_budget file in block level." \
    -define_args {
       {-file "Specify the output file name. Default is current directory." "" "string" optional} \
       {-check_type  "Specify setup hold  ." "" "string" optional} \
    }
    #############################################
	# Description    : report clock status
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc report_clock_status {args} {

    	set setup_uncertainty_flag 0
    	set hold_uncertainty_flag 0
    	set rise_transition_flag 0
    	set fall_transition_flag 0

		puts [string repeat # 100]
    	puts "# Design : [get_object_name [current_design]]"
    	puts "# Items  : report clock status"
    	puts "# Author : JN-CAD"
    	puts "# Date   : [date]"
   	 	puts [string repeat # 100]

    	#puts [format "%-30s%-20s%-20s%-20s%-20s%-20s%-20s" " clock name"  " period"  " frequency"  " setup uncertainty"  " hold uncertainty"  " transition(r/f)"  " Sinks"]
    	#puts [format "%-30s%-20s%-20s%-20s%-20s%-20s%-20s" "------------" "--------" "-----------" "-------------------" "------------------" "-----------------" "-------"]
		#-------------------------------------------------------------------------------------------------------------------------------
		set all_clk_dict [get_all_clk_info_dict]
		set real_clocks [dict keys [dict filter $all_clk_dict value *real*]]
		puts ""
		puts "#[string repeat - 99]"	
		puts "Info : Total [sizeof_collection [get_clocks *]] clks ,Real_clock [llength $real_clocks] , Generated_clock [sizeof_collection [get_clocks -filter {is_generated == true}]] "
		puts "#[string repeat - 99]"	
		puts [format "%-50s %-15s %-15s %-15s %-25s %-25s %-25s %-30s" "M/G:clockName" "period" "frequency" "sinks" "setup uncertainty" "hold uncertainty" "transition(r/f)" "Source"] 
		puts "#[string repeat - 99]"	
    	foreach clockName [get_attr [get_clocks $real_clocks -q -filter "is_generated == false" ] full_name] { 
			set temp_dict ""
			set temp_dict          [dict get [dict filter $all_clk_dict value *real*] $clockName]
			set freq               [dict get $temp_dict frequency]
			set nu_sink            [dict get $temp_dict loadNum]
			set setup_uncer        [dict get $temp_dict setup_uncertainty]
			set hold_uncer         [dict get $temp_dict hold_uncertainty]
			set soucePoint         [dict get $temp_dict sourcePoint]
			set period             [dict get $temp_dict period] 
			set clock_transition   [dict get $temp_dict clock_transition] 
			puts [format "%-50s %-15s %-15s %-15s %-25s %-25s %-25s %-30s" M:$clockName $period $freq $nu_sink $setup_uncer $hold_uncer $clock_transition $soucePoint]
			check_generated_clock $clockName
		}
    	set V_CLK [remove_from_collection [get_clocks *] [filter_collection [get_clocks  *]  defined(sources)]]
    	foreach_in_collection virtual_clk $V_CLK {
			puts ""
			puts "#[string repeat - 99]"
        	puts [format "%-20s " " virtual clock:"]
        	puts [format "%-20s" " ------------"]
        	puts [format "%-20s" " [get_attribute $virtual_clk full_name]"]
    	}
    	set clockDefinedOnHierPinNum 0
    	set clockDefinedOnPortNum 0
    	set clockDefinedOnPinNum 0
    	set clockDefinedNoSourcesNum 0
    	foreach_in_collection id [get_clocks *] {
        	set source_point [get_attribute [get_clocks $id] sources]
        	if {[get_attribute $source_point object_class] == "pin"} {
            	if {[get_attribute $source_point is_hierarchical] == "true"} {
                	incr clockDefinedOnHierPinNum 1
                	puts "Error: the clock [get_attribute $id full_name] defined on hierarchical port: [get_attribute $source_point full_name]"
            	} else {
                	incr clockDefinedOnPinNum 1
            	}
        	} elseif {[get_attribute $source_point object_class] == "port"} {
            	incr clockDefinedOnPortNum 1
        	} else {
            	incr clockDefinedNoSources 1
        	}
    	}
    	set no_sink_clock_num 0
    	foreach_in_collection id [get_clocks *] {
        	set sources [get_attribute [get_attribute [get_clocks $id] sources] full_name]
        	if {[sizeof_collection [get_attribute [get_clocks $id] sources] ]} {
            	if {[sizeof_collection [ all_fanout -from  [get_attribute [get_clocks $id] sources ] -flat -end ]]} {
                    set clock_loads_num [sizeof_collection [ all_fanout -from  [get_attribute [get_clocks $id] sources ] -flat -end ]]
                    if {$clock_loads_num == 0} {
                        incr no_sink_clock_num 1
                        puts "Warning: the clock [get_attribute $id full_name] is no sinks."
                    }
            	}
        	}
    	} 
	}
    #############################################
	# Description    : timing budget top
	# Auther         : David
	# Version        : 1.0.0 2024/12/11
	#############################################
	proc timing_budget_topGen {args} {
	
    	parse_proc_arguments -args $args results
    	global TOP RPT_DIR SESSION

    	set outFile "timing_budget_topGen.rpt"
    	if {[info exists results(-topGenFile)]} {
        	set outFile $results(-topGenFile)
    	}

    	if {[info exists results(-blkFile)]} {
        	set subblkFile $results(-blkFile)
    	}

    	if {[info exists results(-blkName)]} {
        	set subblkName $results(-blkName)
    	}

		set check_type "setup"
    	if {[info exists results(-check_type)]} {
        	set check_type $results(-check_type)
    	}

		set checkToCustomer 0
		set checkReportDetail 0 
    	if {[info exists results(-checkToCustomer)]} {
			set checkToCustomer 1
   		}

    	if {[info exists results(-details)]} {
			set checkReportDetail 1
   		}
   		if {$check_type == "hold"} {set delay_type min}
   		if {$check_type == "setup"} {set delay_type max}


		set f1 [open $outFile w]
		### get sub-blk io information
		set file_contents [read_blkGen_file $subblkFile]
   		set cnt_input_case1  0
   		set cnt_input_case2  0
   		set cnt_input_case3  0
   		set cnt_input_case4  0
   		set cnt_output_case1 0
   		set cnt_output_case2 0
   		set cnt_output_case3 0
   		set cnt_output_case4 0

		array unset blkIO_array *
		array unset topIO_array *
		set allPorts ""
		foreach line $file_contents {
		    if {![regexp \# $line]} {
	        	set dir [lindex $line 0] ; set iodelay [lindex $line 1] ; set timingpathType [lindex $line 2] ; set slack [lindex $line 3] ; set dataPath [lindex $line 4] ; set clockName [lindex $line 6] ; set clkPeriod [lindex $line 7] ; set portName [lindex $line 8]
	        	if {[llength $line] == 8} {
	        		set dir [lindex $line 0] ; set iodelay [lindex $line 1] ; set timingpathType [lindex $line 2] ; set slack [lindex $line 3] ; set dataPath [lindex $line 4] ; set clockName [lindex $line 6] ; set clkPeriod NA ; set portName [lindex $line 7]
				}
		    	append allPorts $portName " "
		    	set blkIO_array($portName,dir) $dir
		    	set blkIO_array($portName,iodelay) $iodelay
		    	set blkIO_array($portName,timingpathType) $timingpathType
		    	set blkIO_array($portName,slack) $slack
		   		set blkIO_array($portName,dataPath) $dataPath
		    	set blkIO_array($portName,clockName) $clockName
		    	set blkIO_array($portName,clkPeriod) $clkPeriod
			}
		}
		###  
		set blkFullNames [get_object_name  [get_cells  * -hierarchical  -filter "ref_name == $subblkName" ]]

		foreach portName $allPorts {
			set delay NA ; set slack 1000  ; set clockName NA ; set clkPeriod NA ; set dataPath NA
			set porttimingpath ""
			#### foreach all blocks results 
			foreach blkName $blkFullNames {
				set hierPortname [concat $blkName/$portName]		
				set hierPort_direction [get_attr [get_pins $hierPortname] direction]
				set top_temp_tp [get_timing_paths -delay_type $delay_type -through $hierPortname]
				if {$checkReportDetail == 1} {
                	echo "report_timing -nosplit -delay_type $delay_type -through $hierPortname  -input_pins -include_hierarchical_pins -transition_time -nets -path_type full_clock_expanded" >> $outFile.details
					report_timing -nosplit -delay_type $delay_type -through $hierPortname  -input_pins -include_hierarchical_pins -transition_time -nets -path_type full_clock_expanded  >> $outFile.details
				}
            	if {$top_temp_tp == ""} {
            		set timingpathType NoPaths
					set slack NA
           		} else { 
					set Slack_tps [get_attr $top_temp_tp slack -q] 
					if {$Slack_tps == "INFINITY"} {
						set slack NA
						set timingpathType [get_attr $top_temp_tp dominant_exception -q]
						if {$timingpathType == "" && $slack == "NA"} {set timingpathType unconstrained}
					} else {
						if {$Slack_tps < $slack } {
							# get min slack of all block
							set slack $Slack_tps
							set dataPath [lindex [get_attr  [get_attr $top_temp_tp points] arrival ] end]

                	        if {$hierPort_direction == "in"} {
                	        	set delay [get_ioDelay_top $top_temp_tp $hierPortname $hierPort_direction]
                	        	set clockName [get_attr [get_attr $top_temp_tp startpoint_clock -q] full_name]
                	        }
                	        if {$hierPort_direction == "out"} {
                	        	set delay [get_ioDelay_top $top_temp_tp $hierPortname $hierPort_direction]
                	        	set clockName [get_attr [get_attr $top_temp_tp endpoint_clock -q] full_name]
                	        }
                	        if {$hierPort_direction == "inout"} {
                	        	set delay NA ; set clockName NA
                	        }
						}
						set timingpathType [get_attr $top_temp_tp dominant_exception -q]
						if {$timingpathType == "" && $slack != "NA"} {set timingpathType timingPath}
					}
				}
				#
				if {$dataPath == ""} {set dataPath NA}
				if {$clockName == ""} {set clockName NA}
				if {$clockName != "NA"} {set clkPeriod [get_attr [get_clocks $clockName -q] period]} else {set clkPeriod NA}
				if {$delay == ""} {set delay NA}
				if {$timingpathType == "multicycle_path"} {
					if {[get_attr $top_temp_tp endpoint_clock_open_edge_value -q] != ""} { 
						set timingpathType multicycle_path([expr [get_attr $top_temp_tp endpoint_clock_open_edge_value -q] / $clkPeriod])
					} else {
						set timingpathType multicycle_path(noClk)
					} 
				}
				## print top timing info of block
				puts $f1 "[format "%-5s %-15.8s %-25s %-15.8s %-20.8s %-40s %-15.8s %-20s" "$hierPort_direction" "$delay" "$timingpathType" "$slack" "$dataPath" "$clockName" "$clkPeriod" "$hierPortname"]"
				lappend porttimingpath $timingpathType
			}
			set porttimingpath [lsort -u $porttimingpath]
			if {[regexp NoPaths|false_path|unconstrained $porttimingpath] && [regexp timingPath|min_max_delay|multicycle_path|path_margin $porttimingpath]} {
				set timingpathType "partialUnconstrainted"
			}
			## set array 
        	set topIO_array($portName,dir) $hierPort_direction
        	set topIO_array($portName,iodelay) $delay
        	set topIO_array($portName,timingpathType) $timingpathType
        	set topIO_array($portName,slack) $slack
        	set topIO_array($portName,dataPath) $dataPath
        	set topIO_array($portName,clockName) $clockName
        	set topIO_array($portName,clkPeriod) $clkPeriod

			set clocks $blkIO_array($portName,clockName)
			set delays $blkIO_array($portName,iodelay)
			set blkSlack $blkIO_array($portName,slack)
			set topSlack $topIO_array($portName,slack)
			set Pins     $portName
			if {$blkSlack != "NA" && $topSlack != "NA"} {
				########################################## inputs budget
                if {$hierPort_direction == "in" } {
                    if {$topSlack < 0 && $blkSlack > 0} {
                        incr cnt_input_case1
                        if {[expr $blkSlack + $topSlack ] < 0} {
                            set newDelays [expr $delays - $topSlack + $blkSlack + 0.01 ]
                        } else {
                            set newDelays [expr $delays - $topSlack + 0.01]
                        }
                        if {$checkToCustomer == 0} {
                        	puts $f1  "#input#case1# topSlack: $topSlack  blkSlack: $blkSlack  oldDelay: $delays  newDelay: $newDelays $Pins"
                        	puts $f1  "set_input_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -fall  \[get_ports  $Pins\] "
                        	puts $f1  "set_input_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -rise  \[get_ports  $Pins\] "
                        }
                    }

                    if {$topSlack > 0 && $blkSlack < 0} {
                        incr cnt_input_case2
                        set newDelays [expr $delays + $blkSlack - 0.002]
                        if {$checkToCustomer == 0} {
                            puts $f1  "#input#case2# topSlack: $topSlack  blkSlack: $blkSlack  oldDelay: $delays  newDelay: $newDelays $Pins"
                            puts $f1  "set_input_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -fall  \[get_ports  $Pins\] "
                            puts $f1  "set_input_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -rise  \[get_ports  $Pins\] "
                        }
                    }
                    if {$topSlack >= 0 && $blkSlack >= 0} {
                        incr cnt_input_case3
						set newDelays [expr $blkSlack/2]
                        if {$checkToCustomer == 0} {
							if {$blkSlack == 0 } {
                                puts $f1  "#input#case3 topSlack: $topSlack blkSlack: $blkSlack $Pins"
							} else {
								set min_slack 100
								if {$topSlack < $min_slack} { set min_slack $topSlack}
								if {$blkSlack < $min_slack} { set min_slack $topSlack}
								set range1_tmp [expr $min_slack/2]
								set range2 [expr $range1_tmp + $delays]
								set newDelays [RandomRange $delays $range2]
                                puts $f1  "#input#case3 topSlack: $topSlack blkSlack: $blkSlack $Pins"
                		        puts $f1  "#set_input_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -fall  \[get_ports  $Pins\] "
 		                        puts $f1  "#set_input_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -rise  \[get_ports  $Pins\] "
							}
                        }
                    }
                    if {$topSlack <= 0 && $blkSlack <= 0} {
                        incr cnt_input_case4
                        if {$checkToCustomer == 0} {
							set range2 [expr 0.002 + $delays]
							set newDelays [RandomRange $delays $range2]
                            puts $f1  "#input#case4 topSlack: $topSlack blkSlack: $blkSlack $Pins"
                		    puts $f1  "#set_input_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -fall  \[get_ports  $Pins\] "
 		                    puts $f1  "#set_input_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -rise  \[get_ports  $Pins\] "
                        }
                    }
                }
				########################################## outputs budget
                if {$hierPort_direction == "out" } {
                    if {$topSlack < 0 && $blkSlack > 0} {
                        incr cnt_output_case1
                        set newDelays [expr $delays - $topSlack + $blkSlack + 0.01 ]
                        if {$checkToCustomer == 0} {
                            puts $f1  "#output#case1 topSlack: $topSlack  blkSlack: $blkSlack  oldDelay: $delays  newDelay: $newDelays $Pins "
                            puts $f1  "set_output_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -fall  \[get_ports  $Pins\] "
                            puts $f1  "set_output_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -rise  \[get_ports  $Pins\] "
                        }
                    }
                    if {$topSlack > 0 && $blkSlack < 0} {
                        incr cnt_output_case2
                        set newDelays [expr $delays + $blkSlack - 0.002]
                        if {$checkToCustomer == 0} {
                            puts $f1  "#output#case2# topSlack: $topSlack  blkSlack: $blkSlack  oldDelay: $delays  newDelay: $newDelays $Pins"
                            puts $f1  "set_output_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -fall  \[get_ports  $Pins\] "
                            puts $f1  "set_output_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -rise  \[get_ports  $Pins\] "
                        }
                    }
                    if {$topSlack >= 0 && $blkSlack >= 0} {
                        incr cnt_output_case3
                        if {$checkToCustomer == 0} {
							if {$blkSlack == 0 } {
                                puts $f1  "#output#case3 topSlack: $topSlack blkSlack: $blkSlack $Pins"
							} else {
								set min_slack 100
								if {$topSlack < $min_slack} { set min_slack $topSlack}
								if {$blkSlack < $min_slack} { set min_slack $topSlack}
								set range1_tmp [expr $min_slack/2]
								set range2 [expr $range1_tmp + $delays]
								set newDelays [RandomRange $delays $range2]
                                puts $f1  "#output#case3 topSlack: $topSlack blkSlack: $blkSlack $Pins"
                		        puts $f1  "#set_input_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -fall  \[get_ports  $Pins\] "
 		                        puts $f1  "#set_input_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -rise  \[get_ports  $Pins\] "
							}
                    	}
                    }
                    if {$topSlack <= 0 && $blkSlack <= 0} {
                        incr cnt_output_case4
                        if {$checkToCustomer == 0} {
							set range2 [expr 0.002 + $delays]
							set newDelays [RandomRange $delays $range2]
                            puts $f1  "#output#case4 topSlack: $topSlack blkSlack: $blkSlack $Pins"
                		    puts $f1  "#set_input_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -fall  \[get_ports  $Pins\] "
 		                    puts $f1  "#set_input_delay  $newDelays  -clock \[get_clocks {$clocks}\]  -max  -rise  \[get_ports  $Pins\] "
                        }
                    }
                }
			}
		}
		#### print block and top constraints comparison
		array unset all_caseNote_dict *
		foreach portName $allPorts {
			set hierPortname [concat $blkName/$portName]
	        set hierPort_direction [get_attr [get_pins $hierPortname] direction]
	        set blkConstraints $blkIO_array($portName,timingpathType)
	        set topConstraints $topIO_array($portName,timingpathType)
	        set blkConstraints_mode 1 ; set topConstraints_mode 1;
	        if {[regexp NoPaths|false_path|unconstrained $blkConstraints]} {set blkConstraints_mode 0}
	        if {[regexp NoPaths|false_path|unconstrained|partialUnconstrainted $topConstraints]} {set topConstraints_mode 0}
	        if {$topConstraints_mode != $blkConstraints_mode} {
	            if {$topConstraints_mode < $blkConstraints_mode} {
					if {$topConstraints == "partialUnconstrainted"} {
						set caseNote [concat "#WARN#case1_0:$topConstraints,$blkConstraints"]
					} else {
						set caseNote [concat "#WARN#case1_1:$topConstraints,$blkConstraints"]
					}
	    		} else {
	        		set caseNote [concat "#WARN#case2:$topConstraints,$blkConstraints"]
	    		}
	        } else {
	        	if {$topConstraints_mode == 0 && $blkConstraints_mode == 0} {
					if {$topConstraints == "partialUnconstrainted"} {
						set caseNote [concat "#WARN#case1_2:$topConstraints,$blkConstraints"]
					} else {
						set caseNote [concat "#INFO#case1:$topConstraints,$blkConstraints"]
					}
				}
	            if {$topConstraints_mode == 1 && $blkConstraints_mode == 1} {
	                if {$topConstraints == $blkConstraints} {
	                    if {$topIO_array($portName,slack) > 0} {
	                        set caseNote [concat "#INFO#case2:$topConstraints,$blkConstraints"]
	                    } else {
	                        if {$blkIO_array($portName,slack) > 0} {
	                            set caseNote [concat "#WARN#case3:$topConstraints,$blkConstraints"]
	                        } else {
	                            set caseNote [concat "#WARN#case4:$topConstraints,$blkConstraints"]
	                        }
	                    }
	                } else {
	                 	set caseNote [concat "#INFO#case3:$topConstraints,$blkConstraints"]
	                }
	        	}
	        }
	        lappend all_caseNote_dict($caseNote) "$hierPort_direction:$hierPortname:$blkIO_array($portName,slack):$topIO_array($portName,slack)"
		}
		## puts information
		foreach key [array names all_caseNote_dict] {
			set caseName [lindex [split $key ":"] 0]
			set top_con [lindex [split [lindex [split $key ":"] end] ","] 0] 
			set blk_con [lindex [split [lindex [split $key ":"] end] ","] end]
			foreach point $all_caseNote_dict($key) {
				set hierPort_direction	[lindex [split $point ":"] 0]
				set hierPortname 				[lindex [split $point ":"] 1]
				set portName 						[file tail $portName]
				set blk_slack 					[lindex [split $point ":"] 2]
				set top_slack 					[lindex [split $point ":"] 3]
				puts $f1 "[format "%-10s %-20s %-30s %-10s %-20s %-25s %-20s" "$caseName :" "$top_con\(top\)" "$blk_con\(blk\)" "$hierPort_direction" "$top_slack\(top_slack\)" "$blk_slack\(blk_slack\)" "$hierPortname"]"
      			puts $f1 "[format "%-20s %-15.8s %-25s %-15.8s %-20.8s %-40s %-15.8s %-20s" "$caseName : $hierPort_direction\(hierPort_Dir\)" "$topIO_array($portName,iodelay)\(ioDelay\)" "$topIO_array($portName,timingpathType)\(timingpathType\)" "$top_slack\(top_slack\)" "$blk_slack\(blk_slack\)" "$topIO_array($portName,clockName)\(clockName\)" "$topIO_array($portName,clkPeriod)\(clkPeriod\)" "$hierPortname\(hierPortname\)"]"
			}	
		}
		## summary
		puts $f1 "##=======================##"
		puts $f1 "##        Summary        ##"
		puts $f1 "##=======================##"
  		puts $f1 "##CaseNote:"
		puts $f1 "#WARN#case1_0 : the blk level has constraints , the top level is partial NoPaths|false_path|unconstrained "
		puts $f1 "#WARN#case1_1 : the blk level has constraints , the top level is NoPaths|false_path|unconstrained"
		puts $f1 "#WARN#case1_2 : the blk level has unconstraints , the top level is partial NoPaths|false_path|unconstrained "
		puts $f1 "#WARN#case2   : the top level has constraints , the blk level is NoPaths|false_path|unconstrained"
		puts $f1 "#WARN#case3   : the top & blk level have same io constraints ; top slack < 0 , blk slack > 0 ; need to update io constraints at blk level to fix these timing paths"
		puts $f1 "#WARN#case4   : the top & blk level have same io constraints ; but both have timing violation , please confirm"
		puts $f1 "#INFO#case1   : the top & blk both not constraints"
		puts $f1 "#INFO#case2   : the top & blk level have same io constraints , top slack > 0"
		puts $f1 "#INFO#case3   : the top & blk both have constraints , but different constraints"
		puts $f1 ""
		puts $f1 "[format "%-15s %-15s %-30s %-20s" "CaseName" "CaseNum" "TOP_Constraints" "BLK_Constraints"]"
		foreach key [array names all_caseNote_dict] {
			set caseName [lindex [split $key ":"] 0]
			set caseNote [lindex [split $key ":"] end]
			set top_con [lindex [split $caseNote ","] 0]
			set blk_con [lindex [split $caseNote ","] end]
			set caseNum [llength $all_caseNote_dict($key)] ;
			puts $f1 "[format "%-15s %-15s %-30s %-20s" "$caseName" "$caseNum" "$top_con" "$blk_con"]"
  		}
		puts $f1 ""
		close $f1
	}
	define_proc_attributes timing_budget_topGen \
    -info "Generate timing_budget file in block level." \
    -define_args {
       {-blkFile "Specify the input sub-block file name. " "" "string" required} \
       {-topGenFile "Specify the output timing budget file name.." "" "string" required} \
       {-blkName   "Specify the sub-block ref name." "" "string" required} \
       {-check_type "Specify check type setup hold" "" "string" optional}
       {-checkToCustomer   "if true, will generate #WARN#case2# #WARN#case3# only." "Bool" "string" optional} \
       {-details   "if true, will generate #WARN#case2# #WARN#case3# only." "Bool" "string" optional} \

    }
}
