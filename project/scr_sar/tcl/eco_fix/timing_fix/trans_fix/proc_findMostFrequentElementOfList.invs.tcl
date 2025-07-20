#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/20 23:35:41 Sunday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : Find the most frequent element in a list with frequency threshold
# ref       : link url
# --------------------------
proc findMostFrequentElement {inputList {minPercentage 50.0} {returnUnique 1}} {
	# 检查输入是否为有效列表
	set listLength [llength $inputList]
	if {$listLength == 0} {
		error "proc findMostFrequentElement: input list is empty!!!"
	}
	# 创建哈希表统计每个元素的出现次数
	array set count {}
	foreach element $inputList {
		incr count($element)
	}
	# 找出最大出现次数
	set maxCount 0
	foreach element [array names count] {
		if {$count($element) > $maxCount} {
			set maxCount $count($element)
		}
	}
	# 计算最大频率百分比
	set frequencyPercentage [expr {($maxCount * 100.0) / $listLength}]
	# 检查是否达到最小百分比阈值
	if {$frequencyPercentage < $minPercentage} {
		if {$returnUnique} {
			return [lsort -unique $inputList]  ;# 返回唯一元素列表
		} else {
			return ""  ;# 未达到阈值且不返回唯一元素时返回空字符串
		}
	}
	# 收集所有达到最大次数的元素
	set mostFrequentElements {}
	foreach element [array names count] {
		if {$count($element) == $maxCount} {
			lappend mostFrequentElements $element
		}
	}
	# 如果有多个元素出现次数相同，返回第一个遇到的元素
	return [lindex $mostFrequentElements 0]
}
