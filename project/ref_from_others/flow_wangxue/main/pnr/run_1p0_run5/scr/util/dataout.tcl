deleteAllCellPad
deleteFiller -prefix spare_decap
deleteFiller -prefix spare_filler
deleteFiller -prefix decap_ir
deleteFiller -prefix decap
deleteFiller -prefix filler
setFillerMode -add_fillers_with_drc false
setFillerMode -check_signal_drc true

#set gdcap_cell {GDCAP12BWP7T30P140 GDCAP10BWP7T30P140 GDCAP4BWP7T30P140 GDCAP3BWP7T30P140 GDCAP2BWP7T30P140 GDCAPBWP7T30P140 }
#set gdcap_cell {GDCAP10BWP7T30P140}
set gdcap_cell {GDCAP12BWP7T30P140HVT GDCAP10BWP7T30P140HVT GDCAP4BWP7T30P140HVT GDCAP3BWP7T30P140HVT GDCAP2BWP7T30P140HVT GDCAPBWP7T30P140HVT}
#set decap_cell {DCAP64BWP7T35P140 DCAP32BWP7T35P140 DCAP16BWP7T35P140 DCAP8BWP7T35P140 DCAP4BWP7T35P140}
set decap_cell {DCAP64BWP7T40P140HVT DCAP32BWP7T40P140HVT DCAP16BWP7T40P140HVT DCAP8BWP7T40P140HVT DCAP4BWP7T40P140HVT}
#set gfiller    {GFILL12BWP7T30P140 GFILL10BWP7T30P140 GFILL4BWP7T30P140 GFILL3BWP7T30P140 GFILL2BWP7T30P140 GFILLBWP7T30P140 }
set gfiller    {GFILL12BWP7T30P140HVT GFILL10BWP7T30P140HVT GFILL4BWP7T30P140HVT GFILL3BWP7T30P140HVT GFILL2BWP7T30P140HVT GFILLBWP7T30P140HVT}

if {[dbGet -e top.fplan.rows.site.name ga*] ==""} {
        set siteName [dbGet head.sites.name gacore7T]
                if {[dbGet -e top.fplan.flipRows] == "first"} {
                        createRow -site $siteName -limitInCore -area [dbGet top.fplan.coreBox] -flip1st
                } else {
                        createRow -site $siteName -limitInCore -area [dbGet top.fplan.coreBox]
                }
}
clearDeCapCellCandidates

foreach i $gdcap_cell {
        addDeCapCellCandidates $i [expr [dbGet [dbGet head.libCells.name $i -p].size_x]/100]
        }
foreach i $decap_cell {
        addDeCapCellCandidates $i [expr [dbGet [dbGet head.libCells.name $i -p].size_x]/100]
        }
foreach i $gfiller {
        addDeCapCellCandidates $i [expr [dbGet [dbGet head.libCells.name $i -p].size_x]/100]
        }
set count 0
set rows ""
foreach i [dbGet top.fPlan.rows.site.name gacore7T -p2] {
        incr count
        if {[expr $count%4] ==0} {continue}
                lappend rows $i
        }
foreach box [dbShape [dbGet $rows.box] OR [dbGet $rows.box]] {
        createPlaceBlockage -box $box -name tmpBLK_GDCAP
}
#set aon_box [dbShape [dbGet [dbGet top.pds.group.name  PD_AON -p].boxes]  ANDNOT  {{1669.57 3159.6 1709.19 3178.5} {1298.99 3217.0 1334.41 3243.6} {1298.99 3160.3 1515.71 3217.0}}]
#set srame_box [dbShape [dbGet [dbGet top.pds.group.name  PD_SRAM_RE  -p].boxes]  ANDNOT  {1321.81 2941.9 1674.89 3129.5}]
        #set decap_box [concat $aon_box $srame_box ]
addDeCap -prefix spare_decap -cells $gdcap_cell -totCap 999999 
addDeCap -prefix spare_filler -cells $gfiller -totCap 999999 
deletePlaceBlockage tmpBLK_GDCAP
addDeCap -prefix decap -cells $decap_cell -totCap 999999 
setFillerMode -check_signal_drc false
addFiller -cell {FILL8BWP7T40P140HVT FILL4BWP7T40P140HVT FILL3BWP7T40P140HVT FILL2BWP7T40P140HVT} -prefix filler
setPlaceMode -reset
addFiller -cell {FILL3BWP7T40P140HVT FILL2BWP7T40P140HVT} -prefix filler  -fitGap
#addFiller -cell {FILL8BWP7T40P140HVT FILL4BWP7T40P140HVT FILL3BWP7T40P140HVT FILL2BWP7T40P140HVT} -prefix filler
#addFiller -cell {FILL8BWP7T35P140 FILL4BWP7T35P140 FILL3BWP7T35P140 FILL2BWP7T35P140} -prefix filler -fitGap

