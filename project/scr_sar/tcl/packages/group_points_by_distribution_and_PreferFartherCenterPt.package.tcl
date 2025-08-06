#!/bin/tclsh
# --------------------------
# author    : sar song
# date      : 2025/07/26 16:49:42 Saturday
# label     : math_proc
#   -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|misc_proc)
# descrip   : This proc takes coordinates of a start point and multiple end points, groups the end 
#             points into two sets based on their spatial distribution using a simplified K-means algorithm, 
#             and calculates each set's center point. In the returned result, the first set's center is farther 
#             from the start point, while the second set's center is closer.
# return    : { { {sink1_1_name { x y }} { sink1_2_name { x y } } { sink1_3_name { x y } } ... {center1_x center1_y} } \
#               { {sink2_1_name { x y }} { sink2_2_name { x y } } { sink2_3_name { x y } } ... {center2_x center2_y} } }
#             center1 is farther center point from startPoint
# ref       : link url
# --------------------------
proc group_points_by_distribution_and_preferFartherCenterPt {start_point end_points {debug 0}} {
	# Error checking
	if {[llength $start_point] != 2} {
		error "Invalid start point format, should be {name {x y}}"
	}
	foreach ep $end_points {
		if {[llength $ep] != 2} {
			error "Invalid end point format, should be {name {x y}}"
		}
	}
	# Extract start point coordinates
	set start_name [lindex $start_point 0]
	set start_coords [lindex $start_point 1]
	set sx [lindex $start_coords 0]
	set sy [lindex $start_coords 1]
	# Debug output controlled by $debug
	if {$debug} {
		puts "DEBUG: Start point - $start_name ($sx, $sy)"
		puts "DEBUG: Total [llength $end_points] end points to group"
	}
	# Calculate distance from each end point to start point
	set distances {}
	foreach ep $end_points {
		set ep_name [lindex $ep 0]
		set ep_coords [lindex $ep 1]
		set epx [lindex $ep_coords 0]
		set epy [lindex $ep_coords 1]
		# Calculate Euclidean distance
		set dx [expr {$epx - $sx}]
		set dy [expr {$epy - $sy}]
		set dist [expr {sqrt($dx*$dx + $dy*$dy)}]
		lappend distances [list $ep_name $dist $ep_coords]
		if {$debug} {
			puts "DEBUG: Point $ep_name at ($epx, $epy) distance to start: $dist"
		}
	}
	# Sort by distance
	set sorted_dists [lsort -index 1 $distances]
	# Group points using simplified K-means approach
	# Initialize two centers: start point and farthest point
	set center1 [list $sx $sy]
	set far_point [lindex $sorted_dists end]
	set center2 [lindex $far_point 2]
	if {$debug} {
		puts "DEBUG: Initial center1: ($sx, $sy)"
		puts "DEBUG: Initial center2: [lindex $center2 0], [lindex $center2 1]"
	}
	# Iterate to update centers (simplified K-means, 3 iterations)
	for {set iter 0} {$iter < 3} {incr iter} {
		if {$debug} {
			puts "DEBUG: Iteration $iter"
		}
		# Clear groups
		set group1 {}
		set group2 {}
		# Assign points to nearest center
		foreach point $distances {
			set p_name [lindex $point 0]
			set p_coords [lindex $point 2]
			set px [lindex $p_coords 0]
			set py [lindex $p_coords 1]
			# Calculate distances to both centers
			set dx1 [expr {$px - [lindex $center1 0]}]
			set dy1 [expr {$py - [lindex $center1 1]}]
			set dist1 [expr {sqrt($dx1*$dx1 + $dy1*$dy1)}]
			set dx2 [expr {$px - [lindex $center2 0]}]
			set dy2 [expr {$py - [lindex $center2 1]}]
			set dist2 [expr {sqrt($dx2*$dx2 + $dy2*$dy2)}]
			if {$dist1 < $dist2} {
				lappend group1 $p_name
				if {$debug} {
					puts "DEBUG: Point $p_name assigned to group1 (Dist to C1: $dist1, C2: $dist2)"
				}
			} else {
				lappend group2 $p_name
				if {$debug} {
					puts "DEBUG: Point $p_name assigned to group2 (Dist to C1: $dist1, C2: $dist2)"
				}
			}
		}
		# Update centers
		set sum_x1 0.0
		set sum_y1 0.0
		foreach p_name $group1 {
			foreach ep $end_points {
				if {[lindex $ep 0] eq $p_name} {
					set coords [lindex $ep 1]
					set sum_x1 [expr {$sum_x1 + [lindex $coords 0]}]
					set sum_y1 [expr {$sum_y1 + [lindex $coords 1]}]
					break
				}
			}
		}
		set count1 [llength $group1]
		if {$count1 > 0} {
			set center1 [list [expr {$sum_x1 / $count1}] [expr {$sum_y1 / $count1}]]
			set center1 [format "%.2f %.2f" {*}$center1]
			if {$debug} {
				puts "DEBUG: New center1: [format "%.2f" [lindex $center1 0]], [format "%.2f" [lindex $center1 1]]"
			}
		}
		set sum_x2 0.0
		set sum_y2 0.0
		foreach p_name $group2 {
			foreach ep $end_points {
				if {[lindex $ep 0] eq $p_name} {
					set coords [lindex $ep 1]
					set sum_x2 [expr {$sum_x2 + [lindex $coords 0]}]
					set sum_y2 [expr {$sum_y2 + [lindex $coords 1]}]
					break
				}
			}
		}
		set count2 [llength $group2]
		if {$count2 > 0} {
			set center2 [list [expr {$sum_x2 / $count2}] [expr {$sum_y2 / $count2}]]
			set center2 [format "%.2f %.2f" {*}$center2]
			if {$debug} {
				puts "DEBUG: New center2: [format "%.2f" [lindex $center2 0]], [format "%.2f" [lindex $center2 1]]"
			}
		}
	}
	# Calculate distances from both centers to the start point
	set dx1 [expr {[lindex $center1 0] - $sx}]
	set dy1 [expr {[lindex $center1 1] - $sy}]
	set dist1 [expr {sqrt($dx1*$dx1 + $dy1*$dy1)}]
	set dx2 [expr {[lindex $center2 0] - $sx}]
	set dy2 [expr {[lindex $center2 1] - $sy}]
	set dist2 [expr {sqrt($dx2*$dx2 + $dy2*$dy2)}]
	# Add group 1 info
	set group1_data [list]
	foreach p_name $group1 {
		foreach ep $end_points {
			if {[lindex $ep 0] eq $p_name} {
				lappend group1_data $ep
				break
			}
		}
	}
	# Add group 2 info
	set group2_data [list]
	foreach p_name $group2 {
		foreach ep $end_points {
			if {[lindex $ep 0] eq $p_name} {
				lappend group2_data $ep
				break
			}
		}
	}
	# Ensure the first returned group has the center farther from the start point
	if {$dist1 >= $dist2} {
		set result [list [list $group1_data $center1] [list $group2_data $center2]]
		if {$debug} {puts "INFO: Group 1's center is farther from the start point (Distance: [format "%.2f" $dist1])"}
	} else {
		set result [list [list $group2_data $center2] [list $group1_data $center1]]
		if {$debug} { puts "INFO: Group 2's center is farther from the start point (Distance: [format "%.2f" $dist2])" }
	}
	# Print final results
  if {$debug} {
    puts "Grouping completed!"
    puts "Group 1 (Center farther from start, Center: [format "%.2f" [lindex [lindex $result 0 1] 0]], [format "%.2f" [lindex [lindex $result 0 1] 1]]):"
    foreach p [lindex $result 0 0] { puts "  - [lindex $p 1] : [lindex $p 0]" }
    puts "Group 2 (Center closer to start, Center: [format "%.2f" [lindex [lindex $result 1 1] 0]], [format "%.2f" [lindex [lindex $result 1 1] 1]]):"
    foreach p [lindex $result 0 1] { puts "  - [lindex $p 1] : [lindex $p 0]" }
  }
	return $result
}
