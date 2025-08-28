#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/28 13:52:29 Thursday
# label     : display_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : Translate the provided list into a table and perform a series of subsequent summaries and information extraction.
# return    : for display and dump to output file
# ref       : link url
# --------------------------
source ../../../packages/logic_AND_OR.package.tcl; # eo
source ../../../packages/every_any.package.tcl; # any
source ../../../packages/pw_puts_message_to_file_and_window.package.tcl; # pw
source ../../../packages/print_formattedTable.package.tcl; # print_formattedTable
source ../../../packages/count_items_advance.package.tcl; # count_items_advance
proc summarize_all_list_to_display {args} {
  set listsDict               {}
  set titleOfListMap          {}
  set filesIncludeListMap     {}
  set needDumpWindowList      {}
  set notNeedCountSumList     {}
  set notNeedFormatTableList  {}
  set onlyCountTotalNumList   {}
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {![llength $listsDict] || ![llength $titleOfListMap] || ![llength $filesIncludeListMap]} {
    error "proc summarize_all_list_to_display: check your input: listsDict($listsDict) or titleOfListMap($titleOfListMap) or filesIncludeListMap($filesIncludeListMap) has error!!!" 
  } elseif {[expr {[dict size $listsDict] != [llength [set filesAllList [join [lmap file_lists $filesIncludeListMap { lindex $file_lists 1 }]]]]}] || [any x [dict keys $listsDict] { set ifHave 0 ; foreach tempFileLists $filesIncludeListMap { if {[expr {$x in [lindex $tempFileLists 1]}]} { set ifHave 1 }} ; expr {!$ifHave} }]} {
    error "proc summarize_all_list_to_display: check your listsDict(size: [dict size $listsDict] \n\t| keys : [lsort [dict keys $listsDict]]) \n\tand filesIncludeListMap(size : [llength $filesAllList] \n\t| content : [lsort $filesAllList]) : not Match!!!" 
  } else {
    dict with listsDict {
      foreach tempFileLists $filesIncludeListMap {
        set fileName [lindex $tempFileLists 0]
        set fi [open $fileName w]
        foreach tempListName [lindex $tempFileLists 1] {
          set ifOnlyCountTotalNum [expr {$tempListName in $onlyCountTotalNumList}]
          set ifDumpWindow [expr {$tempListName in $needDumpWindowList}]
          set ifNeedFormatTable [expr {$tempListName ni $notNeedFormatTableList}]
          if {[lsearch -index 1 $titleOfListMap $tempListName] != -1} { 
            set ifHaveTitle 1 ; set titleName [lindex [lsearch -index 1 -inline $titleOfListMap $tempListName] 0]; set titleSegments [list [lrepeat 25 "-"] $titleName ""] } else { 
              set ifHaveTitle 0 ; set titleSegments [list [lrepeat 25 "-"] " list name: [lindex [lsearch -index 1 $titleOfListMap $tempListName] 1]" ""] }
          set preCmd [list [eo $ifDumpWindow pw puts] $fi]
          if {[llength [subst \${$tempListName}]] > 1} {
            {*}$preCmd [join $titleSegments \n]
            {*}$preCmd [if {$ifNeedFormatTable} { print_formattedTable [subst \${$tempListName}] } else { join [subst \${$tempListName}] \n } ]
            if {$tempListName ni $notNeedCountSumList} {
              set allCountList [count_items_advance [lrange [subst \${$tempListName}] 1 end] 1 {type num}]
              set countList [eo $ifOnlyCountTotalNum [lindex $allCountList end] $allCountList]
              {*}$preCmd [print_formattedTable $countList]
            }
          } else {
            {*}$preCmd [join [list [lrepeat 25 "-"] "### HAVE NO [regsub ":" [eo $ifHaveTitle "$tempListName CONTENTS" $titleName] ""] !!!" ] \n]
          }
        }
        close $fi
      }
    }
  }
}

define_proc_arguments summarize_all_list_to_display \
  -info "summary"\
  -define_args {
    {-listsDict "specify listsDict" AList list required}
    {-titleOfListMap "specify title for every list" AList list required}
    {-filesIncludeListMap "specify the map from files to List" AList list required}
    {-needDumpWindowList "specify the list to dump window" AList list optional}
    {-notNeedCountSumList "specify the list that is not need count summary" AList list optional}
    {-notNeedFormatTableList "specify the list that is not need format to table" AList list optional}
    {-onlyCountTotalNumList "specify the list that is only count total num" AList list optional}
  }
