#! tvf
namespace import tvf::VERBATIM tvf::LAYOUT tvf::DRC tvf::INCLUDE

LAYOUT SYSTEM GDSII
LAYOUT PATH '/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/dataout/$env(DATAOUT_VERSION)/gds/$env(DESIGN).pr.afe.text.gds.gz'
LAYOUT PRIMARY $env(DESIGN)

DRC RESULTS DATABASE '/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/dataout/$env(DATAOUT_VERSION)/gds/$env(DESIGN).DM.gds' GDSII _DM       // Output topcell name will be suffixed by _DM
DRC SUMMARY REPORT '/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/dataout/$env(DATAOUT_VERSION)/gds/$env(DESIGN).DM.sum' REPLACE HIER


VERBATIM {
LAYOUT ERROR ON INPUT NO
INCLUDE "/home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/scr/Dummy_Metal_Via_Calibre_28nm.20a.encrypt"
}

