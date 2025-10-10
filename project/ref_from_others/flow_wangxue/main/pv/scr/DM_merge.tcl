set DESIGN $env(DESIGN)
set VERSION $env(DATAOUT_VERSION)
set design_gds /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/dataout/${VERSION}/gds/${DESIGN}.pr.afe.text.gds.gz
set dm_metal_gds /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/dataout/${VERSION}/gds/${DESIGN}.DM.gds
set dm_ODPO_gds  /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/dataout/${VERSION}/gds/${DESIGN}.DODP.gds

set Ldesign [layout create $design_gds -dt_expand -preserveTextAttributes -preserveProperties]
set topcell [$Ldesign topcell]
set db_unit [$Ldesign units]

foreach regds "$dm_metal_gds" refcell "${DESIGN}_DM" {
	$Ldesign import layout $regds FALSE rename -dt_expand -preserveTextAttributes -preserveProperties
	$Ldesign create ref $topcell $refcell 0.0u 0.0u 0 0 1
}

foreach regds "$dm_ODPO_gds" refcell "${DESIGN}_DODP" {
	$Ldesign import layout $regds FALSE rename -dt_expand -preserveTextAttributes -preserveProperties
	$Ldesign create ref $topcell $refcell 0.0u 0.0u 0 0 1
}

set outMergeGds /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/dataout/${VERSION}/gds/${DESIGN}.MergeDMDP.gds.gz

$Ldesign gdsout $outMergeGds

exit

