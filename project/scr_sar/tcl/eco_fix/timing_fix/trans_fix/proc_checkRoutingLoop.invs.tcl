#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/21 12:16:50 Monday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : check routing loop in invs
# ref       : link url
# --------------------------
# 判断布线绕圈情况并分级的过程
# 参数:
#   - 直线距离: 两点间的最短距离(um)
#   - 实际线长: 网络的实际走线长度(um)
#   - 严重级别: 可选参数，用于调整各级别的阈值
# 返回值:
#   0: 无绕圈
#   1: 轻微绕圈
#   2: 中度绕圈
#   3: 严重绕圈
#   -1: 输入错误
proc checkRoutingLoop {straightDistance netLength {severityLevel "normal"}} {
	# 错误防御: 检查输入是否为有效数值
	if {![string is double -strict $straightDistance] || $straightDistance <= 0} {
		error "PROC checkRoutingLoop: Invalid parameter 'straightDistance' - must be a positive number ($straightDistance)"
	}
	if {![string is double -strict $netLength] || $netLength <= 0} {
		error "PROC checkRoutingLoop: Invalid parameter 'netLength' - must be a positive number ($netLength)"
	}
	# 将输入参数转换为double类型，确保除法运算精度
	set straightDistance [expr {double($straightDistance)}]
	set netLength [expr {double($netLength)}]
	# 根据严重级别设置阈值
	set thresholds [dict create \
		normal  {1.5 2.0 3.0} \
		relaxed {1.8 2.5 3.5} \
		strict  {1.2 1.8 2.5}
	]
	if {![dict exists $thresholds $severityLevel]} {
		puts "WARNING: Unknown severity level '$severityLevel', using default 'normal'"
		set severityLevel "normal"
	}
	lassign [dict get $thresholds $severityLevel] mildThreshold moderateThreshold severeThreshold
	# 计算线长比
	set lengthRatio [expr {$netLength / $straightDistance}]
	# 判断绕圈等级
	if {$lengthRatio <= $mildThreshold} {
		return 0 ;# No loop
	} elseif {$lengthRatio <= $moderateThreshold} {
		return 1 ;# Mild loop
	} elseif {$lengthRatio <= $severeThreshold} {
		return 2 ;# Moderate loop
	} else {
		return 3 ;# Severe loop
	}
}

# 辅助过程: 获取绕圈等级的文本描述
proc getLoopDescription {loopLevel} {
	switch -- $loopLevel {
		0 { return "No Loop" }
		1 { return "Mild Loop" }
		2 { return "Moderate Loop" }
		3 { return "Severe Loop" }
		default { return "Unknown Level" }
	}
}

# 示例用法
if {0} {
	# 测试案例
	puts "Testing checkRoutingLoop procedure:"
	puts "Straight Distance\tNet Length\tSeverity Level\tLoop Level\tDescription"
	puts "------------------------------------------------------------"

	foreach {dist length level} {
		10.0   12.0   normal
		10.0   18.0   normal
		10.0   22.0   normal
		10.0   35.0   normal
		10.0   12.0   strict
		10.0   12.0   relaxed
		10.0   -5.0   normal
		abc    20.0   normal
	} {
		puts -nonewline "$dist\t\t$length\t\t$level\t\t"
		# 使用错误捕获机制，避免测试时因错误中断
		if {[catch {set result [checkRoutingLoop $dist $length $level]} errMsg]} {
			puts "ERROR: $errMsg"
		} else {
			set desc [getLoopDescription $result]
			puts "$result\t\t$desc"
		}
	}
}
