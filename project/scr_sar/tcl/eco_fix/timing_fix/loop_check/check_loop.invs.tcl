# 检测布线绕圈的Tcl程序
# 输入: buffer坐标, 逻辑单元坐标, 布线线段列表
# 输出: 绕圈程度分级(0表示无绕圈, 数值越大绕圈越严重)

package require math::linearalgebra

# 线段结构体
proc createSegment {x1 y1 x2 y2} {
    return [list $x1 $y1 $x2 $y2]
}

# 获取线段端点
proc getSegmentStart {seg} {
    return [list [lindex $seg 0] [lindex $seg 1]]
}

proc getSegmentEnd {seg} {
    return [list [lindex $seg 2] [lindex $seg 3]]
}

# 计算线段方向向量
proc getSegmentDirection {seg} {
    set start [getSegmentStart $seg]
    set end [getSegmentEnd $seg]
    return [list [expr [lindex $end 0] - [lindex $start 0]] [expr [lindex $end 1] - [lindex $start 1]]]
}

# 计算向量点积
proc dotProduct {v1 v2} {
    return [expr [lindex $v1 0] * [lindex $v2 0] + [lindex $v1 1] * [lindex $v2 1]]
}

# 计算向量叉积模长(二维向量叉积结果为标量)
proc crossProductMagnitude {v1 v2} {
    return [expr [lindex $v1 0] * [lindex $v2 1] - [lindex $v1 1] * [lindex $v2 0]]
}

# 线段相交检测(不包括端点)
proc segmentsIntersect {seg1 seg2} {
    set a [getSegmentStart $seg1]
    set b [getSegmentEnd $seg1]
    set c [getSegmentStart $seg2]
    set d [getSegmentEnd $seg2]
    
    # 快速排斥试验
    if {![bboxOverlap $a $b $c $d]} {
        return 0
    }
    
    # 跨立试验
    set ccw1 [ccw $a $c $d]
    set ccw2 [ccw $b $c $d]
    if {$ccw1 == $ccw2} {
        return 0
    }
    
    set ccw3 [ccw $c $a $b]
    set ccw4 [ccw $d $a $b]
    if {$ccw3 == $ccw4} {
        return 0
    }
    
    return 1
}

# 边界框重叠检测
proc bboxOverlap {a b c d} {
    set minax [expr min([lindex $a 0], [lindex $b 0])]
    set maxax [expr max([lindex $a 0], [lindex $b 0])]
    set minay [expr min([lindex $a 1], [lindex $b 1])]
    set maxay [expr max([lindex $a 1], [lindex $b 1])]
    
    set mincx [expr min([lindex $c 0], [lindex $d 0])]
    set maxcx [expr max([lindex $c 0], [lindex $d 0])]
    set mincy [expr min([lindex $c 1], [lindex $d 1])]
    set maxcy [expr max([lindex $c 1], [lindex $d 1])]
    
    if {$maxax < $mincx || $maxcx < $minax || $maxay < $mincy || $maxcy < $minay} {
        return 0
    }
    return 1
}

# 判断三点逆时针方向
proc ccw {a b c} {
    set val [expr ([lindex $b 0] - [lindex $a 0]) * ([lindex $c 1] - [lindex $a 1]) - 
                ([lindex $b 1] - [lindex $a 1]) * ([lindex $c 0] - [lindex $a 0])]
    if {$val > 0} {
        return 1
    } elseif {$val < 0} {
        return -1
    } else {
        return 0
    }
}

# 计算两点之间的欧氏距离
proc distance {p1 p2} {
    return [expr sqrt(pow([lindex $p2 0] - [lindex $p1 0], 2) + 
                     pow([lindex $p2 1] - [lindex $p1 1], 2))]
}

# 计算线段总长度
proc calculateTotalLength {segments} {
    set total 0
    foreach seg $segments {
        set start [getSegmentStart $seg]
        set end [getSegmentEnd $seg]
        set total [expr $total + [distance $start $end]]
    }
    return $total
}

# 计算最小包围矩形周长
proc calculateBoundingPerimeter {segments} {
    if {[llength $segments] == 0} {
        return 0
    }
    
    set minX 999999
    set maxX -999999
    set minY 999999
    set maxY -999999
    
    foreach seg $segments {
        set start [getSegmentStart $seg]
        set end [getSegmentEnd $seg]
        
        foreach point [list $start $end] {
            set x [lindex $point 0]
            set y [lindex $point 1]
            
            if {$x < $minX} {set minX $x}
            if {$x > $maxX} {set maxX $x}
            if {$y < $minY} {set minY $y}
            if {$y > $maxY} {set maxY $y}
        }
    }
    
    return [expr 2 * ($maxX - $minX + $maxY - $minY)]
}

# 计算绕圈严重程度
proc calculateLoopSeverity {segments {threshold 1.5}} {
    # 方法1: 计算线段相交次数
    set intersectionCount 0
    set n [llength $segments]
    
    for {set i 0} {$i < $n} {incr i} {
        for {set j [expr $i + 1]} {$j < $n} {incr j} {
            if {[segmentsIntersect [lindex $segments $i] [lindex $segments $j]]} {
                incr intersectionCount
            }
        }
    }
    
    # 方法2: 计算路径长度与最小包围矩形周长的比率
    set totalLength [calculateTotalLength $segments]
    set boundingPerimeter [calculateBoundingPerimeter $segments]
    
    if {$boundingPerimeter == 0} {
        set lengthRatio 0
    } else {
        set lengthRatio [expr $totalLength / $boundingPerimeter]
    }
    
    # 方法3: 计算反向线段的数量
    set reverseCount 0
    for {set i 0} {$i < $n - 1} {incr i} {
        set seg1 [lindex $segments $i]
        set seg2 [lindex $segments [expr $i + 1]]
        
        set dir1 [getSegmentDirection $seg1]
        set dir2 [getSegmentDirection $seg2]
        
        set dot [dotProduct $dir1 $dir2]
        if {$dot < 0} {
            incr reverseCount
        }
    }
    
    # 综合评分
    set score [expr $intersectionCount * 5 + ($lengthRatio > $threshold ? int($lengthRatio * 2) : 0) + $reverseCount]
    
    # 分级
    if {$score == 0} {
        return 0
    } elseif {$score <= 3} {
        return 1
    } elseif {$score <= 7} {
        return 2
    } elseif {$score <= 12} {
        return 3
    } else {
        return 4
    }
}

# 构建有向线段列表
proc buildDirectedSegments {bufferCoord sinkCoords undirectedSegments {tolerance 0.1}} {
    # 创建点到线段的映射
    array set pointToSegments {}
    foreach seg $undirectedSegments {
        set p1 [getSegmentStart $seg]
        set p2 [getSegmentEnd $seg]
        
        lappend pointToSegments([list {*}$p1]) $seg
        lappend pointToSegments([list {*}$p2]) $seg
    }
    
    # 计算每个sink点的替代点
    set sinkReplacements {}
    foreach sink $sinkCoords {
        set minDist 999999
        set closestPoint ""
        set closestSegment ""
        
        # 找到距离sink最近的线段上的点
        foreach seg $undirectedSegments {
            set projection [projectPointToSegment $sink $seg]
            set dist [distance $sink $projection]
            
            if {$dist < $minDist} {
                set minDist $dist
                set closestPoint $projection
                set closestSegment $seg
            }
        }
        
        # 如果找到的最近点足够近，使用它作为替代
        if {$minDist <= $tolerance} {
            lappend sinkReplacements [list $sink $closestPoint $closestSegment]
        } else {
            # 如果没有足够近的点，使用最近的端点
            set p1 [getSegmentStart [lindex $closestSegment 0]]
            set p2 [getSegmentEnd [lindex $closestSegment 0]]
            set dist1 [distance $sink $p1]
            set dist2 [distance $sink $p2]
            
            if {$dist1 < $dist2} {
                lappend sinkReplacements [list $sink $p1 $closestSegment]
            } else {
                lappend sinkReplacements [list $sink $p2 $closestSegment]
            }
        }
    }
    
    # 已处理的线段集合
    set processedSegments {}
    
    # 结果有向线段列表
    set directedSegments {}
    
    # 从buffer开始构建路径
    set currentPoint $bufferCoord
    
    # 找到与buffer相连的线段
    set startSegments $pointToSegments([list {*}$currentPoint])
    
    foreach startSeg $startSegments {
        # 初始化路径
        set path [list $startSeg]
        set visitedPoints [list $currentPoint]
        
        # 确定线段方向
        set p1 [getSegmentStart $startSeg]
        set p2 [getSegmentEnd $startSeg]
        
        if {[lindex $p1 0] == [lindex $currentPoint 0] && [lindex $p1 1] == [lindex $currentPoint 1]} {
            lappend directedSegments $startSeg
            set nextPoint $p2
        } else {
            lappend directedSegments [createSegment {*}$p2 {*}$p1]
            set nextPoint $p1
        }
        
        lappend visitedPoints [list {*}$nextPoint]
        lappend processedSegments $startSeg
        
        # 继续构建路径
        set current $nextPoint
        while {1} {
            # 检查是否到达替代sink点
            foreach {original replacement seg} $sinkReplacements {
                if {[lindex $current 0] == [lindex $replacement 0] && [lindex $current 1] == [lindex $replacement 1]} {
                    # 标记此sink已到达
                    set sinkReplacements [lreplace $sinkReplacements [lsearch -exact $sinkReplacements [list $original $replacement $seg]] [lsearch -exact $sinkReplacements [list $original $replacement $seg]]]
                    break 2
                }
            }
            
            # 找到与当前点相连的未处理线段
            set connectedSegments $pointToSegments([list {*}$current])
            set nextSegment ""
            
            foreach seg $connectedSegments {
                if {$seg ni $processedSegments} {
                    set nextSegment $seg
                    break
                }
            }
            
            # 如果没有找到下一个线段，退出循环
            if {$nextSegment eq ""} {
                break
            }
            
            # 确定线段方向
            set p1 [getSegmentStart $nextSegment]
            set p2 [getSegmentEnd $nextSegment]
            
            if {[lindex $p1 0] == [lindex $current 0] && [lindex $p1 1] == [lindex $current 1]} {
                lappend directedSegments $nextSegment
                set current $p2
            } else {
                lappend directedSegments [createSegment {*}$p2 {*}$p1]
                set current $p1
            }
            
            lappend processedSegments $nextSegment
        }
    }
    
    return $directedSegments
}

# 计算点到线段的投影点
proc projectPointToSegment {point segment} {
    set p [list [lindex $point 0] [lindex $point 1]]
    set a [getSegmentStart $segment]
    set b [getSegmentEnd $segment]
    
    # 线段向量
    set ab [list [expr [lindex $b 0] - [lindex $a 0]] [expr [lindex $b 1] - [lindex $a 1]]]
    
    # 点到线段起点的向量
    set ap [list [expr [lindex $p 0] - [lindex $a 0]] [expr [lindex $p 1] - [lindex $a 1]]]
    
    # 计算投影比例
    set abLen2 [expr pow([lindex $ab 0], 2) + pow([lindex $ab 1], 2)]
    
    # 处理零长度线段
    if {$abLen2 == 0} {
        return $a
    }
    
    # 计算点积
    set dot [expr [lindex $ap 0] * [lindex $ab 0] + [lindex $ap 1] * [lindex $ab 1]]
    
    # 计算投影比例
    set t [expr max(0, min(1, $dot / $abLen2))]
    
    # 计算投影点
    return [list [expr [lindex $a 0] + $t * [lindex $ab 0]] [expr [lindex $a 1] + $t * [lindex $ab 1]]]
}

# 主检测函数
proc detectWireLoops {bufferCoord sinkCoords undirectedSegments {threshold 1.5}} {
    # 输入验证
    if {[llength $undirectedSegments] < 2} {
        return 0
    }
    
    # 构建有向线段列表
    set directedSegments [buildDirectedSegments $bufferCoord $sinkCoords $undirectedSegments]
    
    # 执行绕圈检测
    return [calculateLoopSeverity $directedSegments $threshold]
}

# 分级标准说明
proc getSeverityDescription {level} {
    switch -- $level {
        0 {return "无绕圈"}
        1 {return "轻微绕圈 (建议检查)"}
        2 {return "中度绕圈 (需要优化)"}
        3 {return "严重绕圈 (急需优化)"}
        4 {return "极严重绕圈 (必须重构)"}
        default {return "未知级别"}
    }
}    
