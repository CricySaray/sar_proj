proc check_antennaCell {args} {
  set ipCelltypeToCheckAnt [list]
  set rptName "signoff_check_antennaCell.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set ipInsts [list]
  foreach temp_ipCelltype $ipCelltypeToCheckAnt {
    set temp_inst [dbget [dbget top.insts.cell.name $temp_ipCelltype -p2].name -e]
    if {$temp_inst ne ""} {
      lappend ipInsts {*}$temp_inst
    }
  }
  set fo [open $rptName w]
  set antCellNum [llength [dbget top.insts.cell.name ANTENNA*]]
  puts $fo "antenna cell num in design: $antCellNum"
  set totalNum 0
  foreach temp_inst $ipInsts {
    set temp_pins [dbget [dbget [dbget top.insts.name $temp_inst -p].instTerms.isOutput 1 -p].name -e]
    foreach temp_pin $temp_pins {
      set temp_net [dbget [dbget top.insts.instTerms.name $temp_pin -p].net.name -e]
      if {$temp_net ne "" && ![regexp {NIL|UNCONNECTED} $temp_net]} {
        set temp_net_insts_col [get_cells -q -of [get_nets $temp_net]]
        if {![regexp {ANT} [get_property $temp_net_insts_col ref_name]]} {
          puts $fo "noAntennaCell pin: $temp_pin"
          incr totalNum
        }
      }
    }
  }
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "noAntCellPin $totalNum"
  close $fo
  return [list noAntCellPin $totalNum]
}
define_proc_arguments check_antennaCell \
  -info "check antenna cell"\
  -define_args {
    {-ipCelltypeToCheckAnt "specify the list of ip celltype" AList list optional}
    {-rptName "specify output file name" AString string optional}
  }
proc check_clockCellFixed {args} {
  set rptName "signoff_check_clockCellFixed.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set fo [open $rptName w]
  set totalNum 0
  set allTreeInsts_col [get_cells -q [get_clock_network_objects -type cell] -filter "!is_sequential"]
  foreach_in_collection temp_inst_itr $allTreeInsts_col {
    set temp_inst_name [get_object_name $temp_inst_itr]
    if {![regexp fixed [dbget [dbget top.insts.name $temp_inst_name -p].pStatusCTS]] && ![regexp fixed [dbget [dbget top.insts.name $temp_inst_name -p].pStatus]]} {
      highlight $temp_inst_name -color yellow
      puts $fo "notFixedOrCTSFixed: $temp_inst_name"
      incr totalNum
    }
  }
  set rootdir [lrange [split $rptName "/"] 0 end-1]
  set temp_filename [lindex [split $rptName "/"] end]
  set basenameFile [join [lrange [split $temp_filename "."] 0 end-1] "."]
  deselectAll
  fit
  gui_dump_picture [join [concat $rootdir gif_$basenameFile.gif] "/"] -format GIF
  dehighlight
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "clkCellFixed $totalNum"
  close $fo
  return [list clkCellFixed $totalNum]
}
define_proc_arguments check_clockCellFixed \
  -info "check clock cell status"\
  -define_args {
    {-rptName "specify output file name" AString string optional}
  }
proc check_clockPathLength {args} {
  set lengthThreshold 240
  set rptName         "signoff_check_clockPathLength.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set finalList [list]
  set totalNum 0
  set nets_list_ptr [dbget top.nets. {.isClock == 1 && .isPwrOrGnd == 0}]
  foreach temp_net_ptr $nets_list_ptr {
    set temp_net_name [lindex [dbget $temp_net_ptr.name] 0 0]
    set temp_net_length [get_net_length $temp_net_name]
    if {$temp_net_length > $lengthThreshold} {
      lappend finalList [list $temp_net_length $temp_net_name]
      incr totalNum
    }
  }
  set finalList [lsort -decreasing -index 0 -real $finalList]
  set fo [open $rptName w]
  puts $fo [join [table_format_with_title $finalList 0 left "" 0] \n]
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "clockLength $totalNum"
  close $fo
  return [list clockLength $totalNum]
}
define_proc_arguments check_clockPathLength \
  -info "check clock path net length"\
  -define_args {
    {-lengthThreshold "specify the threshold of net length" AFloat float optional}
    {-rptName "specify output file name" AString string optional}
  }
proc check_clockTreeCells {args} {
  set remove_celltype_list {RCLIB_PLB DEL}
  set remove_instname_list {}
  set specify_VT           "LVT"
  set celltypeRegExp       {.*D(\d+)BWP.*140([(UL)LH]VT)?$}
  set availableVT          {HVT SVT LVT ULVT}
  set clkFlagExp           {^DCCK|^CK}
  set rptName              "signoff_check_clockTreeCells.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set allCTSinstname_collection [get_clock_network_objects -type cell]
  set allCTSinstname_collection [filter_collection $allCTSinstname_collection "ref_name !~ ANT* && is_black_box == false && is_pad_cell == false"]
  set error_driveCapacity [add_to_collection "" ""]
  set error_VTtype [add_to_collection "" ""]
  set error_CLKcelltype [add_to_collection "" ""]
  if {$celltypeRegExp eq ""} {
    error "proc check_clockTreeCells: please provide \$celltypeRegExp!!!"
  }
  if {$celltypeRegExp == "" || $availableVT == "" || $clkFlagExp == ""} {
    error "proc check_CTScelltype: check your lutDict info: celltypeRegExp($celltypeRegExp) , availableVT($availableVT) , clkFlagExp($clkFlagExp). check it!!!"
  }
  set removeCelltypeExp [join $remove_celltype_list "\|"]
  set removeInstnameExp [join $remove_instname_list "\|"]
  set numAllCtsInsts [sizeof_collection $allCTSinstname_collection]
  set numremoveInst 0
  foreach_in_collection instname_itr $allCTSinstname_collection {
    set driveCapacity [get_driveCapacity_of_celltype [get_attribute $instname_itr ref_name] $celltypeRegExp]
    if {$remove_celltype_list ne "" && [regexp $removeCelltypeExp [get_attribute $instname_itr ref_name]]} { incr numremoveInst; continue }
    if {$remove_instname_list ne "" && [regexp $removeInstnameExp [get_attribute $instname_itr full_name]]} { incr numremoveInst; continue }
    if {$driveCapacity < 4} {
      set error_driveCapacity [add_to_collection $error_driveCapacity $instname_itr] ;
    }
    if {$specify_VT in $availableVT && [lindex [get_cellDriveLevel_and_VTtype_of_inst [get_object_name $instname_itr] $celltypeRegExp] end] != $specify_VT} {
      set error_VTtype [add_to_collection $error_VTtype $instname_itr] ;
    } elseif {$specify_VT ni $availableVT} {
      error "proc check_CTScelltype: \$specify_VT can't in availableVT list"
    }
    if {![regexp $clkFlagExp [get_attribute $instname_itr ref_name]]} {
      set error_CLKcelltype [add_to_collection $error_CLKcelltype $instname_itr] ;
    }
  }
  set error_driveCapacity_list [get_object_name $error_driveCapacity]
  set error_VTtype_list [get_object_name $error_VTtype]
  set error_CLKcelltype_list [get_object_name $error_CLKcelltype]
  set categorized_List [categorize_overlapping_sets [list [list greaterThanD4 $error_driveCapacity_list] [list UseVTto$specify_VT $error_VTtype_list] [list UseCLKcelltype $error_CLKcelltype_list]]]
  set raw_display_List [lmap cat_category $categorized_List {
    set cat_inst_celltype [lmap instname [lindex $cat_category end] {
      set celltype [get_attribute [get_cells $instname] ref_name]
      set inst_celltype [list $celltype $instname]
    }]
    set new_cat_category [list [lindex $cat_category 0] $cat_inst_celltype]
  }]
  set formatedTable_toDisplay [print_formattedTable_D2withCategory $raw_display_List]
  array set category_count {}
  set totalNum 0
  foreach cate $raw_display_List {
    set cate_name [lindex $cate 0]
    set category_count($cate_name) [llength [lindex $cate 1]]
    incr totalNum $category_count($cate_name)
  }
  set fo [open $rptName w]
  puts $fo $formatedTable_toDisplay
  puts $fo ""
  if {[llength [lindex $raw_display_List 0 1]]} {
    puts $fo ""
    puts $fo "STATISTICS OF CATEGORIES:"
    puts $fo "-------------------------"
    puts $fo [print_formattedTable [lmap cate_name [array names category_count] { set cate_num [list $cate_name $category_count($cate_name)] }]]
    puts $fo ""
  } else {
    puts $fo ""
    puts $fo "# HAVE NO ERROR OF CLK CELL TYPE!!!"
    puts $fo ""
  }
  puts $fo "# num of total ccopt clock tree cells : $numAllCtsInsts"
  puts $fo "# num of total removed inst: $numremoveInst"
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "ctsCellNum $totalNum"
  close $fo
  return [list ctsCellNum $totalNum]
}
define_proc_arguments check_clockTreeCells \
  -info "check clock tree cells"\
  -define_args {
    {-remove_celltype_list "specify the remove list of celltype" AList list optional}
    {-remove_instname_list "specify the remove list of instname" AList list optional}
    {-specify_VT "specify the clock tree vt" AList list optional}
    {-celltypeRegExp "specify the reg expression of celltype to match" AString string optional}
    {-availableVT "specify the list of all vt type" AList list optional}
    {-clkFlagExp "specify the clock cell type flag" AString string optional}
    {-rptName "specify inst to eco when type is add/delete" AString string optional}
  }
proc check_dataPathLength {args} {
  set lengthThreshold 400
  set rptName         "signoff_check_dataPathLength.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set finalList [list]
  set totalNum 0
  set nets_list_ptr [dbget top.nets. {.isClock == 0 && .isPwrOrGnd == 0}]
  foreach temp_net_ptr $nets_list_ptr {
    set temp_net_name [lindex [dbget $temp_net_ptr.name] 0 0]
    set temp_net_length [get_net_length $temp_net_name]
    if {$temp_net_length > $lengthThreshold} {
      lappend finalList [list $temp_net_length $temp_net_name]
      incr totalNum
    }
  }
  set finalList [lsort -decreasing -index 0 -real $finalList]
  set fo [open $rptName w]
  puts $fo [join [table_format_with_title $finalList 0 left "" 0] \n]
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "dataLength $totalNum"
  close $fo
  return [list dataLength $totalNum]
}
define_proc_arguments check_dataPathLength \
  -info "check data path net length"\
  -define_args {
    {-lengthThreshold "specify the threshold of net length" AFloat float optional}
    {-rptName "specify output file name" AString string optional}
  }
proc check_decapDensity {args} {
  set rptName "signoff_check_decapDensity.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set decapResult [lmap temp_decapcell [dbget top.insts.cell.name DCAP* -u -e] {
    set temp_num [llength [dbget top.insts.cell.name $temp_decapcell]]
    list $temp_num $temp_decapcell
  }]
  set fo [open $rptName w]
  puts $fo [join $decapResult \n]
  proc temp_add {x y} { expr $x + $y }
  set decap_area [struct::list::Lfold [dbget [dbget top.insts.cell.name DCAP* -e -p2].area -e] 0 temp_add]
  checkFPlan -reportUtil > ./temp_checkFPlan_reportUtil.rpt
  set alloc_area [regsub -all {\(|\)} [lindex  [split [exec grep alloc_area temp_checkFPlan_reportUtil.rpt | tail -n 1] "sites"] end 0] ""]
  if {$alloc_area == 0 || $decap_area == 0} {
    return [list decapDensity -1]
  }
  set decap_density [format "%.2f" [expr {$decap_area / double($alloc_area)}]]
  puts $fo ""
  puts $fo "DECAP_DENSITY: $decap_density"
  puts $fo "decapDensity $decap_density"
  close $fo
  fit
  deselectAll
  highlight [dbget top.insts.cell.name DCAP* -p2]
  setLayerPreference violation -isVisible 0
  setLayerPreference node_route -isVisible 0
  setLayerPreference node_blockage -isVisible 0
  setLayerPreference node_layer -isVisible 1
  gui_dump_picture gif_signoff_check_decap_density.gif -format GIF
  dehighlight
  return [list decapDensity $decap_density]
}
define_proc_arguments check_decapDensity \
  -info "check decap density"\
  -define_args {
    {-rptName "specify output file name" AString string optional}
  }
proc check_delayCellInClockTreeLeaf {args} {
  set rptName "signoff_check_delayCellInClockTreeLeaf.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set finalList [list]
  set totalNum 0
  set nets [get_nets *CTS*]
  set instsNumToDealWith 0
  foreach_in_collection temp_net_itr $nets {
    set temp_insts_col [get_cells -of $temp_net_itr -leaf]
    foreach_in_collection temp_inst_itr $temp_insts_col {
      set temp_celltype [get_property $temp_inst_itr ref_name]
      incr instsNumToDealWith
      if {[regexp "DEL" $temp_celltype]} {
        lappend finalList [list [get_object_name $temp_net_itr] $temp_celltype [get_object_name $temp_inst_itr]]
        incr totalNum
      }
    }
  }
  if {[llength $finalList]} {
    set finalList [linsert $finalList 0 [list rootNetName celltypeName instName]]
  }
  set fo [open $rptName w]
  if {$finalList ne ""} {
    puts $fo [join [table_format_with_title $finalList 0 left "" 0] \n]
  } else {
    puts $fo "have deal with $instsNumToDealWith insts, but have no DEL cell in clock tree."
  }
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "dlyCellInTree $totalNum"
  close $fo
  return [list dlyCellInTree $totalNum]
}
define_proc_arguments check_delayCellInClockTreeLeaf \
  -info "check delay cell in clock tree leaf"\
  -define_args {
    {-rptName "specify inst to eco when type is add/delete" AString string optional}
  }
proc check_delayCellLevel {args} {
  set levelThreshold 10
  set rptName "signoff_check_delayCellLeval.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set all_delay_cells [lsort -u -ascii -increasing [dbget [dbget top.insts.cell.name DEL* -p2].name -e]]
  foreach temp_delay_cell $all_delay_cells {
  }
}
define_proc_arguments check_delayCellLevel \
  -info "check delay cell level"\
  -define_args {
    {-levelThreshold "specify the threshold of delay cell level" AInt int optional}
    {-rptName "specify inst to eco when type is add/delete" AString string optional}
  }
proc check_dfmVia {args} {
  set rptName "signoff_check_dfmVia.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {[file exists temp_report_route_multi_cut.rpt]} {
    file delete temp_report_route_multi_cut.rpt
  }
  report_route -multi_cut > temp_report_route_multi_cut.rpt
  set fi [open "temp_report_route_multi_cut.rpt" r]
  set lineList [split [read $fi] "\n"]
  close $fi
  set fo [open $rptName w]
  set dfm_table [lrange $lineList 0 25]
  puts $fo [join $dfm_table \n]
  set total_row [lsearch -regexp -inline $dfm_table {^\|\s+Total}]
  if {$total_row eq ""} {
    set DFM_ratio "-1%"
  } else {
    set DFM_ratio [lindex [regsub -all {\(|\)} [lsearch -regexp -inline -all $total_row {\d+\.\d+%}] ""] end]
  }
  puts $fo "DFM_RATIO: $DFM_ratio"
  puts $fo "dfmVia $DFM_ratio"
  close $fo
  return [list dfmVia $DFM_ratio]
}
define_proc_arguments check_dfmVia \
  -info "signoff check: double via"\
  -define_args {
    {-rptName "specify output file name" AString string optional}
  }
proc check_dontTouchCell {args} {
  set setSizeOkInstFileList                         ""
  set setDontTouchInstFileList                      ""
  set setBoundaryHierPinDontTouchModuleNameFileList ""
  set rptName                                       "signoff_check_dontTouchCell.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set fo [open $rptName w]
  set sizeOkList [list]
  set dontTouchList [list]
  set boundaryHierPinDontTouchMoudleNameList [list]
  puts $fo "Reading Input file:"
  puts $fo "# setSizeOkInstFileList: file num: [llength $setSizeOkInstFileList]"
  foreach temp_sizeokfile $setSizeOkInstFileList {
    if {[file exists $temp_sizeokfile]} {
      lappend sizeOkList {*}[convert_file_to_list $temp_sizeokfile]
      puts $fo "# read file successfully: $temp_sizeokfile"
    } else {
      puts $fo "# read file ERROR(FAILED): $temp_sizeokfile"
    }
  }
  puts $fo ""
  puts $fo "# setDontTouchInstFileList: file num: [llength $setDontTouchInstFileList]"
  foreach temp_dontTouchFile $setDontTouchInstFileList {
    if {[file exists $temp_dontTouchFile]} {
      lappend dontTouchList {*}[convert_file_to_list $temp_dontTouchFile]
      puts $fo "# read file successfully: $temp_dontTouchFile"
    } else {
      puts $fo "# read file ERROR(FAILED): $temp_dontTouchFile"
    }
  }
  puts $fo ""
  puts $fo "# setBoundaryHierPinDontTouchModuleNameFileList: file num: [llength $setBoundaryHierPinDontTouchModuleNameFileList]"
  foreach temp_modulefile $setBoundaryHierPinDontTouchModuleNameFileList {
    if {[file exists $temp_modulefile]} {
      lappend boundaryHierPinDontTouchMoudleNameList {*}[convert_file_to_list $temp_modulefile]
      puts $fo "# read file successfully: $temp_modulefile"
    } else {
      puts $fo "# read file ERROR(FAILED): $temp_modulefile"
    }
  }
  puts $fo ""
  if {[every x $sizeOkList { expr {$x in $dontTouchList} }] && [llength $sizeOkList] && [llength $dontTouchList]} {
    puts $fo "There are some inst name overlapped between sizeOk and dontTouch(true), it will be set dontTouch(true), please double check it: "
    foreach temp_sizeok $sizeOkList {
      if {$temp_sizeok in $dontTouchList} {
        puts $fo $temp_sizeok
      }
    }
  }
  set sizeOkList [lsort -u $sizeOkList]
  set dontTouchList [lsort -u $dontTouchList]
  set boundaryHierPinDontTouchMoudleNameList [lsort -u $boundaryHierPinDontTouchMoudleNameList]
  set allObjToDealWithNum [expr {[llength $sizeOkList] + [llength $dontTouchList] + [llength $boundaryHierPinDontTouchMoudleNameList]}]
  puts $fo "--------------"
  set noFoundSizeOkInstList [list]
  set failedSetSizkOkInstList [list]
  set sizeOkSuccessNum 0
  foreach temp_sizeok $sizeOkList {
    if {[dbget top.insts.name $temp_sizeok -e] ne ""} {
      if {[dbget [dbget top.insts.name $temp_sizeok -p].dontTouch -e] eq "sizkOk"} {
        puts $fo "success(set inst sizeOk): $temp_sizeok"
        incr sizeOkSuccessNum
      } else {
        lappend failedSetSizkOkInstList $temp_sizeok
      }
    } else {
      lappend noFoundSizeOkInstList $temp_sizeok
    }
  }
  set noFoundDontTouchInstList [list]
  set failedSetDontTouchInstList [list]
  set dontTouchSuccessNum 0
  foreach temp_donttouch $dontTouchList {
    if {[dbget top.insts.name $temp_donttouch -e] ne ""} {
      if {[dbget [dbget top.insts.name $temp_donttouch -p].dontTouch -e] eq "true"} {
        puts $fo "success(set inst dontTouch true): $temp_donttouch"
        incr dontTouchSuccessNum
      } else {
        lappend failedSetDontTouchInstList $temp_donttouch
      }
    } else {
      lappend noFoundDontTouchInstList $temp_donttouch
    }
  }
  set failedSetDontTouchHierPinList [list]
  set dontTouchHierPinSuccessNum 0
  foreach temp_moduleName $boundaryHierPinDontTouchMoudleNameList {
    deselectAll
    select_obj [get_pins -of $temp_moduleName -q]
    set hierPins_ptr [dbget selected.]
    foreach temp_hierpin_ptr $hierPins_ptr {
      if {[dbget $temp_hierpin_ptr.dontTouch] eq "true"} {
        puts $fo "success(set dontTouchHierPin true): [dbget $temp_hierpin_ptr.name]"
        incr dontTouchHierPinSuccessNum
      } else {
        lappend failedSetDontTouchHierPinList [dbget $temp_hierpin_ptr.name]
      }
    }
  }
  set totalNum [expr {[llength $noFoundSizeOkInstList] + [llength $failedSetSizkOkInstList] + [llength $noFoundDontTouchInstList] + [llength $failedSetDontTouchInstList] + [llength $failedSetDontTouchHierPinList]}]
  if {$totalNum > 0} {
    puts $fo "failed to set dontTouch or sizeOk list:"
    if {$noFoundSizeOkInstList ne ""} {
      foreach temp_nofound_sizeok $noFoundSizeOkInstList { puts $fo "noFoundSizeOkInst: $temp_nofound_sizeok" }
      puts $fo ""
    }
    if {$failedSetSizkOkInstList ne ""} {
      foreach temp_failed_sizeok $failedSetSizkOkInstList { puts $fo "failedSetSizeOkInst: $temp_failed_sizeok" }
      puts $fo ""
    }
    if {$noFoundDontTouchInstList ne ""} {
      foreach temp_nofound_doutTouch $noFoundDontTouchInstList { puts $fo "noFoundDontTouchInst: $temp_nofound_doutTouch" }
      puts $fo ""
    }
    if {$failedSetDontTouchInstList ne ""} {
      foreach temp_failed_dontTouch $failedSetDontTouchInstList { puts $fo "failedSetDontTouchInst: $temp_failed_dontTouch" }
      puts $fo ""
    }
    if {$failedSetDontTouchHierPinList ne ""} {
      foreach temp_failed_hierpin_dontTouch $failedSetDontTouchHierPinList { puts $fo "failedSetDontTouchHierPin: $temp_failed_hierpin_dontTouch" }
      puts $fo ""
    }
  }
  puts $fo "num of all object to deal with : $allObjToDealWithNum"
  puts $fo ""
  puts $fo "success sizeOk num: $sizeOkSuccessNum"
  puts $fo "success dontTouch num: $dontTouchSuccessNum"
  puts $fo "success dontTouchHierPin num: $dontTouchHierPinSuccessNum"
  puts $fo ""
  puts $fo "noFoundSizeOkInst num: [llength $noFoundSizeOkInstList]"
  puts $fo "failedSetSizeOkInst num: [llength $failedSetSizkOkInstList]"
  puts $fo "noFoundDontTouchInst num: [llength $noFoundDontTouchInstList]"
  puts $fo "failedSetDontTouchInst num: [llength $failedSetDontTouchInstList]"
  puts $fo "failedSetDontTouchHierPin num: [llength $failedSetDontTouchHierPinList]"
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "dontTouchFail $totalNum"
  close $fo
  return [list dontTouchFail $totalNum]
}
define_proc_arguments check_dontTouchCell \
  -info "check dont touch cell"\
  -define_args {
    {-setSizeOkInstFileList "file name list to set sizeok inst" AList list optional}
    {-setDontTouchInstFileList "file name list to set dontTouch inst" AList list optional}
    {-setBoundaryHierPinDontTouchModuleNameFileList "file name list to set dontTouch hier pin" AList list optional}
    {-rptName "specify inst to eco when type is add/delete" AString string optional}
  }
proc check_dontUseCell {args} {
  set dontUseExpressionList    {G* K* CLK*}
  set ignoreCellExpressionList {G* CK* DCCK* TIE* FILL* DCAP* *SYNC* DEL*}
  set rptName                  "signoff_check_dontUseCell.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set cellList [dbget [dbget top.insts.cell.subClass core -p].name -u -e]
  if {![llength $dontUseExpressionList]} {
    return "-1"
  } else {
    set dontUseRegexpList [util_wildcardList_to_regexpList -wildcardList $dontUseExpressionList]
    set matchDontUseList [lsearch -regexp -all -inline $cellList [join $dontUseRegexpList "|"]]
    set ignoreCellRegexpList [util_wildcardList_to_regexpList -wildcardList $ignoreCellExpressionList]
    set removedIgnoreCellList [lsearch -regexp -not -all -inline $matchDontUseList [join $ignoreCellRegexpList "|"]]
    set totalNum 0
    set finalList [lmap temp_cell $removedIgnoreCellList {
      set temp_insts [dbget [dbget top.insts.cell.name $temp_cell -p2].name]
      set temp_len [llength $temp_insts]
      incr totalNum $temp_len
      list $temp_cell $temp_len $temp_insts
    }]
    set fo [open $rptName w]
    foreach temp_list $finalList {
      lassign $temp_list temp_cell temp_len temp_insts
      puts $fo "CELLNAME: $temp_cell LEN: $temp_len"
      puts $fo [join $temp_insts \n]
      puts $fo ""
    }
    puts $fo "TOTALNUM: $totalNum"
    puts $fo "dontUseNum $totalNum"
    close $fo
    return [list dontUseNum $totalNum]
  }
}
define_proc_arguments check_dontUseCell \
  -info "check dont use cell"\
  -define_args {
    {-dontUseExpressionList "specify the dont use cell regExpression list" AList list optional}
    {-ignoreCellExpressionList "specify the cell regExpression to ignore check" AString string optional}
    {-rptName "specify the output file name" AString string optional}
  }
proc check_inputTermsFloating {args} {
  set rptName "signoff_check_inputTermsFloating.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set allInputTerms_ptr [dbget top.insts.instTerms.isInput 1 -p]
  set floatingInputTermsList [list]
  set totalNum 0
  foreach temp_ptr $allInputTerms_ptr {
    if {![dbget $temp_ptr.net.isPwrOrGnd]} {
      if {[dbget $temp_ptr.net. -e] eq ""} {
        lappend floatingInputTermsList "NO_NET: [dbget $temp_ptr.name]"
        incr totalNum
      } elseif {![dbget $temp_ptr.net.numOutputTerms]} {
        lappend floatingInputTermsList "NO_OUTPUT_TERM: [dbget $temp_ptr.name]"
        incr totalNum
      }
    }
  }
  set fo [open $rptName w]
  puts $fo [join $floatingInputTermsList \n]
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "inputTermFloat $totalNum"
  close $fo
  return [list inputTermFloat $totalNum]
}
define_proc_arguments signoff_check_inputTermsFloating \
  -info "check input terms floating"\
  -define_args {
    {-rptName "specify output file name" AString string optional}
  }
proc check_ipMemInputBufCellDriveSize {args} {
  set removeInstExpList {mesh}
  set removeCelltypeExpList {TIE}
  set celltypeExp       {.*D(\d+)BWP.*140([(UL)LH]VT)?$}
  set sizeThreshold     4
  set rptName           "signoff_check_ipMemInputBufCellDriveSize.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set allIpMems_ptr [dbget top.insts.cell.subClass block -p2]
  set totalNum 0
  set fo [open $rptName w]
  set finalList [list]
  if {$allIpMems_ptr ne ""} {
    foreach temp_inst_ptr $allIpMems_ptr {
      if {![regexp [join $removeInstExpList "\|"] [dbget $temp_inst_ptr.name]]} {
        set inputInsts_ptr [dbget [dbget $temp_inst_ptr.instTerms.isInput 1 -p].net.instTerms.inst.cell.name $celltypeExp -regexp -p2]
        foreach temp_inputinst_ptr $inputInsts_ptr {
          set temp_celltype [dbget $temp_inputinst_ptr.cell.name -e]
          if {$temp_celltype ne ""} {
            set temp_driverCapacity [get_driveCapacity_of_celltype $temp_celltype $celltypeExp]
            if {$temp_driverCapacity < $sizeThreshold} {
              lappend finalList [list $temp_driverCapacity $temp_celltype [dbget $temp_inputinst_ptr.name]]
            }
          }
        }
      }
    }
  }
  set totalNum [llength $finalList]
  set finalList [linsert $finalList 0 [list size celltype instname]]
  puts $fo [join [table_format_with_title $finalList 0 left "" 0] \n]
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "ipMemInputBufSize $totalNum"
  close $fo
  return [list ipMemInputBufSize $totalNum]
}
define_proc_arguments check_ipMemInputBufCellDriveSize \
  -info "check ip/mem input buffer cell drive capacity size"\
  -define_args {
    {-removeInstExpList "specify the remove inst using expression list" AList list optional}
    {-removeCelltypeExpList "specify the remove celltype using expression list" AList list optional}
    {-celltypeExp "specify the celltype expression to match and get drive capacity" AString string optional}
    {-sizeThreshold "specify the drive capacity size threshold" AInt int optional}
    {-rptName "specify inst to eco when type is add/delete" AString string optional}
  }
proc check_ipMemPinNetLength {args} {
  set memCelltypeExp_toIgnore {^ram_} ;
  set ipExpOrNameListToMatch {} ;
  set lengthThreshold 50
  set rptName "signoff_check_ipMemPinNetLength.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set celltypesOfBlockSubClass [dbget [dbget top.insts.cell.subClass block -p].name]
  if {$celltypesOfBlockSubClass eq ""} {
    return [list ipBuffNetLength 0]
  } else {
    if {$ipExpOrNameListToMatch ne ""} {
      set ipCelltypes [dbget -regexp top.insts.cell.name [join $ipExpOrNameListToMatch "|"]]
    } elseif {$memCelltypeExp_toIgnore eq ""} {
      set ipCelltypes $celltypesOfBlockSubClass
    } else {
      set ipCelltypes [lsearch -not -regexp -inline -all $celltypesOfBlockSubClass $memCelltypeExp_toIgnore]
    }
    set ipInsts [dbget [dbget -regexp top.insts.cell.name [join $ipCelltypes "|"] -p2].name]
    set finalList [list]
    foreach temp_ipinst $ipInsts {
      set temp_terms [dbget [dbget top.insts.name $temp_ipinst -p].instTerms.name -e]
      foreach temp_term $temp_terms {
        set temp_net [dbget [dbget top.insts.instTerms.name $temp_term -p].net.name -e]
        if {$temp_net ne ""} {
          set temp_length [get_net_length $temp_net]
          if {$temp_length > $lengthThreshold} {
            lappend finalList [list $temp_length $temp_net $temp_term]
          }
        }
      }
    }
    set finalList [lsort -decreasing -real -index 0 $finalList]
    set finalList [linsert $finalList 0 [list netLength netName termName]]
    set totalNum [expr [llength $finalList] - 1]
    set fo [open $rptName w]
    puts $fo [join [table_format_with_title $finalList 0 left "" 0] \n]
    puts $fo ""
    puts $fo "TOTALNUM: $totalNum"
    puts $fo "ipBuffNetLength $totalNum"
    close $fo
    return [list ipBuffNetLength $totalNum]
  }
}
define_proc_arguments check_ipMemPinNetLength \
  -info "check ip buffer net length"\
  -define_args {
    {-memCelltypeExp_toIgnore "specify the mem celltype expression to ignore" AString string optional}
    {-ipExpOrNameListToMatch "specify the list of expressing or name of ip to matching" AList list optional}
    {-lengthThreshold "specify the net length threshold" AFloat float optional}
    {-inst "specify inst to eco when type is add/delete" AString string optional}
  }
proc check_maxFanout {args} {
  set fanoutThreshold 32
  set rptName "signoff_check_maxFanout.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set_interactive_constraint_modes [lsearch -regexp -all -inline [all_constraint_modes] func]
  set_max_fanout $fanoutThreshold [current_design]
  report_constraint -drv_violation_type max_fanout -all_violaters -view [lsearch -inline -regexp [all_analysis_views -type active] setup] > $rptName
  set totalNum []
  return [list maxFanoutViol $totalNum]
}
define_proc_arguments check_maxFanout \
  -info "check max fanout"\
  -define_args {
    {-fanoutThreshold "specify the max fanout threshold" AInt int optional}
    {-rptName "specify output file name" AString string optional}
  }
proc check_missingVia {args} {
  set layersToCheck {M4 M5 M6 M7 M8} ;
  set rptName "signoff_check_missingVia.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set rootdir [lrange [split $rptName "/"] 0 end-1]
  set temp_filename [lindex [split $rptName "/"] end]
  set extensionOfRptName [lindex [split $temp_filename "."] end]
  set basenameOfRptName [lrange [split $temp_filename "."] 0 end-1]
  deselectAll
  delete_gui_object -all
  fit
  gui_dim_foreground -lightness_level medium
  setLayerPreference node_route -isVisible 0
  setLayerPreference node_blockage -isVisible 0
  setLayerPreference node_layer -isVisible 1
  setLayerPreference violation -isVisible 1
  foreach upLayer [lrange $layersToCheck 1 end] downLayer [lrange $layersToCheck 0 end-1] {
    clearDrc
    deselectAll
    select_obj [dbget -v top.nets.swires.shape notype -p]
    verifyPowerVia -report [join [concat $rootdir middleFile_${basenameOfRptName}_$downLayer$upLayer.$extensionOfRptName] "/"] -layerRange [list $upLayer $downLayer] -nonOrthogonalCheck -error 1000000 -checkWirePinOverlap -selected
    deselectAll
    gui_dump_picture [join [concat $rootdir gif_${basenameOfRptName}_$downLayer$upLayer.gif] "/"] -format GIF
    saveDrc [join [concat $rootdir drc_${basenameOfRptName}_$downLayer$upLayer.drc] "/"]
  }
  set pgGap 6
  clearDrc
  deselectAll
  editSelect -type Special -shape {FOLLOWPIN STRIPE} -layer {M2 M5}
  verifyPowerVia -report [join [concat $rootdir middleFile_${basenameOfRptName}_stackM2M5.$extensionOfRptName] "/"] -layer_rail M2 -layer_stripe M5 -stackedVia -stripe_rule $pgGap -layerRange {M2 M5} -selected -error 1000000
  deselectAll
  gui_dump_picture [join [concat $rootdir gif_${basenameOfRptName}_stackM2M5.gif -format GIF] "/"]
  saveDrc [join [concat $rootdir drc_${basenameOfRptName}_stackM2M5.drc] "/"]
  return
}
define_proc_arguments check_missingVia \
  -info "check missing via"\
  -define_args {
    {-layersToCheck "specify the list of layers to check" AList list optional}
    {-rptName "specify output file name" AString string optional}
  }
proc check_place {args} {
  set rptName "signoff_check_place.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set rootdir [lrange [split $rptName "/"] 0 end-1]
  set temp_filename [lindex [split $rptName "/"] end]
  set middle_file [join [concat $rootdir middleFile_$temp_filename] "/"]
  checkPlace -ignoreFillerInUtil > $middle_file
  set fi [open $middle_file r]
  set temp_content [split [read $fi] "\n"]
  close $fi
  set overlapNum [lindex [lsearch -regexp -inline $temp_content "^Overlapping with other instance: "] end]
  set temp_fillerGapsList [lsearch -regexp -all -inline $temp_content "^FillerGap Violation:"]
  set fillerGapNum 0
  foreach temp_fillergap $temp_fillerGapsList {
    set temp_fillernum [lindex $temp_fillergap end]
    set fillerGapNum [expr $fillerGapNum + int($temp_fillernum)]
  }
  set unplacedInstNum [lindex [lsearch -regexp -inline $temp_content "\\*info: Unplaced ="] end]
  set densityRatio [lindex [regexp -inline -expanded {\d+(\.\d+)?%} [lsearch -regexp -inline $temp_content "^Placement Density:"]] 0] ;
  if {$overlapNum eq ""} { set overlapNum 0 }
  set fo [open $rptName w]
  puts $fo "overlapNum $overlapNum fillerGapNum $fillerGapNum unplacedInstNum $unplacedInstNum"
  close $fo
  return [list overlapNum $overlapNum fillerGapNum $fillerGapNum unplacedInstNum $unplacedInstNum]
}
define_proc_arguments check_place \
  -info "check place"\
  -define_args {
    {-rptName "specify output file name" AString string optional}
  }
proc check_portNetLength {args} {
  set lengthThreshold 100
  set rptName         "signoff_check_portNetLength.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set finalList [list]
  set ports [get_object_name [get_ports -of *]]
  foreach temp_port $ports {
    set temp_netname [get_object_name [get_nets -of $temp_port]]
    set temp_netlength [get_net_length $temp_netname]
    if {$temp_netlength > $lengthThreshold} {
      lappend finalList [list $temp_netlength $temp_netname]
    }
  }
  set finalList [lsort -real -index 0 -decreasing $finalList]
  set totalNum [llength $finalList]
  set fo [open $rptName w]
  puts $fo [join $finalList \n]
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "portLength $totalNum"
  close $fo
  return [list portLength $totalNum]
}
define_proc_arguments check_portNetLength \
  -info "check port net length"\
  -define_args {
    {-rptName "specify output file name" AString string optional}
  }
proc check_signalNetOutofDieAndOverlapWithRoutingBlkg {args} {
  set layersToCheck "M2 M3 M4 M5 M6 M7"
  set rptName "signoff_check_signalOutofDieAndOverlapWithRoutingBlkg.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set dieRects [dbShape -output hrect [dbget top.fplan.boxes]]
  set finalList [list]
  set totalNum 0
  foreach temp_layer $layersToCheck {
    set temp_routingBlkg_rects [dbget [dbget top.fplan.rblkgs.layer.name $temp_layer -e -p2].boxes -e]
    set temp_coreAvailableRects [dbShape -output hrect $dieRects ANDNOT $temp_routingBlkg_rects]
    set temp_nets_list_ptr [dbget top.nets.wires.layer.name $temp_layer -e -p3]
    foreach temp_net_ptr $temp_nets_list_ptr {
      set temp_wire_rects [dbShape -output hrect [dbget $temp_net_ptr.wires.box -e]]
      if {[dbShape $temp_wire_rects INSIDE $temp_coreAvailableRects] eq ""} {
        set rectsOutOfAvailable [dbShape $temp_wire_rects ANDNOT $temp_coreAvailableRects]
        lappend finalList [list [dbget $temp_net_ptr.name] $rectsOutOfAvailable]
        incr totalNum
      }
    }
  }
  set fo [open $rptName w]
  puts $fo [join $finalList \n]
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "signalNetOut $totalNum"
  close $fo
  return [list signalNetOut $totalNum]
}
define_proc_arguments check_signalNetOutofDieAndOverlapWithRoutingBlkg \
  -info "check signal net out of die and overlap with routing blockage"\
  -define_args {
    {-layersToCheck "specify the layer list to check" AList list optional}
    {-rptName "specify inst to eco when type is add/delete" AString string optional}
  }
proc check_stdUtilization {args} {
  set rptName "signoff_check_stdUtilization.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set coreRects_withBoundary [proc_findCoreRectInsideBoundary_usingCoreBoxesAndHaloAndPlaceBlockages_withBoundaryRects]
  set coreArea_withBoundary [dbShape -output area $coreRects_withBoundary]
  proc _add {a b} {expr $a + $b}
  set stdCellAreaWoPhys [struct::list::Lfold [dbget [dbget [dbget top.insts.cell.subClass core -p2].isPhysOnly 0 -p].area -e] 0 _add]
  set stdCellAreaWiPhys [struct::list::Lfold [dbget [dbget top.insts.cell.subClass core -p2].area -e] 0 _add]
  set stdUtilization "[format "%.2f" [expr {double($stdCellAreaWoPhys) / double($coreArea_withBoundary) * 100}]]%"
  set fo [open $rptName w]
  puts $fo "coreRects_withBoundary: \{$coreRects_withBoundary\}"
  puts $fo ""
  puts $fo ""
  puts $fo "coreArea_withBoundary: $coreArea_withBoundary um^2"
  puts $fo "stdCellArea(withoutPhysicalCell): $stdCellAreaWoPhys um^2"
  puts $fo "stdCellArea(withPhysicalCell): $stdCellAreaWiPhys um^2"
  puts $fo "stdUtilization: $stdUtilization  (\$coreArea_withBoundary / \$stdCellAreaWoPhys * 100)%"
  puts $fo ""
  puts $fo "stdUtilization $stdUtilization"
  close $fo
  return [list stdUtilization $stdUtilization]
}
define_proc_arguments check_stdUtilization \
  -info "check std cell utilization"\
  -define_args {
    {-rptName "specify the output file name" AString string optional}
  }
proc check_tieCellLoadLength {args} {
  set lengthThreshold 20
  set rptName         "signoff_check_tieCellLoadLength.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set tieCells [dbget top.insts.cell.name *TIE* -u]
  set finalList [list]
  foreach temp_cell $tieCells {
    set temp_tieInsts [dbget [dbget top.insts.cell.name $temp_cell -p2].name -e]
    foreach temp_inst $temp_tieInsts {
      set temp_netname [get_object_name [get_nets -of [get_pins -of [get_cells $temp_inst]]]]
      set temp_length [get_net_length $temp_netname]
      if {$temp_length > $lengthThreshold} {
        lappend finalList [list $temp_length $temp_netname]
      }
    }
  }
  set fo [open $rptName w]
  set finalList [lsort -real -decreasing -index 0 $finalList]
  puts $fo [join $finalList \n]
  puts $fo ""
  set totalNum [llength $finalList]
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "tieLengh $totalNum"
  close $fo
  return [list tieLengh $totalNum]
}
define_proc_arguments check_tieCellLoadLength \
  -info "check tie cell load length"\
  -define_args {
    {-lengthThreshold "specify the threshold of length" AFloat float optional}
    {-rptName "specify output file name" AString string optional}
  }
proc check_tieFanout {args} {
  set fanoutThreshold 1
  set rptName         "signoff_check_tieFanout.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set tieCells [dbget top.insts.cell.name *TIE* -u]
  set finalList [list]
  foreach temp_cell $tieCells {
    set temp_tieInsts [dbget [dbget top.insts.cell.name $temp_cell -p2].name -e]
    foreach temp_inst $temp_tieInsts {
      set temp_netname [get_object_name [get_nets -of [get_pins -of [get_cells $temp_inst]]]]
      set temp_fanout [llength [dbget [dbget top.nets.name $temp_netname -p].instTerms.isInput 1]]
      if {$temp_fanout > $fanoutThreshold} {
        lappend finalList [list $temp_fanout $temp_netname]
      }
    }
  }
  set fo [open $rptName w]
  set finalList [lsort -real -decreasing -index 0 $finalList]
  puts $fo [join $finalList \n]
  puts $fo ""
  set totalNum [llength $finalList]
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "tieFanout $totalNum"
  close $fo
  return [list tieFanout $totalNum]
}
define_proc_arguments check_tieFanout \
  -info "check tie cell fanout"\
  -define_args {
    {-fanoutThreshold "specify the threshold of length" AFloat float optional}
    {-rptName "specify output file name" AString string optional}
  }
proc check_vtRatio {args} {
  set vtTypeExpNameList {{{BWP.*140HVT$} HVT} {{BWP.*140$} SVT} {{BWP.*140LVT$} LVT} {{BWP.*140ULVT} ULVT}}
  set rptName    "signoff_check_vtRatio.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$rptName == ""} {
    error "proc check_vtRatio: check your input: output file name must be provided!!!"
  }
  set totalVtInst_withoutPhysical 0
  set totalVtInst_onlyPhysical 0
  set totalVtInst_withPhysical 0
  set area_totalVtInst_withoutPhysical 0
  set area_totalVtInst_onlyPhysical 0
  set area_totalVtInst_withPhysical 0
  proc _add {a b} { expr {$a + $b} }
  set contentVTtypeName [lmap temp_exp_name $vtTypeExpNameList {
    lassign $temp_exp_name temp_exp temp_vtname
    set temp_len_withoutPhysical [llength [dbget -regexp [dbget top.insts.isPhysOnly 0 -p].cell.name $temp_exp -e]]
    set temp_len_onlyPhysical [llength [dbget -regexp [dbget top.insts.isPhysOnly 1 -p].cell.name $temp_exp -e]]
    set temp_len_withPhysical [expr $temp_len_withoutPhysical + $temp_len_onlyPhysical]
    if {!$temp_len_withoutPhysical} {
      set temp_area_withoutPhysical 0
    } else {
      set temp_area_withoutPhysical [struct::list::Lfold [dbget [dbget -regexp [dbget top.insts.isPhysOnly 0 -p].cell.name $temp_exp -p2].area] 0 _add]
    }
    if {!$temp_len_onlyPhysical} {
      set temp_area_onlyPhysical 0
    } else {
      set temp_area_onlyPhysical [struct::list::Lfold [dbget [dbget -regexp [dbget top.insts.isPhysOnly 1 -p].cell.name $temp_exp -p2].area] 0 _add]
    }
    if {!$temp_len_withPhysical} {
      set temp_area_withPhysical 0
    } else {
      set temp_area_withPhysical [expr $temp_area_withoutPhysical + $temp_area_onlyPhysical]
    }
    set totalVtInst_withoutPhysical [expr {$totalVtInst_withoutPhysical + $temp_len_withoutPhysical}]
    set totalVtInst_onlyPhysical [expr {$totalVtInst_onlyPhysical + $temp_len_onlyPhysical}]
    set totalVtInst_withPhysical [expr {$totalVtInst_withPhysical + $temp_len_withPhysical}]
    set area_totalVtInst_withoutPhysical [expr {$area_totalVtInst_withoutPhysical + $temp_area_withoutPhysical}]
    set area_totalVtInst_onlyPhysical [expr {$area_totalVtInst_onlyPhysical + $temp_area_onlyPhysical}]
    set area_totalVtInst_withPhysical [expr {$area_totalVtInst_withPhysical + $temp_area_withPhysical}]
    list $temp_vtname $temp_len_withoutPhysical $temp_len_onlyPhysical $temp_len_withPhysical $temp_area_withoutPhysical $temp_area_onlyPhysical $temp_area_withPhysical
  }]
  set suffixInfo {
    "# Please note info below:"
  }
  set ratioOfVT [lmap temp_content $contentVTtypeName {
    lassign $temp_content temp_vtname temp_len_withoutPhysical temp_len_onlyPhysical temp_len_withPhysical temp_area_withoutPhysical temp_area_onlyPhysical temp_area_withPhysical
    if {!$totalVtInst_withoutPhysical || !$area_totalVtInst_withoutPhysical} {
      set temp_ratio_withoutPhysical "0.0%"
      set temp_area_ratio_withoutPhysical "0.0%"
      lappend suffixInfo "# $temp_vtname total count == 0, ratio and area can't calculate it!!!"
    } else {
      set temp_ratio_withoutPhysical "[format "%.2f" [expr {double($temp_len_withoutPhysical) / $totalVtInst_withoutPhysical * 100}]]%"
      set temp_area_ratio_withoutPhysical "[format "%.2f" [expr {$temp_area_withoutPhysical / $area_totalVtInst_withoutPhysical * 100}]]%"
    }
    if {!$totalVtInst_onlyPhysical || !$area_totalVtInst_onlyPhysical} {
      set temp_ratio_onlyPhysical "0.0%"
      set temp_area_ratio_onlyPhysical "0.0%"
    } else {
      set temp_ratio_onlyPhysical "[format "%.2f" [expr {double($temp_len_onlyPhysical) / $totalVtInst_onlyPhysical * 100}]]%"
      set temp_area_ratio_onlyPhysical "[format "%.2f" [expr {$temp_area_onlyPhysical / $area_totalVtInst_onlyPhysical * 100}]]%"
    }
    if {!$totalVtInst_withPhysical || !$area_totalVtInst_withPhysical} {
      set temp_ratio_withPhysical "0.0%"
      set temp_area_ratio_withPhysical "0.0%"
      lappend suffixInfo "# $temp_vtname total count == 0, ratio and area can't calculate it!!!"
    } else {
      set temp_ratio_withPhysical "[format "%.2f" [expr {double($temp_len_withPhysical) / $totalVtInst_withPhysical * 100}]]%"
      set temp_area_ratio_withPhysical "[format "%.2f" [expr {$temp_area_withPhysical / $area_totalVtInst_withPhysical * 100}]]%"
    }
    list $temp_vtname $temp_len_withoutPhysical $temp_ratio_withoutPhysical [format "%.2f" $temp_area_withoutPhysical] $temp_area_ratio_withoutPhysical
  }]
  set ratioOfVT [linsert $ratioOfVT 0 [list "VTtype" "count(woPhys)" "countRatio(woPhys)" "area(woPhys)" "areaRatio(woPhys)"]]
  set ratioOfVt_transposed [list]
  foreach temp_vtlist $ratioOfVT {
    if {$ratioOfVt_transposed eq ""} {
      set ratioOfVt_transposed [lindex $ratioOfVT 0]
    } else {
      set i 0
      foreach temp_item $ratioOfVt_transposed {
        lset ratioOfVt_transposed $i [concat $temp_item [lindex $temp_vtlist $i]]
        incr i
      }
    }
  }
  set fo [open $rptName w]
  puts $fo [join [table_format_with_title $ratioOfVt_transposed 0 left "count and ratio of every vt type specified by user" 1] \n]
  if {[llength $suffixInfo] > 1} {
    puts $fo ""
    puts $fo [join $suffixInfo \n]
  }
  set indexOfAreaRatio [lsearch [lindex $ratioOfVT 0] "areaRatio(woPhys)"]
  set lvtAreaRatio [lindex [lsearch -inline -exact -index 0 $ratioOfVT LVT] $indexOfAreaRatio]
  set ulvtAreaRatio [lindex [lsearch -inline -exact -index 0 $ratioOfVT ULVT] $indexOfAreaRatio]
  puts $fo "lvtAreaRatio $lvtAreaRatio ulvtAreaRatio $ulvtAreaRatio"
  close $fo
  return [list lvtAreaRatio $lvtAreaRatio ulvtAreaRatio $ulvtAreaRatio]
}
define_proc_arguments check_vtRatio \
  -info "check vt ratio and count"\
  -define_args {
    {-vtTypeExpNameList "specify the exp_name list for every vt type" AList list optional}
    {-rptName "specify the output file name" AString string optional}
  }
proc check_weakDriveInstNetLength {args} {
  set driveCapacityGetExp    {.*D(\d+)BWP.*} ;
  set lengthThreshold        200
  set driveCapacityThreshold 4
  set rptName                "signoff_check_weakDriveInstNetLength.rpt"
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  set allCelltypes [dbget top.insts.cell.name -u -e]
  set weakDriveCapacityCelltypes [lmap temp_celltype $allCelltypes {
    regexp $driveCapacityGetExp $temp_celltype -> temp_driveCapacity
    if {$temp_driveCapacity < $driveCapacityThreshold} {
      list $temp_driveCapacity $temp_celltype
    } else { continue }
  }]
  set netLengthLIST [list]
  foreach temp_weakCelltype $weakDriveCapacityCelltypes {
    lassign $temp_weakCelltype temp_driveCapacity temp_celltype
    set weakInsts [dbget [dbget top.insts.cell.name $temp_celltype -p2].name -e]
    foreach temp_inst $weakInsts {
      set temp_outputTerms [dbget [dbget [dbget top.insts.name $temp_inst -p].instTerms.isOutput 1 -p].name]
      foreach temp_outputterm $temp_outputTerms {
        set temp_netname [dbget [dbget top.insts.instTerms.name $temp_outputterm -p].net.name -e]
        if {$temp_netname eq ""} { continue } else {
          set temp_length [get_net_length $temp_netname]
          if {$temp_length > $lengthThreshold} {
            lappend netLengthLIST [list $temp_driveCapacity $temp_celltype $temp_length $temp_netname $temp_outputTerms]
          }
        }
      }
    }
  }
  set netLengthLIST [lsort -index 2 -real -decreasing $netLengthLIST]
  set totalNum [llength $netLengthLIST]
  set netLengthLIST [linsert $netLengthLIST 0 [list driveCap celltype netLength netName outputTermName]]
  set fo [open $rptName w]
  puts $fo [join [table_format_with_title $netLengthLIST 0 left "" 0] \n]
  puts $fo ""
  puts $fo "TOTALNUM: $totalNum"
  puts $fo "weakDriveNetLength $totalNum"
  close $fo
  return [list weakDriveNetLength $totalNum]
}
define_proc_arguments check_weakDriveInstNetLength \
  -info "check weak drive inst net length"\
  -define_args {
    {-driveCapacityGetExp "specify the expression of drive capacity from celltype to get info" AString string optional}
    {-lengthThreshold "specify the length threshold" AFloat float optional}
    {-driveCapacityThreshold "specify the drive capacity threshold" AFloat float optional}
    {-rptName "specify output file" AString string optional}
  }
