#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/12/09 18:05:38 Tuesday
# label     : task_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Set the content of each group path through a more convenient interface, with multiple checking effects, and the results are returned in the form of a command list.
# return    : cmds list
# ref       : link url
# --------------------------
source ../../packages/every_any.package.tcl; # every
proc genCmd_setPathGroup_invs {args} {
  set debug 0
  set memCelltypeExp {^ram_.*} ; # The regular expression you write needs to exactly match the entire name of the celltype/ref_name. using for filter_collection cmd, can define using args
  set all_regs [all_registers]
  set macros [all_registers -macros]
  set mems [filter_collection -regexp [all_registers -macros] [subst {ref_name =~ "$memCelltypeExp"}]]
  set ips [remove_from_collection $macros $mems]
  set regs_and_icgs $all_regs
  set regs_and_icgs [remove_from_collection $regs_and_icgs $mems]
  set regs_and_icgs [remove_from_collection $regs_and_icgs $ips]
  set icgs [filter_collection $regs_and_icgs "is_integrated_clock_gating_cell"] ; # icg: integrated clock gating cell
  set regs [remove_from_collection $regs_and_icgs $icgs]
  set in_ports [all_inputs -no_clocks]
  set out_ports [all_outputs]
  
  set basic_default_groupPartName [list regs icgs regs_and_icgs mems ips in_ports out_ports]
  # The first column must be groupName, and the other columns can be combined in any order, but they must be the option names of group_path.
  # can define using args
  set baseConfigList [subst -nobackslashes {
    {groupName from to effortLevel weight targetSlack}
    {reg2reg $regs_and_icgs $regs_and_icgs  high 10 0}
    {reg2icg $regs          $icgs           high 10 0}
    {reg2mem $regs_and_icgs $mems           high 10 0}
    {mem2reg $mems          $regs_and_icgs  high 10 0}
    {mem2icg $mems          $icgs           high 10 0}
    {reg2ip  $regs_and_icgs $ips            high 5 0}
    {ip2reg  $ips           $regs_and_icgs  high 5 0}
    {ip2ip   $ips           $ips            high 5 0}
    {in2out  $in_ports      $out_ports      low 1 0}
    {reg2out $regs_and_icgs $out_ports      low 1 0}
    {in2reg  $in_ports      $regs_and_icgs  low 1 0}
  }]
  # NOTICE: this title 'earlyOrLate' is fixed that is not changed!!!
  # If the content of a certain column in your data is "/", it means that the content of this column will not set any value in the command.
  # The groupName in extraOptionsList must have appeared in baseConfigList.
  set extraOptionsList [subst -nobackslashes {
    {groupName skewingSlackConstraint slackAdjustment slackAdjustmentPriority earlyOrLate view} 
    {in2out 0.03  "/" "/" "/" "/" }
  }]
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set firstItemLength [llength [lindex $baseConfigList 0]]
  if {![every x $baseConfigList { expr {[llength $x] == $firstItemLength} }]} {
    error "proc genCmd_setPathGroup_invs: check your input: baseConfigList: The length of each sublist is inconsistent."
  }
  set keyWord1 "from" ; set keyWord2 "to"
  if {$keyWord1 ni [lindex $baseConfigList 0] || $keyWord2 ni [lindex $baseConfigList 0]} {
    error "proc genCmd_setPathGroup_invs: The first header in the list must contain the two items 'from' and 'to'."
  }
  set cmdsList [list]
  lappend cmdsList "reset_path_group -all"
  lappend cmdsList "resetPathGroupOptions"
  set userOptionSequenceList [list] 
  set num_notSet 0 ; set num_haveSet 0
  set groupnames_from_to_list [list]
  foreach temp_pathgroup_config $baseConfigList {
    if {$userOptionSequenceList eq ""} { set userOptionSequenceList $temp_pathgroup_config }
    if {[lindex $userOptionSequenceList 0] ne "groupName"} {
      error "proc genCmd_setPathGroup_invs: check your baseConfigList: The first sublist must be the header, and the \n\
        first item of the header must be groupName, which needs to be filled in and set according to the requirements." 
    } elseif {$userOptionSequenceList ne "" && $userOptionSequenceList ne $temp_pathgroup_config} {
      lassign $temp_pathgroup_config {*}$userOptionSequenceList
      set flagOfEmpty 0
      foreach temp_item [list from to] {
        if {[regexp {^0x[0-9a-z]{1,}$} [subst \${$temp_item}]]} { ; # must be collection data type
          if {$temp_item eq "from"} { set len_from [sizeof_collection [subst \${$temp_item}]] }
          if {$temp_item eq "to"} { set len_to [sizeof_collection [subst \${$temp_item}]] }
        } else {
          error "proc genCmd_setPathGroup_invs: check your baseConfigList: 'from' and 'to' is not collection data type!!!" 
        }
      }
      if {$len_from == 0 || $len_to == 0} { set flagOfEmpty 1 } else { set flagOfEmpty 0 }
      if {!$flagOfEmpty} {
        lappend groupnames_from_to_list [list haveset $groupName $len_from $len_to]
        incr num_haveSet
        lappend cmdsList "group_path -name $groupName -from \{[get_object_name $from]\} -to \{[get_object_name $to]\}"
        set other_userOptionSequenceList [lsearch -regexp -not -all -inline $userOptionSequenceList {groupName|from|to}]
        set temp_setPathGroupOption_cmd_option [list]
        foreach temp_user_option $other_userOptionSequenceList {
          lappend temp_setPathGroupOption_cmd_option "-$temp_user_option" [subst \${$temp_user_option}] 
        }
        lappend cmdsList "setPathGroupOptions $groupName $temp_setPathGroupOption_cmd_option"
      } else {
        lappend groupnames_from_to_list [list notset $groupName $len_from $len_to]
        incr num_notSet
      }
    }
  }
  if {$debug} { 
    foreach temp_groupname_from_to $groupnames_from_to_list {
      lassign $temp_groupname_from_to ifSet temp_groupname len_from len_to
      if {$ifSet eq "haveset"} { 
        puts "(already set pathgroup) groupName : $temp_groupname  | 'from' length: $len_from  | 'to' length: $len_to"
      } elseif {$ifSet eq "notset"} { 
        puts "(not set pathgroup) groupName : $temp_groupname  | 'from' length: $len_from  | 'to' length: $len_to" 
      } else {
        error "proc genCmd_setPathGroup_invs: check your script: internal value of var \$ifSet($ifSet) is not valid!!!" 
      }
    }
  }
  if {$debug} { puts "total pathgroup that have set: $num_haveSet , total pathgroup that not set: $num_notSet" }
  lappend cmdsList "get_object_name \[get_path_groups *\]"
  lappend cmdsList "reportPathGroupOptions"
  return $cmdsList
}

define_proc_arguments genCmd_setPathGroup_invs \
  -info "gen cmd to set config path group for invs.\n\
         All variables of 'from' and 'to' need to be written in the data format of collection."\
  -define_args {
    {-memExp "specify the expression for memory" AString string optional}
    {-baseConfigList "specify baseConfig list" AString string optional}
    {-debug "debug mode" "" boolean optional}
  }

