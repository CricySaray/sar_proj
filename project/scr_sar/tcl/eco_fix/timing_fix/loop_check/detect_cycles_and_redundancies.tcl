source ./graphStore.tcl
proc detect_cycles_and_redundancies {start_point segments {epsilon 0.1} {redundancy_threshold 1.2}} {
    # 辅助函数：坐标编码（用于节点唯一标识）
    proc encode_point {point} {
        return [string map {" " ","} $point]
    }

    # 错误检查
    if {[llength $start_point] != 2} {
        error "Invalid start point format, expected {x y}"
    }
    if {![llength $segments]} {
        error "No segments provided"
    }

    # 验证线段是否轴对齐
    foreach seg $segments {
        if {[llength $seg] != 2} {
            error "Invalid segment format, expected {{x1 y1} {x2 y2}}"
        }
        lassign $seg p1 p2
        lassign $p1 x1 y1; lassign $p2 x2 y2
        if {$x1 != $x2 && $y1 != $y2} {
            error "Segment $seg is not axis-aligned (must be parallel to x or y axis)"
        }
    }

    # 提取所有点（含起点和线段端点）
    set all_points [list $start_point]
    foreach seg $segments {
        lappend all_points {*}$seg
    }

    # 并查集：合并相近节点（距离 < epsilon）
    array set parent {}
    array set rank {}
    
    proc find {node} {
        upvar parent parent
        if {$parent($node) ne $node} {
            set parent($node) [find $parent($node)]
        }
        return $parent($node)
    }
    
    proc union {n1 n2} {
        upvar parent parent rank rank
        set r1 [find $n1]; set r2 [find $n2]
        if {$r1 eq $r2} return
        if {$rank($r1) < $rank($r2)} {
            set parent($r1) $r2
        } else {
            set parent($r2) $r1
            if {$rank($r1) == $rank($r2)} {incr rank($r1)}
        }
    }

    # 初始化并查集
    foreach p $all_points {
        set e [encode_point $p]
        if {![info exists parent($e)]} {
            set parent($e) $e
            set rank($e) 0
        }
    }

    # 合并相近点（曼哈顿距离）
    proc distance {p1 p2} {
        expr {abs([lindex $p1 0]-[lindex $p2 0]) + abs([lindex $p1 1]-[lindex $p2 1])}
    }
    set unique_points [lsort -unique $all_points]
    for {set i 0} {$i < [llength $unique_points]} {incr i} {
        set p1 [lindex $unique_points $i]
        set e1 [encode_point $p1]
        for {set j [expr {$i+1}]} {$j < [llength $unique_points]} {incr j} {
            set p2 [lindex $unique_points $j]
            set e2 [encode_point $p2]
            if {[distance $p1 $p2] < $epsilon} {
                union $e1 $e2
            }
        }
    }

    # 构建图（树结构）
    graph_init
    set root [find [encode_point $start_point]]  ;# 根节点（起点）
    array set root_nodes {}
    foreach p $all_points {
        set n [find [encode_point $p]]
        set root_nodes($n) 1
    }
    set all_nodes [array names root_nodes]
    foreach node $all_nodes {
        graph_add_node $node
    }

    # 添加边（无向图，记录长度）
    foreach seg $segments {
        lassign $seg p1 p2
        set e1 [encode_point $p1]; set e2 [encode_point $p2]
        set n1 [find $e1]; set n2 [find $e2]
        if {$n1 eq $n2} continue

        # 计算长度
        lassign $p1 x1 y1; lassign $p2 x2 y2
        set len [expr {$y1 == $y2 ? abs($x1 - $x2) : abs($y1 - $y2)}]
        graph_add_edge $n1 $n2 $len  ;# 移除方向参数，明确为无向边
    }

    # --------------------------
    # 优化1：正确识别树的叶子节点
    # 叶子节点定义：除根节点外，度为1的节点（在无向图中，度=独特邻居数）
    # --------------------------
    array set node_degree {}  ;# 存储每个节点的度
    array set node_neighbors {}  ;# 存储去重后的邻居列表

    foreach node $all_nodes {
        set raw_neighbors [graph_get_neighbors $node]
        # 去重邻居（处理无向图双向引用导致的重复）
        array set temp_neigh {}
        foreach n $raw_neighbors {
            set temp_neigh($n) 1
        }
        set unique_neighbors [array names temp_neigh]
        set node_neighbors($node) $unique_neighbors
        set node_degree($node) [llength $unique_neighbors]
    }

    # 提取叶子节点（非根节点且度为1）
    set leaf_nodes [list]
    foreach node $all_nodes {
        if {$node eq $root} continue  ;# 排除根节点
        if {$node_degree($node) == 1} {
            lappend leaf_nodes $node
            puts "Leaf node identified: $node (degree: 1)"  ;# 调试信息
        }
    }

    # 特殊情况：无叶子节点（闭环或异常结构）
    if {![llength $leaf_nodes]} {
        puts "No leaf nodes detected - likely a cycle or invalid tree structure"
        return 10  ;# 闭环视为严重冗余
    }

    # --------------------------
    # 优化2：改进路径收集逻辑
    # 确保从根到叶子的所有路径都被正确收集
    # --------------------------
    array set leaf_paths {}  ;# 存储 {叶子节点 -> 路径长度列表}

    # 优化的DFS路径查找（处理无向图，避免父节点回访）
    proc dfs_collect {current_node target_leaf current_length parent_node} {
        upvar node_neighbors node_neighbors  ;# 引用外部邻居列表
        
        # 到达目标叶子节点，返回当前路径长度
        if {$current_node eq $target_leaf} {
            return [list $current_length]
        }
        
        set paths [list]
        # 遍历所有邻居（排除父节点，避免回环）
        foreach neighbor $node_neighbors($current_node) {
            if {$neighbor eq $parent_node} continue  ;# 跳过父节点
            
            # 获取边的权重
            set weight [graph_get_weight $current_node $neighbor]
            if {$weight eq ""} {
                puts "Warning: No weight found for edge $current_node-$neighbor"
                continue
            }
            
            # 递归收集子路径
            set new_length [expr {$current_length + $weight}]
            set subpaths [dfs_collect $neighbor $target_leaf $new_length $current_node]
            set paths [concat $paths $subpaths]
        }
        return $paths
    }

    # 为每个叶子节点收集所有路径
    foreach leaf $leaf_nodes {
        # 从根节点开始，父节点为""（无父节点）
        set all_lengths [dfs_collect $root $leaf 0 ""]
        # 过滤无效路径（确保为正数）
        set valid_lengths [list]
        foreach len $all_lengths {
            if {[string is double -strict $len] && $len > 0} {
                lappend valid_lengths $len
            }
        }
        set leaf_paths($leaf) $valid_lengths
        puts "Paths to leaf $leaf: [llength $valid_lengths] paths (lengths: $valid_lengths)"
    }

    # --------------------------
    # 优化3：冗余度计算逻辑
    # 基于树结构特性：正常树到每个叶子只有1条路径，多条路径即存在冗余
    # --------------------------
    set total_redundancy 0.0
    set valid_leaf_count 0

    foreach leaf $leaf_nodes {
        set lengths $leaf_paths($leaf)
        set path_count [llength $lengths]
        
        # 树结构中正常情况只有1条路径，多条路径即为冗余
        if {$path_count <= 1} {
            puts "Leaf $leaf: No redundancy (only $path_count path)"
            continue
        }
        
        # 计算最短和最长路径的比值（冗余度）
        set sorted_lengths [lsort -real $lengths]
        set min_len [lindex $sorted_lengths 0]
        set max_len [lindex $sorted_lengths end]
        
        if {$min_len <= 0} {
            puts "Leaf $leaf: Invalid path length (min length <= 0)"
            continue
        }
        
        set redundancy [expr {double($max_len) / $min_len}]
        puts "Leaf $leaf: $path_count paths, redundancy = $max_len / $min_len = $redundancy"
        
        # 超过阈值则计入总冗余
        if {$redundancy > $redundancy_threshold} {
            set excess [expr {$redundancy - $redundancy_threshold}]
            # 路径数量越多，冗余权重越高（指数级增长）
            set path_factor [expr {1 + log($path_count)}]  ;# 路径多则冗余更严重
            set weighted_excess [expr {$excess * $path_factor}]
            
            set total_redundancy [expr {$total_redundancy + $weighted_excess}]
            incr valid_leaf_count
            puts "Leaf $leaf: Excess redundancy = $excess (weighted: $weighted_excess)"
        }
    }

    # --------------------------
    # 计算最终冗余分数（0-10）
    # --------------------------
    if {$valid_leaf_count == 0} {
        puts "No redundancy detected"
        return 0
    }

    set avg_excess [expr {$total_redundancy / $valid_leaf_count}]
    puts "Average weighted excess redundancy: $avg_excess"

    # 映射规则（更贴合树结构特性）：
    # 0.1 → 1分（轻微冗余：2条路径，略长）
    # 0.2 → 3分（中等冗余：2-3条路径）
    # 0.3 → 5分（明显冗余：3-4条路径）
    # 0.4 → 7分（严重冗余：4-5条路径）
    # 0.5+ → 10分（极端冗余：多条长路径）
    set score [expr {
        $avg_excess >= 0.5 ? 10 :
        $avg_excess >= 0.4 ? 7 :
        $avg_excess >= 0.3 ? 5 :
        $avg_excess >= 0.2 ? 3 :
        $avg_excess >= 0.1 ? 1 : 0
    }]

    return $score
}



# 假设detect_cycles_and_redundancies和GraphStore已在之前定义
# 此处仅包含测试案例

# 测试辅助函数：执行测试并输出结果
#  proc run_test {name start segments expected_range} {
#    puts "\n测试案例: $name"
#    puts "起点: $start"
#    puts "线段: $segments"
#    
#    if {[catch {
#      set result [detect_cycles_and_redundancies $start $segments]
#    } err]} {
#      puts "结果: 错误 - $err"
#      if {[lindex $expected_range 0] eq "error"} {
#        puts "状态: 符合预期"
#      } else {
#        puts "状态: 不符合预期 (预期$expected_range)"
#      }
#      return
#    }
#    
#    puts "返回值: $result"
#    
#    set min_val [lindex $expected_range 0]
#    set max_val [lindex $expected_range 1]
#    
#    if {$result >= $min_val && $result <= $max_val} {
#      puts "状态: 符合预期"
#    } else {
#      puts "状态: 不符合预期 (预期范围: $min_val-$max_val)"
#    }
#  }

# 测试案例1: 无环无冗余的简单树结构（预期返回0）
# 线段说明：
# - 从(0,0)垂直向上到(0,5)
# - 从(0,5)水平向右到(5,5)
# - 从(5,5)垂直向下到(5,0)
#  run_test "无环无冗余的简单树" \
#    {0 0} \
#    {
#      {{0 0} {0 50}}
#      {{0 50} {50 50}}
#      {{50 50} {50 0}}
#    } \
#    {0 10}
#  
#  # 测试案例2: 存在一个环（预期返回1-100）
#  # 线段说明：
#  # - 4条线段形成矩形闭合环
#  run_test "存在一个环的图" \
#    {0 0} \
#    {
#      {{0 0} {0 5}}
#      {{0 5} {5 5}}
#      {{5 5} {5 0}}
#      {{5 0} {0 0}}
#    } \
#    {1 100}
#  
#  # 测试案例3: 存在冗余路径但无环（预期返回101-200）
#  # 线段说明：
#  # - 基础路径形成开放结构
#  # - 额外线段形成冗余连接
#  run_test "存在冗余路径的图" \
#    {0 0} \
#    {
#      {{0 0} {0 5}}
#      {{0 5} {5 5}}
#      {{5 5} {5 0}}
#      {{5 0} {0 0}}
#      {{0 0} {5 5}}
#    } \
#    {101 200}
#  
#  # 测试案例4: 既有环又有冗余路径（预期返回201-300）
#  # 线段说明：
#  # - 基础矩形环
#  # - 额外水平和垂直线段形成冗余
#  run_test "既有环又有冗余路径的图" \
#    {0 0} \
#    {
#      {{0 0} {0 5}}
#      {{0 5} {5 5}}
#      {{5 5} {5 0}}
#      {{5 0} {0 0}}
#      {{0 0} {5 0}}
#      {{0 5} {0 0}}
#    } \
#    {201 300}
#  
#  # 测试案例5: 存在多个环（预期返回较高的环严重程度1-100）
#  # 线段说明：
#  # - 外环形成大矩形
#  # - 内环形成小矩形
#  # - 连接线段形成更多环结构
#  run_test "存在多个环的图" \
#    {0 0} \
#    {
#      {{0 0} {0 5}}
#      {{0 5} {5 5}}
#      {{5 5} {5 0}}
#      {{5 0} {0 0}}
#      {{1 1} {1 4}}
#      {{1 4} {4 4}}
#      {{4 4} {4 1}}
#      {{4 1} {1 1}}
#      {{1 1} {4 4}}
#    } \
#    {0 10}
#  
#  # 测试案例6: 存在轻微冗余（低于阈值，预期返回0）
#  # 线段说明：
#  # - 主路径：(0,0)→(0,10)
#  # - 分支路径长度接近主路径，冗余度低于阈值
#  run_test "轻微冗余（低于阈值）" \
#    {0 0} \
#    {
#      {{0 0} {0 10}}
#      {{0 0} {5 0}}
#      {{5 0} {5 10}}
#      {{5 10} {0 10}}
#    } \
#    {0 0}
#  
#  # 测试案例7: 存在严重冗余（远高于阈值，预期返回较高的冗余值）
#  # 线段说明：
#  # - 直接路径长度10
#  # - 冗余路径总长度30，冗余度3.0（远高于阈值1.5）
#  run_test "严重冗余路径" \
#    {0 0} \
#    {
#      {{0 0} {0 10}}
#      {{0 0} {10 0}}
#      {{10 0} {10 10}}
#      {{10 10} {0 10}}
#    } \
#    {150 200}
#  
#  # 测试案例8: 节点合并测试（相近节点被合并，预期无环）
#  # 线段说明：
#  # - (0,0)与(0.01,0)为相近节点，应被合并
#  # - 合并后形成开放结构，无环
#  run_test "相近节点合并" \
#    {0 0} \
#    {
#      {{0 0} {0 5}}
#      {{0.01 0} {5 0}}
#      {{5 0} {5 5}}
#      {{5 5} {0 5}}
#    } \
#    {0 0}
#  
#  # 测试案例9: 错误情况 - 非轴对齐线段（预期报错）
#  # 线段说明：
#  # - 对角线线段（3,4）不符合轴对齐要求
#  run_test "非轴对齐线段（错误）" \
#    {0 0} \
#    {
#      {{0 0} {3 4}}
#    } \
#    {error error}
#  
#  # 测试案例10: 错误情况 - 无效起点格式（预期报错）
#  # 起点说明：
#  # - 仅包含一个坐标值，格式错误
#  run_test "无效起点格式（错误）" \
#    {0} \
#    {
#      {{0 0} {0 5}}
#    } \
#    {error error}
#  
#  # 测试案例11: 空线段列表（预期报错）
#  # 线段说明：
#  # - 未提供任何线段，为空列表
#  run_test "空线段列表（错误）" \
#    {0 0} \
#    {} \
#    {error error}
#  
#  puts "\n所有测试案例执行完毕"
#  
