#BEGIN {
#	while (getline < "/ux/V37_ES2/user/llsun/TNL_0104/STA/60_sta/report/rpt_scripts/block_path.list" > 0) {
#		path[$1]=$2
#	}
#}

## put block rpt in sub_dir
NR==1   {
        scenario=FILENAME;
	gsub(/\/reports\/cons_vio_verbose.*rpt/,"",scenario)
	gsub(/.*\//,"",scenario)
}

## setup/hold
/Startpoint:/,/slack \((MET|VIOLATED)/ {
		if ($1~/Startpoint/) {start=convert_to_block($2);l=0}
		if ($1~/Endpoint/) end=convert_to_block($2)
		if ($0~/Path Group:/) group=$3
		if ($0~/Path Type:/) type=$NF
		if ($2~/(VIOLATED|MET)/) {
			if (group=="reg2reg" || group=="in2reg" || group=="reg2out" || group=="in2out") {
				save_to_array_group(group,$NF)
			} else {
				save_to_array(start,end,type,$NF)
			}
			type=""
		}
	}

## max_cap/max_tran
$1=="Pin:",/VIOLATED/ {
		if ($1=="Pin:") {block="top";l=0}
		if ($1=="max_capacitance") {
			type="max_cap"
		} else if ($1=="max_transition") {
			type="max_tran"
		} else if ($2=="sequential_clock_pulse_width" || $2=="clock_tree_pulse_width") {
			type="mpw"
		} else if ($2=="sequential_clock_min_period") {
			type="min_period"
		}
		#content[l++]=$0
		if ($0~/VIOLATED/) {
			if (type == "max_cap") {
				max_cap(block,$2)
			}else if (type == "max_tran") {
				max_tran(block,$2)
			} else if (type == "mpw") {
				max_mpw(block,$NF)
			} else if (type == "min_period") {
				min_period(block,$NF)
			} else {
				## ignore min_cap/min_tran/max_fanout
				next
			}
			#print_to_block_rpt("",block,type,content)
			type=""
			#delete content
		}
	}

END {
		## add noise
		f=FILENAME;gsub(/all_violation_v/,"report_noise_all",f)
		while (getline < f >0) {
			if ($2~/\(/ && $3>0 && $4>0 && $5<=0) {
				b="top"
				noise_vio(b,$5)
				## print to sub block rpt
				#print $0 >> block_rpt_dir"/"b".noise.rpt"
			}
		}
		#split(get_wns_tns(internal_max),I_max,"+")
		#split(get_wns_tns(internal_min),I_min,"+")
		#split(get_wns_tns(external_max),E_max,"+")
		#split(get_wns_tns(external_min),E_min,"+")
		#split(get_wns_tns(tran),Trans,"+")
		#split(get_wns_tns(cap),Caps,"+")
		#split(get_wns_tns(noise),Noises,"+")

        #printf ("%s %s %.3f/%.3f/%d %s %.3f/%.3f/%d %s %.3f/%.3f/%d %s %.3f/%.3f/%d \n",
        #        "reg2reg",setupHold["reg2reg","wns"], setupHold["reg2reg","tns"],setupHold["reg2reg","count"],
        #        "io",setupHold["io","wns"], setupHold["io","tns"],setupHold["io","count"],
        #        "max_tran",tran["top","wns"],tran["top","tns"],tran["top","count"],
        #        "max_cap",cap["top","wns"],cap["top","tns"],cap["top","count"])
        printf ("%s %.3f/%.3f/%d %.3f/%.3f/%d %.3f/%.3f/%d %.3f/%.3f/%d %.3f/%.3f/%d %.3f/%.3f/%d %.3f/%.3f/%d\n",scenario,
                setupHold["reg2reg","wns"], setupHold["reg2reg","tns"],setupHold["reg2reg","count"],
                setupHold["io","wns"], setupHold["io","tns"],setupHold["io","count"],
                tran["top","wns"],tran["top","tns"],tran["top","count"],
                cap["top","wns"],cap["top","tns"],cap["top","count"],
				mpw["top","wns"],mpw["top","tns"],mpw["top","count"],
				period["top","wns"],period["top","tns"],period["top","count"],
                noise["top","wns"],noise["top","tns"],noise["top","count"])
}

function convert_to_block(s) {
	if (match(s,"/")) {
		return "reg"
	} else {
        return "port"
    }
}

## save in 4 2D-arrays
function save_to_array(start,end,type,slack) {
    if (start == "reg" ) {
        if (end == "reg" ) {
            #reg2reg
            group = "reg2reg"
        } else {
            #reg2out
            #group = "reg2out"
            group = "io"
        }
    } else {
        if (end == "reg" ) {
            #in2reg
            #group = "in2reg"
            group = "io"
        } else {
            #in2out
            #group = "in2out"
            group = "io"
        }
    }
	setupHold[group,"wns"] = (slack < setupHold[group,"wns"]? slack: setupHold[group,"wns"])
	setupHold[group,"tns"] += slack
	setupHold[group,"count"]++
}

function save_to_array_group(group,slack) {
    if (group != "reg2reg" ) {
        group = "io"
    }
	setupHold[group,"wns"] = (slack < setupHold[group,"wns"]? slack: setupHold[group,"wns"])
	setupHold[group,"tns"] += slack
	setupHold[group,"count"]++
}

## save for tran
function max_tran(block,slack) {
	tran[block,"wns"] = (slack < tran[block,"wns"]? slack : tran[block,"wns"])
	tran[block,"tns"] += slack
	tran[block,"count"]++
}

## save for cap
function max_cap(block,slack) {
	cap[block,"wns"] = (slack < cap[block,"wns"]? slack : cap[block,"wns"])
	cap[block,"tns"] += slack
	cap[block,"count"]++
}

## save for mpw
function max_mpw(block,slack) {
	mpw[block,"wns"] = (slack < mpw[block,"wns"]? slack : mpw[block,"wns"])
	mpw[block,"tns"] += slack
	mpw[block,"count"]++
}

## save for period
function min_period(block,slack) {
	period[block,"wns"] = (slack < period[block,"wns"]? slack : period[block,"wns"])
	period[block,"tns"] += slack
	period[block,"count"]++
}

## save for noise
function noise_vio(block,slack) {
	noise[block,"wns"] = (slack < noise[block,"wns"]? slack : noise[block,"wns"])
	noise[block,"tns"] += slack
	noise[block,"count"]++
}

## multi-print
function multi_concat(string,num) {
	s=""
	for (i=0;i<num;i++) {
		s=s string
	}
	return s
}

## 2D-array --> 1D array 
function get_wns_tns(vio_array) {
	total["wns"]=total["tns"]=total["count"]=0
	for (k in vio_array) {
		split(k,x,SUBSEP)
		if (x[2]=="wns") {
			total["wns"] = total["wns"] < vio_array[x[1],x[2]] ? total["wns"] : vio_array[x[1],x[2]]
		} else if (x[2]=="tns") {
			total["tns"] +=  vio_array[x[1],x[2]]
		} else if (x[2]=="count") {
			total["count"] += vio_array[x[1],x[2]]
		}
	}
	#cannot return array?
	#return total
	return total["wns"]"+"total["tns"]"+"total["count"]
}

## print block vio rpt
function print_to_block_rpt(start,end,type,cont) {
	rpt=""
	if (type=="min" ||type=="max") {
		in_ex = start==end?"internal":"external"
		rpt = end"."in_ex"_"type".rpt"
	} else if (type == "max_cap") {
		rpt = end".max_cap.rpt"
	}else if (type == "max_tran") {
		rpt = end".max_tran.rpt"
	}
	len=length(cont)
	for (i=0;i<=len;i++) {
		print cont[i] >> block_rpt_dir"/"rpt
	}
}


