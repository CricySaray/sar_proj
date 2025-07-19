set pg_net { vdd1 vdd2 vdd3 PLLVDD1 PLVDD2}
for { set i 0} { $i <5 } {incr i } {
	set net [lindex $pg_net $i]
	puts $net
	if [dbGetNetByName $net] {
		puts "$net exist! continue"
		continue
	}
	addNet $net -physical
        setNet -net $net -type special -setTermSpecial
        if {[regexp VSS $net] || [regexp vss $net] } {
		dbSetIsNetGnd $net
        } else {
		dbSetIsNetPwr $net
        }
}
