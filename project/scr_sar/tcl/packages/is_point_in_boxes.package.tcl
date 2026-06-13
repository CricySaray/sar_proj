#!/bin/tclsh
# --------------------------
# author    : aiden song
# date      : 2026/06/14
# label     : check_proc
# descrip   : Determine whether the input point is inside any rectangle in boxes list
# input     : point  -> {x y} coordinate list
#             boxes  -> list of rectangles, each rect format {x y x1 y1}
# return    : 1 = point inside boxes, 0 = point outside boxes
# error     : Throw error when input format or value is invalid
# --------------------------
proc is_point_in_boxes {point boxes} {
	# 1. Verify point format: must be 2 elements
	if {[llength $point] != 2} {
		error "Invalid point format: point must be a 2-element list {x y}"
	}

	# 2. Verify point coordinates are valid numbers
	foreach coord $point {
		if {![string is double -strict $coord]} {
			error "Invalid point coordinate: '$coord' is not a valid numeric value"
		}
	}

	# 3. Verify boxes is not empty
	if {[llength $boxes] == 0} {
		error "Invalid boxes: boxes list cannot be empty"
	}

	# 4. Traverse and verify each rectangle in boxes
	set rect_index 0
	foreach rect $boxes {
		# Each rectangle must be 4 elements {rx ry rx1 ry1}
		if {[llength $rect] != 4} {
			error "Rectangle $rect_index format error: must be 4-element list {x y x1 y1}"
		}

		# Verify rectangle coordinates are valid numbers
		foreach r_coord $rect {
			if {![string is double -strict $r_coord]} {
				error "Rectangle $rect_index coordinate error: '$r_coord' is not a valid numeric value"
			}
		}

		# Parse rectangle coordinates
		lassign $rect rx ry rx1 ry1

		# Verify rectangle: lower-left < upper-right
		if {$rx >= $rx1 || $ry >= $ry1} {
			error "Rectangle $rect_index range error: lower-left corner must be smaller than upper-right corner"
		}

		incr rect_index
	}

	# Parse target point coordinate
	lassign $point px py

	# 5. Judge if point is inside any rectangle
	foreach rect $boxes {
		lassign $rect rx ry rx1 ry1
		if {$px >= $rx && $px <= $rx1 && $py >= $ry && $py <= $ry1} {
			return 1
		}
	}

	# Point is outside all rectangles
	return 0
}
