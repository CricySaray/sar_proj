#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/20 14:15:19 Sunday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc|math_proc)
# descrip   : Calculate the coordinates of the center point of the anti-exception point (distance threshold filtering method)
# ref       : link url
# --------------------------
# now both two procs is not combine with each other!!! - view ./proc_calculateResistantCenter_advanced.invs.tcl
proc calculateResistantCenter_fromPoints {pointsList {threshold 0}} {
  if {![llength $pointsList]} {
    return "0x0:1"; # check your input
  } elseif {$threshold <= 0} {
    # 当threshold <=0时，直接计算所有点的平均值
    set sumX 0.0
    set sumY 0.0
    set count 0
    foreach point $pointsList {
      lassign $point x y
      set sumX [expr {$sumX + $x}]
      set sumY [expr {$sumY + $y}]
      incr count
    }
    return [list [expr {$sumX / $count}] [expr {$sumY / $count}]]
  } else {
    # 第一次计算普通均值
    set sumX 0.0
    set sumY 0.0
    set count 0
    foreach point $pointsList {
      lassign $point x y
      set sumX [expr {$sumX + $x}]
      set sumY [expr {$sumY + $y}]
      incr count
    }
    set meanX [expr {$sumX / $count}]
    set meanY [expr {$sumY / $count}]
    # 计算每个点到初始均值的距离
    set distances {}
    foreach point $pointsList {
      lassign $point x y
      set dx [expr {$x - $meanX}]
      set dy [expr {$y - $meanY}]
      set dist [expr {sqrt($dx*$dx + $dy*$dy)}]
      lappend distances $dist
    }
    # 计算平均距离和标准差
    set sumDist 0.0
    foreach dist $distances {
      set sumDist [expr {$sumDist + $dist}]
    }
    set avgDist [expr {$sumDist / $count}]

    set sumSqDiff 0.0
    foreach dist $distances {
      set diff [expr {$dist - $avgDist}]
      set sumSqDiff [expr {$sumSqDiff + ($diff * $diff)}]
    }
    set stdDev [expr {sqrt($sumSqDiff / $count)}]
    # 过滤掉距离超过阈值的点
    set filteredPoints {}
    for {set i 0} {$i < $count} {incr i} {
      if {[lindex $distances $i] <= $threshold * $stdDev} {
        lappend filteredPoints [lindex $pointsList $i]
      }
    }
    # 如果过滤后没有点了，返回初始均值
    if {[llength $filteredPoints] == 0} {
      return [list $meanX $meanY]
    }
    # 重新计算过滤后的均值
    set sumX 0.0
    set sumY 0.0
    set count 0
    foreach point $filteredPoints {
      lassign $point x y
      set sumX [expr {$sumX + $x}]
      set sumY [expr {$sumY + $y}]
      incr count
    }
    return [list [expr {$sumX / $count}] [expr {$sumY / $count}]]
  }
}

proc shouldFilterCoordinates {pointsList {densityThreshold 0.75} {outlierThreshold 3.0} {minPoints 5}} {
    # 检查点数量是否足够
    set pointCount [llength $pointsList]
    if {$pointCount < $minPoints} {
        return 0 ;# 点太少，不进行过滤
    }
    
    # 计算初始中心点（使用所有点的均值）
    set sumX 0.0
    set sumY 0.0
    foreach point $pointsList {
        lassign $point x y
        set sumX [expr {$sumX + $x}]
        set sumY [expr {$sumY + $y}]
    }
    set centerX [expr {$sumX / $pointCount}]
    set centerY [expr {$sumY / $pointCount}]
    
    # 计算所有点到中心点的距离
    set distances {}
    foreach point $pointsList {
        lassign $point x y
        set dx [expr {$x - $centerX}]
        set dy [expr {$y - $centerY}]
        lappend distances [expr {sqrt($dx*$dx + $dy*$dy)}]
    }
    
    # 计算平均距离和标准差
    set sumDist 0.0
    foreach dist $distances {
        set sumDist [expr {$sumDist + $dist}]
    }
    set avgDist [expr {$sumDist / $pointCount}]
    
    set sumSqDiff 0.0
    foreach dist $distances {
        set diff [expr {$dist - $avgDist}]
        set sumSqDiff [expr {$sumSqDiff + ($diff * $diff)}]
    }
    set stdDev [expr {sqrt($sumSqDiff / $pointCount)}]
    
    # 计算分布偏态系数，判断是否存在较多异常值
    set sumCubedDiff 0.0
    foreach dist $distances {
        set diff [expr {$dist - $avgDist}]
        set sumCubedDiff [expr {$sumCubedDiff + ($diff * $diff * $diff)}]
    }
    set skewness [expr {$sumCubedDiff / ($pointCount * ($stdDev ** 3))}]
    
    # 自动调整参数
    # 1. 若偏态系数为正且较大，说明右侧长尾（异常值较多），提高outlierThreshold
    # 2. 若标准差较大，说明分布分散，降低densityThreshold
    set adjustedOutlierThreshold $outlierThreshold
    set adjustedDensityThreshold $densityThreshold
    
    if {$skewness > 1.0} {
        set adjustedOutlierThreshold [expr {$outlierThreshold * (1.0 + $skewness/5.0)}]
    }
    
    set relativeStdDev [expr {$stdDev / $avgDist}]
    if {$relativeStdDev > 0.5} {
        set reductionFactor [expr {0.2 * ($relativeStdDev - 0.5)}]
        set adjustedDensityThreshold [expr {$densityThreshold * (1.0 - $reductionFactor)}]
    }
    
    # 计算在调整后的阈值内的点的比例
    set inlierCount 0
    foreach dist $distances {
        if {$dist <= $adjustedOutlierThreshold * $stdDev} {
            incr inlierCount
        }
    }
    set inlierRatio [expr {$inlierCount / double($pointCount)}]
    
    # 判断是否需要过滤
    if {$inlierRatio < $adjustedDensityThreshold} {
        return 1 ;# 密集区域内的点太少，需要过滤
    } else {
        return 0 ;# 分布良好，不需要过滤
    }
}
