#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/21 03:07:46 Monday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : Convert decimal between 0-1 to fixed-length string starting with '0'
# ref       : link url
# --------------------------
alias fm "formatDecimal"
proc formatDecimal {value {fixedLength 2} {strictRange 1} {padZero 1}} {
	# 错误防御：验证输入是否为有效小数
	if {![string is double -strict $value]} {
		error "Invalid input: '$value' is not a valid decimal number"
	}
	# 错误防御：验证数值范围
	if {$strictRange && ($value <= 0.0 || $value >= 1.0)} {
		error "Value must be between 0 and 1 (exclusive)"
	}
	# 转换为字符串并移除前导0和小数点
	set strValue [string map {"0." ""} [format "%.15g" $value]]
	# 处理特殊情况：纯零值（如0.000）
	if {$strValue eq ""} {
		if {$padZero} {
			# 确保至少有一个0（加上前缀0后长度为2）
			return "0[string repeat "0" [expr {$fixedLength - 1}]]"
		} else {
			return "0"
		}
	}
	# 确保字符串以0开头，并应用固定长度
	if {$fixedLength > 0} {
		# 计算需要的剩余长度（包括前缀0）
		set remainingLength [expr {$fixedLength - 1}]

		if {$remainingLength <= 0} {
			# 至少保留前缀0
			return "0"
		}
		if {$padZero} {
			# 补零至剩余长度
			set paddedValue [string range [format "%0*s" $remainingLength $strValue] 0 $remainingLength-1]
		} else {
			# 直接截断
			set paddedValue [string range $strValue 0 $remainingLength-1]
		}
		return "0$paddedValue"
	} else {
		# 不限制长度时，直接添加前缀0
		return "0$strValue"
	}
}
