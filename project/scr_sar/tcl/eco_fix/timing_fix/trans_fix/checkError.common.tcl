#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/21 14:30:19 Monday
# label     : dev_tool
# descrip   : Check for illegal characters following closed double quotes in Tcl code
# ref       : link url
# --------------------------

	proc string_count {pattern string} {
		set count 0
		set pos 0
		while {[set idx [string first $pattern $string $pos]] >= 0} {
			incr count
			set pos [expr {$idx + 1}]
		}
		return $count
	}

proc checkQuotedStrings {code {legalChars {; ) ,\n]}}} {
	set result {}
	set pos 0
	set len [string length $code]

	while {$pos < $len} {
		# 查找下一个双引号
		set quotePos [string first "\"" $code $pos]
		if {$quotePos == -1} {
			break  ;# 没有更多双引号
		}

		# 检查是否为转义双引号
		set backslashCount 0
		set checkPos [expr {$quotePos - 1}]
		while {$checkPos >= 0 && [string index $code $checkPos] eq "\\"} {
			incr backslashCount
			incr checkPos -1
		}

		# 如果是奇数个反斜杠，则是转义双引号，跳过
		if {$backslashCount % 2 == 1} {
			set pos [expr {$quotePos + 1}]
			continue
		}

		# 找到对应的闭合双引号
		set closePos [string first "\"" $code [expr {$quotePos + 1}]]
		if {$closePos == -1} {
			lappend result [list "Unclosed quote" $quotePos]
			break
		}

		# 检查闭合双引号后的字符
		set nextPos [expr {$closePos + 1}]
		if {$nextPos < $len} {
			set nextChar [string index $code $nextPos]

			# 特殊处理：如果是换行符，检查是否在合法字符列表中
			if {$nextChar eq "\n" && [string first "\n" $legalChars] == -1} {
				# 获取行号（闭合引号所在行）
				set lineNum [expr {[string_count "\n" [string range $code 0 $closePos]] + 1}]

				# 获取错误上下文
				set contextStart [expr {max(0, $closePos - 20)}]
				set contextEnd [expr {min($len - 1, $closePos + 10)}]  ;# 减少换行后的字符，避免显示过多
				set context [string range $code $contextStart $contextEnd]

				lappend result [list "Illegal newline after quote" $lineNum $closePos $context]
			}

			# 检查其他字符
			if {$nextChar ne "\n" && ![string match -nocase -- [$nextChar] [$legalChars]]} {
				# 获取行号
				set lineNum [expr {[string_count "\n" [string range $code 0 $closePos]] + 1}]

				# 获取错误上下文
				set contextStart [expr {max(0, $closePos - 20)}]
				set contextEnd [expr {min($len - 1, $closePos + 20)}]
				set context [string range $code $contextStart $contextEnd]

				lappend result [list "Illegal character '$nextChar' after quote" $lineNum $closePos $context]
			}
		}

		# 继续查找下一个双引号
		set pos [expr {$closePos + 1}]
	}

	return $result
}

# 辅助函数：标记错误位置（纯文本方式）
proc highlightError {context pos} {
	set pre [string range $context 0 [expr {$pos - 1}]]
	set err [string range $context $pos $pos]
	set post [string range $context [expr {$pos + 1}] end]

	# 特殊处理换行符显示
	if {$err eq "\n"} {
		set err "\\n"
		set post "\n[Next line] [string range $post 0 20]"
	}

	return "${pre}[ERROR:${err}]${post}"
}

# 主程序：读取文件并检查
if {$argc > 0} {
	set filename [lindex $argv 0]
	if {![file exists $filename]} {
		puts "Error: File '$filename' does not exist"
		exit 1
	}

	set code [read [open $filename]]
	set errors [checkQuotedStrings $code]

	if {[llength $errors] == 0} {
		puts "No errors found!"
	} else {
		puts "Found [llength $errors] potential errors:"
		foreach error $errors {
			lassign $error message line pos context
			puts "Line $line: $message"
			puts "  Context: [highlightError $context [expr {$pos - [string first $context $code]}]]"
			puts ""
		}
	}
} else {
	puts "Usage: tclsh check_quoted.tcl <filename>"
}
