#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2026/01/20 12:25:38 Tuesday
# label     : signoff_check
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc
#             |flow_proc|report_proc|cross_lang_proc|eco_proc|misc_proc|snippet|signoff_check)
#   perl -> (format_sub|getInfo_sub|perl_task|flow_perl)
# descrip   : run signoff_check procs
# return    : output file and format list
# ref       : link url
# --------------------------
proc run_signoff_check_procs {} {
  set targetDir "./"
  set items_check {
    {antennaCell                                1}
    {weakDriveInstNetLength                     1}
    {clockCellFixed                             1}
    {clockPathLength                            1}
    {clockTreeCells                             1}
    {dataPathLength                             1}
    {decapDensity                               1}
    {delayCellInClockTreeLeaf                   1}
    {delayCellLevel                             0}
    {dfmVia                                     1}
    {dontTouchCell                              1}
    {dontUseCell                                1}
    {inputTermsFloating                         1}
    {ipMemInputBufCellDriveSize                 1}
    {ipMemPinNetLength                          1}
    {maxFanout                                  1}
    {missingVia                                 1}
    {place                                      1}
    {portNetLength                              1}
    {stdUtilization                             1}
    {tieCellLoadLength                          1}
    {tieFanout                                  1}
    {vtRatio                                    1}
    {signalNetOutofDieAndOverlapWithRoutingBlkg 1}
  }
  set simpleCheck_onlyHaveRptNameArgs {inputTermsFloating dfmVia delayCellInClockTreeLeaf decapDensity clockCellFixed place stdUtilization}

  set delayCellLevelThreshold                                      10
  set ipsCelltypeNamesToCheckAntennaCell                           [list]
  set driveCapacityGetExp                                          {.*D(\d+)BWP.*}
  set weakDriveInstNetLengthThreshold                              200
  set weakDriveInstDriveCapacityThreshold                          4
  set clockPathLengthThreshold                                     240
  set dataPathLengthThreshold                                      400
  set clockTreeCells_removeCelltypeList                            [list]
  set clockTreeCells_removeInstNameList                            [list]
  set clockTreeCells_and_ipMemInputBufCellDriveSize_celltypeRegExp {.*D(\d+)BWP.*140([(UL)LH]VT)?$}
  set clockTreeCells_availableVT                                   {HVT SVT LVT ULVT}
  set clockTreeCells_clkFlagExp                                    {^DCCK|^CK}
  set delayCellLevel_levelThreshold                                10
  set dontTouch_setSizeOkInstFileList                              [list]
  set dontTouch_setDontTouchInstFileList                           [list]
  set dontTouch_setBoundaryHierPinDontTouchModuleNameFileList      [list]
  set dontUseCell_dontUseExpressionList                            {G* K* CLK*}
  set dontUseCell_ignoreCellExpressionList                         {G* CK* DCCK* TIE* FILL* DCAP* *SYNC* DEL*}
  set ipMemInputBufCellDriveSize_removeInstExpList                 {mesh}
  set ipMemInputBufCellDriveSize_removeCelltypeExpList             {TIE}
  set ipMemInputBufCellDriveSize_sizeThreshold                     4
  set ipMemPinNetLength_memCelltypeExp_toIgnore                    {}
  set ipMemPinNetLength_ipExpOrNameListToMatch                     {}
  set ipMemPinNetLength_lengthThreshold                            50
  set maxFanout_fanoutThreshold                                    32
  set missingVia_layersToCheck                                     {M4 M5 M6 M7 M8}
  set portNetLength_lengthThreshold                                100
  set signalNetOutofDieAndOverlapWithRoutingBlkg_layersToCheck     {M2 M3 M4 M5 M6 M7}
  set tieCellLoadLength_lengthThreshold                            20
  set tieFanout_fanoutThreshold                                    1
  set vtRatio_vtTypeExpNameList                                    {{{BWP.*140HVT$} HVT} {{BWP.*140$} SVT} {{BWP.*140LVT$} LVT} {{BWP.*140ULVT} ULVT}}

  set currentDir [pwd]
  cd $targetDir
  foreach temp_item $items_check {
    lassign $temp_item temp_checkname temp_enable
    if {$temp_enable} {
      puts "begin run: check_$temp_checkname" 
      if {$temp_checkname in $simpleCheck_onlyHaveRptNameArgs} {
        check_$temp_checkname
      } elseif {$temp_checkname eq "antennaCell"} {
        check_$temp_checkname -ipCelltypeToCheckAnt $ipsCelltypeNamesToCheckAntennaCell
      } elseif {$temp_checkname eq "weakDriveInstNetLength"} {
        check_$temp_checkname -driveCapacityGetExp $driveCapacityGetExp -lengthThreshold $weakDriveInstNetLengthThreshold -driveCapacityThreshold $weakDriveInstDriveCapacityThreshold
      } elseif {$temp_checkname eq "clockPathLength"} {
        check_$temp_checkname -lengthThreshold $clockPathLengthThreshold
      } elseif {$temp_checkname eq "clockTreeCells"} {
        check_$temp_checkname -remove_celltype_list $clockTreeCells_removeCelltypeList -remove_instname_list $clockTreeCells_removeInstNameList -celltypeRegExp $clockTreeCells_and_ipMemInputBufCellDriveSize_celltypeRegExp -availableVT $clockTreeCells_availableVT -clkFlagExp $clockTreeCells_clkFlagExp
      } elseif {$temp_checkname eq "dataPathLength"} {
        check_$temp_checkname -lengthThreshold $dataPathLengthThreshold
      } elseif {$temp_checkname eq "delayCellLevel"} {
        check_$temp_checkname -levelThreshold $delayCellLevel_levelThreshold
      } elseif {$temp_checkname eq "dontTouchCell"} {
        check_$temp_checkname -setSizeOkInstFileList $dontTouch_setSizeOkInstFileList -setDontTouchInstFileList $dontTouch_setDontTouchInstFileList -setBoundaryHierPinDontTouchModuleNameFileList $dontTouch_setBoundaryHierPinDontTouchModuleNameFileList
      } elseif {$temp_checkname eq "dontUseCell"} {
        check_$temp_checkname -dontUseExpressionList $dontUseCell_dontUseExpressionList -ignoreCellExpressionList $dontUseCell_ignoreCellExpressionList
      } elseif {$temp_checkname eq "ipMemInputBufCellDriveSize"} {
        check_$temp_checkname -removeInstExpList $ipMemInputBufCellDriveSize_removeInstExpList -removeCelltypeExpList $ipMemInputBufCellDriveSize_removeCelltypeExpList -celltypeExp $clockTreeCells_and_ipMemInputBufCellDriveSize_celltypeRegExp -sizeThreshold $ipMemInputBufCellDriveSize_sizeThreshold
      } elseif {$temp_checkname eq "ipMemPinNetLength"} {
        check_$temp_checkname -memCelltypeExp_toIgnore $ipMemPinNetLength_memCelltypeExp_toIgnore -ipExpOrNameListToMatch $ipMemPinNetLength_ipExpOrNameListToMatch -lengthThreshold $ipMemPinNetLength_lengthThreshold
      } elseif {$temp_checkname eq "maxFanout"} {
        check_$temp_checkname -fanoutThreshold $maxFanout_fanoutThreshold
      } elseif {$temp_checkname eq "missingVia"} {
        check_$temp_checkname -layersToCheck $missingVia_layersToCheck
      } elseif {$temp_checkname eq "portNetLength"} {
        check_$temp_checkname -lengthThreshold $portNetLength_lengthThreshold
      } elseif {$temp_checkname eq "tieCellLoadLength"} {
        check_$temp_checkname -lengthThreshold $tieCellLoadLength_lengthThreshold
      } elseif {$temp_checkname eq "tieFanout"} {
        check_$temp_checkname -fanoutThreshold $tieFanout_fanoutThreshold
      } elseif {$temp_checkname eq "vtRatio"} {
        check_$temp_checkname -vtTypeExpNameList $vtRatio_vtTypeExpNameList
      } elseif {$temp_checkname eq "signalNetOutofDieAndOverlapWithRoutingBlkg"} {
        check_$temp_checkname -layersToCheck $signalNetOutofDieAndOverlapWithRoutingBlkg_layersToCheck
      } else {
        puts "**ERROR: check item: $temp_checkname is not valid!!! check it." 
      }
       
    }
  }
  cd $currentDir
}
