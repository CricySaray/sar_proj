# editSelect -physical_pin_only
set physicalPinPtr [dbget selected.]
set physicalPinName [dbget $physicalPinPtr.name]
set physicalPinBox  [dbget $physicalPinPtr.box]
set pin_box_List [lmap pin $physicalPinName box $physicalPinBox {
  set temp [list $pin $box]
}]
puts [join $pin_box_List \n]
