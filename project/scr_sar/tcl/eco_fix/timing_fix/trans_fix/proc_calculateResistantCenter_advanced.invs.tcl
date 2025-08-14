#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/20 14:15:19 Sunday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : advanced calculateResistantCenter_fromPoints, it have more function and more reasonable method!!!
#             Enabling the filtering mode($filterStrategy) can filter out points that are too far from the cluster points, 
#             preventing extreme points from causing excessive deviation of the cluster center points.
# input     : $filterStrategy: auto|always|never
# ref       : link url
# --------------------------
proc calculateResistantCenter_fromPoints {pointsList {filterStrategy "auto"} {threshold 3.0} {densityThreshold 0.75} {minPoints 5}} {
  # 检查点数量是否足够
  set pointCount [llength $pointsList]
  if {$pointCount == 0} {
    return "0x0:1"; # check your input
  }

  # 直接计算所有点的均值（用于不过滤或过滤失败的情况）
  set sumX 0.0
  set sumY 0.0
  foreach point $pointsList {
    lassign $point x y
    set sumX [expr {$sumX + $x}]
    set sumY [expr {$sumY + $y}]
  }
  set rawMeanX [expr {$sumX / $pointCount}]
  set rawMeanY [expr {$sumY / $pointCount}]

  # 提前计算距离数组，解决变量作用域问题
  set distances {}
  foreach point $pointsList {
    lassign $point x y
    set dx [expr {$x - $rawMeanX}]
    set dy [expr {$y - $rawMeanY}]
    lappend distances [expr {sqrt($dx*$dx + $dy*$dy)}]
  }

  # 根据过滤策略决定是否执行过滤
  switch -- $filterStrategy {
    "never" {
      # 强制不过滤，直接返回原始均值
      return [list $rawMeanX $rawMeanY]
    }
    "always" {
      # 强制过滤，无论点分布如何
      set shouldFilter 1
    }
    "auto" {
      # 自动判断是否需要过滤
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

      # 处理标准差为零的情况（所有点距离相等）
      if {$stdDev < 1e-10} {
        # 所有点到中心点的距离几乎相同，没有明显异常值
        set shouldFilter 0
        set skewness 0.0
      } else {
        # 计算分布偏态系数
        set sumCubedDiff 0.0
        foreach dist $distances {
          set diff [expr {$dist - $avgDist}]
          set sumCubedDiff [expr {$sumCubedDiff + ($diff * $diff * $diff)}]
        }
        set skewness [expr {$sumCubedDiff / ($pointCount * ($stdDev ** 3))}]
      }

      # 自动调整参数
      set adjustedOutlierThreshold $threshold
      set adjustedDensityThreshold $densityThreshold

      if {$skewness > 1.0} {
        set adjustedOutlierThreshold [expr {$threshold * (1.0 + $skewness/5.0)}]
      }

      # 处理avgDist为零的情况（所有点重合）
      if {$avgDist < 1e-10} {
        # 所有点几乎重合，无需过滤
        set shouldFilter 0
        set relativeStdDev 0.0
      } else {
        set relativeStdDev [expr {$stdDev / $avgDist}]
        if {$relativeStdDev > 0.5} {
          set reductionFactor [expr {0.2 * ($relativeStdDev - 0.5)}]
          set adjustedDensityThreshold [expr {$densityThreshold * (1.0 - $reductionFactor)}]
        }
      }

      # 只有当标准差不为零时才计算inlierRatio
      if {$stdDev >= 1e-10} {
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
          set shouldFilter 1
        } else {
          set shouldFilter 0
        }
      }
    }
    default {
      error "Invalid filterStrategy: must be 'auto', 'always', or 'never'"
    }
  }

  # 如果不需要过滤或点太少，直接返回原始均值
  if {!$shouldFilter || $pointCount < $minPoints} {
    return [list $rawMeanX $rawMeanY]
  }

  # 执行距离过滤（使用原始threshold，而非调整后的）
  # 重新计算标准差（避免之前的early return影响）
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

  # 处理标准差为零的情况（强制不过滤）
  if {$stdDev < 1e-10} {
    return [list $rawMeanX $rawMeanY]
  }

  set filteredPoints {}
  for {set i 0} {$i < $pointCount} {incr i} {
    if {[lindex $distances $i] <= $threshold * $stdDev} {
      lappend filteredPoints [lindex $pointsList $i]
    }
  }

  # 如果过滤后没有点了，返回原始均值
  if {[llength $filteredPoints] == 0} {
    return [list $rawMeanX $rawMeanY]
  }

  # 重新计算过滤后的均值
  set sumX 0.0
  set sumY 0.0
  foreach point $filteredPoints {
    lassign $point x y
    set sumX [expr {$sumX + $x}]
    set sumY [expr {$sumY + $y}]
  }

  return [list [expr {$sumX / [llength $filteredPoints]}] [expr {$sumY / [llength $filteredPoints]}]]
}

# 辅助函数：模拟Python的zip功能
proc zip {list1 list2} {
  set result {}
  for {set i 0} {$i < [min [llength $list1] [llength $list2]]} {incr i} {
    lappend result [list [lindex $list1 $i] [lindex $list2 $i]]
  }
  return $result
}

# 辅助函数：返回最小值
proc min {a b} {
  expr {$a < $b ? $a : $b}
}
