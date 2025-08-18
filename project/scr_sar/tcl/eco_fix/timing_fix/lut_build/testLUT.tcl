#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/18 09:19:23 Monday
# label     : test_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : test if the lut has been loaded at the beginning of proc.
# return    : summary file -> $summaryResultCheckinglutDictFilename
# ref       : link url
# --------------------------
source ../../../packages/pw_puts_message_to_file_and_window.package.tcl; # pw
source ../../../packages/logic_AND_OR.package.tcl; # eo
source ../../../packages/table_col_format_wrap.package.tcl; # table_col_format_wrap
alias sus "subst -nocommands -nobackslashes"
proc testLUT {args} {
  set summaryResultCheckinglutDictFilename "sor_checkLUT.list"
  set lutDictName                          "lutDict"
  set promptPrefix                         "# song"
  set checkExistsList                      {process vtrange stdcellflag designName mainCoreRowHeight mainCoreSiteWidth sitetype core_rects core_inner_boundary_rects refbuffer refclkbuffer {celltype {class size vt capacity vtlist caplist}}}
  set waiveList                            {stdcellflag}
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  global $lutDictName
  set promptINFO [string cat $promptPrefix "INFO"] ; set promptERROR [string cat $promptPrefix "ERROR"] ; set promptWARN [string cat $promptPrefix "WARN"]
  set fo [open $summaryResultCheckinglutDictFilename w]
  try { ; # Place statements that are prone to errors in the try block, making it convenient to catch errors and take corresponding actions.
    set resultCheckList [list ]
    set resultColumn [list checkItem status comment]
    lappend resultCheckList $resultColumn
    # checkItem 01: ifHavelutDictVar
    set ifHaveLutDictVar [info globals $lutDictName]
    if {$ifHaveLutDictVar == ""} {
      lappend resultCheckList [list ifHavelutDictVar ERROR "you don't source file to load global variable: $lutDictName"]
    } else {
      lappend resultCheckList [list ifHavelutDictVar pass "/"]
      # checkItem 02: ifHaveAllFirstKeys
      set ifHaveAllFirstKeys 1
      set missingFirstKeys [list]
      foreach firstKeys $checkExistsList {
        if {[llength $firstKeys] > 1} { set firstKeys [lindex $firstKeys 0] } 
        if {[dict exists [sus \${$lutDictName}] $firstKeys]} { continue } else { lappend missingFirstKeys $firstKeys ; set ifHaveAllFirstKeys 0}
      }
      if {![llength $missingFirstKeys]} { set missingFirstKeys "have NO missing" }
      lappend resultCheckList [list ifHaveAllFirstKeys [eo $ifHaveAllFirstKeys pass ERROR] $missingFirstKeys]
      # checkItem 03: ifHaveAllSubKeys
      set ifHaveAllSubKeys 1
      set missingCelltypeSubKeys [list]
      set needCheckSubKeys [list]
      foreach checkKeys $checkExistsList { ; # you can add other subKeys checking.
        if {[llength $checkKeys] > 1} { 
          set firstKey [lindex $checkKeys 0]
          lappend needCheckSubKeys $firstKey 
          if {$firstKey == "celltype" && $firstKey ni $missingFirstKeys} {
            set celltypeSubKeys [lsort -unique [lindex [lsearch -index 0 -inline $checkExistsList $firstKey] end]]
            dict for {tempkey tempval} [dict get [dict filter [sus \${$lutDictName}] key celltype] celltype] {
              set oneCelltypeSubDict [lsort -unique [dict key $tempval]]
              if {$celltypeSubKeys eq $oneCelltypeSubDict} { continue } else { lappend missingCelltypeSubKeys $tempkey ; set ifHaveAllSubKeys 0 }
            }
            if {![llength $missingCelltypeSubKeys]} { set missingCelltypeSubKeys "have NO missing" }
            lappend resultCheckList [list ifHaveAllSubKeys:$firstKey [eo $ifHaveAllSubKeys pass ERROR] $missingCelltypeSubKeys]
          } elseif {$firstKey == "celltype" && $firstKey in $missingFirstKeys} { 
            lappend resultCheckList [list ifHaveAllSubKeys:$firstKey ERROR "the first key '$firstKey' is not exists"] 
          }
        }
      }
    }
  } finally {
    pw $fo [table_col_format_wrap $resultCheckList 3 30 150]
    close $fo  
  }
}

define_proc_arguments testLUT \
  -info "test lut quality"\
  -define_args {
    {-promptPrefix "specify the prefix of Prompt, like ERROR, INFO, WARN." AString string optional}
    {-summaryResultCheckinglutDictFilename "specify the result file of checking (output filename)" AString string optional}
    {-lutDictName "specify the dict variable name(global var), you will also modify in proc operateLUT" AString string optional}
    {-checkExistsList "specify the checking list judging if exists" AList list optional}
    {-waiveList "specify the waive list for special checking items" AList list optional}
  }
