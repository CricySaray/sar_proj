#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/08 09:48:33 Friday
# label     : db_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : build the LUT(look-up table) for some fixed design info in order to reduce complexity and other levels of running time
# NOTICE    : MUST run this proc at invs db WITH TIMING info
# update    : 2025/08/17 22:39:02 Sunday
#             (U001) update method to get core inner boundary rects!!! simple and efficient!!! using proc:findCoreRectsInsideBoundary
# return    : tcl script to create dict database(it is convenient for searching. it can save permently and source it whenever you need it.)
#             dict database include:
#             dictName: $LUT_filename
#               layer1 attribute: designName/mainCoreRowHeight/mainCoreSiteWidth/celltype 
#               layer2 attribute of celltype: [allLibCellTypeNames(like BUFX3AR9/INVX8AL9/...)] 
#               layer3 attribute of every item of celltype(layer2): class/size (AT001) capacity/vt(AT002) caplist/vtlist(AT003)
# input     : $process: {M31GPSC900NL040P*_40N}|{TSMC_cln12ffc}
# args      : $process: {M31GPSC900NL040P*_40N}|...
# ref       : link url
# --------------------------
source ../../../packages/print_formattedTable.package.tcl; # print_formattedTable
source ../../../eco_fix/timing_fix/trans_fix/proc_findMostFrequentElementOfList.invs.tcl; # findMostFrequentElement
source ../trans_fix/proc_get_cell_class.invs.tcl; # get_cell_class ; get_class_of_celltype
source ../trans_fix/proc_getDriveCapacity_ofCelltype.pt.tcl; # get_driveCapacityAndVTtype_of_celltype_spcifyingStdCellLib | get_driveCapacity_of_celltype_returnCapacityAndVTtype
# source ./proc_getRect_innerAreaEnclosedByEndcap.invsGUI.tcl; # getRect_innerAreaEnclosedByEndcap
source ./proc_findCoreRectInsideBoundary.invsGUI.tcl; # findCoreRectsInsideBoundary (used to replace proc:getRect_innerAreaEnclosedByEndcap)
source ../../../packages/add_file_header.package.tcl; # add_file_header
alias sus "subst -nocommands -nobackslashes"
proc build_sar_LUT_usingDICT {args} {
  set process                                {TSMC_cln40lp} ; # TSMC_cln12ffc|M31GPSC900NL040P*_40N|TSMC_cln40lp
  set promptPrefix                           "# song"
  set LUT_filename                           "lutDict.tcl"
  set lutDictName                            "lutDict"
  set selectSmallOrMuchRowSiteSizeAsMainCore "small" ; # small|much
  set boundaryOrEndCapCellName               "ENDCAP"
  set shrinkOff                              "-1"  ; # -1: using mainCoreRowHeight, >=0: will using value of this var
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {$process in {M31GPSC900NL040P*_40N}} {
    set capacityFlag "X" ; set vtFastRange {AL9 AR9 AH9} ; set stdCellFlag "" ; set celltypeMatchExp {^.*X(\d+).*(A[HRL]9)$} ; set VtMatchExp {A[HRL]9} ; set refBuffer "BUFX3AR9" ; set refClkBuffer "CLKBUFX3AR9"
    set noCareCellClass {notFoundLibCell IP mem filler noCare IOfiller cutCell IOpad tapCell}
  } elseif {$process in {TSMC_cln12ffc}} {
    set capacityFlag "D" ; set vtFastRange {ULVT LVT SVT HVT} ; set stdCellFlag "BWP" ; set celltypeMatchExp {^.*D(\d+)BWP.*CPD(U?L?H?VT)?$} ; set VtMatchExp {(U?LVT)?} ; set refBuffer "BUFFD1BWP6T24P96CPDLVT" ; set refClkBuffer "DCCKBD12BWP6T16P96CPDLVT"
    set noCareCellClass {notFoundLibCell IP mem filler noCare BoundaryCell DTCD pad physical clamp esd decap ANT tapCell}
  } elseif {$process in {TSMC_cln40lp}} {
    set capacityFlag "D" ; set vtFastRange {LVT RVT} ; set stdCellFlag "" ; set celltypeMatchExp {^[^_]*_X(\d+P?\d?)[ABEMF]?_A\dT([RL])40$} ; set VtMatchExp {(U?LVT)?} ; set refBuffer "BUF_X1M_A9TL40" ; set refClkBuffer "BUF_X1B_A9TL40"
    
    set noCareCellClass {notFoundLibCell IP mem filler noCare BoundaryCell DTCD pad physical clamp esd decap ANT tapCell}
  } else {
    error "proc build_sar_LUT_usingDICT: error process($process) which is not support now!!!"
  }
  set promptINFO [string cat $promptPrefix "INFO"] ; set promptERROR [string cat $promptPrefix "ERROR"] ; set promptWARN [string cat $promptPrefix "WARN"]
  #puts "expandedMapList: $expandedMapList"
  set fo [open $LUT_filename w]
  set descrip "It functions as a lookup table. This file records some necessary information, all of which are stored as dict-type data and can be easily \
    accessed using the operateLUT proc. If such information were obtained through calculations each time, it would make the proc extremely inefficient."
  set usage "You can obtain the content here through a unified lookup table function. For example: operateLUT -type read -attr {core_inner_boundary_rects}, \
    but note that you need to source this file in the invs db beforehand."
  add_file_header -fileID $fo -descrip $descrip -usage $usage
  puts $fo "catch \{unset $lutDictName\}"
  puts $fo "global $lutDictName"
  puts $fo "set $lutDictName \[dict create\]"
  if {$process == ""} {
    puts $fo "$promptERROR: have no process defination!!!" 
  } else {
    puts $fo "dict set $lutDictName process $process" 
  }
  if {$capacityFlag == ""} {
    puts $fo "$promptWARN: have no process capacity flag defination!!!" 
  } else {
    puts $fo "dict set $lutDictName capacityflag $capacityFlag" 
  }
  if {$vtFastRange == ""} {
    puts $fo "$promptWARN: have no process vt fast range defination!!!"
  } else {
    puts $fo "dict set $lutDictName vtrange \{$vtFastRange\} ; # please write from fastest vt to the most slow vt!!!" 
  }
  if {$stdCellFlag == ""} {
    puts $fo "$promptWARN: have no process std cell flag defination!!!" 
    puts $fo "dict set $lutDictName stdcellflag \"\""
  } else {
    puts $fo "dict set $lutDictName stdcellflag $stdCellFlag" 
  }
  set designName [dbget top.name -e] 
  if {$designName == ""} { puts $fo "$promptERROR : have no design name!!!" } else { puts $fo "dict set $lutDictName designName $designName" }
  set rowHeightAllList [dbget top.fplan.rows.box_sizey -e]
  if {$rowHeightAllList == ""} { 
    puts $fo "$promptERROR : have no row defination!!!" 
  } else { 
    if {$selectSmallOrMuchRowSiteSizeAsMainCore == "much"} {
      set mainCoreRowHeight [findMostFrequentElement $rowHeightAllList 50.0 1]
    } elseif {$selectSmallOrMuchRowSiteSizeAsMainCore == "small"} {
      set mainCoreRowHeight [lindex [lsort -real -increasing $rowHeightAllList] 0]
    }
    puts $fo "dict set $lutDictName mainCoreRowHeight $mainCoreRowHeight" 
  }
  set siteWidthAllList [dbget top.fplan.rows.site.size_x -e]
  if {$siteWidthAllList == ""} { 
    puts $fo "$promptERROR : have no site defination!!!" 
  } else {
    if {$selectSmallOrMuchRowSiteSizeAsMainCore == "much"} {
      set mainCoreSiteWidth [findMostFrequentElement $siteWidthAllList 50.0 1]
    } elseif {$selectSmallOrMuchRowSiteSizeAsMainCore == "small"} {
      set mainCoreSiteWidth [lindex [lsort -real -increasing $siteWidthAllList] 0]
    }
    puts $fo "dict set $lutDictName mainCoreSiteWidth $mainCoreSiteWidth"
  }
  set siteTypesInDesign [dbget top.fplan.rows.site.name -u -e]
  if {$siteTypesInDesign == ""} {
    puts $fo "$promptWARN: have no site type used in design, you need createRow!!!" 
  } else {
    set coreRect {0 0 0 0}
    set rowsBoxesForSiteTypes [lmap tempsitetype $siteTypesInDesign {
      set tempsitetype_row_ptr [dbget top.fplan.rows.site.name $tempsitetype -p2]
      set temprows [dbget $tempsitetype_row_ptr.box]
      lassign [dbget $tempsitetype_row_ptr.site.size -u] temp_sitewidth temp_siteheight
      set tempjoinedrows "{[join $temprows "} OR {"]}"
      set tempinitrowRect {0 0 0 0}
      set tempinitrowRect [dbShape -output hrect $tempinitrowRect OR {*}$tempjoinedrows]
      set coreRect [dbShape -output hrect $coreRect OR {*}$tempjoinedrows]
      list $tempsitetype $tempinitrowRect $temp_sitewidth $temp_siteheight
    }] ; # {{siteTypeName {{x y x1 y1} {x y x1 y1} ...}} { ... }}
    foreach tempsitetype_rowrect $rowsBoxesForSiteTypes {
      lassign $tempsitetype_rowrect sitetype rowrect sitewidth siteheight
      puts $fo "dict set $lutDictName sitetype $sitetype row_rects \{$rowrect\}" 
      puts $fo "dict set $lutDictName sitetype $sitetype size \{$sitewidth $siteheight\}"
    }
    puts $fo "dict set $lutDictName core_rects \{$coreRect\}"
  }
  flush $fo
  set allBoundaryCellRects [dbget [dbget top.insts.name *$boundaryOrEndCapCellName* -p].box]
  set coreRects_innerBoundary [findCoreRectsInsideBoundary $allBoundaryCellRects] ; # U001
  if {$coreRects_innerBoundary == ""} {
    puts $fo "$promptWARN: can't calculate core inner boundary rects (std cell rects) correctly, check whether there are disconnected boundary cells in your fplan."
  } else {
    puts $fo "dict set $lutDictName core_inner_boundary_rects \{$coreRects_innerBoundary\}"
  }
  #puts "# Begin source $LUT_filename, and then continue add some other info\n" ; 
  set fs [open $LUT_filename r]
  while {[gets $fs line] > -1} { eval $line }
  close $fs
  #puts "# End source ."
  set expandedMapList [expandMapList [operateLUT -type read -attr process]]
  set allCellType_ptrList [dbget head.libCells.]
  if {$allCellType_ptrList == ""} { 
    puts $fo "$promptERROR : have no celltype in library!!!" 
  } else {
    set sortedCellType_ptrList [lsort -increasing -unique $allCellType_ptrList]
    set celltype_class_size_D3List [lmap temptype_ptr $sortedCellType_ptrList {
      set temptypename [dbget $temptype_ptr.name]
      set tempclass [get_class_of_celltype $temptypename $expandedMapList] 
      set tempsize [lindex [dbget $temptype_ptr.size] 0]
      set ifInNoCare [expr {$tempclass in $noCareCellClass}]
      # songNOTE: NOTICE: you can't judge if have error using catch cmd monitoring cmd 'regexp'. cuz regexp will not prompt error when it is not match successfully!!!
      if {!$ifInNoCare} { catch {unset wholname} ; catch {unset capacity} ; catch {unset vt} ; set ifErr [catch {regexp $celltypeMatchExp $temptypename wholname capacity vt} errInfo] }
      if {$ifInNoCare || ![info exists wholname]} {
        set tempcapacity "NaN" 
        set tempvttype "NaN"
        set tempvtList "NaN"
        set tempcapacityList "NaN"
        if {![info exists wholname]} {lappend cantMatchList [list $temptypename $tempclass]}
      } else {
        lassign [get_driveCapacity_of_celltype_returnCapacityAndVTtype $temptypename $celltypeMatchExp] tempcapacity tempvttype
        if {$tempcapacity == 0.5} {set tempcapacity_2 05} else {set tempcapacity_2 $tempcapacity}
        if {$process == {TSMC_cln12ffc} && $tempvttype == "SVT"} { set vtFromExp "" } else { set vtFromExp $tempvttype }
        set tempvtcapacityExp [regsub [sus {^(.*$capacityFlag)${tempcapacity_2}($stdCellFlag.*)${vtFromExp}$}] $temptypename [sus {^\1\d+\2$VtMatchExp$}]]
        set tempvtcapacityList_raw [dbget -regexp head.libCells.name $tempvtcapacityExp]
        set tempvtList [lsort -unique [lmap tmpvt $tempvtcapacityList_raw {
          regexp $celltypeMatchExp $tmpvt vtwholename vtcapacity vtvt
          if {$vtvt == "" && $process == {TSMC_cln12ffc}} {set vtvt SVT} else {set vtvt}
        }]]
        set tempcapacityList [lsort -unique -real -increasing [lmap tmpcapacity $tempvtcapacityList_raw {
          regexp $celltypeMatchExp $tmpcapacity capwholename capcapacity capvt
          if {$capcapacity == 05} {set capcapacity 0.5}
          set capcapacity
        }]]
      }
      set temp_typename_class_size "{{$temptypename $tempclass {$tempsize} $tempvttype $tempcapacity {$tempvtList} {$tempcapacityList}}}"
    }]
    set sorted_celltype_class_size_D3List [lsort $celltype_class_size_D3List]
    if {$refBuffer == ""} {
      puts $fo "$promptWARN: have no refBuffer defination!!!"
    } else {
      puts $fo "dict set $lutDictName refbuffer $refBuffer"
    }
    if {$refClkBuffer == ""} {
      puts $fo "$promptWARN: have no refClkBuffer defination!!!"
    } else {
      puts $fo "dict set $lutDictName refclkbuffer $refClkBuffer"
    }
    puts $fo "set celltype_subAttributes \{"
    puts $fo [print_formattedTable $sorted_celltype_class_size_D3List]
    puts $fo "\}"
    puts $fo "foreach temp_celltype_attribute \$celltype_subAttributes \{"
    puts $fo "  set celltypeName \[lindex \$temp_celltype_attribute 0\]"
    puts $fo "  set cellclass \[lindex \$temp_celltype_attribute 1\]"
    puts $fo "  set cellsize \[lindex \$temp_celltype_attribute 2\]"
    puts $fo "  set cellvt \[lindex \$temp_celltype_attribute 3\]"
    puts $fo "  set cellcapacity \[lindex \$temp_celltype_attribute 4\]"
    puts $fo "  set cellvtList \[lindex \$temp_celltype_attribute 5\]"
    puts $fo "  set cellcapacityList \[lindex \$temp_celltype_attribute 6\]"
    puts $fo "  dict set $lutDictName celltype \$celltypeName class \$cellclass" ; # AT001
    puts $fo "  dict set $lutDictName celltype \$celltypeName size \$cellsize" ; # AT001
    puts $fo "  dict set $lutDictName celltype \$celltypeName vt \$cellvt" ; # AT002
    puts $fo "  dict set $lutDictName celltype \$celltypeName capacity \$cellcapacity" ; # AT002
    puts $fo "  dict set $lutDictName celltype \$celltypeName vtlist \$cellvtList" ; # AT003
    puts $fo "  dict set $lutDictName celltype \$celltypeName caplist \$cellcapacityList" ; # AT003
    puts $fo "\}"
  }
  puts $fo ""
  close $fo
  # puts [join $cantMatchList \n]
}

define_proc_arguments build_sar_LUT_usingDICT \
  -info "build LUT using dict in tcl"\
  -define_args {
    {-process "specify the type of process" oneOfString one_of_string {optional value_type {values {TSMC_cln12ffc M31GPSC900NL040P*_40N}}}}
    {-promptPrefix "specify the prefix of Prompt, like ERROR, INFO, WARN." AString string optional}
    {-LUT_filename "specify the lut filename(output filename)" AString string optional}
    {-lutDictName "specify the dict variable name(global var), you will also modify in proc operateLUT" AString string optional}
    {-selectSmallOrMuchRowSiteSizeAsMainCore "specify the item to compare as core main row/site" oneOfString one_of_string {optional value_type {values {small much}}}}
    {-boundaryOrEndCapCellName "specify the boundary cell name used for input of proc findCoreRectsInsideBoundary" AString string optional}
    {-shrinkOff "specify the value to off when calculate the core_inner_boundary_rects" AFloat float optional}
  }
