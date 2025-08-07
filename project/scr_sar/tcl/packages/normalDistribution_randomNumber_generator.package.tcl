proc generate_normal {{min -0.050} {max -0.001} {count 1} {mean -0.025} {stddev 0.01} {force_seed ""}} {
  # Validate input parameters
  if {![string is double -strict $min]} {
    error "Invalid minimum value: must be a number"
  }
  if {![string is double -strict $max]} {
    error "Invalid maximum value: must be a number"
  }
  if {$min >= $max} {
    error "Minimum value must be less than maximum value"
  }
  if {![string is integer -strict $count] || $count < 1} {
    error "Count must be a positive integer"
  }
  if {![string is double -strict $mean]} {
    error "Mean must be a number"
  }
  if {$mean <= $min || $mean >= $max} {
    error "Mean must be within the range ($min to $max)"
  }
  if {![string is double -strict $stddev] || $stddev <= 0} {
    error "Standard deviation must be a positive number"
  }
  if {$force_seed ne "" && ![string is integer -strict $force_seed]} {
    error "Force seed must be an integer"
  }
  
  # Initialize random seed
  if {$force_seed ne ""} {
    expr {srand($force_seed)}
  } elseif {[expr {rand()}] == 0.0} {
    expr {srand([clock seconds])}
  }
  
  set result [list]
  set attempts 0
  set max_attempts [expr {$count * 100}] ;# Prevent infinite loop
  
  # Box-Muller transform variables
  set has_spare 0
  set spare 0.0
  
  while {[llength $result] < $count && $attempts < $max_attempts} {
    incr attempts
    
    # Generate normal distribution using Box-Muller transform
    if {$has_spare} {
      set has_spare 0
      set normal_val $spare
    } else {
      set u 0.0
      set v 0.0
      # Generate two uniform numbers in (0,1]
      while {$u == 0.0} { set u [expr {rand()}] }
      while {$v == 0.0} { set v [expr {rand()}] }
      
      set mag [expr {sqrt(-2.0 * log($u))}]
      set z0 [expr {$mag * cos(2.0 * 3.141592653589793 * $v)}]
      set z1 [expr {$mag * sin(2.0 * 3.141592653589793 * $v)}]
      
      set normal_val $z0
      set spare $z1
      set has_spare 1
    }
    
    # Scale to desired mean and standard deviation
    set value [expr {$normal_val * $stddev + $mean}]
    
    # Round to 3 decimal places
    set value [expr {round($value * 1000) / 1000.0}]
    
    # Check if value is within range
    if {$value >= $min && $value <= $max} {
      lappend result $value
    }
  }
  
  if {[llength $result] < $count} {
    error "Could not generate enough values within range after $max_attempts attempts"
  }
  
  # Return single value or list
  if {$count == 1} {
    return [lindex $result 0]
  } else {
    return $result
  }
}

# 生成1个符合默认设置的随机数
puts [generate_normal]

# 生成10个以-0.030为中心的随机数
puts [lsort -real [generate_normal -0.050 -0.001 10 -0.030 0.01]]

# 生成5个更集中分布的随机数（较小的标准差）
puts [lsort -real [generate_normal -0.050 -0.001 5 -0.020 0.005]]
