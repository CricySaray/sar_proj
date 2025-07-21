set version        ECO0705_eco_070901
set REPORTS_DIR    "./${version}/rpt/"
set DESIGN_NAME    pcie_block

#set dmsa_corners "wcl_cworst_t lt_cworst ml_cworst wcl_cworst typ_85"
#set dmsa_modes      "func scan"
#set dmsa_check  "setup hold setuphold"
#
####
#foreach mode $dmsa_modes {
#	foreach corner $dmsa_corners {
#		foreach check $dmsa_check {
#			set REPORTS_DIR "./${version}/rpt/${mode}_${corner}_${check}"
#			source scr/get_vio.tcl > $REPORTS_DIR/vio_summary.pba.${version}
#		}
#	}
#}

###cdc
set dmsa_corners      " wcl_cworst_t wcl_rcworst_t \
			wc_cworst_t wc_rcworst_t \
			wcz_cworst_t wcz_rcworst_t \
            "
set dmsa_modes      "cdc"
set dmsa_check  "setup"

foreach mode $dmsa_modes {
	foreach corner $dmsa_corners {
		foreach check $dmsa_check {
			set VIEW  $version
			set REPORTS_DIR "./${version}/rpt/${mode}_${corner}_${check}"
			source scr/get_vio.tcl > $REPORTS_DIR/vio_summary.pba
		}
	}
}
