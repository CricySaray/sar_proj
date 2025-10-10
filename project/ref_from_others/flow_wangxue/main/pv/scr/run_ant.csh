#!/bin/tcsh

mkdir -p {work,rpt,db}/${DATAOUT_VERSION}/ant
mkdir -p log/${DATAOUT_VERSION}

cd work/${DATAOUT_VERSION}/ant
calibre -64 -drc -hier -hyper -turbo 64 /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/scr/calibre_ant.tcl | tee /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/pv/log/${DATAOUT_VERSION}/${DESIGN}.ant.log

