#!/bin/bash
########################################
# author: llsun
# Date: 2017/09/27 19:26:25
# Version: 1.0
# generate all scenario violation rpt summary
# For block level
########################################
scenarios="\
func_ssm40_cworst_T \
func_ssm40_rcworst_T \
func_ss125_cworst_T \
func_ss125_rcworst_T \
func_ssm40_cworst \
func_ssm40_rcworst \
func_ss125_cworst \
func_ss125_rcworst \
func_ffm40_cworst \
func_ffm40_rcworst \
func_ffm40_rcbest \
func_ssm40_rcbest \
func_ffm40_cbest \
func_ff125_cworst \
func_ff125_rcworst \
func_ff125_rcbest \
func_ss125_rcbest \
func_ff125_cbest \
func_ff0_cworst \
func_ff0_rcworst \
func_ff0_rcbest \
func_ff0_cbest \
func_tt_85 \
func_tt_25 \
scan_ssm40_cworst_T \
scan_ssm40_rcworst_T \
scan_ss125_cworst_T \
scan_ss125_rcworst_T \
scan_ssm40_cworst \
scan_ssm40_rcworst \
scan_ss125_cworst \
scan_ss125_rcworst \
scan_ffm40_cworst \
scan_ffm40_rcworst \
scan_ffm40_rcbest \
scan_ffm40_cbest \
scan_ff125_cworst \
scan_ff125_rcworst \
scan_ff125_rcbest \
scan_ff125_cbest \
scan_ff0_cworst \
scan_ff0_rcworst \
scan_ff0_rcbest \
scan_ff0_cbest \
scan_tt_85 \
scan_tt_25 \
func_ssm40_2p5vio_cworst_T \
func_ssm40_2p5vio_rcworst_T \
func_ss125_2p5vio_cworst_T \
func_ss125_2p5vio_rcworst_T \
func_ssm40_2p5vio_cworst \
func_ssm40_2p5vio_rcworst \
func_ss125_2p5vio_cworst \
func_ss125_2p5vio_rcworst \
func_ffm40_2p5vio_cworst \
func_ffm40_2p5vio_rcworst \
func_ffm40_2p5vio_rcbest \
func_ssm40_2p5vio_rcbest \
func_ffm40_2p5vio_cbest \
func_ff125_2p5vio_cworst \
func_ff125_2p5vio_rcworst \
func_ff125_2p5vio_rcbest \
func_ss125_2p5vio_rcbest \
func_ff125_2p5vio_cbest \
func_ff0_2p5vio_cworst \
func_ff0_2p5vio_rcworst \
func_ff0_2p5vio_rcbest \
func_ff0_2p5vio_cbest \
func_tt_2p5vio_85 \
func_tt_2p5vio_25 \
func_ssm40_1p8vio_cworst_T \
func_ssm40_1p8vio_rcworst_T \
func_ss125_1p8vio_cworst_T \
func_ss125_1p8vio_rcworst_T \
func_ssm40_1p8vio_cworst \
func_ssm40_1p8vio_rcworst \
func_ss125_1p8vio_cworst \
func_ss125_1p8vio_rcworst \
func_ffm40_1p8vio_cworst \
func_ffm40_1p8vio_rcworst \
func_ffm40_1p8vio_rcbest \
func_ssm40_1p8vio_rcbest \
func_ffm40_1p8vio_cbest \
func_ff125_1p8vio_cworst \
func_ff125_1p8vio_rcworst \
func_ff125_1p8vio_rcbest \
func_ss125_1p8vio_rcbest \
func_ff125_1p8vio_cbest \
func_ff0_1p8vio_cworst \
func_ff0_1p8vio_rcworst \
func_ff0_1p8vio_rcbest \
func_ff0_1p8vio_cbest \
func_tt_1p8vio_85 \
func_tt_1p8vio_25 \
func_ssm40_0p8std_cworst_T \
func_ssm40_0p8std_rcworst_T \
func_ss125_0p8std_cworst_T \
func_ss125_0p8std_rcworst_T \
func_ssm40_0p8std_cworst \
func_ssm40_0p8std_rcworst \
func_ss125_0p8std_cworst \
func_ss125_0p8std_rcworst \
func_ffm40_0p8std_cworst \
func_ffm40_0p8std_rcworst \
func_ffm40_0p8std_rcbest \
func_ssm40_0p8std_rcbest \
func_ffm40_0p8std_cbest \
func_ff125_0p8std_cworst \
func_ff125_0p8std_rcworst \
func_ff125_0p8std_rcbest \
func_ss125_0p8std_rcbest \
func_ff125_0p8std_cbest \
func_ff0_0p8std_cworst \
func_ff0_0p8std_rcworst \
func_ff0_0p8std_rcbest \
func_ff0_0p8std_cbest \
func_tt_0p8std_85 \
func_tt_0p8std_25 \
"
echo "Scenario reg2reg io max_tran max_cap mpw min_period noise" > ./tmp_vio.sum
#for i in `ls report/$1/*/all_violation_v.rpt`
#do
#	awk -f ./script/rpt_script/vio_summary_block.awk $i
#	#echo 
#done >> ./tmp_vio.sum
#column -t ./tmp_vio.sum > vio_summary.${1}.rpt
#rm -f ./tmp_vio.sum
#
#for i in `ls report/$1/*/all_violation_v.pba.rpt`
#do
#	awk -f ./script/rpt_script/vio_summary_block.awk $i
#	#echo 
#done >> ./tmp_vio.sum
for s in $scenarios
do
	if [ -e ../rm_pt/run/${1}/${s}/ ] 
	then
		awk -f ./vio_summary_block.awk ../rm_pt/run/${1}/${s}/reports/cons_vio_verbose.rpt
	fi
done >> ./tmp_vio.sum
column -t ./tmp_vio.sum > all_vio_summary.${1}.rpt
rm -f ./tmp_vio.sum

echo "Scenario reg2reg io max_tran max_cap mpw min_period noise" > ./tmp_vio.sum
for s in $scenarios
do
	if [ -e ../rm_pt/run/${1}/${s}/ ] 
	then
		awk -f ./vio_summary_block.awk ../rm_pt/run/${1}/${s}/reports/cons_vio_verbose.pba.rpt
	fi
done >> ./tmp_vio.sum
column -t ./tmp_vio.sum > vio_summary.${1}.pba.rpt
rm -f ./tmp_vio.sum

