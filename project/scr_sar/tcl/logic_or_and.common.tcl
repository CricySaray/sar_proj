#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/16 19:17:29 Wednesday
# label     : atomic_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|misc_proc)
# descrip   : logic or / logic and (string comparition)
# ref       : link url
# --------------------------

# (la = Logic AND)
#  la $var1 "value1" $var2 "value2" ...
proc la {args} {
    if {[llength $args] == 0} {
        error "la: requires at least one argument"
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
