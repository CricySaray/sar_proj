#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/16 19:17:29 Wednesday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : logic or(lo) / logic and(la) (string comparition): check if variable is equaled to string
# update    : 2025/07/16 23:18:45 Wednesday
#             add ol/al proc: check empty string or zero value
# update    : 2025/07/17 10:11:36 Thursday
#             add eo proc: judge if the first arg is empty string or number 0. advanced version of [expr $test ? trueValue : falseValue ]
#             it(eo) can input string and the trueValue and falseValue can also be string
# ref       : link url
# --------------------------

# (la = Logic AND)
#  la $var1 "value1" $var2 "value2" ...
proc la {args} {
	if {[llength $args] == 0} {
		error "la: requires at least one argument"; # error command , you can try it 
	}
	if {[llength $args] % 2 != 0} {
		error "la: requires arguments in pairs: variable value"
	}
	for {set i 0} {$i < [llength $args]} {incr i 2} {
		set varName [lindex $args $i]
		set expectedValue [lindex $args [expr {$i+1}]]
		if {$varName ne $expectedValue} {
			return 0  ;# 不匹配，立即返回假
		}
	}
	return 1  ;# 全部匹配，返回真
}

# (lo = Logic OR)
#  lo $var1 "value1" $var2 "value2" ...
proc lo {args} {
	if {[llength $args] == 0} {
		error "lo: requires at least one argument"
	}
	if {[llength $args] % 2 != 0} {
		error "lo: requires arguments in pairs: variable value"
	}
	for {set i 0} {$i < [llength $args]} {incr i 2} {
		set varName [lindex $args $i]
		set expectedValue [lindex $args [expr {$i+1}]]
		if {$varName eq $expectedValue} {
			return 1  ;# 匹配，立即返回真
		}
	}
	return 0  ;# 全部不匹配，返回假
}

# (al = AND Logic for arbitrary number of arguments)
#  al $arg1 $arg2 ...
proc al {args} {
	if {[llength $args] == 0} {
		error "al: requires at least one argument"
	}

	foreach arg $args {
		if {$arg eq "" || ([string is integer -strict $arg] && $arg == 0)} {
			return 0  ;# 遇到空字符串或值为0的整数字符串，立即返回假
		}
	}

	return 1  ;# 所有参数都满足条件，返回真
}

# (ol = OR Logic for arbitrary number of arguments)
#  ol $arg1 $arg2 ...
proc ol {args} {
	if {[llength $args] == 0} {
		error "ol: requires at least one argument"
	}

	foreach arg $args {
		if {$arg ne "" && (![string is integer -strict $arg] || $arg != 0)} {
			return 1  ;# 遇到非空字符串，且不是值为0的整数字符串，立即返回真
		}
	}

	return 0  ;# 所有参数都不满足条件，返回假
}

proc re {args} {
	# 支持多种调用方式：
	# 1. re <value>         - 直接取反单个值
	# 2. re -list <list>    - 对列表中每个元素取反
	# 3. re -dict <dict>    - 对字典中每个值取反
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
	# 处理剩余参数
	if {[info exist list]} {
		# 列表模式：对每个元素取反
		return [lmap item $list {expr {![_to_boolean $item]}}]
	} elseif {[info exist dict]} {
		# 字典模式：对每个值取反
		if {[llength $args] != 1} {
			error "Dictionary mode requires exactly one dictionary argument"
		}
		set resultDict [dict create]
		dict for {key value} [lindex $dict 0] {
			dict set resultDict $key [expr {![_to_boolean $value]}]
		}
		return $resultDict
	} else {
		# 单值模式：直接取反
		if {[llength $args] != 1} {
			error "Single value mode requires exactly one argument"
		}
		return [expr {![_to_boolean [lindex $args 0]]}]
	}
}
# TODO(FIXED) : 这里设置了option，但是假如没有写option，直接写了值或者字符串，该如何解析？
define_proc_arguments re \
  -info ":re ?-list|-dict? value(s) - Logical negation of values"\
  -define_args {
	  {value "boolean value" "" boolean optional}
    {-list "list mode" AList list optional}
    {-dict "dict mode" ADict list optional}
  }

# 内部辅助函数：将各种类型的值转换为布尔值
proc _to_boolean {value} {
	switch -exact -- [string tolower $value] {
		"1" - "true" - "yes" - "on" { return 1 }
		"0" - "false" - "no" - "off" { return 0 }
		default {
			# 尝试将数值字符串转换为布尔值
			if {[string is integer -strict $value]} {
				return [expr {$value != 0}]
			}
			# 其他情况视为无效值
			error "Cannot convert '$value' to boolean"
		}
	}
}

# test if firstArg is unempty string or non-zero number
#     if it is, return secondArg(trueValue)
#     if it is not , return thirdArg(falseValue)
alias eo "ifEmptyZero"
proc ifEmptyZero {value trueValue falseValue} {
    # 错误检查：使用 [info level 0] 获取当前过程的参数数量
    if {[llength [info level 0]] != 4} {
        error "Usage: ifEmptyZero value trueValue falseValue"
    }
    # 处理空值或空白字符串
    if {$value eq "" || [string trim $value] eq ""} {
        return $falseValue
    }
    # 尝试将值转换为数字进行判断
    set numericValue [string is double -strict $value]
    if {$numericValue} {
        # 数值为0时返回falseValue
        if {[expr {$value == 0}]} {
            return $falseValue
        }
    } elseif {$value eq "0"} {
        # 字符串"0"返回falseValue
        return $falseValue
    }
    # 其他情况返回trueValue
    return $trueValue
}

# test if firstArg is unempty string or non-zero number
#     if it is, return secondArg(trueScript)
#     if it is not , return thirdArg(falseScript)
alias er "ifEmptyZeroRUN"
proc ifEmptyZeroRUN {value trueScript falseScript} {
    # 错误检查：使用 [info level 0] 获取当前过程的参数数量
    if {[llength [info level 0]] != 4} {
        error "Usage: ifEmptyZero value trueScript falseScript"
    }
    # 处理空值或空白字符串
    if {$value eq "" || [string trim $value] eq ""} {
        return [uplevel 1 $falseScript]
    }
    # 尝试将值转换为数字进行判断
    set numericValue [string is double -strict $value]
    if {$numericValue} {
        # 数值为0时返回falseScript
        if {[expr {$value == 0}]} {
            return [uplevel 1 $falseScript]
        }
    } elseif {$value eq "0"} {
        # 字符串"0"返回falseScript
        return [uplevel 1 $falseScript]
    }
    # 其他情况返回trueScript
    return [uplevel 1 $trueScript]
}

