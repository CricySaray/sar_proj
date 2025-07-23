#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/25
# label     : misc_proc
# descrip   : Merge sourced files with accurate comment stripping (handles semicolon and # in closed punctuation)
# update    : 2025/07/25 15:00:00 Friday
#             Optimized comment detection: # is comment only if after ; and both not in closed punctuation
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
	"{" "}"
	"(" ")"
	"[" "]"
	"\"" "\""  ;# 双引号
	"'" "'"    ;# 单引号
}

# 改进的注释处理函数：仅处理分号后且不在闭合标点内的#注释
proc strip_line_comments {line mode} {
	if {$mode == 0} {
		return $line
	}
	
	# 处理整行注释 (模式1或3)：仅行首（忽略前导空白）是#且不在闭合标点内
	set trimmed [string trimleft $line]
	if {($mode & 1) && [string index $trimmed 0] eq "#"} {
		# 检查整行#是否在闭合标点外（栈为空）
		if {[is_outside_closed_punct $trimmed]} {
			return ""
		}
	}
	
	# 处理行内注释 (模式2或3)：#必须在分号后，且两者都不在闭合标点内
	if {($mode & 2)} {
		set len [string length $line]
		set stack [list]  ;# 跟踪闭合标点的栈（左符号入栈，匹配右符号出栈）
		set semicolon_pos -1  ;# 分号位置（需在闭合标点外）
		set comment_pos -1    ;# #位置（需在分号后且闭合标点外）
		
		for {set i 0} {$i < $len} {incr i} {
			set char [string index $line $i]
			
			# 更新闭合标点栈状态
			update_bracket_stack $char stack
			
			# 栈为空表示不在任何闭合标点内
			if {[llength $stack] == 0} {
				# 记录第一个有效分号位置
				if {$semicolon_pos == -1 && $char eq ";"} {
					set semicolon_pos $i
				}
				# 分号已找到，记录第一个有效#位置
				if {$semicolon_pos != -1 && $comment_pos == -1 && $char eq "#"} {
					set comment_pos $i
					break  ;# 只处理第一个有效#
				}
			}
		}
		
		# 同时找到有效分号和#，截断#及其后面的内容
		if {$comment_pos != -1} {
			return [string trimright [string range $line 0 [expr {$comment_pos - 1}]]]
		}
	}
	
	return $line
}

# 辅助函数：更新闭合标点栈
proc update_bracket_stack {char stack_var} {
	upvar $stack_var stack
	global bracket_pairs
	
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
	for {set i 0} {$i < $len} {incr i} {
		update_bracket_stack [string index $str $i] stack
	}
	return [expr {[llength $stack] == 0}]
}

# 主处理过程（其余代码与之前一致，此处省略以突出核心修改）
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
	# 处理输出文件路径（基于原始目录或指定路径）
	if {$output eq ""} {
		set output "all_$target_file"
		# 输出文件默认放在原始工作目录
		set output_path [file join $original_dir $output]
	} else {
		# 如果输出路径是相对路径，基于原始目录解析
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
	# 开始递归处理
	if {[catch {
		CatAll::process_file $target_file $fo 0 $opts
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
	proc process_file {filename fo depth opts} {
		# 检查递归深度
		set max_depth [dict get $opts -max_depth]
		if {$depth > $max_depth} {
			set msg "Maximum recursion depth ($max_depth) reached for $filename"
			puts $fo "# WARNING: $msg"
			if {[dict get $opts -verbose]} {puts "Warning: $msg"}
			return
		}
		# 获取当前工作目录
		set current_dir [pwd]
		set abs_path [file normalize [file join $current_dir $filename]]
		# 检查是否已处理
		if {[is_file_processed $abs_path]} {
			set msg "Skipping already processed file: $filename"
			puts $fo "# $msg"
			if {[dict get $opts -verbose]} {puts $msg}
			return
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
			return
		}
		# 检查文件是否存在
		if {![file exists $filename]} {
			set msg "File not found: $filename (resolved to $abs_path)"
			puts $fo "# ERROR: $msg"
			if {[dict get $opts -verbose]} {puts "Error: $msg"}
			return
		}
		# 打开并读取文件
		if {[catch {set fi [open $filename r]} err]} {
			set msg "Failed to open file $filename: $err"
			puts $fo "# ERROR: $msg"
			if {[dict get $opts -verbose]} {puts "Error: $msg"}
			return
		}
		fconfigure $fi -encoding utf-8
		# 写入文件开始标记
		if {[dict get $opts -include_comments]} {
			puts $fo "\n#"
			puts $fo "# START OF FILE: $filename (depth $depth)"
			puts $fo "# Resolved path: $abs_path"
			puts $fo "#"
		}
		# 分离source行和普通行
		set source_lines [list]
		set regular_lines [list]
		while {[gets $fi line] >= 0} {
			if {[regexp {^\s*source\s+(\S+)(.*)$} $line -> filename_part remainder]} {
				# 处理带引号的文件名
				if {[string index $filename_part 0] eq "\""} {
					if {[regexp {^"([^"]*)"(.*)$} $filename_part -> clean_file rest]} {
						lappend source_lines [list $clean_file $line]
						continue
					}
				} elseif {[string index $filename_part 0] eq "'"} {
					if {[regexp {^'([^']*)'(.*)$} $filename_part -> clean_file rest]} {
						lappend source_lines [list $clean_file $line]
						continue
					}
				}
				# 处理不带引号的文件名
				set clean_file [string map {";" ""} $filename_part]
				set clean_file [string trimright $clean_file " \t;"]
				if {[string first "#" $clean_file] >= 0} {
					set clean_file [string range $clean_file 0 [expr {[string first "#" $clean_file] - 1}]]
					set clean_file [string trimright $clean_file " \t"]
				}
				lappend source_lines [list $clean_file $line]
			} else {
				lappend regular_lines $line
			}
		}
		close $fi
		# 写入普通行（处理注释）
		set strip_mode [dict get $opts -strip_comments]
		foreach line $regular_lines {
			set processed_line [strip_line_comments $line $strip_mode]
			if {$processed_line ne ""} {
				puts $fo $processed_line
			}
		}
		# 处理source行
		if {[dict get $opts -preserve_order]} {
			foreach item $source_lines {
				lassign $item src_file orig_line
				process_source_line $src_file $orig_line $fo [expr {$depth + 1}] $opts
			}
		} else {
			foreach item [lsort -index 0 $source_lines] {
				lassign $item src_file orig_line
				process_source_line $src_file $orig_line $fo [expr {$depth + 1}] $opts
			}
		}
		# 写入文件结束标记
		if {[dict get $opts -include_comments]} {
			puts $fo "\n#"
			puts $fo "# END OF FILE: $filename (depth $depth)"
			puts $fo "#"
		}
	}
	proc process_source_line {src_file orig_line fo depth opts} {
		if {[dict get $opts -include_comments]} {
			puts $fo "\n# SOURCE COMMAND: $orig_line"
			puts $fo "# Resolving: $src_file (from current working directory)"
		}
		process_file $src_file $fo $depth $opts
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
