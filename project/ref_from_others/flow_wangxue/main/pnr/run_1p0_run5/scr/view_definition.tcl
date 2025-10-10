#####lib set
create_library_set  -name  ssm40  -timing  $vars(ssm40_3v3io,timing)
create_library_set  -name  ss125  -timing  $vars(ss125_3v3io,timing)
create_library_set  -name  ffm40  -timing  $vars(ffm40_3v3io,timing)
create_library_set  -name  ff125  -timing  $vars(ff125_3v3io,timing)
create_library_set  -name  ff0    -timing  $vars(ff0_3v3io,timing)
create_library_set  -name  tt_85  -timing  $vars(tt_85_3v3io,timing)

create_library_set  -name  ssm40_2p5io  -timing  $vars(ssm40_2p5io,timing)
create_library_set  -name  ss125_2p5io  -timing  $vars(ss125_2p5io,timing)
create_library_set  -name  ffm40_2p5io  -timing  $vars(ffm40_2p5io,timing)
create_library_set  -name  ff125_2p5io  -timing  $vars(ff125_2p5io,timing)
create_library_set  -name  ff0_2p5io    -timing  $vars(ff0_2p5io,timing)
create_library_set  -name  tt_85_2p5io  -timing  $vars(tt_85_2p5io,timing)

create_library_set  -name  ssm40_1p8io  -timing  $vars(ssm40_1p8io,timing)
create_library_set  -name  ss125_1p8io  -timing  $vars(ss125_1p8io,timing)
create_library_set  -name  ffm40_1p8io  -timing  $vars(ffm40_1p8io,timing)
create_library_set  -name  ff125_1p8io  -timing  $vars(ff125_1p8io,timing)
create_library_set  -name  ff0_1p8io    -timing  $vars(ff0_1p8io,timing)
create_library_set  -name  tt_85_1p8io  -timing  $vars(tt_85_1p8io,timing)

####rc corner
create_rc_corner -name cworst_m40_T \
   -T \
   -40 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_cworst_T/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name cworst_125_T \
   -T 125 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_cworst_T/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name rcworst_m40_T \
   -T \
   -40 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_rcworst_T/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name rcworst_125_T \
   -T 125 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_rcworst_T/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name cworst_m40 \
   -T \
   -40 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_cworst/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name cworst_125 \
   -T 125 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_cworst/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name rcworst_m40 \
   -T \
   -40 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_rcworst/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name rcworst_125 \
   -T 125 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_rcworst/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name cbest_m40 \
   -T \
   -40 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_cbest/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name cbest_125 \
   -T 125 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_cbest/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name rcbest_m40 \
   -T \
   -40 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_rcbest/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name rcbest_125 \
   -T 125 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_rcbest/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name tt_85 \
   -T 85 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_typical/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name cworst_0 \
   -T 0 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_cworst/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name rcworst_0 \
   -T 0 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_rcworst/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name cbest_0 \
   -T 0 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_cbest/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"
create_rc_corner -name rcbest_0 \
   -T 0 \
   -qx_tech_file /process/TSMC28/PDK/tn28clbl198v1_1_3a/RC_QRC_cln28hpc+_1p8m_5x2z_ut-alrdl_9corners_1.3a/RC_QRC_cln28hpc+_1p08m+ut-alrdl_5x2z_rcbest/qrcTechFile \
   -preRoute_res 1.0 \
   -preRoute_cap 1.0 \
   -preRoute_clkres 1.0 \
   -preRoute_clkcap 1.0 \
   -postRoute_res "1.0 1.0 1.0" \
   -postRoute_cap "1.0 1.0 1.0" \
   -postRoute_clkres "1.0 1.0 1.0" \
   -postRoute_clkcap "1.0 1.0 1.0" \
   -postRoute_xcap "1.0 1.0 1.0"

####delay corner
create_delay_corner  -name  tt_85            -library_set  tt_85  -rc_corner  tt_85
create_delay_corner  -name  ssm40_cworst_T   -library_set  ssm40  -rc_corner  cworst_m40_T
create_delay_corner  -name  ssm40_rcworst_T  -library_set  ssm40  -rc_corner  rcworst_m40_T
create_delay_corner  -name  ss125_cworst_T   -library_set  ss125  -rc_corner  cworst_125_T
create_delay_corner  -name  ss125_rcworst_T  -library_set  ss125  -rc_corner  rcworst_125_T
create_delay_corner  -name  ssm40_cworst     -library_set  ssm40  -rc_corner  cworst_m40
create_delay_corner  -name  ssm40_rcworst    -library_set  ssm40  -rc_corner  rcworst_m40
create_delay_corner  -name  ss125_cworst     -library_set  ss125  -rc_corner  cworst_125
create_delay_corner  -name  ss125_rcworst    -library_set  ss125  -rc_corner  rcworst_125
create_delay_corner  -name  ffm40_cworst     -library_set  ffm40  -rc_corner  cworst_m40
create_delay_corner  -name  ffm40_rcworst    -library_set  ffm40  -rc_corner  rcworst_m40
create_delay_corner  -name  ffm40_cbest      -library_set  ffm40  -rc_corner  cbest_m40
create_delay_corner  -name  ffm40_rcbest     -library_set  ffm40  -rc_corner  rcbest_m40
create_delay_corner  -name  ff125_cworst     -library_set  ff125  -rc_corner  cworst_125
create_delay_corner  -name  ff125_rcworst    -library_set  ff125  -rc_corner  rcworst_125
create_delay_corner  -name  ff125_cbest      -library_set  ff125  -rc_corner  cbest_125
create_delay_corner  -name  ff125_rcbest     -library_set  ff125  -rc_corner  rcbest_125
create_delay_corner  -name  ff0_cworst       -library_set  ff0    -rc_corner  cworst_0
create_delay_corner  -name  ff0_rcworst      -library_set  ff0    -rc_corner  rcworst_0
create_delay_corner  -name  ff0_cbest        -library_set  ff0    -rc_corner  cbest_0
create_delay_corner  -name  ff0_rcbest       -library_set  ff0    -rc_corner  rcbest_0

create_delay_corner  -name  tt_85_2p5io            -library_set  tt_85_2p5io  -rc_corner  tt_85
create_delay_corner  -name  ssm40_cworst_T_2p5io   -library_set  ssm40_2p5io  -rc_corner  cworst_m40_T
create_delay_corner  -name  ssm40_rcworst_T_2p5io  -library_set  ssm40_2p5io  -rc_corner  rcworst_m40_T
create_delay_corner  -name  ss125_cworst_T_2p5io   -library_set  ss125_2p5io  -rc_corner  cworst_125_T
create_delay_corner  -name  ss125_rcworst_T_2p5io  -library_set  ss125_2p5io  -rc_corner  rcworst_125_T
create_delay_corner  -name  ssm40_cworst_2p5io     -library_set  ssm40_2p5io  -rc_corner  cworst_m40
create_delay_corner  -name  ssm40_rcworst_2p5io    -library_set  ssm40_2p5io  -rc_corner  rcworst_m40
create_delay_corner  -name  ss125_cworst_2p5io     -library_set  ss125_2p5io  -rc_corner  cworst_125
create_delay_corner  -name  ss125_rcworst_2p5io    -library_set  ss125_2p5io  -rc_corner  rcworst_125
create_delay_corner  -name  ffm40_cworst_2p5io     -library_set  ffm40_2p5io  -rc_corner  cworst_m40
create_delay_corner  -name  ffm40_rcworst_2p5io    -library_set  ffm40_2p5io  -rc_corner  rcworst_m40
create_delay_corner  -name  ffm40_cbest_2p5io      -library_set  ffm40_2p5io  -rc_corner  cbest_m40
create_delay_corner  -name  ffm40_rcbest_2p5io     -library_set  ffm40_2p5io  -rc_corner  rcbest_m40
create_delay_corner  -name  ff125_cworst_2p5io     -library_set  ff125_2p5io  -rc_corner  cworst_125
create_delay_corner  -name  ff125_rcworst_2p5io    -library_set  ff125_2p5io  -rc_corner  rcworst_125
create_delay_corner  -name  ff125_cbest_2p5io      -library_set  ff125_2p5io  -rc_corner  cbest_125
create_delay_corner  -name  ff125_rcbest_2p5io     -library_set  ff125_2p5io  -rc_corner  rcbest_125
create_delay_corner  -name  ff0_cworst_2p5io       -library_set  ff0_2p5io    -rc_corner  cworst_0
create_delay_corner  -name  ff0_rcworst_2p5io      -library_set  ff0_2p5io    -rc_corner  rcworst_0
create_delay_corner  -name  ff0_cbest_2p5io        -library_set  ff0_2p5io    -rc_corner  cbest_0
create_delay_corner  -name  ff0_rcbest_2p5io       -library_set  ff0_2p5io    -rc_corner  rcbest_0


create_delay_corner  -name  tt_85_1p8io            -library_set  tt_85_1p8io  -rc_corner  tt_85
create_delay_corner  -name  ssm40_cworst_T_1p8io   -library_set  ssm40_1p8io  -rc_corner  cworst_m40_T
create_delay_corner  -name  ssm40_rcworst_T_1p8io  -library_set  ssm40_1p8io  -rc_corner  rcworst_m40_T
create_delay_corner  -name  ss125_cworst_T_1p8io   -library_set  ss125_1p8io  -rc_corner  cworst_125_T
create_delay_corner  -name  ss125_rcworst_T_1p8io  -library_set  ss125_1p8io  -rc_corner  rcworst_125_T
create_delay_corner  -name  ssm40_cworst_1p8io     -library_set  ssm40_1p8io  -rc_corner  cworst_m40
create_delay_corner  -name  ssm40_rcworst_1p8io    -library_set  ssm40_1p8io  -rc_corner  rcworst_m40
create_delay_corner  -name  ss125_cworst_1p8io     -library_set  ss125_1p8io  -rc_corner  cworst_125
create_delay_corner  -name  ss125_rcworst_1p8io    -library_set  ss125_1p8io  -rc_corner  rcworst_125
create_delay_corner  -name  ffm40_cworst_1p8io     -library_set  ffm40_1p8io  -rc_corner  cworst_m40
create_delay_corner  -name  ffm40_rcworst_1p8io    -library_set  ffm40_1p8io  -rc_corner  rcworst_m40
create_delay_corner  -name  ffm40_cbest_1p8io      -library_set  ffm40_1p8io  -rc_corner  cbest_m40
create_delay_corner  -name  ffm40_rcbest_1p8io     -library_set  ffm40_1p8io  -rc_corner  rcbest_m40
create_delay_corner  -name  ff125_cworst_1p8io     -library_set  ff125_1p8io  -rc_corner  cworst_125
create_delay_corner  -name  ff125_rcworst_1p8io    -library_set  ff125_1p8io  -rc_corner  rcworst_125
create_delay_corner  -name  ff125_cbest_1p8io      -library_set  ff125_1p8io  -rc_corner  cbest_125
create_delay_corner  -name  ff125_rcbest_1p8io     -library_set  ff125_1p8io  -rc_corner  rcbest_125
create_delay_corner  -name  ff0_cworst_1p8io       -library_set  ff0_1p8io    -rc_corner  cworst_0
create_delay_corner  -name  ff0_rcworst_1p8io      -library_set  ff0_1p8io    -rc_corner  rcworst_0
create_delay_corner  -name  ff0_cbest_1p8io        -library_set  ff0_1p8io    -rc_corner  cbest_0
create_delay_corner  -name  ff0_rcbest_1p8io       -library_set  ff0_1p8io    -rc_corner  rcbest_0
####constraint_mode
create_constraint_mode -name func -sdc_files $vars(func_sdc)
create_constraint_mode -name scan -sdc_files $vars(scan_sdc)
create_constraint_mode -name func_1p8io -sdc_files $vars(func_1p8vio_sdc)

####analysis_view
create_analysis_view  -name  func_ssm40_rcworst_T  -constraint_mode  func  -delay_corner  ssm40_rcworst_T
create_analysis_view  -name  func_ssm40_cworst_T   -constraint_mode  func  -delay_corner  ssm40_cworst_T
create_analysis_view  -name  func_ss125_rcworst_T  -constraint_mode  func  -delay_corner  ss125_rcworst_T
create_analysis_view  -name  func_ss125_cworst_T   -constraint_mode  func  -delay_corner  ss125_cworst_T
create_analysis_view  -name  func_ff0_cbest        -constraint_mode  func  -delay_corner  ff0_cbest
create_analysis_view  -name  func_ff0_cworst       -constraint_mode  func  -delay_corner  ff0_cworst
create_analysis_view  -name  func_ff0_rcbest       -constraint_mode  func  -delay_corner  ff0_rcbest
create_analysis_view  -name  func_ff0_rcworst      -constraint_mode  func  -delay_corner  ff0_rcworst
create_analysis_view  -name  func_ff125_cbest      -constraint_mode  func  -delay_corner  ff125_cbest
create_analysis_view  -name  func_ff125_cworst     -constraint_mode  func  -delay_corner  ff125_cworst
create_analysis_view  -name  func_ff125_rcbest     -constraint_mode  func  -delay_corner  ff125_rcbest
create_analysis_view  -name  func_ff125_rcworst    -constraint_mode  func  -delay_corner  ff125_rcworst
create_analysis_view  -name  func_ffm40_cbest      -constraint_mode  func  -delay_corner  ffm40_cbest
create_analysis_view  -name  func_ffm40_cworst     -constraint_mode  func  -delay_corner  ffm40_cworst
create_analysis_view  -name  func_ffm40_rcbest     -constraint_mode  func  -delay_corner  ffm40_rcbest
create_analysis_view  -name  func_ffm40_rcworst    -constraint_mode  func  -delay_corner  ffm40_rcworst
create_analysis_view  -name  func_ss125_cworst     -constraint_mode  func  -delay_corner  ss125_cworst
create_analysis_view  -name  func_ss125_rcworst    -constraint_mode  func  -delay_corner  ss125_rcworst
create_analysis_view  -name  func_ssm40_cworst     -constraint_mode  func  -delay_corner  ssm40_cworst
create_analysis_view  -name  func_ssm40_rcworst    -constraint_mode  func  -delay_corner  ssm40_rcworst
create_analysis_view  -name  func_tt85             -constraint_mode  func  -delay_corner  tt_85

create_analysis_view  -name  func_ssm40_rcworst_T_2p5io  -constraint_mode  func  -delay_corner  ssm40_rcworst_T_2p5io
create_analysis_view  -name  func_ssm40_cworst_T_2p5io   -constraint_mode  func  -delay_corner  ssm40_cworst_T_2p5io
create_analysis_view  -name  func_ss125_rcworst_T_2p5io  -constraint_mode  func  -delay_corner  ss125_rcworst_T_2p5io
create_analysis_view  -name  func_ss125_cworst_T_2p5io   -constraint_mode  func  -delay_corner  ss125_cworst_T_2p5io
create_analysis_view  -name  func_ff0_cbest_2p5io        -constraint_mode  func  -delay_corner  ff0_cbest_2p5io
create_analysis_view  -name  func_ff0_cworst_2p5io       -constraint_mode  func  -delay_corner  ff0_cworst_2p5io
create_analysis_view  -name  func_ff0_rcbest_2p5io       -constraint_mode  func  -delay_corner  ff0_rcbest_2p5io
create_analysis_view  -name  func_ff0_rcworst_2p5io      -constraint_mode  func  -delay_corner  ff0_rcworst_2p5io
create_analysis_view  -name  func_ff125_cbest_2p5io      -constraint_mode  func  -delay_corner  ff125_cbest_2p5io
create_analysis_view  -name  func_ff125_cworst_2p5io     -constraint_mode  func  -delay_corner  ff125_cworst_2p5io
create_analysis_view  -name  func_ff125_rcbest_2p5io     -constraint_mode  func  -delay_corner  ff125_rcbest_2p5io
create_analysis_view  -name  func_ff125_rcworst_2p5io    -constraint_mode  func  -delay_corner  ff125_rcworst_2p5io
create_analysis_view  -name  func_ffm40_cbest_2p5io      -constraint_mode  func  -delay_corner  ffm40_cbest_2p5io
create_analysis_view  -name  func_ffm40_cworst_2p5io     -constraint_mode  func  -delay_corner  ffm40_cworst_2p5io
create_analysis_view  -name  func_ffm40_rcbest_2p5io     -constraint_mode  func  -delay_corner  ffm40_rcbest_2p5io
create_analysis_view  -name  func_ffm40_rcworst_2p5io    -constraint_mode  func  -delay_corner  ffm40_rcworst_2p5io
create_analysis_view  -name  func_ss125_cworst_2p5io     -constraint_mode  func  -delay_corner  ss125_cworst_2p5io
create_analysis_view  -name  func_ss125_rcworst_2p5io    -constraint_mode  func  -delay_corner  ss125_rcworst_2p5io
create_analysis_view  -name  func_ssm40_cworst_2p5io     -constraint_mode  func  -delay_corner  ssm40_cworst_2p5io
create_analysis_view  -name  func_ssm40_rcworst_2p5io    -constraint_mode  func  -delay_corner  ssm40_rcworst_2p5io
create_analysis_view  -name  func_tt85_2p5io             -constraint_mode  func  -delay_corner  tt_85_2p5io

create_analysis_view  -name  func_ssm40_rcworst_T_1p8io  -constraint_mode  func_1p8io  -delay_corner  ssm40_rcworst_T_1p8io
create_analysis_view  -name  func_ssm40_cworst_T_1p8io   -constraint_mode  func_1p8io  -delay_corner  ssm40_cworst_T_1p8io
create_analysis_view  -name  func_ss125_rcworst_T_1p8io  -constraint_mode  func_1p8io  -delay_corner  ss125_rcworst_T_1p8io
create_analysis_view  -name  func_ss125_cworst_T_1p8io   -constraint_mode  func_1p8io  -delay_corner  ss125_cworst_T_1p8io
create_analysis_view  -name  func_ff0_cbest_1p8io        -constraint_mode  func_1p8io  -delay_corner  ff0_cbest_1p8io
create_analysis_view  -name  func_ff0_cworst_1p8io       -constraint_mode  func_1p8io  -delay_corner  ff0_cworst_1p8io
create_analysis_view  -name  func_ff0_rcbest_1p8io       -constraint_mode  func_1p8io  -delay_corner  ff0_rcbest_1p8io
create_analysis_view  -name  func_ff0_rcworst_1p8io      -constraint_mode  func_1p8io  -delay_corner  ff0_rcworst_1p8io
create_analysis_view  -name  func_ff125_cbest_1p8io      -constraint_mode  func_1p8io  -delay_corner  ff125_cbest_1p8io
create_analysis_view  -name  func_ff125_cworst_1p8io     -constraint_mode  func_1p8io  -delay_corner  ff125_cworst_1p8io
create_analysis_view  -name  func_ff125_rcbest_1p8io     -constraint_mode  func_1p8io  -delay_corner  ff125_rcbest_1p8io
create_analysis_view  -name  func_ff125_rcworst_1p8io    -constraint_mode  func_1p8io  -delay_corner  ff125_rcworst_1p8io
create_analysis_view  -name  func_ffm40_cbest_1p8io      -constraint_mode  func_1p8io  -delay_corner  ffm40_cbest_1p8io
create_analysis_view  -name  func_ffm40_cworst_1p8io     -constraint_mode  func_1p8io  -delay_corner  ffm40_cworst_1p8io
create_analysis_view  -name  func_ffm40_rcbest_1p8io     -constraint_mode  func_1p8io  -delay_corner  ffm40_rcbest_1p8io
create_analysis_view  -name  func_ffm40_rcworst_1p8io    -constraint_mode  func_1p8io  -delay_corner  ffm40_rcworst_1p8io
create_analysis_view  -name  func_ss125_cworst_1p8io     -constraint_mode  func_1p8io  -delay_corner  ss125_cworst_1p8io
create_analysis_view  -name  func_ss125_rcworst_1p8io    -constraint_mode  func_1p8io  -delay_corner  ss125_rcworst_1p8io
create_analysis_view  -name  func_ssm40_cworst_1p8io     -constraint_mode  func_1p8io  -delay_corner  ssm40_cworst_1p8io
create_analysis_view  -name  func_ssm40_rcworst_1p8io    -constraint_mode  func_1p8io  -delay_corner  ssm40_rcworst_1p8io
create_analysis_view  -name  func_tt85_1p8io             -constraint_mode  func_1p8io  -delay_corner  tt_85_1p8io

create_analysis_view  -name  scan_ssm40_rcworst_T  -constraint_mode  scan  -delay_corner  ssm40_rcworst_T
create_analysis_view  -name  scan_ssm40_cworst_T   -constraint_mode  scan  -delay_corner  ssm40_cworst_T
create_analysis_view  -name  scan_ss125_rcworst_T  -constraint_mode  scan  -delay_corner  ss125_rcworst_T
create_analysis_view  -name  scan_ss125_cworst_T   -constraint_mode  scan  -delay_corner  ss125_cworst_T
create_analysis_view  -name  scan_ff0_cbest        -constraint_mode  scan  -delay_corner  ff0_cbest
create_analysis_view  -name  scan_ff0_cworst       -constraint_mode  scan  -delay_corner  ff0_cworst
create_analysis_view  -name  scan_ff0_rcbest       -constraint_mode  scan  -delay_corner  ff0_rcbest
create_analysis_view  -name  scan_ff0_rcworst      -constraint_mode  scan  -delay_corner  ff0_rcworst
create_analysis_view  -name  scan_ff125_cbest      -constraint_mode  scan  -delay_corner  ff125_cbest
create_analysis_view  -name  scan_ff125_cworst     -constraint_mode  scan  -delay_corner  ff125_cworst
create_analysis_view  -name  scan_ff125_rcbest     -constraint_mode  scan  -delay_corner  ff125_rcbest
create_analysis_view  -name  scan_ff125_rcworst    -constraint_mode  scan  -delay_corner  ff125_rcworst
create_analysis_view  -name  scan_ffm40_cbest      -constraint_mode  scan  -delay_corner  ffm40_cbest
create_analysis_view  -name  scan_ffm40_cworst     -constraint_mode  scan  -delay_corner  ffm40_cworst
create_analysis_view  -name  scan_ffm40_rcbest     -constraint_mode  scan  -delay_corner  ffm40_rcbest
create_analysis_view  -name  scan_ffm40_rcworst    -constraint_mode  scan  -delay_corner  ffm40_rcworst
create_analysis_view  -name  scan_ss125_cworst     -constraint_mode  scan  -delay_corner  ss125_cworst
create_analysis_view  -name  scan_ss125_rcworst    -constraint_mode  scan  -delay_corner  ss125_rcworst
create_analysis_view  -name  scan_ssm40_cworst     -constraint_mode  scan  -delay_corner  ssm40_cworst
create_analysis_view  -name  scan_ssm40_rcworst    -constraint_mode  scan  -delay_corner  ssm40_rcworst
create_analysis_view  -name  scan_tt85             -constraint_mode  scan  -delay_corner  tt_85

#set_analysis_view -setup [list func_ssm40_rcworst_T func_ss125_rcworst_T func_tt85 scan_ssm40_rcworst_T scan_ss125_rcworst_T scan_tt85 ] -hold [list func_ffm40_rcbest func_ff125_rcbest func_ff0_rcbest func_tt85 scan_ffm40_rcbest scan_ff125_rcbest scan_ff0_rcbest scan_tt85]

set_analysis_view -setup [list func_ssm40_cworst_T func_ssm40_cworst_T_2p5io func_ssm40_cworst_T_1p8io func_ss125_cworst_T func_ss125_cworst_T_2p5io func_ss125_cworst_T_1p8io func_ssm40_cworst_T_2p5io func_tt85 scan_ssm40_cworst_T scan_ss125_cworst_T scan_tt85 ] -hold [list func_ff125_rcbest  func_ssm40_cworst func_ssm40_cworst_2p5io func_ssm40_cworst_1p8io func_ss125_cworst func_ss125_cworst_2p5io func_ss125_cworst_1p8io  func_tt85 scan_ff125_rcbest  scan_ssm40_cworst scan_ss125_cworst scan_tt85]

