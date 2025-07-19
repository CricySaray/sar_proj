#! /usr/bin/csh -f

#bsub -Ip -q I2100_PR  /eda_tools/synopsys/lc/O-2018.06-SP1/bin/lc_shell -f gen_db.tcl |& tee transimate.db.log
bsub -Ip -q I2100_PR  lc_shell -f gen_db.tcl |& tee transimate.db.log
