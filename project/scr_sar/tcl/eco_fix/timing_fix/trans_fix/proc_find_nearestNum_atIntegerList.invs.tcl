#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : Tue Jul  8 11:05:01 CST 2025
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc)
# descrip   : find the nearest number from list, you can control which one of bigger or smaller
#             if $returnBigOneFlag is 1, return big one near number
#             if $returnBigOneFlag is 0, return small one near number
#             if $ifClamp is 1 and $number is out of $realList, return the maxOne or small one of $realList
#             if $ifClamp is 0 and $number is out of $realList, return "0x0:1"(error)
# update    : 2025/07/18 12:15:10 Friday
#             adapt to list with only one item
# ref       : link url
# --------------------------
proc find_nearestNum_atIntegerList {{realList {}} number {returnBigOneFlag 1} {ifClamp 1}} {
  # $ifClamp: When out of range, take the boundary value.
  set s [lsort -unique -increasing -real $realList]
  set idx [lsearch -exact -real $s $number]
  if {$idx != -1} {
    return [lsearch -inline -real -exact $s $number] ; # number is not equal every real digit of list
  }
  if {[llength $realList] == 1 && $ifClamp} {
    return [lindex $realList 0]
  } elseif {$ifClamp && $number < [lindex $s 0]} {
    return [lindex $s 0] 
  } elseif {$ifClamp && $number > [lindex $s end]} { ; # adapt to list with only one item
    return [lindex $s 1] 
  } elseif {$number < [lindex $s 0] || $number > [lindex $s end]} {
    error "proc find_nearestNum_atIntegerList: your number is not in the range of list (without turning on switch \$ifClamp)"; # your number is not in the range of list
  }
  foreach i $s {
    set next_i [lindex $s [expr [lsearch $s $i] + 1]]
    if {$i < $number && $number < $next_i} {
      set lowerIdx [lsearch $s $i]
      break
    } 
  }
  set upperIdx [expr {$lowerIdx + 1}]
  return [lindex $s [expr {$returnBigOneFlag ? $upperIdx : $lowerIdx}]]
}
