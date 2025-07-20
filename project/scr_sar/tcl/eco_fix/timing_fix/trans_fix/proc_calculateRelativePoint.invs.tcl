#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/20 16:10:10 Sunday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : Calculate relative point between two coordinates based on relative value
# ref       : link url
# --------------------------
proc calculateRelativePoint {startPoint endPoint {relativeValue 0.5} {clampValue 1} {epsilon 1e-10}} {
  if {[llength $startPoint] != 2 || [llength $endPoint] != 2} {
    error "Both startPoint and endPoint must be 2D coordinates in the format {x y}"
  }
  lassign $startPoint startX startY
  lassign $endPoint endX endY
  # 检查relativeValue是否需要被限制在[0,1]范围内
  if {$clampValue} {
    # 限制relativeValue在[0,1]范围内
    if {$relativeValue < 0.0} {
      set relativeValue 0.0
    } elseif {$relativeValue > 1.0} {
      set relativeValue 1.0
    }
  } else {
    # 检查relativeValue是否在有效范围内
    if {$relativeValue < 0.0 - $epsilon || $relativeValue > 1.0 + $epsilon} {
      error "relativeValue must be between 0 and 1 (or use clampValue=1 to auto-clamp)"
    }
  }
  # 计算中间点坐标
  set x [expr {$startX + $relativeValue * ($endX - $startX)}]
  set y [expr {$startY + $relativeValue * ($endY - $startY)}]
  # 处理边界情况，确保数值稳定性
  if {abs($relativeValue - 0.0) < $epsilon} {
    set x $startX
    set y $startY
  } elseif {abs($relativeValue - 1.0) < $epsilon} {
    set x $endX
    set y $endY
  }
  set x [format "%.3f" $x]
  set y [format "%.3f" $y]
  return [list $x $y]
}
