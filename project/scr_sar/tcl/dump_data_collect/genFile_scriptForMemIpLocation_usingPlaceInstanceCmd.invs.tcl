#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/12/02 14:28:19 Tuesday
# label     : 
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Write out the positions and orientations of mem or ip using placeInstance, and then use them in new versions such 
#             as 95pv2->100p to solve the impact of def's forced introduction of new mem, ip, or terms. This script only places 
#             existing mem or ip and will not introduce new mem or ip.
# return    : tcl output file
# ref       : link url
# --------------------------
proc genFile_scriptForMemIpLocation {args} {
  set outputfilename "./mem_placeInstance_forFP_at[clock format [clock second] -format "%Y%m%d_%H%M"].tcl"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set allPlacedMemAndIP_ptr [dbget [dbget top.insts.cell.subClass block -p2].pstatus {^placed|fixed} -regexp -p -e]
  if {$allPlacedMemAndIP_ptr ne ""} {
    set cmdsList [lmap temp_memip_ptr $allPlacedMemAndIP_ptr {
      set temp_pt {*}[dbget $temp_memip_ptr.pt -e] 
      set temp_memip_name [dbget $temp_memip_ptr.name -e]
      set temp_orient [dbget $temp_memip_ptr.orient -e]
      set temp_halo_top [dbget $temp_memip_ptr.pHaloTop -e]
      set temp_halo_bottom [dbget $temp_memip_ptr.pHaloBot -e]
      set temp_halo_left [dbget $temp_memip_ptr.pHaloLeft -e]
      set temp_halo_right [dbget $temp_memip_ptr.pHaloRight -e]
      set temp "placeInstance $temp_memip_name \{$temp_pt\} $temp_orient -fixed\naddHaloToBlock -snapToSite -ori $temp_orient $temp_halo_left $temp_halo_bottom $temp_halo_right $temp_halo_top $temp_memip_name"
    }]
    set fo_temp [open $outputfilename w]
    puts $fo_temp [join $cmdsList \n]
    close $fo_temp
  } else {
    error "proc genFile_scriptForMemIpLocation: check your invs db: there is no mem or ip!!!"
  }
}

define_proc_arguments genFile_scriptForMemIpLocation \
  -info "write script for mem or ip"\
  -define_args {
    {-outputfilename "specify output file of script" AString string optional}
  }
