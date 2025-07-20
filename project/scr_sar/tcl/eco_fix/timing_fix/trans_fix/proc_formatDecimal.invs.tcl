#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/21 01:33:31 Monday
# label     : misc_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : Convert decimal between 0-1 to fixed-length string without leading zero and dot
# ref       : link url
# --------------------------
alias fm "formatDecimal"
proc formatDecimal {value {fixedLength 0} {strictRange 1} {padZero 1}} {
  # 错误防御：验证输入是否为有效小数
  if {![string is double -strict $value]} {
    error "Invalid input: '$value' is not a valid decimal number"
  }
  # 错误防御：验证数值范围
  if {$strictRange && ($value <= 0.0 || $value >= 1.0)} {
    error "Value must be between 0 and 1 (exclusive)"
  }
  # 转换为字符串并移除前导0和小数点
  set strValue [string map({"0." ""}) [format "%.15g" $value]]
  # 处理特殊情况：纯零值（如0.000）
  if {$strValue eq ""} {
    if {$padZero} {
      return [string repeat "0" $fixedLength]
    } else {
      return "0"
    }
  }
  # 应用固定长度（如果指定）
  if {$fixedLength > 0} {
    if {$padZero} {
      # 不足补零，超过截断
      return [string range [format "%0*s" $fixedLength $strValue] 0 $fixedLength-1]
    } else {
      # 直接截断
      return [string range $strValue 0 $fixedLength-1]
    }
  }
  return $strValue
}
