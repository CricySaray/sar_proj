#!/bin/bash
#prefix="~/T22ULL_TECH/STARRC/nxtgrd/"
rcs="cbest cworst rcbest rcworst rcworst_T cworst_T typical"
temps="125 -40 0 85"
for rc in ${rcs}
do
	if [ $rc == "TYPICAL" ]
	then
		rc1="typ"
	else
		rc1=${rc}
	fi
	for t in ${temps}
	do
		if [ $t == "-40" ]
		then
			t1="n40"
		else
			t1=${t}
		fi
		echo "CORNER_NAME: ${rc1}_${t1}c" >> corner.smc
		echo "TCAD_GRD_FILE: /process/TSMC28/PDK/tn28crbl046b1_1_3p2a/RC_Star-RCXT_crn28hpc+_1p8m_5x1z1u_ut-alrdl_9corners_1.3p2a/RC_Star-RCXT_crn28hpc+_1p08m+ut-alrdl_5x1z1u_${rc}/crn28hpc+_1p08m+ut-alrdl_5x1z1u_${rc}.nxtgrd" >> corner.smc
		echo "OPERATING_TEMPERATURE: ${t} " >> corner.smc
		echo "" >> corner.smc
	done
done

