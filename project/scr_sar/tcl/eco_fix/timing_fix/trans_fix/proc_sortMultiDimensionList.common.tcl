# songNOTE: TESTING...
# TODO: need improve
# 多维列表带权重排序函数
# 参数:
#   list - 要排序的二维列表
#   weights - 权重列表，每个元素对应一个列的权重
#   options - 排序选项列表，每个元素是对应列的排序选项列表
# 返回:
#   排序后的二维列表
package require lambda
proc sortMultiDimensionalList {list weights options} {
  # 创建比较函数
  set compareCmd [list]
  lappend compareCmd "lambda {a b} {"

  # 生成基于权重的比较逻辑
  set indices [lsort -decreasing -real -index 1 [zip [list_indices $list 0] $weights]]
puts $indices

  foreach idx $indices {
    set col [lindex $idx 0]
    set colOptions [lindex $options $col]

    # 构建列比较逻辑
    lappend compareCmd "    set cmp [compareColumn \$a \$b $col \{$colOptions\}]"
    lappend compareCmd "    if {\$cmp != 0} { return \$cmp }"
  }

  # 如果所有列都相等
  lappend compareCmd "    return 0"
  lappend compareCmd "}"
puts $compareCmd

  # 编译比较函数
  set compareFunc [uplevel 1 $compareCmd]

  # 执行排序
  return [lsort -command $compareFunc $list]
}
# 辅助函数：比较特定列
proc compareColumn {a b col options} {
  set valA [lindex $a $col]
  set valB [lindex $b $col]

  # 处理常见排序选项
  set caseSensitive 1
  set numeric 0
  set dictionary 0

  foreach {opt val} $options {
    switch -- $opt {
      "-increasing"  {}  ;# 默认行为
      "-decreasing" {set valA [list $valA]; set valB [list $valB]}
      "-nocase"     {set caseSensitive 0}
      "-integer"    {set numeric 1}
      "-real"       {set numeric 1}
      "-dictionary" {set dictionary 1}
    }
  }

  # 执行比较
  if {$numeric} {
    return [expr {$valA <=> $valB}]
  } elseif {$dictionary} {
    if {$caseSensitive} {
      return [string compare -length [string length $valA] $valA $valB]
    } else {
      return [string compare -nocase -length [string length $valA] $valA $valB]
    }
  } else {
    if {$caseSensitive} {
      return [string compare $valA $valB]
    } else {
      return [string compare -nocase $valA $valB]
    }
  }
}

# 辅助函数：生成索引列表
proc list_indices {list start} {
  set result [list]
  for {set i $start} {$i < [llength [lindex $list 0]]} {incr i} {
    lappend result $i
  }
  return $result
}

# 辅助函数：合并两个列表为元组列表
proc zip {list1 list2} {
  set result [list]
  if {[llength $list1] != [llength $list2]} {
    return "0x0:1"; # two lists have different length, check it
  }
  set len [llength $list1]
  for {set i 0} {$i < $len} {incr i} {
    lappend result [list [lindex $list1 $i] [lindex $list2 $i]]
  }

  return $result
}

# 示例使用
set myList {
  {100 2.5 "apple"}
  {200 1.5 "Banana"}
  {100 3.0 "apple"}
  {200 1.0 "Cherry"}
}

# 权重：第1列权重3，第2列权重2，第3列权重1
set weights {10 2 1}

# 排序选项：
# 第1列：数值降序
# 第2列：数值升序
# 第3列：不区分大小写的字典序升序
set options {{-decreasing -integer} {-increasing -real} {-increasing -nocase -dictionary}}

# 执行排序
set sortedList [sortMultiDimensionalList $myList $weights $options]

# 输出排序结果
puts "排序前:"
foreach row $myList {
  puts [join $row "\t"]
}

puts "\n排序后:"
foreach row $sortedList {
  puts [join $row "\t"]
}
