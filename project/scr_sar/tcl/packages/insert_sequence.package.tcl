#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/29 09:41:55 Friday
# label     : package_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|misc_proc)
# descrip   : A procedure to insert sequence numbers into a nested list starting from a specified position, with placeholders in 
#             the same column for other rows.
# return    : processed list
# ref       : link url
# --------------------------
proc insert_sequence {nested_list {start_pos {1 0}} {placeholders {{all "/"} {{0 0 "num"}}}} {debug 0} {strictMode 0}} {
  # 验证起始位置参数
  if {![llength $start_pos] == 2} {
    error "start_pos must be a list of two integers"
  }
  lassign $start_pos start_row start_col
  
  # 验证行列号是否为非负整数
  if {![string is integer -strict $start_row] || ![string is integer -strict $start_col]} {
    error "start_row and start_col must be integers"
  }
  if {$start_row < 0 || $start_col < 0} {
    error "start_row and start_col must be non-negative"
  }
  
  # 解析占位符配置，仅允许在起始列设置占位符
  set all_placeholder ""
  set specific_placeholders [dict create]
  
  foreach ph $placeholders {
    if {[llength $ph] != 2} {
      error "Invalid placeholder format: $ph. Must be a list of two elements."
    }
    lassign $ph pos val
    
    if {$pos eq "all"} {
      # 通用占位符应用于起始列的所有非序号行
      set all_placeholder $val
    } else {
      # 验证位置格式
      if {[llength $pos] != 2} {
        error "Invalid position format: $pos. Must be a list of two integers."
      }
      lassign $pos ph_row ph_col
      
      # 验证占位符行列号有效性
      if {![string is integer -strict $ph_row] || ![string is integer -strict $ph_col]} {
        error "Placeholder row and column must be integers: $pos"
      }
      if {$ph_row < 0 || $ph_col < 0} {
        error "Placeholder row and column must be non-negative: $pos"
      }
      
      # 关键验证：占位符列必须与起始列相同
      if {$ph_col != $start_col} {
        error "Placeholder at $pos has invalid column. Must match start column $start_col"
      }
      
      dict set specific_placeholders "$ph_row,$ph_col" $val
    }
  }
  
  if {$debug} {
    puts "Debug mode enabled"
    puts "Original nested list: $nested_list"
    puts "Start position: row $start_row, column $start_col"
    puts "All placeholder (for start column): '$all_placeholder'"
    puts "Specific placeholders (only in start column): $specific_placeholders"
  }
  
  # 处理每一行
  set result [list]
  set row 0
  
  foreach original_row $nested_list {
    if {$debug} {
      puts "\nProcessing row $row"
      puts "Original row: $original_row (length: [llength $original_row])"
    }
    
    # 构建新行的三个部分：起始列前、起始列内容、起始列后
    set new_row [list]
    
    # 1. 起始列之前的内容（保持原样）
    set before_cols [lrange $original_row 0 [expr {$start_col - 1}]]
    lappend new_row {*}$before_cols
    
    # 2. 起始列的内容（占位符或序号）
    set pos_key "$row,$start_col"
    set insert_val ""
    
    if {[dict exists $specific_placeholders $pos_key]} {
      # 特定占位符优先
      set insert_val [dict get $specific_placeholders $pos_key]
      
      # 检查是否与序号位置冲突
      if {$row >= $start_row && $strictMode} {
        puts "Warning: Placeholder at $pos_key conflicts with sequence position, using placeholder"
      }
      if {$debug} {
        puts "Inserting specific placeholder '$insert_val' at $pos_key"
      }
    } elseif {$row >= $start_row} {
      # 序号行：无特定占位符则插入序号
      set insert_val [expr {$row - $start_row + 1}]
      if {$debug} {
        puts "Inserting sequence number $insert_val at $pos_key"
      }
    } else {
      # 非序号行：使用通用占位符
      set insert_val $all_placeholder
      if {$debug} {
        puts "Inserting all placeholder '$insert_val' at $pos_key"
      }
    }
    
    lappend new_row $insert_val
    
    # 3. 起始列之后的内容（右移一位）
    set after_cols [lrange $original_row $start_col end]
    lappend new_row {*}$after_cols
    
    # 添加到结果列表
    lappend result $new_row
    
    if {$debug} {
      puts "Processed row $row: $new_row (length: [llength $new_row])"
    }
    
    incr row
  }
  
  if {$debug} {
    puts "\nFinal result: $result"
  }
  
  return $result
}


set ok {{first song an rui} {second an rui song } {third rui an song}}
puts [join [insert_sequence $ok {1 0} {{{0 0} "num"}}] \n]
