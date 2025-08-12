#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/07 23:30:26 Thursday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : get blank(avaiable) area(box) from invs GUI
# return    : 
# ref       : link url
# --------------------------
proc get_blank_box {{centerPt {}} {halfOfWidth 12.6} {halfOfHeight 12.6} {debug 0}} {
  if {![string is double [lindex $centerPt 0]] || ![string is double [lindex $centerPt 1]]} {
    error "proc get_blank_box: check your input : centerPt($centerPt) is not real pt!!!"
  } else {
    lassign $centerPt x y
    set pointLeftBottom [list [expr $x - $halfOfWidth] [expr $y - $halfOfHeight]]
    set pointRightTop   [list [expr $x + $halfOfWidth] [expr $y + $halfOfHeight]]
    set searchingBox  [list {*}$pointLeftBottom {*}$pointRightTop]
    set searchingArea [db_rect -area $searchingBox]
    if {$debug} { puts "searchingArea: $searchingArea" }
    if {$debug} { puts "searchingBox: $searchingBox" }
    # set densityOfSearchingBox [queryDensityInBox {*}$searchingBox]
    set insts_ptr [dbQuery -areas $searchingBox -objType inst]
    set insts_box [dbget $insts_ptr.box]
    set blankBoxList [dbShape -output hrect $searchingBox ANDNOT $insts_box]
    set blankBoxArea [dbShape -output area $searchingBox ANDNOT $insts_box]
    if {$debug} { puts "blankBoxArea: $blankBoxArea" }
    if {$debug} { puts "blankBoxList: $blankBoxList" }
    set densityOfSearchingBox "[format "%.2f" [expr (1 - ($blankBoxArea / $searchingArea)) * 100]] %"
    if {$debug} { puts "densityOfSearchingBox: $densityOfSearchingBox" }

    return [list $blankBoxList $blankBoxArea $densityOfSearchingBox]
  }
}
