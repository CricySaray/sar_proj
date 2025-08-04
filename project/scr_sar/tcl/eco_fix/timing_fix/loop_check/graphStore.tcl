# 判断字典中指定key对应的list是否包含某个value
proc dict_list_contains {dict key value} {
  if {![dict exists $dict $key]} {
    return 0
  }
  set list [dict get $dict $key]
  return [expr {[lsearch -exact $list $value] != -1}]
}

# 命名空间用于存储图结构数据，避免全局变量污染
namespace eval GraphStore {
  variable graph_data {} ;# 存储图的核心数据: nodes, adj, weights, directions
}

# 初始化图结构
proc graph_init {} {
  namespace upvar GraphStore graph_data graph_data
  # 初始化图数据结构:
  # - nodes: 存储所有节点集合(编码后的坐标)
  # - adj: 邻接表 {节点 {邻居1 邻居2 ...}}
  # - weights: 边权重 {节点对(竖线分隔) 长度}
  # - directions: 边方向(x/y轴，针对轴对齐) {节点对(竖线分隔) 方向}
  set graph_data [dict create \
    nodes [list] \
    adj [dict create] \
    weights [dict create] \
    directions [dict create] \
  ]
  return 1
}

# 添加节点到图中
# 参数: encoded_node - 编码后的节点名(如"{1,2}")
proc graph_add_node {encoded_node} {
  namespace upvar GraphStore graph_data graph_data
  
  # 错误检查
  if {[string trim $encoded_node] eq ""} {
    error "graph_add_node: 节点名不能为空"
  }
  # 使用dict_list_contains判断节点是否已存在
  if {[dict_list_contains $graph_data nodes $encoded_node]} {
    return 0 ;# 节点已存在，无需重复添加
  }
  
  # 添加节点到集合，并初始化邻接表
  dict lappend graph_data nodes $encoded_node
  dict set graph_data adj $encoded_node [list]
  return 1
}

# 添加边到图中
# 参数: u, v - 编码后的节点名; weight - 边权重(长度); direction - 方向(x/y)
proc graph_add_edge {u v weight direction} {
  namespace upvar GraphStore graph_data graph_data
  
  # 错误检查：使用dict_list_contains判断节点是否存在
  foreach node [list $u $v] {
    if {![dict_list_contains $graph_data nodes $node]} {
      error "graph_add_edge: 节点$node不存在，请先调用graph_add_node添加"
    }
  }
  if {$u eq $v} {
    error "graph_add_edge: 节点$u与$v不能为同一节点"
  }
  if {![string is double -strict $weight] || $weight <= 0} {
    error "graph_add_edge: 权重必须为正数值，实际为$weight"
  }
  if {$direction ni {x y}} {
    error "graph_add_edge: 方向必须为x或y，实际为$direction"
  }
  
  # 边的唯一标识(无向图，u|v与v|u视为同一条边)
  set edge_key [expr {[string compare $u $v] <= 0 ? "$u|$v" : "$v|$u"}]
  
  # 若边已存在则跳过
  if {[dict exists $graph_data weights $edge_key]} {
    return 0
  }
  
  # 添加到邻接表(双向)
  dict lappend graph_data adj $u $v
  dict lappend graph_data adj $v $u
  
  # 存储权重和方向(只存一次)
  dict set graph_data weights $edge_key $weight
  dict set graph_data directions $edge_key $direction
  return 1
}

# 获取节点的邻居列表
# 参数: encoded_node - 编码后的节点名
proc graph_get_neighbors {encoded_node} {
  namespace upvar GraphStore graph_data graph_data
  
  # 错误检查：使用dict_list_contains判断节点是否存在
  if {![dict_list_contains $graph_data nodes $encoded_node]} {
    error "graph_get_neighbors: 节点$encoded_node不存在"
  }
  
  return [dict get $graph_data adj $encoded_node]
}

# 获取边的权重
# 参数: u, v - 编码后的节点名
proc graph_get_weight {u v} {
  namespace upvar GraphStore graph_data graph_data
  
  # 错误检查：使用dict_list_contains判断节点是否存在
  foreach node [list $u $v] {
    if {![dict_list_contains $graph_data nodes $node]} {
      error "graph_get_weight: 节点$node不存在"
    }
  }
  
  set edge_key [expr {[string compare $u $v] <= 0 ? "$u|$v" : "$v|$u"}]
  if {![dict exists $graph_data weights $edge_key]} {
    error "graph_get_weight: 节点$u与$v之间无边"
  }
  
  return [dict get $graph_data weights $edge_key]
}

# 获取边的方向
# 参数: u, v - 编码后的节点名
proc graph_get_direction {u v} {
  namespace upvar GraphStore graph_data graph_data
  
  # 错误检查：使用dict_list_contains判断节点是否存在
  foreach node [list $u $v] {
    if {![dict_list_contains $graph_data nodes $node]} {
      error "graph_get_direction: 节点$node不存在"
    }
  }
  
  set edge_key [expr {[string compare $u $v] <= 0 ? "$u|$v" : "$v|$u"}]
  if {![dict exists $graph_data directions $edge_key]} {
    error "graph_get_direction: 节点$u与$v之间无边"
  }
  
  return [dict get $graph_data directions $edge_key]
}

# 临时移除一条边(用于冗余检测时的路径计算)
# 参数: u, v - 编码后的节点名; 返回值: 被移除的边信息(用于恢复)
proc graph_remove_edge {u v} {
  namespace upvar GraphStore graph_data graph_data
  
  # 错误检查：使用dict_list_contains判断节点是否存在
  foreach node [list $u $v] {
    if {![dict_list_contains $graph_data nodes $node]} {
      error "graph_remove_edge: 节点$node不存在"
    }
  }
  
  set edge_key [expr {[string compare $u $v] <= 0 ? "$u|$v" : "$v|$u"}]
  if {![dict exists $graph_data weights $edge_key]} {
    error "graph_remove_edge: 节点$u与$v之间无边"
  }
  
  # 保存边信息用于恢复
  set edge_info [list \
    weight [dict get $graph_data weights $edge_key] \
    direction [dict get $graph_data directions $edge_key] \
  ]
  
  # 从邻接表移除(双向)
  set u_neighbors [dict get $graph_data adj $u]
  set u_new [lsearch -all -inline -not $u_neighbors $v]
  dict set graph_data adj $u $u_new
  
  set v_neighbors [dict get $graph_data adj $v]
  set v_new [lsearch -all -inline -not $v_neighbors $u]
  dict set graph_data adj $v $v_new
  
  # 从权重和方向表移除
  dict unset graph_data weights $edge_key
  dict unset graph_data directions $edge_key
  
  return $edge_info
}

# 恢复被移除的边
# 参数: u, v - 编码后的节点名; edge_info - graph_remove_edge返回的边信息
proc graph_restore_edge {u v edge_info} {
  namespace upvar GraphStore graph_data graph_data
  
  # 错误检查：使用dict_list_contains判断节点是否存在
  foreach node [list $u $v] {
    if {![dict_list_contains $graph_data nodes $node]} {
      error "graph_restore_edge: 节点$node不存在"
    }
  }
  if {[llength $edge_info] != 4 || [lindex $edge_info 0] ne "weight" || [lindex $edge_info 2] ne "direction"} {
    error "graph_restore_edge: 边信息格式错误，应为{weight x direction y}"
  }
  
  set edge_key [expr {[string compare $u $v] <= 0 ? "$u|$v" : "$v|$u"}]
  if {[dict exists $graph_data weights $edge_key]} {
    error "graph_restore_edge: 边$u|$v已存在，无需恢复"
  }
  
  # 恢复邻接表(双向)
  dict lappend graph_data adj $u $v
  dict lappend graph_data adj $v $u
  
  # 恢复权重和方向
  dict set graph_data weights $edge_key [lindex $edge_info 1]
  dict set graph_data directions $edge_key [lindex $edge_info 3]
  
  return 1
}

# 检查节点是否存在
proc graph_has_node {encoded_node} {
  namespace upvar GraphStore graph_data graph_data
  return [dict_list_contains $graph_data nodes $encoded_node]
}

# 检查边是否存在
proc graph_has_edge {u v} {
  namespace upvar GraphStore graph_data graph_data
  set edge_key [expr {[string compare $u $v] <= 0 ? "$u|$v" : "$v|$u"}]
  return [dict exists $graph_data weights $edge_key]
}

# 获取所有节点
proc graph_get_all_nodes {} {
  namespace upvar GraphStore graph_data graph_data
  return [dict get $graph_data nodes]
}

# 调试用: 打印图结构信息
proc graph_debug_print {} {
  namespace upvar GraphStore graph_data graph_data
  puts "图结构调试信息:"
  puts "  节点总数: [llength [dict get $graph_data nodes]]"
  puts "  节点列表: [dict get $graph_data nodes]"
  puts "  邻接表: [dict get $graph_data adj]"
  puts "  边权重: [dict get $graph_data weights]"
  puts "  边方向: [dict get $graph_data directions]"
}


if {0} {
  # 初始化图
  graph_init

  # 添加节点（编码后的坐标）
  graph_add_node {0,0}
  graph_add_node {0,5}
  graph_add_node {5,5}
  graph_add_node {5,0}
  graph_add_node {5,0}

  #graph_debug_print
  # 添加边（轴对齐）
  graph_add_edge {0,0} {0,5} 5 y ;# 垂直边，长度5
  graph_add_edge {0,5} {5,5} 5 x ;# 水平边，长度5
  graph_add_edge {5,5} {5,0} 5 y ;# 垂直边，长度5
  graph_add_edge {5,0} {0,0} 5 x ;# 水平边，长度5（形成环）

  # 调试打印

  # 获取节点{0,0}的邻居
  puts "节点{0,0}的邻居: [graph_get_neighbors {0,0}]"

  # 获取边{0,0}-{0,5}的权重
  puts "边{0,0}-{0,5}的权重: [graph_get_weight {0,0} {0,5}]"

  # 临时移除边{0,0}-{0,5}
  set edge_info [graph_remove_edge {0,0} {0,5}]
  puts "移除后{0,0}的邻居: [graph_get_neighbors {0,0}]"

  # 恢复边
  graph_restore_edge {0,0} {0,5} $edge_info
  puts "恢复后{0,0}的邻居: [graph_get_neighbors {0,0}]"



  puts ""
  puts ""
  puts ""
  puts ""
  puts ""
  # ------------------------------
  # 全功能测试流程
  # ------------------------------
  puts "======= 图结构数据类型全功能测试 ======="

  # 1. 初始化图
  puts "\n1. 测试初始化图"
  if {[graph_init]} {
    puts "   初始化成功"
  } else {
    puts "   初始化失败"
  }

  # 2. 测试节点添加与存在性检查
  puts "\n2. 测试节点操作"
  set test_nodes [list {0,0} {0,5} {5,5} {5,0} {3,3}]

  # 2.1 添加新节点
  foreach node $test_nodes {
    set result [graph_add_node $node]
    puts "   添加节点$node: [expr {$result ? "成功" : "已存在"}]"
  }

  # 2.2 尝试添加重复节点
  set duplicate_node {0,0}
  set result [graph_add_node $duplicate_node]
  puts "   添加重复节点$duplicate_node: [expr {$result ? "成功(错误)" : "已存在(正确)"}]"

  # 2.3 检查节点存在性
  foreach node [concat $test_nodes {99,99}] {
    set exists [graph_has_node $node]
    puts "   节点$node是否存在: [expr {$exists ? "是" : "否"}]"
  }

  # 2.4 获取所有节点
  set all_nodes [graph_get_all_nodes]
  puts "   所有节点: $all_nodes (预期: $test_nodes)"

  # 3. 测试边添加与基本属性
  puts "\n3. 测试边操作"
  set test_edges {
    {{0,0} {0,5} 5 y}
    {{0,5} {5,5} 5 x}
    {{5,5} {5,0} 5 y}
    {{5,0} {0,0} 5 x}
    {{5,5} {3,3} 3 x}
  }

  # 3.1 添加边
  foreach edge $test_edges {
    lassign $edge u v w d
    if {[catch {graph_add_edge $u $v $w $d} result]} {
      puts "   添加边$u-$v: 失败($result)"
    } else {
      puts "   添加边$u-$v: [expr {$result ? "成功" : "已存在"}]"
    }
  }

  # 3.2 尝试添加重复边
  lassign [lindex $test_edges 0] u v w d
  set result [graph_add_edge $u $v $w $d]
  puts "   添加重复边$u-$v: [expr {$result ? "成功(错误)" : "已存在(正确)"}]"

  # 3.3 尝试添加自环边(应失败)
  set self_node {0,0}
  if {[catch {graph_add_edge $self_node $self_node 10 x} err]} {
    puts "   添加自环边$self_node-$self_node: 失败($err)(正确)"
  } else {
    puts "   添加自环边$self_node-$self_node: 成功(错误)"
  }

  # 3.4 尝试添加不存在节点的边(应失败)
  set invalid_edge {{0,0} {99,99} 10 x}
  lassign $invalid_edge u v w d
  if {[catch {graph_add_edge $u $v $w $d} err]} {
    puts "   添加含无效节点的边$u-$v: 失败($err)(正确)"
  } else {
    puts "   添加含无效节点的边$u-$v: 成功(错误)"
  }

  # 3.5 检查边存在性
  set check_edges [concat $test_edges [list {{0,0} {5,5} 10 x}]] ;# 最后一条是不存在的边
  foreach edge $check_edges {
    lassign $edge u v w d
    set exists [graph_has_edge $u $v]
    puts "   边$u-$v是否存在: [expr {$exists ? "是" : "否"}]"
  }

  # 4. 测试数据访问功能
  puts "\n4. 测试数据访问"

  # 4.1 获取邻居
  foreach node {0,0 5,5 {99,99}} {
    if {[catch {graph_get_neighbors $node} neighbors]} {
      puts "   获取节点$node的邻居: 失败($neighbors)"
    } else {
      puts "   节点$node的邻居: $neighbors"
    }
  }

  # 4.2 获取边权重
  set weight_edges {
    {{0,0} {0,5}}
    {{5,5} {3,3}}
    {{0,0} {5,5}}
  }
  foreach edge $weight_edges {
    lassign $edge u v
    if {[catch {graph_get_weight $u $v} weight]} {
      puts "   边$u-$v的权重: 失败($weight)"
    } else {
      puts "   边$u-$v的权重: $weight"
    }
  }

  # 4.3 获取边方向
  foreach edge $weight_edges {
    lassign $edge u v
    if {[catch {graph_get_direction $u $v} dir]} {
      puts "   边$u-$v的方向: 失败($dir)"
    } else {
      puts "   边$u-$v的方向: $dir"
    }
  }

  # 5. 测试边的临时移除与恢复
  puts "\n5. 测试边的移除与恢复"
  set test_remove_edge [list {0,0} {0,5}]
  lassign $test_remove_edge u v

  # 5.1 移除边前检查
  set exists_before [graph_has_edge $u $v]
  puts "   移除前边$u-$v是否存在: [expr {$exists_before ? "是" : "否"}]"

  # 5.2 移除边
  if {[catch {graph_remove_edge $u $v} edge_info]} {
    puts "   移除边$u-$v: 失败($edge_info)"
  } else {
    puts "   移除边$u-$v成功，边信息: $edge_info"
  }

  # 5.3 移除后检查
  set exists_after_remove [graph_has_edge $u $v]
  puts "   移除后边$u-$v是否存在: [expr {$exists_after_remove ? "是(错误)" : "否(正确)"}]"

  # 5.4 检查邻居变化
  set neighbors_u [graph_get_neighbors $u]
  puts "   移除后$u的邻居: $neighbors_u (应不含$v)"

  # 5.5 恢复边
  if {[catch {graph_restore_edge $u $v $edge_info} result]} {
    puts "   恢复边$u-$v: 失败($result)"
  } else {
    puts "   恢复边$u-$v: [expr {$result ? "成功" : "失败"}]"
  }

  # 5.6 恢复后检查
  set exists_after_restore [graph_has_edge $u $v]
  puts "   恢复后边$u-$v是否存在: [expr {$exists_after_restore ? "是(正确)" : "否(错误)"}]"

  # 5.7 检查邻居是否恢复
  set neighbors_u_after [graph_get_neighbors $u]
  puts "   恢复后$u的邻居: $neighbors_u_after (应包含$v)"

  # 6. 打印完整图结构(调试用)
  puts "\n6. 最终图结构调试信息"
  graph_debug_print

  puts "\n======= 测试完成 ======="
}
