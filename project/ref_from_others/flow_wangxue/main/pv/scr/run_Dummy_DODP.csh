mkdir -p work/${DATAOUT_VERSION}/dummy/FEOL
mkdir -p rpt/${DATAOUT_VERSION}
mkdir -p log/${DATAOUT_VERSION}

cd work/${DATAOUT_VERSION}/dummy/FEOL
calibre -32 -drc -hier -hyper -turbo 64 /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/scr/Dummy_DODP.tcl | tee /home/user3/project/CX200UR1/CX200UR1_SOC_TOP/pv/pv/log/${DATAOUT_VERSION}/${DESIGN}.dummy_FEOL.log 

