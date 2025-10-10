#!/bin/tcsh

mkdir -p {work,rpt,db}/${DATAOUT_VERSION}/drc
mkdir -p log/${DATAOUT_VERSION}

cd work/${DATAOUT_VERSION}/drc
calibre -64 -drc -hier -hyper -turbo 64 /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/scr/calibre_drc.tcl | tee /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/log/${DATAOUT_VERSION}/${DESIGN}.drc.log

