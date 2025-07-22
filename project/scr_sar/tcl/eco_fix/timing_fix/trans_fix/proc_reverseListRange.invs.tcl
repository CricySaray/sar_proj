#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/25
# label     : atomic_proc
# descrip   : Reverse list with range, depth, and group preservation (bugfix)
# --------------------------
proc reverseListRange {listVar {startIdx ""} {endIdx ""} {deep 0} {groupSize 0} {groupByHash 0} {hashMarker "#"} {allowMixedGroups 0}} {
  # $deep: sub list reverse
  # groupSize: set group size
  # allowMixedGroups: all size of group is different(not done)
  # --------------------------
  # 参数处理与错误防御
  # --------------------------
  # 基础列表验证
  if {![string is list -strict $listVar]} {
    error "Input is not a valid list: '$listVar'"
  }
  set originalList $listVar
  set listLen [llength $originalList]
  # 分组参数冲突检查
  if {$groupSize > 0 && $groupByHash} {
    error "Cannot enable both 'groupSize' and 'groupByHash' modes simultaneously"
  }
  if {$groupSize < 0} {
    error "groupSize must be a non-negative integer, got: $groupSize"
  }
  if {$groupSize > 0 && $listLen > 0 && $groupSize > $listLen} {
    error "groupSize ($groupSize) larger than list length ($listLen)"
  }
  if {![string is boolean -strict $groupByHash]} {
    error "groupByHash must be 0 or 1, got: $groupByHash"
  }
  if {$hashMarker eq ""} {
    error "hashMarker cannot be an empty string"
  }
  # 索引参数处理
  if {$startIdx eq ""} {set startIdx 0}
  if {$endIdx eq ""} {set endIdx [expr {$listLen - 1}]}
  if {$startIdx eq "end"} {set startIdx [expr {$listLen - 1}]}
  if {$endIdx eq "end"} {set endIdx [expr {$listLen - 1}]}
  # 索引有效性检查（在分组前验证原始索引）
  foreach idx {startIdx endIdx} {
    if {![string is integer -strict [set $idx]]} {
      error "$idx must be a valid integer or 'end', got: [set $idx]"
    }
    # 处理负索引
    if {[set $idx] < 0} {
      set $idx [expr {$listLen + [set $idx]}]
    }
    # 边界检查（原始列表边界）
    if {[set $idx] < 0 || [set $idx] >= $listLen} {
      error "$idx ([set $idx]) out of bounds (original list length $listLen)"
    }
  }
  if {$startIdx > $endIdx} {
    error "startIdx ($startIdx) cannot be greater than endIdx ($endIdx)"
  }
  # --------------------------
  # 分组逻辑
  # --------------------------
  set groups [list]
  if {$groupSize > 0} {
    # 模式1：按固定大小分组
    for {set i 0} {$i < $listLen} {incr i $groupSize} {
      set groupEnd [expr {min($i + $groupSize - 1, $listLen - 1)}]
      lappend groups [lrange $originalList $i $groupEnd]
    }
  } elseif {$groupByHash} {
    # 模式2：按标记分组
    set currentGroup [list]
    for {set i 0} {$i < $listLen} {incr i} {
      set elem [lindex $originalList $i]
      set isMarker [expr {
        [string index [lindex $elem 0] 0] eq $hashMarker 
        ? 1 
        : ([string index $elem 0] eq $hashMarker ? 1 : 0)
      }]
      if {$isMarker && [llength $currentGroup] > 0} {
        lappend groups $currentGroup
        set currentGroup [list $elem]
      } else {
        lappend currentGroup $elem
      }
    }
    if {[llength $currentGroup] > 0} {
      lappend groups $currentGroup
    }
  } else {
    # 无分组模式：每个元素为单独一组
    foreach elem $originalList {
      lappend groups [list $elem]
    }
  }
  # --------------------------
  # 计算组的反转范围
  # --------------------------
  set groupCount [llength $groups]
  # 处理分组模式下的索引转换
  if {$groupSize > 0 || $groupByHash} {
    # 计算每个组的元素索引范围
    set groupElementRanges [list]
    set elemPos 0
    foreach group $groups {
      set groupLen [llength $group]
      lappend groupElementRanges [list $elemPos [expr {$elemPos + $groupLen - 1}]]
      incr elemPos $groupLen
    }
    # 找到与原始startIdx/endIdx重叠的组索引
    set startGroup -1
    set endGroup -1
    for {set g 0} {$g < $groupCount} {incr g} {
      lassign [lindex $groupElementRanges $g] gStart gEnd
      if {$startGroup == -1 && $gEnd >= $startIdx} {
        set startGroup $g
      }
      if {$gStart <= $endIdx} {
        set endGroup $g
      }
    }
    # 边界修正（防止越界）
    if {$startGroup == -1} {set startGroup 0}
    if {$endGroup == -1} {set endGroup [expr {$groupCount - 1}]}
    if {$startGroup > $endGroup} {
      error "No groups overlap with the specified element range ($startIdx-$endIdx)"
    }
  } else {
    # 无分组模式：直接使用元素索引作为组索引
    set startGroup $startIdx
    set endGroup $endIdx
    # 确保组索引在有效范围内
    set startGroup [expr {max(0, min($startGroup, $groupCount - 1))}]
    set endGroup [expr {max(0, min($endGroup, $groupCount - 1))}]
  }
  # --------------------------
  # 执行组的反转
  # --------------------------
  set groupsToReverse [lrange $groups $startGroup $endGroup]
  set reversedGroups [lreverse $groupsToReverse]
  set groupedResult [lreplace $groups $startGroup $endGroup {*}$reversedGroups]
  # 展开组为最终列表
  set result [list]
  foreach group $groupedResult {
    lappend result {*}$group
  }
  # --------------------------
  # 深度反转处理
  # --------------------------
  if {$deep} {
    set deepResult [list]
    foreach elem $result {
      if {[llength $elem] > 1 && [string is list -strict $elem]} {
        # 对子列表递归应用（不启用分组功能）
        # 注意：递归时使用子列表的长度重新计算索引范围
        set subListLen [llength $elem]
        set subStartIdx [expr {min($startIdx, $subListLen - 1)}]
        set subEndIdx [expr {min($endIdx, $subListLen - 1)}]
        lappend deepResult [reverseListRange $elem $subStartIdx $subEndIdx 1 0 0]
      } else {
        lappend deepResult $elem
      }
    }
    set result $deepResult
  }
  return $result
}    
# --------------------------
# 测试示例
# --------------------------
if {0} {
  # 测试数据
  set testList {a b c d e f {g h} #i j k #l m n}
  # 示例1：无分组，反转整个列表
  puts "示例1：无分组反转整个列表"
  puts "原始: $testList"
  puts "结果: [reverseListRange $testList]\n"
  # 示例2：每2个元素为一组，反转1-4元素范围（对应组1-2）
  puts "示例2：每2个元素一组，反转1-4元素"
  puts "原始: $testList"
  puts "结果: [reverseListRange $testList 1 4 0 2]\n"
  # 示例3：按#号分组，反转所有组
  puts "示例3：按#号分组，反转所有组"
  puts "原始: $testList"
  puts "结果: [reverseListRange $testList 0 end 0 0 1]\n"
  # 示例4：深度反转（子列表内部也反转）
  puts "示例4：深度反转子列表"
  puts "原始: $testList"
  puts "结果: [reverseListRange $testList 0 end 1 0 1]\n"
  # 示例5：混合测试
  puts "示例5：分组+深度反转"
  puts "原始: {1 {2 3} 4 #5 6 {7 8} #9 10}"
  puts "结果: [reverseListRange {1 {2 3} 4 #5 6 {7 8} #9 10} 0 end 1 0 1]"
}
