#!/bin/tclsh
# --------------------------
# author    : Enhanced by Doubao
# date      : 2025/07/21
# label     : misc_proc
# descrip   : Recursively merge all sourced files into a single output file with configurable options
# --------------------------
# 递归深度计数器
array set recursion_depth {}
# 主处理过程 - 支持递归合并所有source文件
proc cat_all {args} {
  set filename [lindex $args 0]
  set verbose 0
  set max_depth 10
  set exclude_patterns [list ]
  set include_comments 1
  set preserve_order 1
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
  if {![info exists output]} {
    set output "all_[file tail $filename]"
  }
	set opts [dict create]
	dict set opts -output $output
	dict set opts -verbose $verbose
	dict set opts -max_depth $max_depth
	dict set opts -exclude_patterns $exclude_patterns
	dict set opts -include_comments $include_comments
	dict set opts -preserve_order $preserve_order

	# 初始化已处理文件记录
	array set processed_files {}
	# 打开输出文件
	set fo [open $output w]
	fconfigure $fo -encoding utf-8
	# 递归处理源文件
	set base_dir [file dirname [file normalize $filename]]
	process_file $filename $fo $base_dir 0 processed_files $opts
	# 关闭输出文件
	close $fo
	if {[dict get $opts -verbose]} {
		puts "Merged file created: $output_file"
	}
}
define_proc_arguments cat_all \
  -info "cat all sourced file to one file" \
  -define_args {
    {inputfilename "specify input filename" AString string required}
    {-output "output file name (default: all_<input>)" AString string optional}
    {-verbose "Enable verbose output (default: 0)" "" boolean optional}
    {-max_depth "Maximum recursion depth (default: 10)" Aint int optional}
    {-exclude "Exclude files matching glob pattern" AString string optional}
    {-include_comments "Do not include file boundary comments(default: 1)" Aint int optional}
    {-preserve_order "Process sourced files in preserve order(default: 1)" Aint int optional}
  }


# 递归处理单个文件
proc process_file {filename fo base_dir depth processed_files opts} {
	upvar $processed_files proc_files
	# 检查递归深度限制
	if {$depth > [dict get $opts -max_depth]} {
		if {[dict get $opts -verbose]} {
			puts "Warning: Maximum recursion depth ($depth) reached for $filename"
		}
		puts $fo "# WARNING: Recursion depth limit reached for $filename"
		return
	}
	# 规范化文件名
	set abs_path [file normalize [file join $base_dir $filename]]
	# 检查文件是否已处理（防止循环引用）
	if {[info exists proc_files($abs_path)]} {
		if {[dict get $opts -verbose]} {
			puts "Skipping already processed file: $abs_path"
		}
		puts $fo "# Skipping already processed file: $filename"
		return
	}
	# 标记文件为已处理
	set proc_files($abs_path) 1
	# 检查排除模式
	foreach pattern [dict get $opts -exclude_patterns] {
		if {[string match $pattern $abs_path]} {
			if {[dict get $opts -verbose]} {
				puts "Excluding file based on pattern: $abs_path"
			}
			puts $fo "# Excluded by pattern: $filename"
			return
		}
	}
	# 尝试打开文件
	if {![file exists $abs_path]} {
		puts $fo "# ERROR: File not found: $filename"
		if {[dict get $opts -verbose]} {
			puts "Error: File not found: $abs_path"
		}
		return
	}
	if {[catch {set fi [open $abs_path r]} err]} {
		puts $fo "# ERROR: Cannot open file $filename: $err"
		if {[dict get $opts -verbose]} {
			puts "Error: Cannot open file $abs_path: $err"
		}
		return
	}
	fconfigure $fi -encoding utf-8
	# 记录当前文件的递归深度
	global recursion_depth
	set recursion_depth($abs_path) $depth
	if {[dict get $opts -include_comments]} {
		puts $fo ""
		puts $fo "#"
		puts $fo "# START OF FILE: $filename (depth $depth)"
		puts $fo "# Path: $abs_path"
		puts $fo "#"
	}
	# 存储source行以便后续处理（保持顺序）
	set source_lines [list]
	set regular_lines [list]
	# 逐行处理文件内容
	while {[gets $fi line] >= 0} {
		if {[regexp {^\s*source\s+([^\s;]+)} $line -> src_file]} {
			lappend source_lines [list $src_file $line]
		} elseif {[regexp {^\s*source\s+([^\s;]+);} $line -> src_file]} {
			lappend source_lines [list $src_file $line]
		} else {
			lappend regular_lines $line
		}
	}
	# 关闭输入文件
	close $fi
	# 写入非source行
	foreach line $regular_lines {
		puts $fo $line
	}
	# 递归处理source行
	if {[dict get $opts -preserve_order]} {
		# 按原始文件中的顺序处理
		foreach item $source_lines {
			lassign $item src_file orig_line
			process_source_line $src_file $orig_line $fo $base_dir $depth $processed_files $opts
		}
	} else {
		# 先处理内层文件（可能提高性能）
		foreach item [lsort -index 0 $source_lines] {
			lassign $item src_file orig_line
			process_source_line $src_file $orig_line $fo $base_dir $depth $processed_files $opts
		}
	}
	if {[dict get $opts -include_comments]} {
		puts $fo ""
		puts $fo "#"
		puts $fo "# END OF FILE: $filename (depth $depth)"
		puts $fo "#"
	}
}
# 处理单个source行
proc process_source_line {src_file orig_line fo base_dir depth processed_files opts} {
	upvar $processed_files proc_files
	# 移除引号和其他可能的包装字符
	set clean_file [string map {"'" "" "\"" ""} $src_file]
	if {[dict get $opts -include_comments]} {
		puts $fo ""
		puts $fo "# SOURCE COMMAND: $orig_line"
	}
	# 计算新的基准目录
	if {[file pathtype $clean_file] eq "relative"} {
		set new_base_dir [file dirname [file join $base_dir $clean_file]]
	} else {
		set new_base_dir [file dirname $clean_file]
	}
	# 递归处理源文件
	process_file $clean_file $fo $new_base_dir [expr {$depth + 1}] $processed_files $opts
}
# 示例用法
puts $argc
if {$argc > 0} {
	set filename [lindex $argv 0]
	set options [lrange $argv 1 end]
	cat_all $filename $options
} else {
	puts "Usage: $argv0 filename ?-option value ...?"
	puts "Options:"
	puts "  -output <filename>    Output file name (default: all_<input>)"
	puts "  -verbose 1|0          Enable verbose output (default: 0)"
	puts "  -max_depth <n>        Maximum recursion depth (default: 10)"
	puts "  -exclude <pattern>    Exclude files matching glob pattern"
	puts "  -no_comments          Do not include file boundary comments"
	puts "  -random_order         Process sourced files in random order"
}

