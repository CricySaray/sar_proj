#!/bin/tcsh

mkdir -p {work,rpt}/${DATAOUT_VERSION}/lvs
mkdir -p {rpt,db}/${DATAOUT_VERSION}/erc
mkdir -p log/${DATAOUT_VERSION}

cd work/${DATAOUT_VERSION}/lvs
calibre -64 -lvs -hier -hyper -turbo 64 -hcell /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/scr/hcell.list /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/scr/calibre_lvs.tcl | tee /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/pv/log/${DATAOUT_VERSION}/${DESIGN}.lvs.log
#calibre -64 -lvs -hier -hyper -turbo 64 /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/scr/calibre_lvs.tcl | tee /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/pv/log/${DATAOUT_VERSION}/${DESIGN}.lvs.log

