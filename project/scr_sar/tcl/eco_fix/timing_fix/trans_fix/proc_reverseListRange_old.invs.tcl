#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/21 00:56:19 Monday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : Reverse elements in a list with range support and optional recursive sublist reversal
# ref       : link url
# --------------------------
proc reverseListRange {listVar {startIdx ""} {endIdx ""} {deep 0}} {
	# 检查输入列表是否有效
	if {![string is list -strict $listVar]} {
		error "Input is not a valid list: '$listVar'"
	}
	set listLen [llength $listVar]
	# 处理特殊值 "end"
	if {$startIdx eq "end"} {
		set startIdx [expr {$listLen - 1}]
	}
	if {$endIdx eq "end"} {
		set endIdx [expr {$listLen - 1}]
	}
	# 处理索引参数
	if {$startIdx eq ""} {
		set startIdx 0  ;# 默认从第一个元素开始
	} elseif {![string is integer -strict $startIdx]} {
		error "Start index '$startIdx' is not a valid integer or 'end'"
	}
	if {$endIdx eq ""} {
		set endIdx [expr {$listLen - 1}]  ;# 默认到最后一个元素结束
	} elseif {![string is integer -strict $endIdx]} {
		error "End index '$endIdx' is not a valid integer or 'end'"
	}
	# 处理负索引（支持Python风格的负索引）
	if {$startIdx < 0} {
		set startIdx [expr {$listLen + $startIdx}]
	}
	if {$endIdx < 0} {
		set endIdx [expr {$listLen + $endIdx}]
	}
	# 验证索引范围
	if {$startIdx < 0 || $startIdx >= $listLen} {
		error "Start index '$startIdx' out of bounds (list length $listLen)"
	}
	if {$endIdx < 0 || $endIdx >= $listLen} {
		error "End index '$endIdx' out of bounds (list length $listLen)"
	}
	if {$startIdx > $endIdx} {
		error "Start index '$startIdx' is greater than end index '$endIdx'"
	}
	# 执行列表反转
	set result {}
	for {set i 0} {$i < $listLen} {incr i} {
		if {$i >= $startIdx && $i <= $endIdx} {
			set element [lindex $listVar $i]
			if {$deep && [llength $element] > 1 && [string is list -strict $element]} {
				lappend result [reverseListRange $element "" "" $deep]
			} else {
				lappend result $element
			}
		} else {
			lappend result [lindex $listVar $i]
		}
	}
	# 反转指定范围内的元素
	set reversedRange [lreverse [lrange $result $startIdx $endIdx]]
	return [lreplace $result $startIdx $endIdx {*}$reversedRange]
}
