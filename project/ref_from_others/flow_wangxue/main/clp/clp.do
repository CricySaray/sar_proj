tclmode
puts "TIMESTAMP:[clock format [clock second ] -format %T]: Begin ***Conformal*** "
setenv ISO_SECONDARY_DOMAIN 1
vpx SET RUle Handling -Note "RTL2.13 RTL14 HRC3.5a HRC3.10a HRC3.16 RTL14 IGN5.5 HRC1.4 LIB_LINT_013 LIB_LINT_036 LIB_LINT_037 RTL2.5 RTL14.1 RTL1.2a RTL19.1 RTL1.2 RTL9.16 RTL9.21 RTL2.2 HRC3.2 HRC3.2a RTL9.17"
vpx SET RUle Handling -Warning "CPF_LIB8 CPF_LIB9"
#------------------------------------------------------------------------------#
#	Conformal and lib setup
#------------------------------------------------------------------------------#          
source lib.do
#vpx read lef file "$vars(TECH_LEF)  $vars(LEF_LIBS)"
vpx read library -statetable -liberty -LP ALL "$ss_lib"

#vpx set lowpower option -netlist_style logical
vpx set lowpower option -netlist_style physical 

vpx set lowpower option -SWITCH_CHAIN_checks 
vpx set lowpower option -INCONSISTENT_DOMAIN_CHECK -ANALYSIS_STYLE POST_ROUTE -CHECK_ISO_ON_TO_OFF_NOT_REQUIRED -SUPPORT_CLOCK_ISO_FOR_CLOCK_TREE_CHECKS

vpx set Instantiation depth 100 
vpx analyze library -lowpower -VERbose > ./report/check_lib.rpt


#------------------------------------------------------------------------------#
#	Read design
#------------------------------------------------------------------------------#   
vpx read design -verilog -root CX250UR1_SOC_TOP "/process/TSMC28/projects/CX200UR1/backend/user3/backend/release/CX200UR1/20250903_for_clp/CX250UR1_SOC_TOP.pr.clp.v.gz"

#------------------------------------------------------------------------------#
#	Read upf
#------------------------------------------------------------------------------#  
vpx report black box
vpx read power intent -1801 "/process/TSMC28/projects/CX200UR1/frontend/upf/cx200_ur1.upf"  -POST_ROUTE -replace


#------------------------------------------------------------------------------#
#	CLP check
#------------------------------------------------------------------------------#  
vpx commit power intent 
vpx analyze power domain
vpx report rule check -Error -Warning -Verbose > report/top_check.rpt

vpx report level shifter -verbose > report/ls.rpt
vpx report isolation cell -verbose > report/iso.rpt
vpx report power switch >  report/sw.rpt
 
# exit 


