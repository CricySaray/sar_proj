proc detect_cycles_and_redundancies {start_point segments {epsilon 0.1} {redundancy_threshold 1.2}} {
  # 辅助函数：坐标编码（用于节点标识）
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

  # 添加边（含长度）
  foreach seg $segments {
    lassign $seg p1 p2
    set e1 [encode_point $p1]; set e2 [encode_point $p2]
    set n1 [find $e1]; set n2 [find $e2]
    if {$n1 eq $n2} continue

    # 计算长度
    lassign $p1 x1 y1; lassign $p2 x2 y2
    set len [expr {$y1 == $y2 ? abs($x1 - $x2) : abs($y1 - $y2)}]
    graph_add_edge $n1 $n2 $len "x"
  }

  # 识别树的叶子节点（端点）：除根节点外，度为1的节点
  set leaf_nodes [list]
  foreach node $all_nodes {
    if {$node eq $root} continue  ;# 排除根节点
    set degree [llength [graph_get_neighbors $node]]
    if {$degree == 1} {
      lappend leaf_nodes $node
    }
  }

  # 若没有叶子节点（仅根节点或闭环），直接返回最高冗余
  if {![llength $leaf_nodes]} {
    return 10  ;# 无端点的结构必然存在严重冗余（如环）
  }

  # 对每个叶子节点，找到所有从根到叶子的路径及长度
  array set leaf_paths {}  ;# 存储 {叶子节点 -> 路径长度列表}

  # DFS寻找所有路径
  proc dfs_paths {current_node target_leaf current_length visited path_lengths} {
    upvar 1 visited visited_internal path_lengths path_lengths_internal
    
    # 标记当前节点为已访问
    lappend visited_internal $current_node
    
    # 到达目标叶子节点，记录路径长度
    if {$current_node eq $target_leaf} {
      lappend $path_lengths_internal $current_length
      return
    }
    
    # 遍历邻居节点（排除已访问节点）
    foreach neighbor [graph_get_neighbors $current_node] {
      if {[lsearch $visited_internal $neighbor] == -1} {
        set new_length [expr {$current_length + [graph_get_weight $current_node $neighbor]}]
        dfs_paths $neighbor $target_leaf $new_length $visited_internal $path_lengths_internal
      }
    }
  }

  # 为每个叶子节点计算所有路径长度
  foreach leaf $leaf_nodes {
    set path_lengths [list]
    dfs_paths $root $leaf 0 [list] path_lengths
    set leaf_paths($leaf) $path_lengths
  }

  # 计算每个叶子节点的冗余度
  set total_redundancy 0.0
  set valid_leaf_count 0
puts "point 3: leaf_nodes: $leaf_nodes"
  foreach leaf $leaf_nodes {
    set lengths $leaf_paths($leaf)
    if {[llength $lengths] < 2} {
      continue  ;# 只有一条路径，无冗余
    }
    
    # 计算最短和最长路径
    set min_len [lsort -real $lengths][0]
    set max_len [lsort -real -decreasing $lengths][0]
    
    # 冗余度 = 最长路径 / 最短路径
    if {$min_len <= 0} {
      continue  ;# 避免除零错误
    }
    set red [expr {double($max_len) / $min_len}]
    
    # 超过阈值的部分计入总冗余
puts "point 2: red: $red"
    if {$red > $redundancy_threshold} {
      set excess [expr {$red - $redundancy_threshold}]
      set total_redundancy [expr {$total_redundancy + $excess}]
      incr valid_leaf_count
    }
graph_debug_print
  }
puts "point 1: valid_leaf_count: $valid_leaf_count"

  # 计算最终冗余分数（0-10）
  if {$valid_leaf_count == 0} {
    return 0  ;# 无冗余
  }


  # 平均冗余度映射到0-10分
  set avg_excess [expr {$total_redundancy / $valid_leaf_count}]
  
  # 映射规则（根据树结构特性调整）：
  # 0.1 → 1分（轻微冗余）
  # 0.2 → 2分
  # 0.3 → 4分
  # 0.4 → 6分
  # 0.5 → 8分
  # 0.6+ → 10分（严重冗余）
  set score [expr {min(10, int($avg_excess * 16.67))}]  ;# 1/0.06 ≈ 16.67

  return $score
}

