#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/09/11 14:25:02 Thursday
# label     : flow_proc
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|misc_proc)
#   perl -> (format_sub)
# descrip   : gen cmds of merging net according to its extanded trend
# return    : cmds list
# ref       : link url
# --------------------------
proc genCmd_mergeNet_accordingToItsExtandedTrend {} {
  
}

proc checkAndMergeNets {nets layers checkRegions extendDirections maxExtendLength maxTolerance {debug 0}} {
  # 初始化结果列表
  set result [list]
  
  # 参数验证
  if {![llength $nets]} {
    error "nets parameter cannot be empty"
  }
  if {![llength $layers]} {
    error "layers parameter cannot be empty"
  }
  if {![llength $checkRegions]} {
    error "checkRegions parameter cannot be empty"
  }
  if {![llength $extendDirections]} {
    error "extendDirections parameter cannot be empty"
  }
  if {![string is integer -strict $maxExtendLength] || $maxExtendLength < 0} {
    error "maxExtendLength must be a non-negative integer"
  }
  if {![string is integer -strict $maxTolerance] || $maxTolerance < 0} {
    error "maxTolerance must be a non-negative integer"
  }
  
  if {$debug} {
    puts "Debug mode enabled"
    puts "Processing [llength $nets] nets across [llength $layers] layers"
  }
  
  # 遍历每个网络
  foreach netName $nets {
    if {$debug} {
      puts "\nProcessing net: $netName"
    }
    
    # 检查网络是否存在
    if {[dbget top.nets.name $netName -e] == ""} {
      error "Net $netName does not exist."
    }
    
    # 遍历每个层
    foreach layer $layers {
      if {$debug} {
        puts "Processing layer: $layer"
      }
      
      # 确定当前层的延伸方向
      set extendDir ""
      foreach dirEntry $extendDirections {
        lassign $dirEntry layerList direction
        if {[lsearch $layerList $layer] != -1} {
          set extendDir $direction
          break
        }
      }
      
      if {$extendDir eq ""} {
        puts "Warning: No extension direction defined for layer $layer. Skipping..."
        continue
      }
      
      if {$debug} {
        puts "  Extension direction: $extendDir"
      }
      
      # 选择当前层和网络的所有形状
      if {[catch {deselectAll} err]} {
        error "Failed to deselect all: $err"
      }
      
      if {[catch {editSelect -layer $layer -net $netName} err]} {
        puts "Warning: Failed to select shapes for net $netName on layer $layer: $err"
        continue
      }
      
      # 获取形状的地址，添加-e参数
      if {[catch {set netRects_ptr [dbget selected. -e]} err]} {
        puts "Warning: Failed to get selected shapes for net $netName on layer $layer: $err"
        continue
      }
      
      if {[llength $netRects_ptr] == 0} {
        if {$debug} {
          puts "  No shapes found for this net on current layer"
        }
        continue ;# 该层上没有此网络的形状
      }
      
      if {$debug} {
        puts "  Found [llength $netRects_ptr] shapes for this net on current layer"
      }
      
      # 获取每个形状的地址和矩形区域
      set netRectsPtr_rects [list]
      foreach temp_ptr $netRects_ptr {
        if {[catch {set temp_rect [dbget $temp_ptr.box -e]} err]} {
          puts "Warning: Failed to get box for shape $temp_ptr: $err"
          continue
        }
        lappend netRectsPtr_rects [list $temp_ptr {*}$temp_rect]
      }
      
      # 筛选出在检查区域内的形状
      set rectsInCheckRegion [list]
      foreach rectEntry $netRectsPtr_rects {
        lassign $rectEntry rect_ptr x y x1 y1
        
        # 检查是否在任何一个检查区域内
        foreach checkRegion $checkRegions {
          if {[llength $checkRegion] != 4} {
            puts "Warning: Invalid check region format: $checkRegion. Skipping..."
            continue
          }
          lassign $checkRegion cx cy cx1 cy1
          
          if {$x >= $cx && $y >= $cy && $x1 <= $cx1 && $y1 <= $cy1} {
            lappend rectsInCheckRegion $rectEntry
            if {$debug} {
              puts "  Shape $rect_ptr is within check region"
            }
            break
          }
        }
      }
      
      # 如果检查区域内至少有两个形状，才可能合并
      if {[llength $rectsInCheckRegion] < 2} {
        if {$debug} {
          puts "  Less than 2 shapes in check region, skipping merge check"
        }
        continue
      }
      
      if {$debug} {
        puts "  Checking [llength $rectsInCheckRegion] shapes for possible merging"
      }
      
      # 根据延伸方向检查形状是否可以合并
      set numRects [llength $rectsInCheckRegion]
      for {set i 0} {$i < $numRects} {incr i} {
        for {set j [expr {$i + 1}]} {$j < $numRects} {incr j} {
          set rect1 [lindex $rectsInCheckRegion $i]
          set rect2 [lindex $rectsInCheckRegion $j]
          
          lassign $rect1 rect1_ptr x1 y1 x1_1 y1_1
          lassign $rect2 rect2_ptr x2 y2 x2_1 y2_1
          
          if {$debug} {
            puts "  Checking shapes $rect1_ptr and $rect2_ptr for possible merge"
          }
          
          set canMerge 0
          set extendDistance 0
          set warnMsg ""
          set targetPtr ""
          
          if {$extendDir eq "top_bottom"} {
            # 上下延伸：检查水平方向是否对齐或在容差范围内
            set minX [expr {max($x1, $x2)}]
            set maxX1 [expr {min($x1_1, $x2_1)}]
            set xOverlap [expr {$maxX1 - $minX}]
            
            if {$xOverlap < 0} {
              set xGap [expr {abs($xOverlap)}]
              if {$xGap <= $maxTolerance} {
                set warnMsg "Warning: Rectangles $rect1_ptr and $rect2_ptr are slightly misaligned in x-direction by $xGap units but within tolerance. They could be merged with minor movement."
              } else {
                if {$debug} {
                  puts "  X gap $xGap exceeds tolerance $maxTolerance, cannot merge"
                }
                continue ;# 水平方向偏差过大，无法合并
              }
            }
            
            # 确定哪个矩形在上方，哪个在下方
            if {$y1_1 < $y2} {
              # rect1在下方，rect2在上方
              set gap [expr {$y2 - $y1_1}]
              if {$gap <= [expr {2 * $maxExtendLength}]} {
                set canMerge 1
                set extendDistance [expr {$gap - $maxExtendLength}]
                if {$extendDistance < 0} {
                  set extendDistance 0
                }
                set targetPtr $rect1_ptr
              } elseif {$debug} {
                puts "  Vertical gap $gap exceeds maximum possible extension [expr {2 * $maxExtendLength}]"
              }
            } elseif {$y2_1 < $y1} {
              # rect2在下方，rect1在上方
              set gap [expr {$y1 - $y2_1}]
              if {$gap <= [expr {2 * $maxExtendLength}]} {
                set canMerge 1
                set extendDistance [expr {$gap - $maxExtendLength}]
                if {$extendDistance < 0} {
                  set extendDistance 0
                }
                set targetPtr $rect2_ptr
              } elseif {$debug} {
                puts "  Vertical gap $gap exceeds maximum possible extension [expr {2 * $maxExtendLength}]"
              }
            } else {
              if {$debug} {
                puts "  Shapes already overlap vertically, no extension needed"
              }
              set canMerge 1
              set extendDistance 0
              set targetPtr [expr {$y1 < $y2 ? $rect1_ptr : $rect2_ptr}]
            }
          } elseif {$extendDir eq "left_right"} {
            # 左右延伸：检查垂直方向是否对齐或在容差范围内
            set minY [expr {max($y1, $y2)}]
            set maxY1 [expr {min($y1_1, $y2_1)}]
            set yOverlap [expr {$maxY1 - $minY}]
            
            if {$yOverlap < 0} {
              set yGap [expr {abs($yOverlap)}]
              if {$yGap <= $maxTolerance} {
                set warnMsg "Warning: Rectangles $rect1_ptr and $rect2_ptr are slightly misaligned in y-direction by $yGap units but within tolerance. They could be merged with minor movement."
              } else {
                if {$debug} {
                  puts "  Y gap $yGap exceeds tolerance $maxTolerance, cannot merge"
                }
                continue ;# 垂直方向偏差过大，无法合并
              }
            }
            
            # 确定哪个矩形在左方，哪个在右方
            if {$x1_1 < $x2} {
              # rect1在左方，rect2在右方
              set gap [expr {$x2 - $x1_1}]
              if {$gap <= [expr {2 * $maxExtendLength}]} {
                set canMerge 1
                set extendDistance [expr {$gap - $maxExtendLength}]
                if {$extendDistance < 0} {
                  set extendDistance 0
                }
                set targetPtr $rect1_ptr
              } elseif {$debug} {
                puts "  Horizontal gap $gap exceeds maximum possible extension [expr {2 * $maxExtendLength}]"
              }
            } elseif {$x2_1 < $x1} {
              # rect2在左方，rect1在右方
              set gap [expr {$x1 - $x2_1}]
              if {$gap <= [expr {2 * $maxExtendLength}]} {
                set canMerge 1
                set extendDistance [expr {$gap - $maxExtendLength}]
                if {$extendDistance < 0} {
                  set extendDistance 0
                }
                set targetPtr $rect2_ptr
              } elseif {$debug} {
                puts "  Horizontal gap $gap exceeds maximum possible extension [expr {2 * $maxExtendLength}]"
              }
            } else {
              if {$debug} {
                puts "  Shapes already overlap horizontally, no extension needed"
              }
              set canMerge 1
              set extendDistance 0
              set targetPtr [expr {$x1 < $x2 ? $rect1_ptr : $rect2_ptr}]
            }
          } else {
            puts "Warning: Unknown extension direction '$extendDir' for layer $layer. Skipping..."
            continue
          }
          
          # 处理警告信息
          if {$warnMsg ne ""} {
            puts $warnMsg
          }
          
          # 如果可以合并，添加到结果列表
          if {$canMerge && $extendDistance <= $maxExtendLength && $targetPtr ne ""} {
            lappend result [list $targetPtr "high" $extendDistance]
            if {$debug} {
              puts "  Added merge candidate: $targetPtr with extension $extendDistance"
            }
          }
        }
      }
    }
  }
  
  if {$debug} {
    puts "\nProcessing complete. Found [llength $result] merge candidates"
  }
  
  return $result
}

