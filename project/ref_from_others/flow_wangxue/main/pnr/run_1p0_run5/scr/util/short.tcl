exec rm -rf deletenet
foreach i [dbGet [dbQuery -areas [dbGet [dbGet top.markers.subType Short -p].box] -objType wire ].net.name] {
	echo "editDelete -net $i -object_type {Via  Wire}" >> deletenet
	}
exec rm -rf deletenet
foreach i [dbGet [dbQuery -areas [dbGet [dbGet top.markers.subType Metal_Short -p].box] -objType wire ].net.name] {
	echo "editDelete -net $i -object_type {Via  Wire}" >> deletenet
	}

