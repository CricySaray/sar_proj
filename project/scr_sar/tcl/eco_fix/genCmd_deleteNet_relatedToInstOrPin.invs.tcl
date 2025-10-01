#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/10/01 11:28:50 Wednesday
# label     : eco_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : Delete the nets connected to the input or output terminals of an instance (inst) as per the instance. This is often used to remove the nets connected to an instance 
#             first before deleting the instance itself. Doing so can prevent the previous routing traces from being retained during ecoRoute, which would otherwise lead to the 
#             formation of loop phenomena.
# return    : cmds list
# ref       : link url
# --------------------------
proc genCmd_deleteNet_relatedToInstOrPin {args} {
  set typeOfInstOrPin      "inst" ; # inst|pin
  set pinConnectedToNet    ""
  set instConnectedByNet   ""
  set inputOrOutputTermNet "input" ; # input|output|all, only effect on type:inst
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set cmdsList [list]
  if {$typeOfInstOrPin eq "pin"} {
    if {$pinConnectedToNet == "" || [dbget top.insts.instTerms.name $pinConnectedToNet -e] == ""} {
      error "proc genCmd_deleteNet_relatedToInstOrPin: check your input: instConnectedByNet($instConnectedByNet) is not found!!!" 
    } else {
      set netName [dbget [dbget top.insts.instTerms.name $pinConnectedToNet -p].net.name -e ]
      if {$netName == ""} {
        error "proc genCmd_deleteNet_relatedToInstOrPin: check your input pinName($pinConnectedToNet), there is no net name connected to this pin!!!" 
      } else {
        lappend cmdsList "editDelete -net $netName"
      }
    }
  } elseif {$typeOfInstOrPin eq "inst"} {
    if {$instConnectedByNet == "" || [dbget top.insts.name $instConnectedByNet -e] == ""} {
      error "proc genCmd_deleteNet_relatedToInstOrPin: check your input: instConnectedByNet($instConnectedByNet) is not found!!!" 
    } else {
      if {$inputOrOutputTermNet ni {input output all}} {
        error "proc genCmd_deleteNet_relatedToInstOrPin: check your argument value of \$inputOrOutputTermNet, it is only provided by 'input', 'output' and 'all'!!!"
      }
      if {$inputOrOutputTermNet in {input all}} {
        set netsNameInputTerm [dbget [dbget [dbget top.insts.name $instConnectedByNet -p].instTerms.isInput 1 -p].net.name -e]
        if {$netsNameInputTerm == ""} {
          error "proc genCmd_deleteNet_relatedToInstOrPin: check your input pinName($pinConnectedToNet), there is no net name connected to this pin!!!" 
        } else {
          foreach temp_netname $netsNameInputTerm {
            lappend cmdsList "editDelete -net $temp_netname"
          }
        }
      } 
      if {$inputOrOutputTermNet in {output all}} {
        set netsNameOutputTerm [dbget [dbget [dbget top.insts.name $instConnectedByNet -p].instTerms.isOutput 1 -p].net.name -e]
        if {$netsNameOutputTerm == ""} {
          error "proc genCmd_deleteNet_relatedToInstOrPin: check your input pinName($pinConnectedToNet), there is no net name connected to this pin!!!" 
        } else {
          foreach temp_netname $netsNameOutputTerm {
            lappend cmdsList "editDelete -net $temp_netname"
          }
        }
      }
    }
  } else {
    error "proc genCmd_deleteNet_relatedToInstOrPin: check your argument value of \$typeOfInstOrPin: $typeOfInstOrPin, it only provided by 'inst' and 'pin'!!!" 
  }
  return $cmdsList
}
define_proc_arguments genCmd_deleteNet_relatedToInstOrPin \
  -info "gen cmd for deleting whole net related to specified instance or specified pin, you can select net connected to inputTerm or outputTerm."\
  -define_args {
    {-typeOfInstOrPin "specify the type of reference to net" oneOfString one_of_string {optional value_type {values {inst pin}}}}
    {-pinConnectedToNet "specify pin name connected to net when type is 'pin'" AString string optional}
    {-instConnectedByNet "specify inst name connected by net when type is 'inst'" AString string optional}
    {-inputOrOutputTermNet "specify the net that is connected to input term or output term of inst when type is 'inst'" oneOfString one_of_string {optional value_type {values {input output all}}}}
  }
