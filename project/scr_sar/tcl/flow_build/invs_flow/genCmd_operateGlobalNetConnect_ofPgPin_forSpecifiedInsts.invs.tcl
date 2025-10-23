#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/23 12:25:19 Thursday
# label     : eco_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : Modify GNC (GlobalNetConnect) for the specified insts' pgpin, committed to batch operations, semantically interpreting 
#             command execution rules, and ensuring the command execution process is sequential.
# return    : cmds List
# ref       : link url
# --------------------------
# TO_WRITE
proc genCmd_operateGlobalNetConnect_ofPgPin_forSpecifiedInsts {args} {
  set typeOfOperating "disconnect" ; # disconnect|connect|createPinAndConnect|getGNC
  set insts           [list]
  set typeOfPin       "pgpin" ; # pgpin
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$typeOfOperating ni [list disconnect connect createPinAndConnect]} {
    error "proc genCmd_operateGlobalNetConnect_ofPgPin_forSpecifiedInsts: check your input: \$typeOfOperating only be one of disconnect|connect|createPinAndConnect"
  } elseif {$typeOfOperating eq "disconnect"} {
    if {![llength $insts]} {
      error "proc genCmd_operateGlobalNetConnect_ofPgPin_forSpecifiedInsts: check your input: length of var:\$insts is empty!!!" 
    } else {
      if {$typeOfPin ni [list pgpin]} {
        error "proc genCmd_operateGlobalNetConnect_ofPgPin_forSpecifiedInsts: check your input: \$typeOfPin is only one of pgpin|..."
      } elseif {$typeOfPin eq "pgpin"} {
        set list_pgpins_toDisconnect [list]
        set cmdsList_toDisconnect [list]
        set list_instOfNotHavePgPin_toDisconnect [list]
        foreach temp_inst $insts {
          set allpgpins_ofInst [dbget [dbget top.insts.name $temp_inst -p].pgInstTerms.name -e]
          if {![llength $allpgpins_ofInst]} {
            lappend list_instOfNotHavePgPin_toDisconnect $temp_inst 
          } else {
            lappend list_pgpins_toDisconnect [list $temp_inst $allpgpins_ofInst] ; # RESERVED: This command is reserved to facilitate future expansion.
            lappend cmdsList_toDisconnect {*}[lmap temp_pgpin $allpgpins_ofInst {
              set temp "globalNetConnect -disconnect -sinst $temp_inst -pin $temp_pgpin -override" 
            }]
          }
        }
        if {[llength $list_instOfNotHavePgPin_toDisconnect]} {
          puts "proc genCmd_operateGlobalNetConnect_ofPgPin_forSpecifiedInsts: WARN: there are some insts that is not have pgpins:\n\t[join $list_instOfNotHavePgPin_toDisconnect \n]\n\n" 
        }
        return $cmdsList_toDisconnect
      }
    }
  } elseif {$typeOfOperating eq "getGNC"} {
    if {![llength $insts]} {
      error "proc genCmd_operateGlobalNetConnect_ofPgPin_forSpecifiedInsts: check your input: length of var:\$insts is empty!!!" 
    } else {
      if {$typeOfPin ni [list pgpin]} {
        error "proc genCmd_operateGlobalNetConnect_ofPgPin_forSpecifiedInsts: check your input : \$typeOfPin is only one of pgpin|..."
      } elseif {$typeOfPin eq "pgpin"} {
        set list_pgpins_toGetGNC [list]
        set cmdsList_toGetGNC [list]
        set list_instOfNotHavePgPin_toGetGNC [list]
        foreach temp_inst $insts {
          set allpgpins_ofInst [dbget [dbget top.insts.name $temp_inst -p].pgInstTerms.name -e]
          if {![llength $allpgpins_ofInst]} {
            lappend list_instOfNotHavePgPin_toGetGNC $temp_inst 
          } else {
            lappend list_pgpins_toGetGNC [list $temp_list $allpgpins_ofInst] ; # RESERVED 
            lappend cmdsList_toGetGNC {*}[lmap temp_pgpin $allpgpins_ofInst {
              set temp_net [dbget [dbget top.insts.pgInstTerms.name $temp_pgpin -p].net.name -e]
              if {$temp_net eq ""} {
                set temp "# pg pin($temp_pgpin) of inst($temp_inst) have no net to connect!!!"
              } else {
                set temp "globalNetConnect $temp_net -sinst $temp_inst -type pgpin -pin $temp_pgpin -override" 
              }
              set temp
            }]
            if {[llength $list_instOfNotHavePgPin_toGetGNC]} {
              puts "proc genCmd_operateGlobalNetConnect_ofPgPin_forSpecifiedInsts: WARN: there are some insts that is not have pgpins:\n\t[join $list_instOfNotHavePgPin_toGetGNC \n]\n\n" 
            }
            return $cmdsList_toGetGNC
          }
        }
      }
    }
  }
}

define_proc_arguments genCmd_operateGlobalNetConnect_ofPgPin_forSpecifiedInsts \
  -info "gen cmd for operating GNC(globalNetConnect) of pgpin for insts"\
  -define_args {
    {-typeOfOperating "specify the type of operating" oneOfString one_of_string {optional value_type {values {disconnect connect createPinAndConnect getGNC}}}}
    {-insts "specify inst to operating" AList list optional}
    {-typeOfPin "specify the type of pin of specified insts" oneOfString one_of_string {optional value_type {values {pgpin}}}}
  }
