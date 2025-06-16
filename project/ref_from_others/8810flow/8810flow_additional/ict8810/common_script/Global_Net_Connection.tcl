# STD             : 
#   VSS/VPW         --> vss
#   VNW/VDD         --> vdd09
# memory          : 
#   VSSE            --> vss
#   VDDPE/VDDCE     --> vdd09
# inno_ddr_phy    : 
#   PLLVCCA         --> PLLVCCA_0 
#   VDD             --> vdd09
#   VDDQ            --> VDDQ_0
#   VSS             --> vss
# PLLUM28HPCPFRAC : 
#   VDDHV           --> VDDHV_0
#   VDDPOST         --> VDDPOST_0
#   VDDREF          --> VDDREF_0
#   VSS             --> pll_gnd
# ddr pll pclamp  :
# 	GNDVESD			--> ddrpll_gnd
# 	VCC3VESD		--> ddrpll_vddhv
# 	VCC09VESD		--> ddrpll_vddpost
# 	VCC09VESD		--> ddrpll_vddref
# tcam            : 
#   VDD             --> vdd09
#   VSS             --> vss
# O12P5PHYU28HPCP : 
#   AVDH            --> AVDH_0/AVDH_1
#   AVDL            --> AVDL_0/AVDL_1
#   AVSS            --> AVSS_0/AVSS_1
#   VDDD            --> VDD_1/VDD_2
#   VDDU            --> VDD_2/VDD_3
#   VSSD            --> VSS_1/VSS_2
#   VSSU            --> VSS_2/VSS_3
# FXEDP447EWHJ0P  : 
#   GNDA            --> GNDA
#   GNDK            --> vss
#   VCC09K          --> vdd09
#   VCC18A_RX       --> VCC18A_RX
#   VCC18A_TX       --> VCC18A_TX
#   VCC33A          --> VCC33A
# u2phy           : 
#   AGND            --> AGND_0
#   VCCA18          --> VCCA18_0
#   VCCA33          --> VCCA33_0
#   VDDA            --> VDDA_0
#   VSSD1           --> VSSD1_0
#   VSSD2           --> VSSD2_0
# ssphy           : 
#   AVDH            --> AVDH_0
#   AVDL            --> AVDL_0
#   AVSS            --> AVSS_0
#   VDD             --> vdd09
#   VDDA            --> vdd09
#   VDDB            --> vdd09
#   VSS             --> vss
#   VSSA            --> vss
#   VSSB            --> VSSD2_1
## core CLAMP     :
#   VCC09VESD       --> vdd09
#   GNDVESD         --> vss
## ljpll CLAMP     :
#   GNDVESD         --> ljpll_gnd
#   VCC3VESD        --> ljpll_vddhv
#   VCC09VESD       --> ljpll_vddpost
#   VCC09VESD       --> ljpll_vddref
## ljpll 
#   PSUB            --> ljpll_gnd
#   VDDHV           --> ljpll_vddhv
#   VDDPOST         --> ljpll_vddpost
#   VDDREF          --> ljpll_vddref
#   VSS             --> ljpll_gnd
## pll CLAMP     :
#   GNDVESD         --> pll_gnd
#   VCC09VESD       --> pll_vddpost
#   VCC09VESD       --> pll_vddref
#   VCC3VESD        --> pll_vddhv
## pll
#   VDDHV           --> pll_vddhv
#   VDDPOST         --> pll_vddpost
#   VDDREF          --> pll_vddref
#   VSS             --> pll_gnd
## CPOR1P8U28HPCP
#   VDD             --> vdd09
#   VDD18           --> pvt_vdd18
#   VSS             --> vss
#   VSS18           --> vss
## UMC028_PVT_01_module
#   GND             --> vss
#   VDD09           --> vdd09
#   VDD18           --> pvt_vdd18
## UMC028_PVT_01_SU09
#   GND             --> vss
#   VDD18           --> pvt_vdd18
#   VIN             --> vdd09
#   VIN_GND         --> vss
## u028efucp01603218400
#   VDD             --> vdd09
#   VSS             --> gnd_efuse
#   VQPS            --> vqps_efuse
## efuse clamp
#   FSOURCE         --> vqps_efuse
#   VSS             --> gnd_efuse
globalNetConnect $vars(gnd_nets)   -override -pin VSS -type pgpin -verbose
globalNetConnect $vars(gnd_nets)   -override -pin VPW -type pgpin -verbose
globalNetConnect $vars(power_nets) -override -pin VDD -type pgpin -verbose
globalNetConnect $vars(power_nets) -override -pin VNW -type pgpin -verbose

#
foreach inst [dbGet [dbGet -p2 top.insts.cell.name -regexp AU28HPC].name] {
    if {[dbGet [dbGet -p1 top.insts.name $inst].pgInstTerms.name VDDE] != "0x0"} {
        globalNetConnect $vars(power_nets) -override -pin VDDE -singleInstance $inst -type pgpin -verbose
    } else {
        globalNetConnect $vars(power_nets) -override -pin VDDCE -singleInstance $inst -type pgpin -verbose
        globalNetConnect $vars(power_nets) -override -pin VDDPE -singleInstance $inst -type pgpin -verbose
    }
    globalNetConnect $vars(gnd_nets)   -override -pin VSSE  -singleInstance $inst -type pgpin -verbose
}  

## core CLAMP     :
#   VCC09VESD       --> vdd09
#   GNDVESD         --> vss
if {[lsearch [dbGet top.insts.cell.pgTerms.name] VCC09VESD] != -1} {
    globalNetConnect $vars(power_nets) -type pgpin -override -pin VCC09VESD
}
if {[lsearch [dbGet top.insts.cell.pgTerms.name] GNDVESD] != -1} {
    globalNetConnect $vars(gnd_nets)   -type pgpin -override -pin GNDVESD
}

# inno_ddr_phy    : 
#   PLLVCCA         --> PLLVCCA_0 
#   VDD             --> vdd09
#   VDDQ            --> VDDQ_0
#   VSS             --> vss
set cell  "inno_ddr_phy"
if {[dbGet top.insts.cell.name $cell] != "0x0"} {
    # pg net
    if {[dbGet top.pgNets.name PLLVCCA_0] == "0x0"} {addNet PLLVCCA_0 -power -physical}
    if {[dbGet top.pgNets.name VDDQ_0   ] == "0x0"} {addNet VDDQ_0    -power -physical}
    globalNetConnect PLLVCCA_0 -pin PLLVCCA -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect VDDQ_0    -pin VDDQ    -type pgpin -override -verbose -instanceBasename $cell 
}
# PLLUM28HPCPFRAC : 
#   VDDHV           --> VDDHV_0
#   VDDPOST         --> VDDPOST_0
#   VDDREF          --> VDDREF_0
#   VSS             --> pll_gnd
set cell  "PLLUM28HPCPFRAC"
if {[dbGet top.insts.cell.name $cell] != "0x0"} {
    # pg net
    if {[dbGet top.pgNets.name VDDHV_0  ] == "0x0"} {addNet VDDHV_0   -power  -physical}
    if {[dbGet top.pgNets.name VDDPOST_0] == "0x0"} {addNet VDDPOST_0 -power  -physical}
    if {[dbGet top.pgNets.name VDDREF_0 ] == "0x0"} {addNet VDDREF_0  -power  -physical}
    if {[dbGet top.pgNets.name pll_gnd  ] == "0x0"} {addNet pll_gnd   -ground -physical}
    globalNetConnect VDDHV_0   -pin  VDDHV   -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect VDDPOST_0 -pin  VDDPOST -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect VDDREF_0  -pin  VDDREF  -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect pll_gnd   -pin  VSS     -type pgpin -override -verbose -instanceBasename $cell 
}
# O12P5PHYU28HPCP : 
#   AVDH            --> AVDH_0/AVDH_1
#   AVDL            --> AVDL_0/AVDL_1
#   AVSS            --> AVSS_0/AVSS_1
#   VDDD            --> VDD_1/VDD_2  
#   VDDU            --> VDD_2/VDD_3  
#   VSSD            --> VSS_1/VSS_2  
#   VSSU            --> VSS_2/VSS_3  
set cell  "O12P5PHYU28HPCP"
if {[dbGet top.insts.cell.name $cell] != "0x0"} {
    # pg net
    if {[dbGet top.pgNets.name AVDH_0/AVDH_1] == "0x0"} {addNet AVDH_0/AVDH_1 -power   -physical}
    if {[dbGet top.pgNets.name AVDL_0/AVDL_1] == "0x0"} {addNet AVDL_0/AVDL_1 -power   -physical}
    if {[dbGet top.pgNets.name AVSS_0/AVSS_1] == "0x0"} {addNet AVSS_0/AVSS_1 -ground  -physical}
    if {[dbGet top.pgNets.name VDD_1/VDD_2  ] == "0x0"} {addNet VDD_1/VDD_2   -power   -physical}
    if {[dbGet top.pgNets.name VDD_2/VDD_3  ] == "0x0"} {addNet VDD_2/VDD_3   -power   -physical}
    if {[dbGet top.pgNets.name VSS_1/VSS_2  ] == "0x0"} {addNet VSS_1/VSS_2   -ground  -physical}
    if {[dbGet top.pgNets.name VSS_2/VSS_3  ] == "0x0"} {addNet VSS_2/VSS_3   -ground  -physical}
    globalNetConnect AVDH_0/AVDH_1 -pin  AVDH -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect AVDL_0/AVDL_1 -pin  AVDL -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect AVSS_0/AVSS_1 -pin  AVSS -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect VDD_1/VDD_2   -pin  VDDD -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect VDD_2/VDD_3   -pin  VDDU -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect VSS_1/VSS_2   -pin  VSSD -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect VSS_2/VSS_3   -pin  VSSU -type pgpin -override -verbose -instanceBasename $cell 
}
# FXEDP447EWHJ0P  : (pad) 
#   GNDA            --> GNDA
#   GNDK            --> vss
#   VCC09K          --> vdd09
#   VCC18A_RX       --> VCC18A_RX
#   VCC18A_TX       --> VCC18A_TX
#   VCC33A          --> VCC33A
set cell  "FXEDP447EWHJ0P"
if {[dbGet top.insts.cell.name $cell] != "0x0"} {
    # pg net
    if {[dbGet top.pgNets.name GNDA     ] == "0x0"} {addNet GNDA      -ground  -physical}
    if {[dbGet top.pgNets.name vdd09    ] == "0x0"} {addNet vdd09     -power   -physical}
    if {[dbGet top.pgNets.name VCC18A_RX] == "0x0"} {addNet VCC18A_RX -power   -physical}
    if {[dbGet top.pgNets.name VCC18A_TX] == "0x0"} {addNet VCC18A_TX -power   -physical}
    if {[dbGet top.pgNets.name VCC33A   ] == "0x0"} {addNet VCC33A    -power   -physical}
    globalNetConnect GNDA      -pin  GNDA      -type pgpin -override -verbose -singleInstance [dbGet [dbGet -p2 top.insts.cell.name $cell].name] 
    globalNetConnect vss       -pin  GNDK      -type pgpin -override -verbose -singleInstance [dbGet [dbGet -p2 top.insts.cell.name $cell].name] 
    globalNetConnect vdd09     -pin  VCC09K    -type pgpin -override -verbose -singleInstance [dbGet [dbGet -p2 top.insts.cell.name $cell].name] 
    globalNetConnect VCC18A_RX -pin  VCC18A_RX -type pgpin -override -verbose -singleInstance [dbGet [dbGet -p2 top.insts.cell.name $cell].name] 
    globalNetConnect VCC18A_TX -pin  VCC18A_TX -type pgpin -override -verbose -singleInstance [dbGet [dbGet -p2 top.insts.cell.name $cell].name] 
    globalNetConnect VCC33A    -pin  VCC33A    -type pgpin -override -verbose -singleInstance [dbGet [dbGet -p2 top.insts.cell.name $cell].name] 
}
# U2OPHYU28HPCP           : 
#   AGND            --> AGND_0
#   VCCA18          --> VCCA18_0
#   VCCA33          --> VCCA33_0
#   VDDA            --> VDDA_0
#   VSSD1           --> VSSD1_0
#   VSSD2           --> VSSD2_0
set cell  "U2OPHYU28HPCP"
if {[dbGet top.insts.cell.name $cell] != "0x0"} {
    # pg net
    if {[dbGet top.pgNets.name AGND_0  ] == "0x0"} {addNet AGND_0   -ground  -physical}
    if {[dbGet top.pgNets.name VCCA18_0] == "0x0"} {addNet VCCA18_0 -power   -physical}
    if {[dbGet top.pgNets.name VCCA33_0] == "0x0"} {addNet VCCA33_0 -power   -physical}
    if {[dbGet top.pgNets.name VDDA_0  ] == "0x0"} {addNet VDDA_0   -power   -physical}
    if {[dbGet top.pgNets.name VSSD1_0 ] == "0x0"} {addNet VSSD1_0  -ground  -physical}
    if {[dbGet top.pgNets.name VSSD2_0 ] == "0x0"} {addNet VSSD2_0  -ground  -physical}
    globalNetConnect AGND_0   -pin  AGND   -type pgpin -override -verbose -instanceBasename u2phy  
    globalNetConnect VCCA18_0 -pin  VCCA18 -type pgpin -override -verbose -instanceBasename u2phy  
    globalNetConnect VCCA33_0 -pin  VCCA33 -type pgpin -override -verbose -instanceBasename u2phy  
    globalNetConnect VDDA_0   -pin  VDDA   -type pgpin -override -verbose -instanceBasename u2phy  
    globalNetConnect VSSD1_0  -pin  VSSD1  -type pgpin -override -verbose -instanceBasename u2phy  
    globalNetConnect VSSD2_0  -pin  VSSD2  -type pgpin -override -verbose -instanceBasename u2phy  
}
# GSM3PHYU28CPL1           : 
#   AVDH            --> AVDH_0
#   AVDL            --> AVDL_0
#   AVSS            --> AVSS_0
#   VDD             --> vdd09
#   VDDA            --> vdd09
#   VDDB            --> vdd09
#   VSS             --> vss
#   VSSA            --> vss
#   VSSB            --> VSSD2_1
set cell  "GSM3PHYU28CPL1"
if {[dbGet top.insts.cell.name $cell] != "0x0"} {
    # pg net
    if {[dbGet top.pgNets.name AVDH_0  ] == "0x0"} {addNet AVDH_0   -power   -physical}
    if {[dbGet top.pgNets.name AVDL_0  ] == "0x0"} {addNet AVDL_0   -power   -physical}
    if {[dbGet top.pgNets.name AVSS_0  ] == "0x0"} {addNet AVSS_0   -ground  -physical}
    if {[dbGet top.pgNets.name ASSD2_1 ] == "0x0"} {addNet ASSD2_1  -ground  -physical}
    globalNetConnect AVDH_0   -pin  AVDH  -type pgpin -override -verbose -instanceBasename ssphy 
    globalNetConnect AVDL_0   -pin  AVDL  -type pgpin -override -verbose -instanceBasename ssphy 
    globalNetConnect AVSS_0   -pin  AVSS  -type pgpin -override -verbose -instanceBasename ssphy 
    globalNetConnect vdd09    -pin  VDD   -type pgpin -override -verbose -instanceBasename ssphy 
    globalNetConnect vdd09    -pin  VDDA  -type pgpin -override -verbose -instanceBasename ssphy 
    globalNetConnect vdd09    -pin  VDDB  -type pgpin -override -verbose -instanceBasename ssphy 
    globalNetConnect vss      -pin  VSS   -type pgpin -override -verbose -instanceBasename ssphy 
    globalNetConnect vss      -pin  VSSA  -type pgpin -override -verbose -instanceBasename ssphy 
    globalNetConnect VSSD2_1  -pin  VSSB  -type pgpin -override -verbose -instanceBasename ssphy 
}
## ljpll CLAMP     :
#   GNDVESD         --> ljpll_gnd
#   VCC3VESD        --> ljpll_vddhv
#   VCC09VESD       --> ljpll_vddpost
#   VCC09VESD       --> ljpll_vddref
## ljpll 
#   PSUB            --> ljpll_gnd
#   VDDHV           --> ljpll_vddhv
#   VDDPOST         --> ljpll_vddpost
#   VDDREF          --> ljpll_vddref
#   VSS             --> ljpll_gnd
set cell  "PLLUM28HPCPLJFRACB"
if {[dbGet top.insts.cell.name $cell] != "0x0"} {
    # pg net
    if {[dbGet top.pgNets.name ljpll_gnd     ] == "0x0"} {addNet ljpll_gnd     -ground -physical}
    if {[dbGet top.pgNets.name ljpll_vddhv   ] == "0x0"} {addNet ljpll_vddhv   -power  -physical}
    if {[dbGet top.pgNets.name ljpll_vddpost ] == "0x0"} {addNet ljpll_vddpost -power  -physical}
    if {[dbGet top.pgNets.name ljpll_vddref  ] == "0x0"} {addNet ljpll_vddref  -power  -physical}
    globalNetConnect ljpll_gnd     -pin PSUB      -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect ljpll_vddhv   -pin VDDHV     -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect ljpll_vddpost -pin VDDPOST   -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect ljpll_vddref  -pin VDDREF    -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect ljpll_gnd     -pin VSS       -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect ljpll_gnd     -pin GNDVESD   -type pgpin -override -verbose -singleInstance clamp_inst_ljpll_vddhv   ;# ljpll clamp hv
    globalNetConnect ljpll_vddhv   -pin VCC3VESD  -type pgpin -override -verbose -singleInstance clamp_inst_ljpll_vddhv   ;#
    globalNetConnect ljpll_gnd     -pin GNDVESD   -type pgpin -override -verbose -singleInstance clamp_inst_ljpll_vddref  ;# ljpll clamp ref
    globalNetConnect ljpll_vddref  -pin VCC09VESD -type pgpin -override -verbose -singleInstance clamp_inst_ljpll_vddref  ;# 
    globalNetConnect ljpll_gnd     -pin GNDVESD   -type pgpin -override -verbose -singleInstance clamp_inst_ljpll_vddref_copy_1  ;# ljpll clamp ref
    globalNetConnect ljpll_vddref  -pin VCC09VESD -type pgpin -override -verbose -singleInstance clamp_inst_ljpll_vddref_copy_1  ;# 
    globalNetConnect ljpll_gnd     -pin GNDVESD   -type pgpin -override -verbose -singleInstance clamp_inst_ljpll_vddpost ;# ljpll clamp post
    globalNetConnect ljpll_vddpost -pin VCC09VESD -type pgpin -override -verbose -singleInstance clamp_inst_ljpll_vddpost ;# 
    globalNetConnect ljpll_gnd     -pin GNDVESD   -type pgpin -override -verbose -singleInstance clamp_inst_ljpll_vddpost_copy_0 ;# ljpll clamp post
    globalNetConnect ljpll_vddpost -pin VCC09VESD -type pgpin -override -verbose -singleInstance clamp_inst_ljpll_vddpost_copy_0 ;# 
}
## pll CLAMP     :
#   GNDVESD         --> pll_gnd
#   VCC09VESD       --> pll_vddpost
#   VCC09VESD       --> pll_vddref
#   VCC3VESD        --> pll_vddhv
## pll
#   VDDHV           --> pll_vddhv
#   VDDPOST         --> pll_vddpost
#   VDDREF          --> pll_vddref
#   VSS             --> pll_gnd
#
set cell  "PLLUM28HPCPFRAC"
if {[dbGet top.insts.cell.name $cell] != "0x0"} {
    # pg net
    if {[dbGet top.pgNets.name pll_gnd     ] == "0x0"} {addNet pll_gnd     -ground -physical}
    if {[dbGet top.pgNets.name pll_vddhv   ] == "0x0"} {addNet pll_vddhv   -power  -physical}
    if {[dbGet top.pgNets.name pll_vddpost ] == "0x0"} {addNet pll_vddpost -power  -physical}
    if {[dbGet top.pgNets.name pll_vddref  ] == "0x0"} {addNet pll_vddref  -power  -physical}
    globalNetConnect pll_gnd     -pin VSS       -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect pll_vddhv   -pin VDDHV     -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect pll_vddpost -pin VDDPOST   -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect pll_vddref  -pin VDDREF    -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect pll_gnd     -pin GNDVESD   -type pgpin -override -verbose -singleInstance clamp_inst_pll_vddhv   ;# pll clamp hv
    globalNetConnect pll_vddhv   -pin VCC3VESD  -type pgpin -override -verbose -singleInstance clamp_inst_pll_vddhv   ;#
    globalNetConnect pll_gnd     -pin GNDVESD   -type pgpin -override -verbose -singleInstance clamp_inst_pll_vddref  ;# pll clamp ref
    globalNetConnect pll_vddref  -pin VCC09VESD -type pgpin -override -verbose -singleInstance clamp_inst_pll_vddref  ;# 
    globalNetConnect pll_gnd     -pin GNDVESD   -type pgpin -override -verbose -singleInstance clamp_inst_pll_vddpost ;# pll clamp post
    globalNetConnect pll_vddpost -pin VCC09VESD -type pgpin -override -verbose -singleInstance clamp_inst_pll_vddpost ;# 
    globalNetConnect pll_gnd     -pin GNDVESD   -type pgpin -override -verbose -singleInstance clamp_inst_pll_vddref_copy_3  ;# pll clamp ref
    globalNetConnect pll_vddref  -pin VCC09VESD -type pgpin -override -verbose -singleInstance clamp_inst_pll_vddref_copy_3  ;# 
    globalNetConnect pll_gnd     -pin GNDVESD   -type pgpin -override -verbose -singleInstance clamp_inst_pll_vddpost_copy_2 ;# pll clamp post
    globalNetConnect pll_vddpost -pin VCC09VESD -type pgpin -override -verbose -singleInstance clamp_inst_pll_vddpost_copy_2 ;# 
}
## CPOR1P8U28HPCP
#   VDD             --> vdd09
#   VDD18           --> pvt_vdd18
#   VSS             --> vss
#   VSS18           --> vss
set cell  "CPOR1P8U28HPCP"
if {[dbGet top.insts.cell.name $cell] != "0x0"} {
    # pg net
    if {[dbGet top.pgNets.name vss      ] == "0x0"} {addNet vss       -ground -physical}
    if {[dbGet top.pgNets.name vdd09    ] == "0x0"} {addNet vdd09     -power  -physical}
    if {[dbGet top.pgNets.name pvt_vdd18] == "0x0"} {addNet pvt_vdd18 -power  -physical}
    globalNetConnect vss       -pin VSS       -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect vss       -pin VSS18     -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect vdd09     -pin VDD       -type pgpin -override -verbose -instanceBasename $cell 
    globalNetConnect pvt_vdd18 -pin VDD18     -type pgpin -override -verbose -instanceBasename $cell 
}
## UMC028_PVT_01_module
#   GND             --> vss
#   VDD09           --> vdd09
#   VDD18           --> pvt_vdd18
## UMC028_PVT_01_SU09
#   GND             --> vss
#   VDD18           --> pvt_vdd18
#   VIN             --> vdd09
#   VIN_GND         --> vss
set cell  "UMC028_PVT_01_module"
if {[dbGet top.insts.cell.name $cell] != "0x0"} {
    # pg net
    if {[dbGet top.pgNets.name vss      ] == "0x0"} {addNet vss       -ground -physical}
    if {[dbGet top.pgNets.name vdd09    ] == "0x0"} {addNet vdd09     -power  -physical}
    if {[dbGet top.pgNets.name pvt_vdd18] == "0x0"} {addNet pvt_vdd18 -power  -physical}
	foreach inst [dbGet [dbGet -p2 top.insts.cell.name $cell].name] {
        globalNetConnect vss       -pin GND       -type pgpin -override -verbose -singleInstance $inst
        globalNetConnect vdd09     -pin VDD09     -type pgpin -override -verbose -singleInstance $inst
        globalNetConnect pvt_vdd18 -pin VDD18     -type pgpin -override -verbose -singleInstance $inst
	}
    globalNetConnect vss       -pin GND       -type pgpin -override -verbose -singleInstance chip_core_inst/UMC028_PVT_01_pd_inst;# pvt 01 pd 
    globalNetConnect vdd09     -pin VDD09     -type pgpin -override -verbose -singleInstance chip_core_inst/UMC028_PVT_01_pd_inst
    globalNetConnect pvt_vdd18 -pin VDD18     -type pgpin -override -verbose -singleInstance chip_core_inst/UMC028_PVT_01_pd_inst
    globalNetConnect vss       -pin GND       -type pgpin -override -verbose -singleInstance chip_core_inst/UMC028_PVT_01_SU_VBAT_inst0;# pvt 01 su vbat 
    globalNetConnect vss       -pin VIN_GND   -type pgpin -override -verbose -singleInstance chip_core_inst/UMC028_PVT_01_SU_VBAT_inst0
    globalNetConnect pvt_vdd18 -pin VDD18     -type pgpin -override -verbose -singleInstance chip_core_inst/UMC028_PVT_01_SU_VBAT_inst0
    globalNetConnect vss       -pin GND       -type pgpin -override -verbose -singleInstance chip_core_inst/UMC028_PVT_01_SU09_inst0;# pvt 01 su09 inst 0
    globalNetConnect vss       -pin VIN_GND   -type pgpin -override -verbose -singleInstance chip_core_inst/UMC028_PVT_01_SU09_inst0
    globalNetConnect pvt_vdd18 -pin VDD18     -type pgpin -override -verbose -singleInstance chip_core_inst/UMC028_PVT_01_SU09_inst0
    globalNetConnect vss       -pin GND       -type pgpin -override -verbose -singleInstance chip_core_inst/UMC028_PVT_01_SU09_inst1;# pvt 01 su09 inst 1 
    globalNetConnect vss       -pin VIN_GND   -type pgpin -override -verbose -singleInstance chip_core_inst/UMC028_PVT_01_SU09_inst1
    globalNetConnect pvt_vdd18 -pin VDD18     -type pgpin -override -verbose -singleInstance chip_core_inst/UMC028_PVT_01_SU09_inst1
}
## u028efucp01603218400
#   VDD             --> vdd09
#   VSS             --> gnd_efuse
#   VQPS            --> vqps_efuse
## efuse clamp
#   FSOURCE         --> vqps_efuse
#   VSS             --> gnd_efuse
set cell  "u028efucp01603218400"
if {[dbGet top.insts.cell.name $cell] != "0x0"} {
    # pg net
    if {[dbGet top.pgNets.name gnd_efuse ] == "0x0"} {addNet gnd_efuse   -ground -physical}
    if {[dbGet top.pgNets.name vqps_efuse] == "0x0"} {addNet vqps_efuse  -power  -physical}
    foreach inst [dbGet [dbGet -p2 top.insts.cell.name $cell].name] {
        globalNetConnect gnd_efuse  -pin VSS       -type pgpin -override -verbose -singleInstance $inst
        globalNetConnect vdd09      -pin VDD       -type pgpin -override -verbose -singleInstance $inst
        globalNetConnect vqps_efuse -pin VQPS      -type pgpin -override -verbose -singleInstance $inst
    }
    globalNetConnect vqps_efuse -pin FSOURCE   -type pgpin -override -verbose -singleInstance clamp_inst_efuse_vqps ;# efuse clamp
    globalNetConnect gnd_efuse  -pin VSS       -type pgpin -override -verbose -singleInstance clamp_inst_efuse_vqps
    globalNetConnect vqps_efuse -pin FSOURCE   -type pgpin -override -verbose -singleInstance clamp_inst_efuse_vqps_copy_4 ;# efuse clamp
    globalNetConnect gnd_efuse  -pin VSS       -type pgpin -override -verbose -singleInstance clamp_inst_efuse_vqps_copy_4
}
# ddr pll clamp
if {[dbGet top.insts.name clamp_inst_ddrpll_vddhv] != "0x0"} {
    # pg net
    if {[dbGet top.pgNets.name ddrpll_gnd] == "0x0"}     {addNet ddrpll_gnd     -ground -physical}
    if {[dbGet top.pgNets.name ddrpll_vddref] == "0x0"}  {addNet ddrpll_vddref  -power  -physical}
    if {[dbGet top.pgNets.name ddrpll_vddpost] == "0x0"} {addNet ddrpll_vddpost -power  -physical}
    if {[dbGet top.pgNets.name ddrpll_vddhv] == "0x0"}   {addNet ddrpll_vddhv   -power  -physical}
	globalNetConnect ddrpll_gnd     -pin GNDVESD    -type pgpin -override -verbose -singleInstance clamp_inst_ddrpll_vddhv
	globalNetConnect ddrpll_vddhv   -pin VCC3VESD   -type pgpin -override -verbose -singleInstance clamp_inst_ddrpll_vddhv
	globalNetConnect ddrpll_gnd     -pin GNDVESD    -type pgpin -override -verbose -singleInstance clamp_inst_ddrpll_vddpost
	globalNetConnect ddrpll_vddpost -pin VCC09VESD  -type pgpin -override -verbose -singleInstance clamp_inst_ddrpll_vddpost
	globalNetConnect ddrpll_gnd     -pin GNDVESD    -type pgpin -override -verbose -singleInstance clamp_inst_ddrpll_vddref
	globalNetConnect ddrpll_vddref  -pin VCC09VESD  -type pgpin -override -verbose -singleInstance clamp_inst_ddrpll_vddref
}
set inst "ddr_crm_wrapper/spll2/PLLUM28HPCPFRAC"
if {[dbGet top.insts.name $inst] != "0x0"} {
    # pg net
    if {[dbGet top.pgNets.name VDDHV_0  ] == "0x0"} {addNet VDDHV_0   -power  -physical}
    if {[dbGet top.pgNets.name VDDPOST_0] == "0x0"} {addNet VDDPOST_0 -power  -physical}
    if {[dbGet top.pgNets.name VDDREF_0 ] == "0x0"} {addNet VDDREF_0  -power  -physical}
    if {[dbGet top.pgNets.name pll_gnd  ] == "0x0"} {addNet pll_gnd   -ground -physical}
    globalNetConnect VDDHV_0   -pin  VDDHV   -type pgpin -override -verbose -singleInstance $inst 
    globalNetConnect VDDPOST_0 -pin  VDDPOST -type pgpin -override -verbose -singleInstance $inst 
    globalNetConnect VDDREF_0  -pin  VDDREF  -type pgpin -override -verbose -singleInstance $inst 
    globalNetConnect pll_gnd   -pin  VSS     -type pgpin -override -verbose -singleInstance $inst 
}
# tie
#globalNetConnect $vars(gnd_nets)   -type tielo -inst * -verbose
#globalNetConnect $vars(power_nets) -type tiehi -inst * -verbose
