#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/08/05 10:06:25 Tuesday
# label     : datatype_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|misc_proc)
# descrip   : stringstore procs handle long string storage by generating formatted IDs, maintain 
#             string-ID mappings, and support operations like querying, retrieval, and data clearing.
# action procs : stringstore:: (init/process/get_id/get_string/clear/size/get_max_length/set_max_length/get_all)
# return    : /
# mini descip: stringstore/ss::init/process/get_id/get_string/clear/size/get_max_length/set_max_length/get_all
# ref       : link url
# --------------------------
# String storage and management package with simplified access
namespace eval stringstore {
  # Private variables
  variable store_str  ;# Maps strings to their IDs
  variable store_id   ;# Maps IDs to their strings
  variable next_id 1  ;# Next available ID number
  variable max_len 0  ;# Maximum allowed length for unmodified strings
  # Character mapping table: 0-9 followed by A-Z (total 36 characters)
  variable chars "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

  # Initialize the package
  proc ss_init {max_length} {
    variable store_str
    variable store_id
    variable next_id
    variable max_len
    
    # Validate max_length is a positive integer
    if {![string is integer -strict $max_length] || $max_length <= 0} {
      error "Invalid maximum length: must be a positive integer"
    }
    
    # Clear any existing data and initialize
    array unset store_str
    array unset store_id
    set next_id 1
    set max_len $max_length
    return 1
  }
  # Helper function: Generate ID that conforms to the new rules
  proc ss_generate_id {num} {
    variable chars
    
    # Calculate the index of the last character (0-35 corresponds to 0-9, A-Z)
    set last_char_idx [expr {($num - 1) % 36}]
    set last_char [string index $chars $last_char_idx]
    
    # Calculate the first four-digit part (starting from 0000)
    set prefix_num [expr {int(($num - 1) / 36)}]
    set prefix [format "%04d" $prefix_num]
    
    # Combine into a complete ID
    return "S${prefix}${last_char}"
  }

  # Process a string - main functionality
  proc ss_process {str} {
    variable store_str
    variable store_id
    variable next_id
    variable max_len
    
    # Check if package is initialized
    if {$max_len == 0} {
      error "Package not initialized. Call init first."
    }
    
    # Validate input is a string
    if {![string is list $str]} {
      error "Invalid input: must be a single string"
    }
    
    # If string is within allowed length, return it
    if {[string length $str] <= $max_len} {
      return $str
    }
    
    # If string already stored, return its ID
    if {[info exists store_str($str)]} {
      return $store_str($str)
    }
    
    # Generate new ID
    set id [generate_id $next_id]
    
    # Store the string with its ID
    set store_str($str) $id
    set store_id($id) $str
    
    # Increment next ID
    incr next_id
    
    return $id
  }

  # Get ID for a stored string
  proc ss_get_id {str} {
    variable store_str
    variable max_len
    
    # Check if package is initialized
    if {$max_len == 0} {
      error "Package not initialized. Call init first."
    }
    
    # Check if string exists in store
    if {[info exists store_str($str)]} {
      return $store_str($str)
    }
    
    # Return empty string if not found (easily distinguishable)
    return ""
  }

  # modify ID format validation in the get_string procedure
  proc ss_get_string {id} {
    variable store_id
    variable max_len
    
    # Check if package is initialized
    if {$max_len == 0} {
      error "Package not initialized. Call init first."
    }
    
    # New ID format validation: S + 4 digits + 1 character (digit or uppercase letter)
    if {![regexp {^S\d[0-9A-Z]{4}$} $id]} {
      error "Invalid ID format. Must be S followed by 4 digits and 1 alphanumeric (e.g., S00001, S0000A)"
    }
    
    # Check if ID exists in store
    if {[info exists store_id($id)]} {
      return $store_id($id)
    }
    
    # Return nothing if not found
    return
  }

  # Clear all stored data
  proc ss_clear {} {
    variable store_str
    variable store_id
    variable next_id
    
    array unset store_str
    array unset store_id
    set next_id 1
    return 1
  }

  # Get current storage size
  proc ss_size {} {
    variable store_str
    return [array size store_str]
  }

  # Get maximum allowed length
  proc ss_get_max_length {} {
    variable max_len
    return $max_len
  }

  # Set new maximum allowed length
  proc ss_set_max_length {new_max} {
    variable max_len
    
    if {![string is integer -strict $new_max] || $new_max <= 0} {
      error "Invalid maximum length: must be a positive integer"
    }
    
    set max_len $new_max
    return $new_max
  }

  # New: Get all stored content
  proc ss_get_all {} {
    variable store_id
    variable max_len
    
    # Check if package is initialized
    if {$max_len == 0} {
      error "Package not initialized. Call init first."
    }
    
    set result [list]
    # Iterate through all ID-string pairs
    foreach id [array names store_id] {
      lappend result [list $id $store_id($id)]
    }
    
    return [lsort -index 0 -increasing $result]
  }
  namespace export *
}
package provide stringstore 1.1

if {0} { ; # this will run error when wrap it using namespace
  # Create namespace alias "ss" for "stringstore"
  namespace eval ss {
    namespace import stringstore::*
  }

  # Create global procedures with "ss_" prefix for even simpler access
  proc ss_init {max_length} {
    return [stringstore::init $max_length]
  }

  proc ss_process {str} {
    return [stringstore::process $str]
  }

  proc ss_get_id {str} {
    return [stringstore::get_id $str]
  }

  proc ss_get_string {id} {
    return [stringstore::get_string $id]
  }

  proc ss_clear {} {
    return [stringstore::clear]
  }

  proc ss_size {} {
    return [stringstore::size]
  }

  proc ss_get_max_length {} {
    return [stringstore::get_max_length]
  }

  proc ss_set_max_length {new_max} {
    return [stringstore::set_max_length $new_max]
  }
  # Add corresponding function for global proc
  proc ss_get_all {} {
    return [stringstore::get_all]
  }

    
}


if {0} {
  # 加载包
  package require stringstore

  # 三种初始化方式（效果完全相同）
  stringstore::ss_init 10   ;# 原始方式
  #ss_init 10            ;# 短命名空间方式
  ss_init 10             ;# 全局过程方式

  # 处理字符串的三种方式
  puts [stringstore::ss_process "short"]       ;# 输出: short
  puts [ss_process "this is long"]         ;# 输出: S00001
  puts [ss_process "this is long too"]      ;# 输出: S00002
  puts [ss_process "sjdlfksjldfjsld jsldf jsdlf "]
  puts [ss_process "sjdlfksjldfjsld sldf jsdlf "]
  puts [ss_process "sdlfksjldfjsld sldf jsdlf "]
  puts [ss_process "sjlfksjldfjsldjsldf jsdlf "]
  puts [ss_process "sjlfksjldfjsl jsldf jsdlf "]
  puts [ss_process "sjlfksjldfjsd jsldf jsdlf "]
  puts [ss_process "sjlfksjldfjld jsldf jsdlf "]
  puts [ss_process "sjlfksjldfsld jsldf jsdlf "]
  puts [ss_process "sjlfksjldjsld jsldf jsdlf "]
  puts [ss_process "sjlfksjlfjsld jsldf jsdlf "]
  puts [ss_process "sjlfksjdfjsld jsldf jsdlf "]
  puts [ss_process "sjdlfkldfjsld jsldf jsdlf "]

puts "porint ----------"

  # 获取ID的三种方式
  puts [stringstore::ss_get_id "this is long"] ;# 输出: S00001
  puts [ss_get_id "this is long too"]      ;# 输出: S00002
  puts [ss_get_id "unknown"]                ;# 输出: （空字符串）

puts "[ss_get_string "S0000C"]"

  # 获取原始字符串的三种方式
puts "----------------------"
  puts [stringstore::ss_get_string "S00001"]   ;# 输出: this is long
  puts [ss_get_string "S00002"]            ;# 输出: this is long too
  puts "S99999 : [ss_get_string "S99999"]"             ;# 输出: （无输出）

  # 其他操作示例
  ss_set_max_length 15
  puts "当前最大长度: [ss_get_max_length]"  ;# 输出: 当前最大长度: 15
  puts "存储的字符串数量: [ss_size]"        ;# 输出: 存储的字符串数量: 2

  ss_clear
  puts "清空后数量: [ss_size]"             ;# 输出: 清空后数量: 0
}
