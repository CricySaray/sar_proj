#! tvf
namespace import tvf::VERBATIM tvf::LAYOUT tvf::DRC

LAYOUT SYSTEM GDSII
LAYOUT PATH '/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/dataout/08011453/gds/CX200UR1_SOC_TOP.pr.afe.text.gds.gz'
#LAYOUT PATH '/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/dataout/$env(DATAOUT_VERSION)/gds/$env(DESIGN).MergeDMDP.gds.gz'
LAYOUT PRIMARY $env(DESIGN)

DRC RESULTS DATABASE '/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/db/$env(DATAOUT_VERSION)/drc/$env(DESIGN).DRC.db'
DRC SUMMARY REPORT '/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/rpt/$env(DATAOUT_VERSION)/drc/$env(DESIGN).DRC.rep'  // HIER

VERBATIM {

//VARIABLE PAD_TEXT ""
//VARIABLE VSS_TEXT ""
//VARIABLE VDD_TEXT ""

DRC CHECK TEXT ALL
DRC MAXIMUM RESULTS ALL
//DRC MAXIMUM RESULTS 2000
INCLUDE "/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/scr/calibre.drc_new"
//INCLUDE "/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/dataout/for_pv/layout_text.tcl"
//INCLUDE "/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/dataout/for_pv/layout_text_voltage.tcl"
}

