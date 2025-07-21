#!/bin/csh

set rel = '/eda_files/proj/ict8810/swap/to_vct/eda_files/proj/ict8810/backend/be8803/scripts_1220'
set loc = `pwd`

mkdir -p scr db log rpt work tempt

ln -s $rel/util_9t $loc/scr/util

ln -s $rel/global.invs.9t $loc/scr/global.invs
ln -s $rel/viewDefine.invs.9t $loc/scr/viewDefine.invs
cp $rel/run.csh $loc/scr/run.csh
ln -s $rel/setup.invs.9t $loc/scr/setup.invs
 
ln -s $rel/floorplan.invs.tcl $loc/scr/floorplan.invs.tcl  
ln -s $rel/init.invs.tcl $loc/scr/init.invs.tcl
cp $rel/fp.tcl $loc/scr/fp.tcl
ln -s $rel/place.invs.tcl $loc/scr/place.invs.tcl
cp $rel/place_opt_plug.tcl $loc/scr/place_opt_plug.tcl
ln -s $rel/cts.invs.tcl $loc/scr/cts.invs.tcl
ln -s $rel/route.invs.tcl $loc/scr/route.invs.tcl
ln -s $rel/postroute.invs.tcl $loc/scr/postroute.invs.tcl
cp $rel/defineInput.tcl $loc/scr/defineInput.tcl

cp $rel/mid_cts.tcl $loc/scr/
cp $rel/post_cts.tcl $loc/scr/
cp $rel/post_place.tcl $loc/scr/
cp $rel/post_postRoute.tcl $loc/scr/
cp $rel/post_route.tcl $loc/scr/
cp $rel/pre_cts.tcl $loc/scr/
cp $rel/pre_place.tcl $loc/scr/
cp $rel/pre_postRoute.tcl $loc/scr/
cp $rel/pre_route.tcl $loc/scr/
cp $rel/user_path_group.tcl $loc/scr/
cp $rel/modify_cts.tcl $loc/scr/
cp $rel/pre_init.tcl $loc/scr/
cp $rel/post_init.tcl $loc/scr/
cp $rel/ecopr.tcl $loc/scr/
cp $rel/pre_ecopr.tcl $loc/scr/
cp $rel/post_ecopr.tcl $loc/scr/
