 calibre -drc -hier -turbo 64 -64 ./scr/Dummy_OD_PO_Calibre_28nm_HP.20a.encrypt | tee ./add_dummy_od.log
 calibre -drc -hier -turbo 64 -64 ./scr/Dummy_Metal_Via_Calibre_28nm.20a.encrypt | tee ./add_dummy_metal.log
calibredrv -shell
layout filemerge -in /local_disk/home/user2/project/CX100_B_R1/release_for_signoff/0827/gds/cx100b_chip.pr.afe.gds.gz  -in DODPO.gds -in DM.gds -out cx100b_chip_DM.gds -createtop cx100b_chip_DM
exit

