namespace eval design:: {

  proc reportUtilization {} {
      #cutRow     ;# you'd better execute 'cutRow' before checking utilization using the command.
      set dieBoxes   [dbGet -e top.fplan.boxes]
      set core2Left  [dbGet -e top.fplan.core2Left]
      set core2Bot [dbGet -e top.fplan.core2Bot]
      set core2Left 0
      set core2Bot  0
      set coreBoxes [dbShape $dieBoxes SIZEX -$core2Left SIZEY -$core2Bot]
      set usefulBoxes $coreBoxes
      set rowsBoxes [dbShape [dbGet -e top.fplan.rows.box]]
      set pblkgBoxes [dbGet -e top.fplan.pblkgs.boxes]
      set pblkgBoxes [dbShape $pblkgBoxes and $coreBoxes]
      set blockBoxes [dbGet -e [dbGet -e top.insts.cell.subClass block -p2].boxes]
      set blockBoxes [dbShape $blockBoxes and $coreBoxes]
      set haloBlkBox [dbGet -e top.insts.pHaloBox]


      set dieArea [dbShape $dieBoxes -output area]
      set parBlkgBoxes [dbGet -e [dbGet -e top.fplan.pblkgs {.type == "partial" || .type == "hard"}].boxes]
      set parBlkgArea [dbShape $parBlkgBoxes -output area]
      set pblkgRatio [expr $parBlkgArea/$dieArea]
      if {$pblkgRatio > 0.9} {
          puts "CPT-WARNING: placement blockage area ratio is [expr $pblkgRatio*100]%."
          puts "              the calculation excude the partial blockages."
          set pblkgBoxes [dbGet -e [dbGet -e top.fplan.pblkgs {.type == "soft" || .type == "hard"}].boxes]
      }
      set usefulBoxes [dbShape $usefulBoxes and    $rowsBoxes]
      set usefulBoxes [dbShape $usefulBoxes andnot $pblkgBoxes]
      set usefulBoxes [dbShape $usefulBoxes andnot $blockBoxes]

      set placedArea [dbShape $usefulBoxes -output area]
      set logicPtrList [list]
      set physicalPtrList [list]


      set unplacedInstCount [llength [dbGet -e top.insts.pStatus unplaced]]
      set totalInstCount    [llength [dbGet -e top.insts]]
      set unplacedRatio   [expr $unplacedInstCount/[format "%.2f" $totalInstCount]]
      if {$unplacedRatio < 0.1} {
          foreach box $usefulBoxes {
             # comment out by simonz fix bug
             # set logicPtrList [concat $logicPtrList [dbGet -e [dbQuery -area $box -objType inst].isPhysOnly 0 -p]]
             set logicPtrList [concat $logicPtrList [dbGet -v [dbGet -e [dbQuery -area $box -objType inst].isPhysOnly 0 -p].cell.subClass block -p2]]
          }
      } else {
          set logicPtrList [dbGet -v [dbGet -e top.insts.isPhysOnly 0 -p].cell.subClass block -p2]
      }
      foreach box $usefulBoxes {
         set physicalPtrList [concat $physicalPtrList [dbGet -e [dbQuery -area $box -objType inst].isPhysOnly 1 -p]]
      }
      set logicPtrList [lsort -u $logicPtrList]
      set physicalPtrList [lsort -u $physicalPtrList]
      set physicalPtrList [dbGet -e $physicalPtrList.pstatus fixed -p]
      if {[dbGet -e $logicPtrList.area] == ""} {
          set logicArea 0
      } else {
          set logicArea [expr [join [dbGet -e $logicPtrList.area] {+}]]
      }
      if {$physicalPtrList == ""} {
          set fixedPhysicalArea 0
      } else {
          set fixedPhysicalArea [expr [join [dbGet -e $physicalPtrList.area] {+}]]
      }
      set density [expr $logicArea/$placedArea]
      set density [format "%.2f" [expr $density*100]]

      set density1 [expr [expr $logicArea+$fixedPhysicalArea]/$placedArea ]
      set density1 [format "%.2f" [expr $density1*100]]

      set allLogicArea [expr [join [dbGet [dbGet top.insts.isPhysOnly 0 -p].area] {+}]]
      set allFixedPhyArea [expr [join [dbGet [dbGet [dbGet top.insts.isPhysOnly 1 -p].pstatus fixed -p].area] {+}]]
      set coreArea [dbShape $coreBoxes -output area]
      set density2 [expr $allLogicArea/$coreArea]
      set density2 [format "%.2f" [expr $density2*100]]

      set allBlkArea [expr [join [dbGet [dbGet top.insts.cell.subClass block -p2].area] {+}]]
      set nonPlacedArea [dbShape $coreBoxes andnot $usefulBoxes -output area]
      if {$nonPlacedArea != 0} {
          set density3 [expr $allBlkArea/$nonPlacedArea]
          set density3 [format "%.2f" [expr $density3*100]]
      } else {
          set density3 [format "%.2f" 0]
      }
      puts "Density: $density% (logic only, excluded hard macros, placement blockages)"
      puts "Density: $density1% (logic + fixed physical cells, excluded hard macros, placement blockages)"
      puts "Density: $density2% (logic + fixed physical cells + macros)"
      puts "Memory Utilization: $density3% (macro's utilization - Channel calculations)"
      puts "Standard Cell Area = $allLogicArea ( $logicArea )"
      puts "Physical Cell Area = $allFixedPhyArea ( $fixedPhysicalArea)"
      puts "Macros   Cell Area = [dbShape $blockBoxes -output area]"
      puts "Core Area          = $coreArea"
  }

proc report_vt_usage {args} {
      global vt_groups
      global process

      #set process tsmcn12
      set maxLength 6
      set expanded 0
      set celltype "all"
      parse_proc_arguments -args $args results
      if {[info exist results(-expanded)]} {
          set expanded 1
      }
      if {[info exist results(-type)]} {
          set celltype $results(-type)
      }
      set outFile "report_vt_usage.rpt"
      if {[info exist results(-file)]} {
          set outFile $results(-file)
      }
      if {[info exist vt_groups] && [llength $vt_groups] > 1} {
          puts "User defined VT Groups: $vt_groups"
              set ivt_groups $vt_groups
      } else {
          if { $expanded == 1} {
              if {[regexp {tsmcn5} $process]} {
                  set ivt_groups "H6SVT *H6*SVT H6SVTLL *H6*SVTLL H6LVT *H6*DLVT H6LVTLL *H6*DLVTLL H6uLVT *H6*ULVT H6uLVTLL *H6*ULVTLL H6eLVT *H6*ELVT"	;# tsmcn5p
              } elseif {[regexp {tsmcn7} $process]} {
                  set ivt_groups "H8SVT *H8*SVT H11SVT *H11*SVT H8LVT *H8*DLVT H11LVT *H11*DLVT  H8uLVT *H8*ULVT H11uLVT *H11*ULVT"	;# tsmcn7
              } elseif {[regexp {tsmcn1} $process]} {
                  #set ivt_groups "C16SVT *16*PD C20SVT *20*PD C24SVT *24*PD C16LVT *16*DLVT C20LVT *20*DLVT C24LVT *24*DLVT C16uLVT *16*ULVT C20uLVT *20*ULVT C24uLVT *24*ULVT"	;# tsmcn12, tsmcn16 
                  set ivt_groups "C24SVT *24*PD C20SVT *20*PD C16SVT *16*PD C24LVT *24*DLVT C20LVT *20*DLVT C16LVT *16*DLVT C24uLVT *24*ULVT C20uLVT *20*ULVT C16uLVT *16*ULVT"	;# tsmcn12, tsmcn16 
              } elseif {[regexp {tsmcn2} $process]} {
                  set ivt_groups "C30HVT *30*P140HVT C35HVT *35*P140HVT C40HVT *40*P140HVT C30SVT *30*P140 C35SVT *35*P140 C40SVT *40*P140 C30LVT *30*P140LVT C35LVT *35*P140LVT C40LVT *40*P140LVT"	;# tsmcn22, tsmcn28
              }
          } else {
              if {[regexp {tsmcn5} $process]} {
                  set ivt_groups "SVT *SVT SVTLL *SVTLL LVT *DLVT LVTLL *DLVTLL uLVT *ULVT uLVTLL *ULVTLL eLVT *ELVT"	;# tsmcn5p
              } elseif {[regexp {tsmcn7} $process]} {
                  set ivt_groups "SVT *SVT LVT *DLVT uLVT *ULVT "	;# tsmcn7
              } elseif {[regexp {tsmcn1} $process]} {
                  set ivt_groups "SVT *PD  LVT *DLVT uLVT *ULVT "	;# tsmcn12, tsmcn16
              } elseif {[regexp {tsmcn2} $process]} {
                  set ivt_groups "HVT *P140HVT SVT *P140 LVT *P140LVT"	;# tsmcn22, tsmcn28
              }
          }
      }
      set items [list]
      array unset vtcells *
      array unset areaCells *
      set vtcells(ALL)    [llength [dbGet -e [dbGet -e top.insts.cell.subClass core -p2] {.isPhysOnly==0&&.isSpareGate==0}]]
      set areaCells(ALL)  0;foreach i [dbGet [dbGet -e [dbGet -e top.insts.cell.subClass core -p2] {.isPhysOnly==0&&.isSpareGate==0}].area]        {set areaCells(ALL)  [expr $areaCells(ALL)  + $i]} 
      set areaCells(ALl) [format "%.2f" $areaCells(ALL)]
      set vtcells(Others) $vtcells(ALL)
      set areaCells(Others) $areaCells(ALL)

      if {$celltype == "clock"} {
          set logicalInstPtr   [dbGet -e [dbGet -u [dbGet [dbGet top.nets.isClock 1 -p].instTerms.isOutput 1 -p].inst {.isPhysOnly==0&&.isSpareGate==0}].cell.subClass core -p2]
      } elseif {$celltype == "data"} {
          set logicalInstPtr   [dbGet -e [dbGet -u [dbGet [dbGet top.nets.isClock 0 -p].instTerms.isOutput 1 -p].inst {.isPhysOnly==0&&.isSpareGate==0}].cell.subClass core -p2]
      } else {
          set logicalInstPtr   [dbGet -e -u [dbGet top.insts.cell.subClass core -p2] {.isPhysOnly==0&&.isSpareGate==0}]
      }

      foreach {label ptns} $ivt_groups {
          set l [string length $label]
          if {$l>$maxLength} {set maxLength $l}
          set items [linsert $items end $label]
          set vtcells($label) 0
                  set areaCells($label) 0
          foreach ptn $ptns {
          set vtcells_ptn    [llength [dbGet -e $logicalInstPtr.cell.name $ptn]]
          set areaCells_ptn  0 ; foreach i [dbGet -e [dbGet $logicalInstPtr.cell.name $ptn -p2].area] {set areaCells_ptn  [expr $areaCells_ptn  + $i]}
          set areaCells_ptn [format "%.3f" $areaCells_ptn]
                  set vtcells($label) [expr $vtcells($label) + $vtcells_ptn]
                  set areaCells($label) [expr $areaCells($label) + $areaCells_ptn]
                  }
          set vtcells(Others) [expr $vtcells(Others) - $vtcells($label)]
          set areaCells(Others) [expr $areaCells(Others) - $areaCells($label)]
          if {[string length $vtcells($label)]>$maxLength} {set maxLength [string length $vtcells($label)]}
          if {[string length $areaCells($label)]>$maxLength} {set maxLength [string length $areaCells($label)]}
          if {[expr [string length $label]+2]>$maxLength} {set maxLength [expr [string length $label] + 2]}
      }

      incr maxLength 2
      lappend items "Others"
      lappend items "ALL"
      array unset pctcells *
      foreach vt [array names vtcells] {
          if {$vtcells(ALL) == 0} {
              set pctcells($vt) 0
          } else {
              set percentage [format "%.4f" [expr $vtcells($vt)*1.0/$vtcells(ALL)*100.0]]
              set pctcells($vt) $percentage
          }
      }
      set results(item)  [format "%-20s"    "| VT Type"]
      set results(inst)  [format "%-20s"    "| # Instance"]
      set results(value) [format "%-20s"    "| Percentage (%)"]
      foreach vt $items {
          append results(item)  [format "| %${maxLength}s"    "  $vt  "]
          append results(inst)  [format "| %${maxLength}s"    $vtcells($vt)]
          append results(value) [format "| %${maxLength}.2f" $pctcells($vt)]
      }
      append results(item)  "|"
      append results(inst)  "|"
      append results(value) "|"

      array unset apctcells *
      foreach vt [array names areaCells] {
          if {$areaCells(ALL) == 0} {
              set apctcells($vt) 0 
          } else {
              set percentage [format "%.4f" [expr $areaCells($vt)*1.0/$areaCells(ALL)*100.0]]
              set apctcells($vt) $percentage 
          }
      }

      set aresults(item)  [format "%-20s"    "| VT Type"]
      set aresults(inst)  [format "%-20s"    "| # Area"]
      set aresults(value) [format "%-20s"    "| Percentage (%)"]
      foreach vt $items {
          append aresults(item)  [format "| %${maxLength}s"    "  $vt  "]
          append aresults(inst)  [format "| %${maxLength}.2f"    $areaCells($vt)]
          append aresults(value) [format "| %${maxLength}.2f" $apctcells($vt)]
      }
      append aresults(item)  "|"
      append aresults(inst)  "|"
      append aresults(value) "|"

      set splitline "+-------------------+"
      foreach vt $items {
         append splitline  [format "%${maxLength}s+"    [join [lrepeat [expr $maxLength+1] -] ""]]
      }

      set f1 [open $outFile w]
      puts $f1 $splitline
      puts $f1 $results(item)
      puts $f1 $splitline
      puts $f1 $results(inst)
      puts $f1 $splitline
      puts $f1 $results(value)
      puts $f1 $splitline
      puts $f1 $aresults(inst)
      puts $f1 $splitline
      puts $f1 $aresults(value)
      puts $f1 $splitline
      close $f1
  }
  define_proc_arguments report_vt_usage \
      -info "report voltage threathold group usage." \
      -define_args {
          {-expanded  "Expanded the channel length." "" "bool" optional} \
          {-type  "Specify the cell type." "" "string" optional} \
          {-file  "Specify the report file name ." "" "string" optional} \
      }


}

###cutRow
set cut_boxes ""
foreach b [dbGet [dbget top.insts.cell.baseClass block -p2].pHaloBox]  {lappend cut_boxes $b}
set bondary [dbShape [dbGet top.fplan.box] ANDNOT [dbGet top.fPlan.rows.box]]
if {![regexp init $vars(step) ] && "" == [dbShape [lindex $cut_boxes 0] INSIDE $bondary] } {
	puts "start cutRow" 
	foreach c $cut_boxes {cutRow -area $c }
} else {puts "already exists cutRow"}



###run
redirect -file $vars(rpt_dir)/report_utilization.rpt {design::reportUtilization}
set process 28
if {[regexp A7 $vars(cts_driver_cells)]} {
	set vt_groups "HVT *A7*P*TH* SVT *A7*P*TS* LVT *A7*P*TL* uLVT *A7*P*TUL*"
} else {
	set vt_groups "HVT *A9*P*TH* SVT *A9*P*TS* LVT *A9*P*TL* uLVT *A9*P*TUL*"
}
design::report_vt_usage -file $vars(rpt_dir)/report_vt_usage.rpt


