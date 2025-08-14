#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/08 09:48:33 Friday
# label     : db_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : build the LUT(look-up table) for some fixed design info in order to reduce complexity and other levels of running time
# return    : tcl script to create dict database(it is convenient for searching. it can save permently and source it whenever you need it.)
#             dict database include:
#             dictName: $LUT_filename
#               layer1 attribute: designName/mainCoreRowHeight/mainCoreSiteWidth/celltype 
#               layer2 attribute of celltype: [allLibCellTypeNames(like BUFX3AR9/INVX8AL9/...)] 
#               layer3 attribute of every item of celltype(layer2): class/size (AT001) capacity/vt(AT002)
# args      : $process: {M31GPSC900NL040P*_40N}|...
# ref       : link url
# --------------------------
source ../../../packages/print_formattedTable.package.tcl; # print_formattedTable
source ../../../eco_fix/timing_fix/trans_fix/proc_findMostFrequentElementOfList.invs.tcl; # findMostFrequentElement
source ../trans_fix/proc_get_cell_class.invs.tcl; # get_cell_class ; get_class_of_celltype
source ../trans_fix/proc_getDriveCapacity_ofCelltype.pt.tcl; # get_driveCapacityAndVTtype_of_celltype_spcifyingStdCellLib
alias sus "subst -nocommands -nobackslashes"
proc build_sar_LUT_usingDICT {{LUT_filename "lutDict.tcl"} {process {M31GPSC900NL040P*_40N}} {capacityFlag "X"} {vtFastRange {AL9 AR9 AH9}} {stdCellFlag ""} {celltypeMatchExp {^.*X(\d+).*(A[HRL]9)$}} {refBuffer "BUFX3AR9"} {refClkBuffer "CLKBUFX3AR9"} {promptPrefix "# song"} {lutDictName "lutDict"}} {
  set promptINFO [string cat $promptPrefix "INFO"] ; set promptERROR [string cat $promptPrefix "ERROR"] ; set promptWARN [string cat $promptPrefix "WARN"]
  global expandedMapList
  #puts "expandedMapList: $expandedMapList"
  set fo [open $LUT_filename w]
  puts $fo "unset $lutDictName"
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
    puts $fo "dict set $lutDictName vtrange \{$vtFastRange\}" 
  }
  if {$stdCellFlag == ""} {
    puts $fo "$promptWARN: have no process std cell flag defination!!!" 
  } else {
    puts $fo "dict set $lutDictName stdcellflag $stdCellFlag" 
  }
  set designName [dbget top.name -e] 
  if {$designName == ""} { puts $fo "$promptERROR : have no design name!!!" } else { puts $fo "dict set $lutDictName designName $designName" }
  set rowHeightAllList [dbget top.fplan.rows.box_sizey -e]
  if {$rowHeightAllList == ""} { 
    puts $fo "$promptERROR : have no row defination!!!" 
  } else { 
    set mainCoreRowHeight [findMostFrequentElement $rowHeightAllList 50.0 1]
    puts $fo "dict set $lutDictName mainCoreRowHeight $mainCoreRowHeight" 
  }
  set siteWidthAllList [dbget top.fplan.rows.site.size_x -e]
  if {$siteWidthAllList == ""} { 
    puts $fo "$promptERROR : have no site defination!!!" 
  } else {
    set mainCoreSiteWidth [findMostFrequentElement $siteWidthAllList 50.0 1]
    puts $fo "dict set $lutDictName mainCoreSiteWidth $mainCoreSiteWidth"
  }
  set siteTypesInDesign [dbget top.fplan.rows.site.class -u -e]
  if {$siteTypesInDesign == ""} {
    puts $fo "$promptWARN: have no site type used in design, you need createRow!!!" 
  } else {
    set coreRect {0 0 0 0}
    set rowsBoxesForSiteTypes [lmap tempsitetype $siteTypesInDesign {
      set tempsitetype_row_ptr [dbget top.fplan.rows.site.class $tempsitetype -p2]
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
  set allCellType_ptrList [dbget head.libCells.]
  if {$allCellType_ptrList == ""} { 
    puts $fo "$promptERROR : have no celltype in library!!!" 
  } else {
    set sortedCellType_ptrList [lsort -increasing -unique $allCellType_ptrList]
    set celltype_class_size_D3List [lmap temptype_ptr $sortedCellType_ptrList {
      set temptypename [dbget $temptype_ptr.name]
      set tempclass [get_class_of_celltype $temptypename $expandedMapList] 
      set tempsize [lindex [dbget $temptype_ptr.size] 0]
      set ifInNoCare [expr {$tempclass in {notFoundLibCell IP mem filler noCare IOfiller cutCell IOpad tapCell}}]
      # songNOTE: NOTICE: you can't judge if have error using catch cmd monitoring cmd 'regexp'. cuz regexp will not prompt error when it is not match successfully!!!
      if {!$ifInNoCare} { catch {unset wholname} ; catch {unset capacity} ; catch {unset vt} ; set ifErr [catch {regexp $celltypeMatchExp $temptypename wholname capacity vt} errInfo] }
      if {$ifInNoCare || ![info exists wholname]} {
        set tempcapacity "NaN" 
        set tempvttype "NaN"
        set tempvtList "NaN"
        set tempcapacityList "NaN"
        if {![info exists wholname]} {lappend cantMatchList [list $temptypename $tempclass]}
      } else {
        lassign [get_driveCapacityAndVTtype_of_celltype_spcifyingStdCellLib $temptypename $process] tempcapacity tempvttype
        if {$tempcapacity == 0.5} {set tempcapacity_2 05} else {set tempcapacity_2 $tempcapacity}
        set tempvtcapacityExp [regsub [sus {^(.*$capacityFlag)${tempcapacity_2}(.*)${tempvttype}$}] $temptypename [sus {^\1\d+\2A[HRL]9$}]]
        # set tempvtExp [regsub [sus {(.*)${tempvttype}$}] $temptypename [sus {^\1A\w9$}]]
        # set tempcapacityExp [regsub [sus {(.*X)${tempcapacity}(.*)}] $temptypename [sus {^\1*\2$}]] ; # sus - subst -nocommands -nobackslashes
        set tempvtcapacityList_raw [dbget -regexp head.libCells.name $tempvtcapacityExp]
        set tempvtList [lsort -unique [lmap tmpvt $tempvtcapacityList_raw {
          regexp $celltypeMatchExp $tmpvt vtwholename vtcapacity vtvt
          set vtvt
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
    puts $fo "  dict set $lutDictName celltype \$celltypeName vtlist \$cellvtList" ; # AT002
    puts $fo "  dict set $lutDictName celltype \$celltypeName caplist \$cellcapacityList" ; # AT002
    puts $fo "\}"
  }
  puts $fo ""
  close $fo
  # puts [join $cantMatchList \n]
}
