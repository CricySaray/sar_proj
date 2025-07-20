#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/20 18:07:26 Sunday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : Calculate Euclidean distance between two points with error handling
# ref       : link url
# --------------------------
proc calculateDistance {point1 point2 {epsilon 1e-10} {maxValue 1.0e+100}} {
  # 验证输入点格式
  if {[llength $point1] != 2 || [llength $point2] != 2} {
    error "Both points must be 2D coordinates in the format {x y}"
  }
  # 提取坐标值
  lassign $point1 x1 y1
  lassign $point2 x2 y2
  # 验证坐标是否为数值
  if {![string is double -strict $x1] || ![string is double -strict $y1] || ![string is double -strict $x2] || ![string is double -strict $y2]} {
    error "Coordinates must be valid numeric values"
  }
  # 检查数值范围（防止溢出）
  foreach coord [list $x1 $y1 $x2 $y2] {
    if {abs($coord) > $maxValue} {
      error "Coordinate value exceeds maximum allowed ($maxValue)"
    }
  }
  # 计算坐标差值
  set dx [expr {$x2 - $x1}]
  set dy [expr {$y2 - $y1}]
  # 检查差值是否过大（防止平方运算溢出）
  if {abs($dx) > $maxValue || abs($dy) > $maxValue} {
    error "Coordinate difference exceeds maximum allowed ($maxValue)"
  }
  # 计算平方和
  set sumSq [expr {$dx*$dx + $dy*$dy}]
  # 处理平方和为零的情况（避免开方运算误差）
  if {$sumSq < $epsilon} {
    return 0.0
  }
  # 计算并返回距离
  return [expr {sqrt($sumSq)}]
}
