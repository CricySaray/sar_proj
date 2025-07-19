#------------------------------------begin floorplan----------------------------------------------
#source /eda_files/proj/ict8810/backend/be8803/scripts/util/proc 
#source ../scr/setup.invs
#set vars(view_from) $env(view_from)
set vars(view_rpt) $env(view_rpt)
#source ../scr/defineInput.tcl

set vars(step) floorplan
#set vars(pre_step) init
set vars(rpt_dir) "$vars(rpt_dir)/$vars(step)/$vars(view_rpt)"
exec mkdir -p $vars(rpt_dir)

puts "run $vars(step) step start..."
#userRunTimeCalculation -start

##restore database
#if {[info exists vars(debug_mode)] && $vars(debug_mode)=="false"} {
#    restoreDesign $vars(dbs_dir)/$vars(design).$vars(pre_step).$vars(view_from).enc.dat $vars(design)
#}

###load fp and create row
#if {$vars(top_or_block) == "top"} {
#    source ../scr/io/genIoFile.tcl
#    source ../scr/padring/output/current/addPowerIoCell.tcl
#    floorPlan -coreMarginsBy die -site core -d 6100 5299 85 85 85 85
#} else {
#    floorPlan -flip s -site core7T -s 450 1100 1.4 1.4 1.4 1.4 -coreMarginsBy die
#    source ../scr/util/userAssignPin.tcl
#    #loadIoFile ../scr/util/ioFile.io
#    #loadFlan $vars(fp_files)
#}

generateTracks -honorPitch

fixAllIos
##load &comit cpf
if {$vars(lp_mode) == "true" && [info exists vars(upf_file)] && $vars(upf_file) != " "} {
    read_power_intent -1801 $vars(upf_file)
    commit_power_intent -verbose -keepRows
#setObjFPlanBox Group PD_SBY 1.4 1.4 451.36 1101.4
#setObjFPlanPolygon
} elseif { $vars(lp_mode) == "true" && [info exists vars(cpf_file)] && $vars(cpf_file) != " " } {
    read_power_intent -cpf $vars(cpf_file)
    commit_power_intent -keepRows -verbose
}

#create row
deleteRow -all
#createRow -site core7T
#createRow -site bcore7T
#createRow -site gacore7T
initCoreRow

if {[info exists vars(lp_mode)] && $vars(lp_mode) == "true"} {
    set pd_gap [expr 2 * [lindex [join [dbGet top.fPlan.coreSite.size]] 1]]
    set dbgInitUnusedCoreSiteRows 1
    set vars(power_domains) [userGetPowerDomains]
    foreach domain $vars(power_domains) {
        if {[dbPowerDomainNrInst [dbGetPowerDomainByName $domain]] > 0} {
            if {[dbget [dbGetPowerDomainByName $domain].isDefault] == 1} {
                continue
            } else {
                modifyPowerDomainAttr $domain -minGaps $pd_gap $pd_gap $pd_gap $pd_gap
            }
        }
    }
}
        
#check for the low power info,report power domain for level_shit ,iso and pg net
if {$vars(lp_mode) == "true"} {
    foreach domain [userGetPowerDomains] {
        #reportPowerDomain -powerDomain $domain -file $vars(rpt_dir)/[dbgDesignName].$vars(step).reportPowerDomain_$domain.$vars(view_rpt).rpt -shiter
        reportPowerDomain -powerDomain $domain -file $vars(rpt_dir)/[dbgDesignName].$vars(step).reportPowerDomain_$domain.$vars(view_rpt).rpt
    }
    reportShifter -outfile $vars(rpt_dir)/[dbgDesignName].$vars(step).reportShifter.$vars(view_rpt).rpt
    reportIsolation -outfile $vars(rpt_dir)/[dbgDesignName].$vars(step).reportIsolation.$vars(view_rpt).rpt
}

##place macro
#source ../scr/macro_loc.tcl
set halo_x [expr 2 * [lindex [join [dbget top.fPlan.coreSite.size]] 1]]
set halo_y [expr 2 * [lindex [join [dbget top.fPlan.coreSite.size]] 1]]

addHaloToBlock $halo_x $halo_y $halo_x $halo_y -allBlock

#check fin grid alinment
checkFPlan -outfile $vars(rpt_dir)/[dbgDesignName].$vars(step).checkplan.$vars(view_rpt).rpt
setInstancePlacementStatus -allHardMacros -status fixed

## create_boundary place/routing blockage
userCreatePlaceBlockage 2
userCreateRouteBlk 1 6

##add power mesh and phsyical cell
#add endcap and broundary cell
source ../scr/util/addEndcapBoundCap.tcl
invsAddEnd
verifyEndCap -report $vars(rpt_dir)/[dbgDesignName].$vars(step).endcap.$vars(view_rpt).rpt

#add powermesh
if { $vars(lp_mode) == "true" } {
} else {
	source /eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/scripts/pg_arm_aon/run_powermesh.tcl
}

#add soft blockage between mem
add_sblk_mem -width 6

#add welltap
set cellPith 116

if {[info exists vars(lp_mode)] && $vars(lp_mode) == "true"} {
    set vars(power_domins) [userGetPowerDomains]
    foreach domain $vars(power_domains) {
        if {[dbPowerDomainNrInst [dbGetPowerDomainByName $domain]] > 0} {
            addWellTap -cell $vars(welltap_cell) -check_channel -cellInterval $cellPith -prefix WELLTAP_$domain -checkerBoard -powerDomain $domain
        }
    }
} else {
    addWellTap -cell $vars(welltap_cell) -check_channel -cellInterval $cellPith -prefix WELLTAP_ -checkerBoard
}

verifyWellTap -rule 30 -cell "$vars(welltap_cell)" -report $vars(rpt_dir)/[dbgDesignName].$vars(step).welltap.$vars(view_rpt).rpt

#check drc and connectivity
verifyConnectivity -noAntenna -type special -noUnroutedNet -report $vars(rpt_dir)/[dbgDesignName].$vars(step).power_verifyConnection.$vars(view_rpt).rpt

if {[regexp {!14} [getVersion]]} {
    verify_drc -limit 100000 -report $vars(rpt_dir)/[dbgDesignName].$vars(step).power_verifydrc.$vars(view_rpt).rpt        
} else {
    verifyGeometry -error 10000 -warning 5000 -report $vars(rpt_dir)/[dbgDesignName].$vars(step).power_verifyGeometry.$vars(view_rpt).rpt        
}

##check filler gap
checkFiller -reportGap [expr $vars(min_gap)/2] -highlight

## defout fp and write out a file 
defOut -floorplan $dsn_def_dir/[dbgDesignName].$vars(step).fp.$vars(view_rpt).def
writeFPlanScript -sections {blocks boundary constraints globalNetConnect groups netGroupAndBusGuide partitions pinBlockages pins placeBlockages routeBlockages} -file $vars(rpt_dir)/[dbgDesignName].$vars(step).$vars(view_rpt).floorplan.tcl ;

##extract block lef

set lef_dir ../../dsn/lef
#lefOut -stripePin -secifyTopLayer 6 -PGpinLayers 7 8 $lef_dir/[dbgDesignName].$vars(step).$vars(view_rpt).lef
write_lef_abstract -5.8 -PGPinLayers "7 8 9" -extractBlockPGPinLayers "7 8 9" -specifyTopLayer 6 $lef_dir/[dbgDesignName].$vars(step).$vars(view_rpt).lef -stripePin

set gate_dir ../../dsn/gate

###netlist
saveNetlist $gate_dir/[dbgDesignName].fp.$vars(view_rpt).vg.gz


# savede    
#saveDesign $vars(dbs_dir)/[dbgDesignName].$vars(step).$vars(view_rpt).enc
puts " ending $vars(step) step..."
#exit
