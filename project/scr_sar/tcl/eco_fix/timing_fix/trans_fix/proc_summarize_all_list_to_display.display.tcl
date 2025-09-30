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
source ../../../packages/stringstore.package.tcl; # stringstore::* ss_init/ss_process/ss_get_id/ss_get_string/ss_clear/ss_size/ss_get_max_length/ss_set_max_length/ss_get_all
source ../../../packages/insert_sequence.package.tcl; # insert_sequence
proc summarize_all_list_to_display {args} {
  set listsDict                                  {}
  set titleOfListMap                             {}
  set filesIncludeListMap                        {}
  set needDumpWindowList                         {}
  set needLimitStringWidth                       {}
  set needInsertSequenceNumberColumn             {}
  set maxWidthForString                          80
  set notNeedCountSumList                        {}
  set notNeedFormatTableList                     {}
  set notNeedTitleHeader                         {}
  set columnToCountSumMapList                    {}
  set onlyCountTotalNumList                      {}
  set defaultColumnToCountSum                    2
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set filesAllListName [lsort -unique [join [lmap file_lists $filesIncludeListMap { lindex $file_lists 1 }]]]
  if {![llength $listsDict] || ![llength $titleOfListMap] || ![llength $filesIncludeListMap]} {
    error "proc summarize_all_list_to_display: check your input: listsDict($listsDict) or titleOfListMap($titleOfListMap) or filesIncludeListMap($filesIncludeListMap) has error!!!" 
  } elseif {[expr {[dict size $listsDict] != [llength $filesAllListName]}] || [any x [dict keys $listsDict] { set ifHave 0 ; foreach tempFileLists $filesIncludeListMap { if {[expr {$x in [lindex $tempFileLists 1]}]} { set ifHave 1 }} ; expr {!$ifHave} }]} {
    error "proc summarize_all_list_to_display: check your listsDict(size: [dict size $listsDict] \n\t| keys : [lsort [dict keys $listsDict]]) \n\tand filesIncludeListMap(size : [llength $filesAllList] \n\t| content : [lsort -unique $filesAllList]) : not Match!!!" 
  } else {
    dict with listsDict {
      foreach tempFileLists $filesIncludeListMap {
        stringstore::ss_init $maxWidthForString
        set fileName [lindex $tempFileLists 0]
        set fi [open $fileName w]
        foreach tempListName [lindex $tempFileLists 1] {
          set ifDumpWindow [expr {$tempListName in $needDumpWindowList}]
          set ifNeedLimitStringWidth [expr {$tempListName in $needLimitStringWidth}]
          set ifNeedFormatTable [expr {$tempListName ni $notNeedFormatTableList}]
          set ifNeedTitleHeader [expr {$tempListName ni $notNeedTitleHeader}]
          set ifNeedInsertSequenceNumberColumn [expr {$tempListName in $needInsertSequenceNumberColumn}]
          set ifOnlyCountTotalNum [expr {$tempListName in $onlyCountTotalNumList}]
          set ifSpecifiedColumnToCountSum [expr {$tempListName in [lsort -unique [join [lmap tempColumnList $columnToCountSumMapList { lindex $tempColumnList 1 }]]]}]
          #set columnToCountSum [eo $ifSpecifiedColumnToCountSum [foreach tempColumnList $columnToCountSumMapList { if {[expr {$tempListName in [lindex $tempColumnList 1]}]} { set temp_column [lindex $tempColumnList 0] ; break  } else {continue}  } ; if {[info exists temp_column]} {set temp_column} else {continue}] $defaultColumnToCountSum]
          if {$ifSpecifiedColumnToCountSum} {
            catch {unset temp_column}
            foreach tempColumnList $columnToCountSumMapList {
              if {[expr {$tempListName in [lindex $tempColumnList 1]}]} {
                set temp_column [lindex $tempColumnList 0]
                break
              } else {
                continue
              }
            }
          }
          if {[info exists temp_column]} {
            set columnToCountSum $temp_column
          } else {
            set columnToCountSum $defaultColumnToCountSum
          }
          if {[lsearch -index 1 $titleOfListMap $tempListName] != -1} { 
            set ifHaveTitle 1 ; set titleName [lindex [lsearch -index 1 -inline $titleOfListMap $tempListName] 0]; set titleSegments [list [string repeat "-" 25] $titleName ""] } else { 
              set ifHaveTitle 0 ; set titleSegments [list "#[string repeat "-" 25]" " list name: [lindex [lsearch -index 1 $titleOfListMap $tempListName] 1]" ""] }
          set preCmd [list [eo $ifDumpWindow pw puts] $fi]
          if {[llength [subst \${$tempListName}]] > 1} {
            {*}$preCmd [if {$ifNeedTitleHeader} { join $titleSegments \n } else { list }]
            if {$ifNeedLimitStringWidth} { set $tempListName [lmap tempContentList [subst \${$tempListName}] { lmap tempItem $tempContentList { stringstore::ss_process $tempItem } }] }
            if {$ifNeedFormatTable} { 
              {*}$preCmd [print_formattedTable [subst \${$tempListName}]]
            } else { 
              {*}$preCmd [join [subst \${$tempListName}] \n]
            }
            if {$tempListName ni $notNeedCountSumList} {
              set allCountList [count_items_advance [lrange [subst \${$tempListName}] 1 end] $columnToCountSum {type num}]
              set countList [eo $ifOnlyCountTotalNum [lindex $allCountList end] $allCountList]
              {*}$preCmd [print_formattedTable $countList]
            }
          } else {
            {*}$preCmd [join [list [string repeat "-" 25] "### HAVE NO [regsub ":" [eo $ifHaveTitle "$tempListName CONTENTS" $titleName] ""] !!!" ] \n]
          }
        }
        set stringstoreList [stringstore::ss_get_all]
        if {[llength $stringstoreList]} {
          {*}$preCmd [join  [list "" "#[string repeat "-" 25]" "STRING STORE LIST:" ] \n]
          {*}$preCmd [print_formattedTable $stringstoreList]
        }
        stringstore::ss_clear
        close $fi
      }
    }
  }
}

define_proc_arguments summarize_all_list_to_display \
  -info "summary for all list to display"\
  -define_args {
    {-listsDict "specify listsDict" AList list required}
    {-titleOfListMap "specify title for every list" AList list required}
    {-filesIncludeListMap "specify the map from files to List" AList list required}
    {-needDumpWindowList "specify the list to dump window" AList list optional}
    {-needLimitStringWidth "specify the list that nned limit String width" AList list optional}
    {-needInsertSequenceNumberColumn "specify the list that need insert the column of sequence number" AList list optional}
    {-maxWidthForString "specify the max width for every string of list" AInteger int optional}
    {-notNeedCountSumList "specify the list that is not need count summary" AList list optional}
    {-notNeedFormatTableList "specify the list that is not need format to table" AList list optional}
    {-notNeedTitleHeader "specify the list that not need add title header " AList list optional}
    {-columnToCountSumMapList "specify the map list of column to count summary" AList list optional}
    {-onlyCountTotalNumList "specify the list that is only count total num" AList list optional}
    {-defaultColumnToCountSum "specify the default column to count summary" AInt integer optional}
  }
