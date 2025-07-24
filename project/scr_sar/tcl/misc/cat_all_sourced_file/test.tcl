#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/27
# label     : misc_proc
# descrip   : Merge sourced files with accurate comment stripping (handles multi-line control structures)
# update    : 2025/07/27 优化正则表达式，避免使用{减少工具解析错误
# --------------------------
namespace eval CatAll {
  variable state
  array set state {
    processed_files {}  ;# 记录已处理的文件
    recursion_depth {}  ;# 记录递归深度
    original_dir ""     ;# 原始工作目录
    target_dir ""       ;# 目标文件所在目录
  }

  # 初始化状态（保存原始目录和目标目录）
  proc init_state {original working} {
    variable state
    array unset state
    set state(processed_files) [dict create]
    set state(recursion_depth) [dict create]
    set state(original_dir) $original  ;# 保存原始工作目录
    set state(target_dir) $working     ;# 保存目标文件所在目录
  }

  # 检查文件是否已处理
  proc is_file_processed {file} {
    variable state
    return [dict exists $state(processed_files) $file]
  }

  # 标记文件为已处理
  proc mark_file_processed {file} {
    variable state
    dict set state(processed_files) $file 1
  }

  # 管理递归深度
  proc set_recursion_depth {file depth} {
    variable state
    dict set state(recursion_depth) $file $depth
  }

  proc get_recursion_depth {file} {
    variable state
    return [dict get $state(recursion_depth) $file 0]
  }

  # 获取目标工作目录
  proc get_target_dir {} {
    variable state
    return $state(target_dir)
  }

  # 恢复原始工作目录
  proc restore_original_dir {} {
    variable state
    catch {cd $state(original_dir)}
  }
}

# 定义闭合标点对（左符号 -> 右符号）
set bracket_pairs {
  { } 
  ( ) 
  [ ] 
  " " 
  ' ' 
}

# 定义Tcl控制结构关键字（避免引号，减少解析问题）
set tcl_commands {
  foreach if while for proc lambda namespace switch
}

# 改进的注释处理函数：避免正则表达式中使用{
proc strip_line_comments {line mode {control_depth 0} {in_quote 0} {quote_char {}} {stack {}}} {
  if {$mode == 0} {
    return [list $line $control_depth $in_quote $quote_char $stack]
  }

  # 初始化栈（如果未提供）
  if {$stack eq ""} {
    set stack [list]
  }

  # 处理整行注释 (模式1或3)：仅行首（忽略前导空白）是#且不在闭合标点内
  set trimmed [string trimleft $line]
  if {($mode & 1) && [string index $trimmed 0] eq "#"} {
    # 检查整行#是否在闭合标点外（栈为空）
    if {[is_outside_closed_punct $trimmed]} {
      return [list "" $control_depth $in_quote $quote_char $stack]
    }
  }

  # 处理行内注释 (模式2或3)
  if {($mode & 2)} {
    set len [string length $line]
    set current_control_depth $control_depth
    set current_in_quote $in_quote
    set current_quote_char $quote_char
    set current_stack $stack
    set comment_pos -1

    # 检查是否在控制结构中开始行
    if {$current_control_depth > 0 && $current_in_quote == 0 && [llength $current_stack] == 0} {
      # 查找不在引号和括号内的分号
      for {set i 0} {$i < $len} {incr i} {
        set char [string index $line $i]

        # 更新闭合标点栈状态
        update_bracket_stack $char current_stack current_in_quote current_quote_char

        # 栈为空且不在引号内，检查分号和注释
        if {[llength $current_stack] == 0 && $current_in_quote == 0} {
          # 找到分号，继续查找其后的#
          if {$char eq ";" && $comment_pos == -1} {
            for {set j [expr {$i + 1}]} {$j < $len} {incr j} {
              set check_char [string index $line $j]
              if {$check_char eq "#"} {
                set comment_pos $j
                break
              } elseif {$check_char ne " " && $check_char ne "\t"} {
                break  ;# 不是空格，不是注释
              }
            }
            break  ;# 只处理第一个分号
          }
        }
      }
    } else {
      # 检查行首是否为控制结构的开始（避免regexp中的{）
      # 步骤1：提取行首的命令关键字
      set cmd ""
      set trimmed_line [string trimleft $line]
      if {[string length $trimmed_line] > 0} {
        # 找到第一个空白位置，提取关键字
        set space_pos [string first " " $trimmed_line]
        if {$space_pos == -1} {
          set cmd $trimmed_line  ;# 整行只有关键字
        } else {
          set cmd [string range $trimmed_line 0 [expr {$space_pos - 1}]]
        }
      }

      # 步骤2：检查关键字是否为控制结构
      if {[lsearch -exact $tcl_commands $cmd] >= 0} {
        # 步骤3：检查行尾是否有{（通过字符串操作替代正则）
        set line_trim_right [string trimright $line]  ;# 去除末尾空白
        if {[string length $line_trim_right] > 0} {
          set last_char [string index $line_trim_right end]
          if {$last_char eq "{"} {
            incr current_control_depth
          }
        }
      }
    }

    # 如果找到有效注释位置，截断#及其后面的内容
    if {$comment_pos != -1} {
      set processed_line [string trimright [string range $line 0 [expr {$comment_pos - 1}]]]
      return [list $processed_line $current_control_depth $current_in_quote $current_quote_char $current_stack]
    }
  }

  return [list $line $control_depth $in_quote $quote_char $stack]
}

# 辅助函数：更新闭合标点栈，同时处理引号状态
proc update_bracket_stack {char stack_var in_quote_var quote_char_var} {
  upvar $stack_var stack
  upvar $in_quote_var in_quote
  upvar $quote_char_var quote_char
  global bracket_pairs

  # 如果已经在引号中，检查是否退出引号
  if {$in_quote} {
    if {$char eq $quote_char} {
      # 检查是否为转义引号
      set escaped 0
      set stack_str [join $stack ""]  ;# 转换栈为字符串便于检查反斜杠
      for {set j [string length $stack_str]-1} {$j >= 0 && [string index $stack_str $j] eq "\\"} {incr j -1} {
        incr escaped
      }
      if {($escaped % 2) == 0} {  ;# 偶数个反斜杠表示未转义
        set in_quote 0
        set quote_char ""
      }
    }
    return
  }

  # 检查是否进入引号
  if {$char eq "\"" || $char eq "'"} {
    set in_quote 1
    set quote_char $char
    return
  }

  # 检查是否为左符号（入栈）
  set left_idx [lsearch -exact $bracket_pairs $char]
  if {$left_idx != -1 && ($left_idx % 2) == 0} {  ;# 左符号索引为偶数
    lappend stack $char
    return
  }

  # 检查是否为右符号（出栈，需匹配栈顶左符号）
  set right_idx [lsearch -exact $bracket_pairs $char]
  if {$right_idx != -1 && ($right_idx % 2) == 1} {  ;# 右符号索引为奇数
    set left_char [lindex $bracket_pairs [expr {$right_idx - 1}]]  ;# 对应的左符号
    if {[llength $stack] > 0 && [lindex $stack end] eq $left_char} {
      set stack [lrange $stack 0 end-1]  ;# 出栈
    }
  }
}

# 辅助函数：检查字符串是否在闭合标点外（栈为空）
proc is_outside_closed_punct {str} {
  global bracket_pairs
  set stack [list]
  set len [string length $str]
  set in_quote 0
  set quote_char ""

  for {set i 0} {$i < $len} {incr i} {
    set char [string index $str $i]
    update_bracket_stack $char stack in_quote quote_char
  }

  return [expr {[llength $stack] == 0 && $in_quote == 0}]
}

# 主处理过程：保持功能不变，优化解析兼容性
proc cat_all {filename {output ""} {verbose 0} {max_depth 10} {exclude ""} {include_comments 1} {preserve_order 1} {strip_comments 3}} {
  # 记录原始工作目录
  set original_dir [file normalize [pwd]]
  # 解析目标文件绝对路径
  set target_file_abs [file normalize $filename]
  if {![file exists $target_file_abs]} {
    puts "Error: Target file not found - $filename"
    return 1
  }
  # 确定目标文件所在目录
  set target_dir [file dirname $target_file_abs]
  set target_file [file tail $target_file_abs]
  # 初始化状态
  CatAll::init_state $original_dir $target_dir
  # 切换到目标文件所在目录进行所有操作
  if {[catch {cd $target_dir} err]} {
    puts "Error: Failed to change to target directory ($target_dir): $err"
    return 1
  }
  # 处理输出文件路径
  if {$output eq ""} {
    set output "all_$target_file"
    set output_path [file join $original_dir $output]
  } else {
    if {[file pathtype $output] eq "relative"} {
      set output_path [file join $original_dir $output]
    } else {
      set output_path $output
    }
  }
  # 初始化状态
  CatAll::init_state $original_dir $target_dir
  # 处理选项参数
  set opts [dict create \
    -verbose $verbose \
    -max_depth $max_depth \
    -exclude [list $exclude] \
    -include_comments $include_comments \
    -preserve_order $preserve_order \
    -output $output_path \
    -strip_comments $strip_comments]
  # 打开输出文件
  if {[catch {set fo [open $output_path w]} err]} {
    puts "Error: Failed to open output file ($output_path): $err"
    CatAll::restore_original_dir
    return 1
  }
  fconfigure $fo -encoding utf-8

  # 递归处理文件，跟踪控制结构状态
  set control_depth 0
  set in_quote 0
  set quote_char ""
  set stack [list]

  if {[catch {
    set result [CatAll::process_file $target_file $fo 0 $opts $control_depth $in_quote $quote_char $stack]
  } err]} {
    puts "Error during processing: $err"
  }

  # 清理操作
  close $fo
  CatAll::restore_original_dir
  if {[dict get $opts -verbose]} {
    puts "Merged file created: $output_path"
  }
  return 0
}

namespace eval CatAll {
  # 处理文件并传递控制结构状态
  proc process_file {filename fo depth opts control_depth in_quote quote_char stack} {
    set max_depth [dict get $opts -max_depth]
    if {$depth > $max_depth} {
      set msg "Maximum recursion depth ($max_depth) reached for $filename"
      puts $fo "# WARNING: $msg"
      if {[dict get $opts -verbose]} {puts "Warning: $msg"}
      return [list $control_depth $in_quote $quote_char $stack]
    }
    # 获取当前工作目录
    set current_dir [pwd]
    set abs_path [file normalize [file join $current_dir $filename]]
    # 检查是否已处理
    if {[is_file_processed $abs_path]} {
      set msg "Skipping already processed file: $filename"
      puts $fo "# $msg"
      if {[dict get $opts -verbose]} {puts $msg}
      return [list $control_depth $in_quote $quote_char $stack]
    }
    # 标记为已处理
    mark_file_processed $abs_path
    set_recursion_depth $abs_path $depth
    # 检查排除模式
    set exclude [dict get $opts -exclude]
    if {$exclude ne "" && [string match $exclude $abs_path]} {
      set msg "Excluded by pattern: $filename"
      puts $fo "# $msg"
      if {[dict get $opts -verbose]} {puts $msg}
      return [list $control_depth $in_quote $quote_char $stack]
    }
    # 检查文件是否存在
    if {![file exists $filename]} {
      set msg "File not found: $filename (resolved to $abs_path)"
      puts $fo "# ERROR: $msg"
      if {[dict get $opts -verbose]} {puts "Error: $msg"}
      return [list $control_depth $in_quote $quote_char $stack]
    }
    # 打开并读取文件
    if {[catch {set fi [open $filename r]} err]} {
      set msg "Failed to open file $filename: $err"
      puts $fo "# ERROR: $msg"
      if {[dict get $opts -verbose]} {puts "Error: $msg"}
      return [list $control_depth $in_quote $quote_char $stack]
    }
    fconfigure $fi -encoding utf-8
    # 写入文件开始标记
    if {[dict get $opts -include_comments]} {
      puts $fo "\n#"
      puts $fo "# START OF FILE: $filename (depth $depth)"
      puts $fo "# Resolved path: $abs_path"
      puts $fo "#"
    }

    # 处理文件内容，跟踪控制结构状态
    set current_control_depth $control_depth
    set current_in_quote $in_quote
    set current_quote_char $quote_char
    set current_stack $stack

    while {[gets $fi line] >= 0} {
      if {[string match "*source*" [string trimleft $line]]} {
        # 处理source命令（用字符串操作替代部分regexp）
        set trimmed_line [string trimleft $line]
        if {[string match "source *" $trimmed_line]} {
          set rest [string range $trimmed_line [string length "source "] end]
          set filename_part [string trimleft $rest]
          # 提取文件名（处理引号和分号）
          set clean_file ""
          if {[string index $filename_part 0] eq "\""} {
            set end_quote [string first "\"" $filename_part 1]
            if {$end_quote != -1} {
              set clean_file [string range $filename_part 1 [expr {$end_quote - 1}]]
            }
          } elseif {[string index $filename_part 0] eq "'"} {
            set end_quote [string first "'" $filename_part 1]
            if {$end_quote != -1} {
              set clean_file [string range $filename_part 1 [expr {$end_quote - 1}]]
            }
          } else {
            # 处理无引号的文件名（去除分号和注释）
            set semicolon_pos [string first ";" $filename_part]
            if {$semicolon_pos != -1} {
              set filename_part [string range $filename_part 0 [expr {$semicolon_pos - 1}]]
            }
            set hash_pos [string first "#" $filename_part]
            if {$hash_pos != -1} {
              set filename_part [string range $filename_part 0 [expr {$hash_pos - 1}]]
            }
            set clean_file [string trim $filename_part]
          }
          if {$clean_file ne ""} {
            # 递归处理source文件
            set result [process_source_line $clean_file $line $fo [expr {$depth + 1}] $opts \
              $current_control_depth $current_in_quote $current_quote_char $current_stack]
            lassign $result current_control_depth current_in_quote current_quote_char current_stack
          }
        } else {
          # 非source命令行，处理注释
          set strip_mode [dict get $opts -strip_comments]
          set result [strip_line_comments $line $strip_mode $current_control_depth $current_in_quote $current_quote_char $current_stack]
          lassign $result processed_line current_control_depth current_in_quote current_quote_char current_stack
          if {$processed_line ne ""} {
            puts $fo $processed_line
          }
        }
      } else {
        # 非source行，处理注释
        set strip_mode [dict get $opts -strip_comments]
        set result [strip_line_comments $line $strip_mode $current_control_depth $current_in_quote $current_quote_char $current_stack]
        lassign $result processed_line current_control_depth current_in_quote current_quote_char current_stack
        if {$processed_line ne ""} {
          puts $fo $processed_line
        }
      }
    }
    close $fi

    # 写入文件结束标记
    if {[dict get $opts -include_comments]} {
      puts $fo "\n#"
      puts $fo "# END OF FILE: $filename (depth $depth)"
      puts $fo "#"
    }

    return [list $current_control_depth $current_in_quote $current_quote_char $current_stack]
  }

  # 处理source行，传递状态
  proc process_source_line {src_file orig_line fo depth opts control_depth in_quote quote_char stack} {
    if {[dict get $opts -include_comments]} {
      puts $fo "\n# SOURCE COMMAND: $orig_line"
      puts $fo "# Resolving: $src_file (from current working directory)"
    }
    # 递归处理source文件
    set result [process_file $src_file $fo $depth $opts $control_depth $in_quote $quote_char $stack]
    return $result
  }
}

# 命令行处理
if {$argc > 0} {
  set filename [lindex $argv 0]
  set options [lrange $argv 1 end]
  # 解析选项参数
  set output ""; set verbose 0; set max_depth 10; set exclude ""; set include_comments 1; set preserve_order 1; set strip_comments 3
  for {set i 0} {$i < [llength $options]} {incr i} {
    set opt [lindex $options $i]
    switch -- $opt {
      "-output" {incr i; set output [lindex $options $i]}
      "-verbose" {incr i; set verbose [lindex $options $i]}
      "-max_depth" {incr i; set max_depth [lindex $options $i]}
      "-exclude" {incr i; set exclude [lindex $options $i]}
      "-include_comments" {incr i; set include_comments [lindex $options $i]}
      "-preserve_order" {incr i; set preserve_order [lindex $options $i]}
      "-strip_comments" {incr i; set strip_comments [lindex $options $i]}
      default {
        puts "Unknown option: $opt"
        exit 1
      }
    }
  }
  # 调用主过程
  cat_all $filename $output $verbose $max_depth $exclude $include_comments $preserve_order $strip_comments
} else {
  puts "Usage: $argv0 filename ?-output outfile? ?-verbose 0|1? ?-max_depth n? ?-exclude pattern? ?-include_comments 0|1? ?-preserve_order 0|1? ?-strip_comments mode?"
  puts "  -strip_comments modes:"
  puts "    0 - 不去除任何注释"
  puts "    1 - 只去除整行注释（#在句首且不在闭合标点内）"
  puts "    2 - 只去除行内注释（#在分号后且两者都不在闭合标点内）"
  puts "    3 - 去除所有符合条件的注释（默认）"
}
