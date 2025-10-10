mkdir -p work/${DATAOUT_VERSION}/dummy/BEOL
mkdir -p rpt/${DATAOUT_VERSION}
mkdir -p log/${DATAOUT_VERSION}

cd work/${DATAOUT_VERSION}/dummy/BEOL
calibre -32 -drc -hier -hyper -turbo 64 /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/scr/Dummy_Metal.tcl | tee /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/log/${DATAOUT_VERSION}/${DESIGN}.dummy_BEOL.log 

