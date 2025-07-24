#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/24
# label     : misc_proc
# descrip   : Merge sourced files with improved source line parsing and comment stripping
# update    : 2025/07/23 11:02:14 Wednesday
#             Adjusted for source line parsing with comments
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
# 改进的注释处理函数，正确处理引号和分号
proc strip_line_comments {line mode} {
	if {$mode == 0} {
		return $line
	}
	
	# 处理整行注释 (模式1或3)
	set trimmed [string trimleft $line]
	if {($mode & 1) && [string index $trimmed 0] eq "#"} {
		return ""
	}
	
	# 处理行内注释 (模式2或3)
	if {($mode & 2)} {
		set len [string length $line]
		set in_quote 0
		set quote_char ""
		set last_semicolon -1
		
		for {set i 0} {$i < $len} {incr i} {
			set char [string index $line $i]
			
			# 检查引号状态
			if {!$in_quote && ($char eq "\"" || $char eq "'")} {
				set in_quote 1
				set quote_char $char
			} elseif {$in_quote && $char eq $quote_char} {
				# 检查是否为转义引号
				set escaped 0
				for {set j $i-1} {$j >= 0 && [string index $line $j] eq "\\"} {incr j -1} {
					incr escaped
				}
				
				if {($escaped % 2) == 0} {  ;# 偶数个反斜杠表示未转义
					set in_quote 0
				}
			}
			
			# 记录最后一个不在引号内的分号
			if {!$in_quote && $char eq ";"} {
				set last_semicolon $i
			}
		}
		
		# 如果找到分号，移除分号及后面的所有内容
		if {$last_semicolon >= 0} {
			return [string trimright [string range $line 0 [expr {$last_semicolon - 1}]]]
		}
	}
	
	return $line
}
# 主处理过程
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
		-strip_comments $strip_comments]  ;# 新增注释处理选项
	# 打开输出文件
	if {[catch {set fo [open $output_path w]} err]} {
		puts "Error: Failed to open output file ($output_path): $err"
		CatAll::restore_original_dir
		return 1
	}
	fconfigure $fo -encoding utf-8
	# 开始递归处理（此时已在目标目录，使用相对路径）
	if {[catch {
		CatAll::process_file $target_file $fo 0 $opts
	} err]} {
		puts "Error during processing: $err"
	}
	# 清理操作
	close $fo
	CatAll::restore_original_dir  ;# 确保切回原始目录
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
		# 获取当前工作目录（已切换到目标目录）
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
		if {![file exists $filename]} {  ;# 基于当前工作目录（目标目录）检查
			set msg "File not found: $filename (resolved to $abs_path)"
			puts $fo "# ERROR: $msg"
			if {[dict get $opts -verbose]} {puts "Error: $msg"}
			return
		}
		# 打开并读取文件
		if {[catch {set fi [open $filename r]} err]} {  ;# 基于当前工作目录打开
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
			# 改进的source命令解析，处理注释和分号
			if {[regexp {^\s*source\s+(\S+)(.*)$} $line -> filename_part remainder]} {
				# 处理带引号的文件名
				if {[string index $filename_part 0] eq "\""} {
					# 双引号文件名
					if {[regexp {^"([^"]*)"(.*)$} $filename_part -> clean_file rest]} {
						lappend source_lines [list $clean_file $line]
						continue
					}
				} elseif {[string index $filename_part 0] eq "'"} {
					# 单引号文件名
					if {[regexp {^'([^']*)'(.*)$} $filename_part -> clean_file rest]} {
						lappend source_lines [list $clean_file $line]
						continue
					}
				}
				# 处理不带引号的文件名（移除分号和注释）
				set clean_file [string map {";" ""} $filename_part]
				set clean_file [string trimright $clean_file " \t;"]
				# 检查是否有注释
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
			if {$processed_line ne ""} {  ;# 跳过空行（原整行注释）
				puts $fo $processed_line
			}
		}
		# 处理source行（已在目标目录，直接使用相对路径）
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
		# 写入source命令标记
		if {[dict get $opts -include_comments]} {
			puts $fo "\n# SOURCE COMMAND: $orig_line"
			puts $fo "# Resolving: $src_file (from current working directory)"
		}
		# 递归处理（此时已在目标目录，直接使用相对路径）
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
			"-strip_comments" {incr i; set strip_comments [lindex $options $i]}  ;# 新增选项
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
	puts "    1 - 只去除整行注释（以#开头的行）"
	puts "    2 - 只去除行内注释（代码后的#注释）"
	puts "    3 - 去除所有注释（整行和行内注释，默认）"
}
