###after defIn high layer stripes 
deselectAll
editSelect -net vss -layer ME7
set boxes [dbget selected.box]
foreach b $boxes {createRouteBlk -layer {VI6 ME7} -name via6_vss -box  $b }
deselectAll
