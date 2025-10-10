#! tvf
namespace import tvf::VERBATIM tvf::LAYOUT tvf::SOURCE tvf::LVS tvf::ERC

#LAYOUT PATH '/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/dataout/$env(DATAOUT_VERSION)/gds/$env(DESIGN).sp'
#LAYOUT PATH '/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/dataout/$env(DATAOUT_VERSION)/gds/$env(DESIGN).pr.afe.text.gds.gz'
LAYOUT PATH '/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/dataout/0216/gds/CX200A_SOC_TOP_wi_dm.gds'
LAYOUT PRIMARY $env(DESIGN)
LAYOUT SYSTEM GDSII
#LAYOUT SYSTEM SPICE

#SOURCE PATH '/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/dataout/$env(DATAOUT_VERSION)/cdl/$env(DESIGN).cdl'
SOURCE PATH '/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/dataout/$env(DATAOUT_VERSION)/cdl/$env(DESIGN).afe.lvs.spi'
SOURCE PRIMARY $env(DESIGN)
SOURCE SYSTEM SPICE

LVS REPORT '/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/pv/rpt/$env(DATAOUT_VERSION)/lvs/$env(DESIGN).LVS.rep'

ERC MAXIMUM RESULTS ALL
ERC RESULTS DATABASE '/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/pv/db/$env(DATAOUT_VERSION)/erc/$env(DESIGN).ERC.db'
ERC SUMMARY REPORT '/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/pv/rpt/$env(DATAOUT_VERSION)/erc/$env(DESIGN).ERC.rep'  

#LVS COMPARE CAE NAMES
#LAYOUT PRESERVE CASE YES

VERBATIM {



//LVS BOX CX200A_SOC_AFE CX200A_SOC_AFE
//INCLUDE "/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/dataout/for_pv/psub.tcl"
INCLUDE "/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/dataout/for_pv/layout_text.tcl"
//INCLUDE "/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/scr/calibre_extract_parasitic_diode.lvs"
INCLUDE "/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/scr/calibre_ana.lvs"

}

