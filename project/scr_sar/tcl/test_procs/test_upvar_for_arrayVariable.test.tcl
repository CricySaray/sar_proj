#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/03 18:18:55 Sunday
# label     : test_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|misc_proc)
# descrip   : test tcl command 'upvar' for array variable!!!
# ref       : link url
# --------------------------
proc updateArrayElement {arrayName index newValue} {
    # 链接调用者的数组元素（arrayName(index)）到当前的 elem
    upvar 1 ${arrayName}($index) elem  ; # NOTICE: var name arrayName must be surrounded with bracket, or error will be occurred
    set elem $newValue  ;# 直接修改数组元素
}

# 使用示例
if {1} {
  array set myArray {}
  set myArray(a) 100
  puts $myArray(a)
  updateArrayElement myArray a 200
  puts $myArray(a)  ;# 输出：200
}
