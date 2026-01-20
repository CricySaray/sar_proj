alias gl "get_net_length"
proc get_net_length {{net ""}} {
  if {[lindex $net 0] == [lindex $net 0 0]} { ;
    set net [lindex $net 0]
  }
	if {$net == "0x0" || [dbget top.nets.name $net -e] == ""} {
		error "proc get_net_length: check your input: net($net) is not found!!!"
	} else {
    set wires_split_length [dbget [dbget top.nets.name $net -u -p].wires.length -e]
    if {$wires_split_length == ""} { return 0 } ;
    set net_length 0
    foreach wire_len $wires_split_length {
      set net_length [expr $net_length + $wire_len]
    }
    return $net_length
	}
}
proc table_format_with_title {inputData {width_spec 0} {align_spec "left"} {title ""} {show_border 1}} {
  if {![llength $inputData]} {
    error "proc table_format_with_title: inputData must be a non-empty nested list (each sublist is a row)"
  }
  foreach row $inputData {
    if {![llength $row] && $row ne ""} {
      error "proc table_format_with_title: all elements in inputData must be sublists (each sublist represents a row)"
    }
  }
  if {![string is integer -strict $width_spec] && ![llength $width_spec]} {
    error "proc table_format_with_title: width_spec must be a non-negative integer or list of non-negative integers"
  }
  if {[string is integer -strict $width_spec] && $width_spec < 0} {
    error "proc table_format_with_title: width_spec integer must be non-negative"
  }
  if {[llength $width_spec]} {
    foreach w $width_spec {
      if {![string is integer -strict $w] || $w < 0} {
        error "proc table_format_with_title: all width_spec list items must be non-negative integers"
      }
    }
  }
  if {![string is list $title] && [llength $title] > 1} {
    error "proc table_format_with_title: title must be a single string"
  }
  set valid_alignments {"left" "center" "right"}
  if {[lsearch -exact $valid_alignments $align_spec] == -1 && [llength $align_spec] == 0} {
    error "proc table_format_with_title: align_spec must be a valid alignment ([join $valid_alignments {, }]) or a list of valid alignments"
  }
  if {![string is integer -strict $show_border] || $show_border < 0 || $show_border > 1} {
    error "proc table_format_with_title: show_border must be 0 (no border) or 1 (show border)"
  }
  set rows [list]
  foreach row $inputData {
    set processed_row [list]
    foreach col $row {
      lappend processed_row [join $col]
    }
    lappend rows $processed_row
  }
  set col_count 0
  foreach row $rows {
    set current_cols [llength $row]
    if {$current_cols > $col_count} {
      set col_count $current_cols
    }
  }
  if {$col_count == 0} {
    return ""
  }
  set col_widths [list]
  if {[string is integer -strict $width_spec]} {
    for {set i 0} {$i < $col_count} {incr i} {
      lappend col_widths $width_spec
    }
  } else {
    if {[llength $width_spec] != $col_count} {
      error "proc table_format_with_title: width_spec list length ([llength $width_spec]) must match column count ($col_count)"
    }
    foreach w $width_spec {
      lappend col_widths $w
    }
  }
  set align_cols [list]
  if {[lsearch -exact $valid_alignments $align_spec] != -1} {
    for {set i 0} {$i < $col_count} {incr i} {
      lappend align_cols $align_spec
    }
  } elseif {[llength $align_spec] > 0} {
    if {[llength $align_spec] != $col_count} {
      error "proc table_format_with_title: align_spec list length ([llength $align_spec]) must match column count ($col_count)"
    }
    foreach align $align_spec {
      if {[lsearch -exact $valid_alignments $align] == -1} {
        error "proc table_format_with_title: invalid alignment '$align' in align_spec. Must be one of [join $valid_alignments {, }]"
      }
      lappend align_cols $align
    }
  }
  if {$show_border} {
    set col_sep "|"
    set line_char "-"
    set corner_char "+"
    set inter_col_spacing 0  ;
  } else {
    set col_sep ""         ;
    set line_char ""
    set corner_char ""
    set inter_col_spacing 2  ;
  }
  proc wrap_text {text max_width} {
    if {$max_width <= 0} {return [list $text]}
    set lines [list]
    set len [string length $text]
    set start 0
    while {$start < $len} {
      set end [expr {min($start + $max_width, $len)}]
      if {$end < $len && [string index $text $end] ne " " && [string index $text [expr {$end - 1}]] ne " "} {
        set space_pos [string last " " $text [expr {$end - 1}]]
        if {$space_pos > $start} {
          set end $space_pos
        }
      }
      lappend lines [string range $text $start [expr {$end - 1}]]
      set start [expr {$end == $start ? $end + 1 : $end}]
    }
    return $lines
  }
  set wrapped_rows [list]
  set row_heights [list]
  foreach row $rows {
    set row_cols [llength $row]
    set wrapped_cols [list]
    set max_lines 1
    for {set i 0} {$i < $col_count} {incr i} {
      set col_content [expr {$i < $row_cols ? [lindex $row $i] : ""}]
      set wrapped [wrap_text $col_content [lindex $col_widths $i]]
      lappend wrapped_cols $wrapped
      set max_lines [expr {max($max_lines, [llength $wrapped])}]
    }
    lappend wrapped_rows $wrapped_cols
    lappend row_heights $max_lines
  }
  set actual_widths [list]
  for {set i 0} {$i < $col_count} {incr i} {
    set max_w 0
    set width_limit [lindex $col_widths $i]
    for {set r 0} {$r < [llength $wrapped_rows]} {incr r} {
      set row_cols [lindex $wrapped_rows $r]
      set col_lines [lindex $row_cols $i]
      foreach line $col_lines {
        set current_len [string length $line]
        set max_w [expr {max($max_w, $current_len)}]
      }
    }
    if {$width_limit > 0 && $max_w > $width_limit} {
      set max_w $width_limit
    }
    lappend actual_widths $max_w
  }
  set base_sep ""
  if {$show_border} {
    set sep_parts [list $corner_char]
    foreach w $actual_widths {
      append sep_parts [string repeat $line_char [expr {$w + 2}]] $corner_char
    }
    set base_sep $sep_parts
  }
  set table_content [list]
  if {$show_border} {
    lappend table_content $base_sep
  }
  for {set r 0} {$r < [llength $wrapped_rows]} {incr r} {
    set row_cols [lindex $wrapped_rows $r]
    set row_height [lindex $row_heights $r]
    for {set line_idx 0} {$line_idx < $row_height} {incr line_idx} {
      set parts [list]
      if {$show_border} {
        lappend parts $col_sep
      }
      for {set i 0} {$i < $col_count} {incr i} {
        set col_lines [lindex $row_cols $i]
        set line_content [expr {$line_idx < [llength $col_lines] ? [lindex $col_lines $line_idx] : ""}]
        set w [lindex $actual_widths $i]
        set align [lindex $align_cols $i]
        if {$align eq "left"} {
          set formatted_col [format " %-*s " $w $line_content]
        } elseif {$align eq "center"} {
          set content_len [string length $line_content]
          if {$content_len >= $w} {
            set formatted_col " $line_content "
          } else {
            set pad_left [expr {int(($w - $content_len) / 2)}]
            set pad_right [expr {$w - $content_len - $pad_left}]
            set formatted_col " [string repeat " " $pad_left]$line_content[string repeat " " $pad_right] "
          }
        } elseif {$align eq "right"} {
          set formatted_col [format " %*s " $w $line_content]
        }
        lappend parts $formatted_col
        if {$i < [expr {$col_count - 1}]} {
          lappend parts $col_sep
        } elseif {$show_border} {
          lappend parts $col_sep
        }
      }
      lappend table_content [join $parts ""]
    }
    if {$show_border} {
      lappend table_content $base_sep
    }
  }
  set table_body $table_content
  set formatted_output [list]
  if {$title ne ""} {
    set table_width [expr {[llength $table_body] > 0 ? [string length [lindex $table_body 0]] : 0}]
    set title_len [string length $title]
    if {$title_len >= $table_width || $table_width == 0} {
      lappend formatted_output $title
    } else {
      set pad [expr {int(($table_width - $title_len) / 2)}]
      lappend formatted_output [string repeat " " $pad]$title
    }
    lappend formatted_output "" ;
  }
  lappend formatted_output {*}$table_body
  return $formatted_output
}
if {0} {
  set product_data {
    {"ID" "Product Name" "Stock" "Category" "Description (long text test)"}
    {"PRD-001" "Wireless Mouse" 450 "Peripherals" "Ergonomic design with Bluetooth 5.1 and 2.4G dual-mode; 800-1600 DPI adjustable; up to 60 days battery life"}
    {"PRD-002" "Mechanical Keyboard" 230 "Peripherals" "Blue switch with anti-ghosting; RGB backlight; compatible with Windows/macOS"}
    {"PRD-003" "27\" Monitor" 89 "Displays" "4K UHD (3840×2160); 100% sRGB; HDR10 support; height-adjustable stand"}
  }
  set formatted_table [table_format_with_title $product_data {10 18 6 12 35} center "Office Equipment Inventory" 0]
  set formatted_table [table_format_with_title $product_data {10 18 6 12 35} center "" 0]
  puts "=== Test Case 1: Valid Nested List Input ==="
  puts [join $formatted_table \n]
  puts "\n=== Test Case 2: Error Handling for Non-Nested List Input ==="
  set invalid_data "2024-09-01 Alice Engineering API integration completed"
  puts [join [table_format_with_title $invalid_data 15 center ""] \n]
  puts "\n=== Test Case 3: Error Handling for Mixed List Input ==="
  set mixed_data {{"Row1 Col1" "Row1 Col2"} "This is not a sublist" {"Row3 Col1" "Row3 Col2"}}
  puts [join [table_format_with_title $mixed_data 0 {right left left left left} "" 0] \n]
}
proc whichProcess_fromStdCellPattern {{celltype ""}} {
  if {$celltype == "" || $celltype == "0x0" || ![sizeof_collection [get_lib_cells "*/$celltype" -quiet]]} {
    return "0x0:1";
  } else {
    if {[regexp BWP $celltype]} {
      set processType "TSMC"
    } elseif {[regexp {A[HRL]\d+$} $celltype]} {
      set processType "HH"
    } else {
      return "0x0:1";
    }
    return $processType
  }
}
proc get_driveCapacity_of_celltype {{celltype ""} {regExp ".*X(\\d+).*(A\[HRL\]\\d+)$"}} {
  if {$celltype == "" || $celltype == "0x0" || ![sizeof_collection [get_lib_cells -q "*/$celltype"]]} {
    return "0x0:1";
  } else {
    regexp $regExp $celltype wholename driveLevel VTtype
    if {![info exists wholename]} {
      error "proc get_driveCapacity_of_celltype: celltype($celltype) can't be matched by regExp($regExp)"
    }
    if {$driveLevel == "05"} {set driveLevel 0.5}
    return $driveLevel
  }
}
proc get_driveCapacity_of_celltype_returnCapacityAndVTtype {{celltype ""} {regExp ".*X(\\d+).*(A\[HRL\]\\d+)$"}} {
  if {$celltype == "" || $celltype == "0x0" || ![sizeof_collection [get_lib_cells -q "*/$celltype"]]} {
    error "proc get_driveCapacity_of_celltype_returnCapacityAndVTtype: check your input : celltype($celltype) not found!!!";
  } else {
    regexp $regExp $celltype wholename driveLevel VTtype
    if {![info exists wholename]} {
      error "proc get_driveCapacity_of_celltype_returnCapacityAndVTtype: celltype($celltype) can't be matched by regExp($regExp)"
    }
    return [list $driveLevel $VTtype]
  }
}
proc get_driveCapacityAndVTtype_of_celltype_spcifyingStdCellLib {{celltype ""} {process {M31GPSC900NL040P*_40N}}} {
  if {$celltype == "" || $celltype == "0x0" || ![sizeof_collection [get_lib_cells -q "*/$celltype"]]} {
    error "proc get_driveCapacityAndVTtype_of_celltype_spcifyingStdCellLib: check your input: celltype($celltype) not found!!!";
  } else {
    if {$process == {M31GPSC900NL040P*_40N}} {
      set regExp {.*X(\d+).*(A[HRL]9)$}
    }
    set ifError [catch {regexp $regExp $celltype wholename driveLevel VTtype} errInfo]
    if {$ifError || ![info exists wholename] || ![info exists driveLevel] || ![info exists VTtype]} {
      error "proc get_driveCapacityAndVTtype_of_celltype_spcifyingStdCellLib: check your regExp($regExp) can't match this celltype($celltype)"
    }
    if {$process == {M31GPSC900NL040P*_40N} && $driveLevel == "05"} {set driveLevel 0.5}
    return [list $driveLevel $VTtype]
  }
}
proc get_cellDriveLevel_and_VTtype_of_inst {{instOrPin ""} {regExp "D(\\d+).*CPD(U?L?H?VT)?"}} {
  if {$instOrPin == "" || $instOrPin == "0x0" || ![sizeof_collection [get_cells -q $instOrPin]] && ![sizeof_collection [get_pins -q $instOrPin]]} {
    return "0x0:1"
  } else {
    if {[get_object_name [get_cells -q $instOrPin]] != ""} {
      set cellName [get_attribute [get_cells -q $instOrPin] ref_name]
      set instname $instOrPin
    } else {
      set cellName [get_attribute [get_cells -q -of $instOrPin] ref_name]
      set instname [get_object_name [get_cells -q -of $instOrPin]]
    }
    set wholeName 0
    set levelNum 0
    set VTtype 0
    set runError [catch {regexp $regExp $cellName wholeName levelNum VTtype} errorInfo]
    if {$runError || $wholeName == ""} {
      return "0x0:2"
    } else {
      if {$VTtype == ""} {set VTtype "SVT"}
      if {$levelNum == "05"} {set levelNumTemp 0.5} else {set levelNumTemp [expr $levelNum]}
      set instName_cellName_driveLevel_VTtype_List [list ]
      lappend instName_cellName_driveLevel_VTtype_List $instname
      lappend instName_cellName_driveLevel_VTtype_List $cellName
      lappend instName_cellName_driveLevel_VTtype_List $levelNumTemp
      lappend instName_cellName_driveLevel_VTtype_List $VTtype
      return $instName_cellName_driveLevel_VTtype_List
    }
  }
}
proc categorize_overlapping_sets {categories {verbose 0} {keep_original 0}} {
  proc smart_sort {items} {
    set all_numeric 1
    foreach item $items {
      if {![string is double -strict $item]} {
        set all_numeric 0
        break
      }
    }
    if {$all_numeric} {
      set numeric_items [lmap item $items {expr {$item}}]
      set sorted [lsort -real $numeric_items]
      return [lmap num $sorted {format "%.10g" $num}]
    } else {
      return [lsort -dictionary $items]
    }
  }
  if {[llength $categories] == 0} {
    error "At least one category must be provided"
  }
  foreach category $categories {
    if {[llength $category] != 2} {
      error "Invalid category format: $category. Correct format is {category_name {item1 item2 ...}}"
    }
    set cat_name [lindex $category 0]
    set cat_items [lindex $category 1]
    if {[catch {llength $cat_items}]} {
      error "Items for category $cat_name are not a valid list: $cat_items"
    }
  }
  set cat_names [list]
  foreach category $categories {
    set cat_name [lindex $category 0]
    if {[lsearch $cat_names $cat_name] != -1} {
      error "Duplicate category name: $cat_name"
    }
    lappend cat_names $cat_name
  }
  array set element_cats {}
  set all_elements [list]
  foreach category $categories {
    set cat_name [lindex $category 0]
    set cat_items [lindex $category 1]
    foreach item $cat_items {
      set item_str [string trim $item]
      if {$item_str eq ""} {
        if {$verbose} {
          puts "Warning: Empty string found in category $cat_name, skipped"
        }
        continue
      }
      lappend element_cats($item_str) $cat_name
      lappend all_elements $item_str
    }
  }
  set unique_elements [lsort -unique $all_elements]
  array set combined_cats {}
  foreach element $unique_elements {
    set cats [lsort $element_cats($element)]
    set combined_name [join $cats "_AND_"]
    lappend combined_cats($combined_name) $element
  }
  set result [list]
  if {$keep_original} {
    foreach category $categories {
      set cat_name [lindex $category 0]
      set cat_items [lsort -unique [lindex $category 1]]
      set sorted_items [smart_sort $cat_items]
      lappend result [list $cat_name $sorted_items]
    }
  }
  foreach combined_name [lsort [array names combined_cats]] {
    if {$keep_original && [llength [split $combined_name "_AND_"]] == 1} {
      continue
    }
    set sorted_items [smart_sort $combined_cats($combined_name)]
    lappend result [list $combined_name $sorted_items]
  }
  if {$verbose} {
    puts "Categorization completed:"
    foreach item $result {
      puts "  [lindex $item 0]: [llength [lindex $item 1]] elements"
    }
  }
  return $result
}
if {0} {
  set category1 {error_VTtype {name1 name3 name2 name4 song}}
  set category2 {error_length {name2 name3 name5 name6 song}}
  set category3 {error_capacity {name3 name6 name7 name8 song}}
  set result [categorize_overlapping_sets [list $category1 $category2 $category3]]
  puts ""
  puts $result
  puts ""
  puts "String items result:"
  foreach item $result {
    puts "[lindex $item 0]: [lindex $item 1]"
  }
  set num_category1 {value_high {3.5 1.2 5.7}}
  set num_category2 {value_low {2.1 1.2 4.3}}
  set num_result [categorize_overlapping_sets [list $num_category1 $num_category2]]
  puts ""
  puts $num_result
  puts ""
  puts "\nNumeric items result:"
  foreach item $num_result {
    puts "[lindex $item 0]: [lindex $item 1]"
  }
}
proc print_formattedTable {{dataList {}}} {
  set text ""
  foreach row $dataList {
      append text [join $row "\t"]
      append text "\n"
  }
  set pipe [open "| column -t" w+]
  puts -nonewline $pipe $text
  close $pipe w
  set formattedLines [list ]
  while {[gets $pipe line] > -1} {
    lappend formattedLines $line
  }
  close $pipe
  return [join $formattedLines \n]
}
proc print_formattedTable_D2withCategory {{dataList {}} {indentChar "\t"} {separator "-"}} {
  if {![llength $dataList]} {
    error "Input list is empty or invalid"
  }
  if {![string length $indentChar]} {
    error "Indent character cannot be empty"
  }
  set output [list]
  foreach category $dataList {
    set categoryName [lindex $category 0]
    set items [lindex $category 1]
    if {![string length $categoryName] || ![llength $items]} {
      error "Invalid category structure: must be {categoryName {itemList}}"
    }
    lappend output $categoryName
    set itemLines [list]
    foreach item $items {
      lappend itemLines [join $item "\t"]
    }
    set pipe [open "| column -t" w+]
    puts $pipe [join $itemLines "\n"]
    close $pipe w
    set formattedItems [list]
    while {[gets $pipe line] > -1} {
      lappend formattedItems "${indentChar}${line}"
    }
    close $pipe
    if {[llength $formattedItems] > 0} {
      set sepLength [expr [string length [lindex $formattedItems 0]] - [string length $indentChar]]
      set sepLine "${indentChar}[string repeat $separator $sepLength]"
      lappend output $sepLine
    }
    lappend output {*}$formattedItems
  }
  return [join $output "\n"]
}
if {0} {
  set test {{cate1 {{sdjfl 1} {jalsdfjlkjg 1244} {jslkkdfjlksjflskdjf 3}}} {cate2 {{jf 34} {sjldkfjklsdjfl k}}}}
  puts [print_formattedTable_D2withCategory $test]
}
proc count_items {two_d_list index} {
  if {[llength $two_d_list] == 0} {
    return [list]
  }
  set first_sublist [lindex $two_d_list 0]
  set sublist_length [llength $first_sublist]
  if {$index < 0 || $index >= $sublist_length} {
    error "Invalid index: $index. Valid range is 0 to [expr {$sublist_length - 1}]"
  }
  foreach sublist $two_d_list {
    if {[llength $sublist] != $sublist_length} {
      error "All sublists must have the same length"
    }
  }
  array set counts {}
  foreach sublist $two_d_list {
    set item [lindex $sublist $index]
    if {[info exists counts($item)]} {
      incr counts($item)
    } else {
      set counts($item) 1
    }
  }
  set result [list]
  foreach item [array names counts] {
    lappend result [list $item $counts($item)]
  }
  return $result
}
if {0} {
  set data {
    {apple red 10}
    {banana yellow 5}
    {apple green 8}
    {orange orange 12}
    {banana yellow 7}
  }
  puts [count_items $data 0]
  puts [count_items $data 1]
}
# Skipping already processed file: ../../../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl
# Skipping already processed file: ../../../packages/table_format_with_title.package.tcl
# Skipping already processed file: ../../../packages/table_format_with_title.package.tcl
alias fl "convert_file_to_list"
proc convert_file_to_list {filename {trim_whitespace 1} {skip_empty 1} {verbose 0} {remove_comments 1}} {
  set result [list]
  if {![file exists $filename]} {
    error "Error: File '$filename' does not exist."
  }
  if {![file isfile $filename]} {
    error "Error: '$filename' is not a regular file."
  }
  if {![file readable $filename]} {
    error "Error: File '$filename' is not readable."
  }
  set f [open $filename r]
  set line_number 0
  while {[gets $f line] != -1} {
    incr line_number
    set original_line $line
    if {$remove_comments} {
      set comment_index [string first "#" $line]
      if {$comment_index != -1} {
        set line [string range $line 0 [expr {$comment_index - 1}]]
        if {$verbose} {
          puts "Removed comment from line $line_number"
        }
      }
    }
    if {$trim_whitespace} {
      set line [string trim $line]
    }
    set is_empty [expr {[string length [string trim $line]] == 0}]
    if {$skip_empty && $is_empty} {
      if {$verbose} {
        puts "Skipping empty line $line_number"
      }
      continue
    }
    lappend result $line
    if {$verbose} {
      puts "Processed line $line_number: [expr {$is_empty ? "(empty)" : $line}]"
    }
  }
  close $f
  if {$verbose} {
    puts "Successfully processed file. Total lines added: [llength $result]"
  }
  return $result
}
proc every {varName list script} {
  foreach item $list {
    uplevel 1 [list set $varName $item]
    if {![uplevel 1 $script]} {
      return 0
    }
  }
  return 1
}
proc any {varName list script} {
  foreach item $list {
    uplevel 1 [list set $varName $item]
    if {[uplevel 1 $script]} {
      return 1
    }
  }
  return 0
}
proc util_wildcardList_to_regexpList {args} {
  set wildcardList [list]
  parse_proc_arguments -args $args opt
  foreach arg [array names opt] {
    regsub -- "-" $arg "" var
    set $var $opt($arg)
  }
	set regexpList [lmap temp_wildcard $wildcardList {
    if {[expr {[string index $temp_wildcard 0] ne "*"}]} {
      set final_regexp [string cat "^" $temp_wildcard]
    } else { set final_regexp $temp_wildcard }
    if {[expr {[string index $temp_wildcard end] ne "*"}]} {
      set final_regexp [string cat $final_regexp "$"]
    }
    set final_regexp
  }]
  set regexpList [regsub -all {\*} $regexpList {.*}]
  return $regexpList
}
define_proc_arguments util_wildcardList_to_regexpList \
  -info "whatFunction"\
  -define_args {
    {-wildcardList "specify the list of wildcard" AList list optional}
  }
# Skipping already processed file: ../../../eco_fix/timing_fix/trans_fix/proc_getDriveCapacity_ofCelltype.pt.tcl
# Skipping already processed file: ../../../packages/table_format_with_title.package.tcl
# Skipping already processed file: ../../../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl
# Skipping already processed file: ../../../packages/table_format_with_title.package.tcl
# Skipping already processed file: ../../../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl
proc proc_findCoreRectInsideBoundary_usingCoreBoxesAndHaloAndPlaceBlockages_withBoundaryRects {} {
  set coreBoxes [dbShape [dbget top.fplan.rows.box -e] -output hrect]
  set memOrIps_ptrs [dbget [dbget top.insts.cell.subClass block -p2].pstatus {^placed|^fixed} -regexp -p -e]
  set memOrIpsRects [lmap temp_inst_ptr $memOrIps_ptrs {
    set temp_rect [dbShape -output hrect [dbget $temp_inst_ptr.pHaloPoly -e]]
  }]
  set valideMemOrIpsRects [dbShape -output hrect $memOrIpsRects]
  set hardBlkgRects [dbShape -output hrect [dbget [dbget top.fplan.pBlkgs.type hard -p].boxes -e]]
  set memOrIpsOrHardBlkgsRects [dbShape -output hrect $valideMemOrIpsRects OR $hardBlkgRects]
  set coreRectsWithOutMemIpHardblkgs [dbShape -output hrect $coreBoxes ANDNOT $memOrIpsOrHardBlkgsRects]
  return $coreRectsWithOutMemIpHardblkgs
}
proc proc_findCoreRectInsideBoundary_usingCoreBoxesAndHaloAndPlaceBlockages {{rects_of_boundary_cells {}}} {
  set coreBoxes [dbShape [dbget top.fplan.rows.box -e] -output hrect]
  set memOrIps_ptrs [dbget [dbget top.insts.cell.subClass block -p2].pstatus {^placed|^fixed} -regexp -p -e]
  set memOrIpsRects [lmap temp_inst_ptr $memOrIps_ptrs {
    set temp_rect [dbShape -output hrect [dbget $temp_inst_ptr.pHaloPoly -e]]
  }]
  set valideMemOrIpsRects [dbShape -output hrect $memOrIpsRects]
  set hardBlkgRects [dbShape -output hrect [dbget [dbget top.fplan.pBlkgs.type hard -p].boxes -e]]
  set memOrIpsOrHardBlkgsRects [dbShape -output hrect $valideMemOrIpsRects OR $hardBlkgRects]
  set coreRectsWithOutMemIpHardblkgs [dbShape -output hrect $coreBoxes ANDNOT $memOrIpsOrHardBlkgsRects]
  set coreRectsWithOutMemIpHardblkgsBoundaryCells [dbShape -output hrect $coreRectsWithOutMemIpHardblkgs ANDNOT $rects_of_boundary_cells]
  return $coreRectsWithOutMemIpHardblkgsBoundaryCells
}
# Skipping already processed file: ../../../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl
# Skipping already processed file: ../../../packages/table_format_with_title.package.tcl
# Skipping already processed file: ../../../eco_fix/timing_fix/trans_fix/proc_get_net_lenth.invs.tcl
# Skipping already processed file: ../../../packages/table_format_with_title.package.tcl
