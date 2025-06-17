#! /usr/bin/perl
use List::Util qw(min);
use List::Util qw(max);
use Cwd;

my $dir = getcwd;
my @dirs = split/\//,$dir;
my $design_name = $dirs[13];
my @scenarios = <*>;
my @ignore_scenarios = qw (func_typ_85_setuphold scan_typ_85_setuphold);
@setup_scenarios = grep (/setup/,@scenarios);
foreach $a (@setup_scenarios) {
	$c =0;
	foreach $b (@ignore_scenarios) {
		if ($a =~ /$b/) {
			$c =1;
		}
	}
	if ($c==0) {
		$d = (length $a);
		$scenario_length = max ($d, $scenario_length);
		push @new, $a;
	}
}
@hold_scenarios = grep (/hold/,@scenarios); 
foreach $a (@hold_scenarios) { 
	$c =0; 
	foreach $b (@ignore_scenarios) { 
		if ($a =~ /$b/) { 
			$c =1; 
		} 
	} 
	if ($c==0) { 
		$d = (length $a); 
		$scenario_length = max ($d, $scenario_length); 
		push @new, $a; 
	} 
}
printf("\033[0;32m%-${scenario_length}s       num         wns         tns  reg2regnum   reg2regwns   reg2regtns   trans_wns:num(clock)   trans_wns:num(data)   fanout_wns:num   noise_wns:num   cap_wns:num   period_wns:num   pluse_wns:num   not_annotated_num\033[0m\n",scenario ) ;
foreach $scenario (@new) {
	$rptfile = "${scenario}/${design_name}.global_timing.rpt";
	$reg2reg_wns = 0;$reg2reg_tns = 0;$reg2reg_num = 0;$wns = 0;$tns = 0;$num = 0;
	if (-e $rptfile) {
		open (IN,$rptfile) or die ("can not open $file \n");
		while(<IN>) {
			chomp;
			if (/WNS\s*(-?\d*\.\d*)\s*(-?\d*\.\d*)/) {
				$wns = $1;
				$reg2reg_wns = $2;
				$count ++;
			}
			if (/TNS\s*(-?\d*\.\d*)\s*(-?\d*\.\d*)/) {
				$tns = $1;
				$reg2reg_tns = $2;
				$count ++;
			}
			if (/NUM\s*(\d*)\s*(\d*)/) {
				$num = $1;
				$reg2reg_num = $2;
				$count ++;
			}
			if ($count == 3) {
				$count = 0;
				close IN;
			}
		}
	} else {
		printf "\033[1;31mWarning:missing $rptfile, please check it.\033[0m\n";
	}
	$rptfile1 = "$scenario/$design_name.drv.rpt.cap";
	$rptfile2 = "$scenario/$design_name.drv.rpt.fanout";
	$rptfile3 = "$scenario/$design_name.drv.rpt.tran.clock";
	$rptfile4 = "$scenario/$design_name.drv.rpt.tran.data";
	$rptfile5 = "$scenario/$design_name.min_period.rpt.sum.slack";
	$rptfile6 = "$scenario/report_noise.rpt";
	$rptfile7 = "$scenario/$design_name.min_pulse_width.rpt.sum.slack";
	$rptfile8 = "$scenario/report_annotated_parasitics.rpt";

	$cap_violation = 0;         $cap_wns = 0;         $cap_num = 0;
	$fanout_violation = 0;      $fanout_wns = 0;      $fanout_num = 0;
	$trans_clock_violation = 0; $trans_clock_wns = 0; $trans_clock_num = 0;
	$trans_data_violation = 0;  $trans_data_wns = 0;  $trans_data_num = 0;
	$period_violation = 0;      $period_wns = 0;      $period_num = 0;
	$noise_violation = 0;       $noise_wns = 0;       $noise_num = 0;
	$pulse_violation = 0;       $pulse_wns = 0;       $pulse_num = 0;
	$not_annotated_num = 0;

	#cap 
	if (-e $rptfile1) {
		open (IN1,$rptfile1) or die ("can not open $rptfile1 \n");
		while(<IN1>) {
			chomp;
			our @check_cap    = split ' ', $_;
			$cap_violation = $check_cap[3];
			$cap_wns = min ($cap_violation,$cap_wns);
			$cap_num ++;
		}
		close IN1;
	} else {printf "\033[1;31mWarning:missing $rptfile1, please check it.\033[0m\n"}
	#fanout
	if (-e $rptfile2) {
		open (IN2,$rptfile2) or die ("can not open $rptfile2 \n");
		while(<IN2>) {
			chomp;
			our @check_fanout    = split ' ', $_;
			$fanout_violation = $check_fanout[3];
			$fanout_wns = min ($fanout_violation,$fanout_wns);
			$fanout_num ++;
		}
		close IN2
	} else {printf "\033[1;31mWarning:missing $rptfile2, please check it.\033[0m\n"}
	#trans_clock
	if (-e $rptfile3) {
		open (IN3,$rptfile3) or die ("can not open $rptfile3 \n");
		while(<IN3>) {
			chomp;
			our @check_tran_clock    = split '\|', $_;
			$trans_clock_violation = $check_tran_clock[3];
			$trans_clock_wns = min ($trans_clock_violation,$trans_clock_wns);
			$trans_clock_num ++;
		}
		close IN3;
	} else {printf "\033[1;31mWarning:missing $rptfile3, please check it.\033[0m\n"}
	#trans_data
	if (-e $rptfile4) {
		open (IN4,$rptfile4) or die ("can not open $rptfile4 \n");
		while(<IN4>) {
			chomp;
			our @check_tran_data   = split '\|', $_;
			$trans_data_violation  = $check_tran_data[3];
			$trans_data_wns = min ($trans_data_violation,$trans_data_wns);
			$trans_data_num ++;
		}
		close IN4;
	} else {printf "\033[1;31mWarning:missing $rptfile4, please check it.\033[0m\n"}
	#period
	if (-e $rptfile5) {
		open (IN5,$rptfile5) or die ("can not open $rptfile5 \n");
		while(<IN5>) {
			chomp;
			our @check_period    = split ' ', $_;
			$period_violation = $check_period[0];
			$period_wns = min ($period_violation,$period_wns);
			$period_num ++;
		}
		close IN5;
	} else {printf "\033[1;31mWarning:missing $rptfile5, please check it.\033[0m\n"}
	#noise
	if (-e $rptfile6) {
		open (IN6,$rptfile6) or die ("can not open $rptfile6 \n");
		$found = 0;
		while(<IN6>) {
			chomp;
			if (/Total:/) {
				(undef,undef,undef,undef,$noise_violation) = split /\s+/,$_;
				$noise_wns = min($noise_violation,$noise_wns);
				$noise_num ++;
			}
		}
		close IN6;
	} else {printf "\033[1;31mWarning:missing $rptfile6, please check it.\033[0m\n"}
	#pluse
	if (-e $rptfile7) {
		open (IN7,$rptfile7) or die ("can not open $rptfile7 \n");
		while(<IN7>) {
			chomp;
			our @check_pulse    = split ' ', $_;
			$pulse_violation = $check_pulse[0];
			$pulse_wns = min ($pulse_violation,$pulse_wns);
			$pulse_num ++;
		}
		close IN7;
	} else {printf "\033[1;31mWarning:missing $rptfile7, please check it.\033[0m\n"}
	#not_annotated
	if (-e $rptfile8) {
		open (IN8,$rptfile8) or die ("can not open $rptfile8 \n");
		while(<IN8>) {
			chomp;
			if (/Pin to pin nets\W*\d*\W*\d*\W*\d*\W*\d*\W*\d*\W*(\d*)/) {
				$not_annotated_num = $1;
				close IN8;
			}
		}
	} else {printf "\033[1;31mWarning:missing $rptfile8, please check it.\033[0m\n"}
	printf ("%-${scenario_length}s\033[1;35m%10s\033[0m%12.3f%12.3f\033[1;35m%12s\033[0m%13.3f%13.3f%12s:%-10s%12s:%-10s%12s:%-6s%9s:%-5s%8s:%-6s%10s:%-5s%10s:%-5s%9s\n" ,$scenario,$num,$wns,$tns,$reg2reg_num,$reg2reg_wns,$reg2reg_tns,$trans_clock_wns,$trans_clock_num,$trans_data_wns,$trans_data_num,$fanout_wns,$fanout_num,$noise_wns,$noise_num,$cap_wns,$cap_num,$period_wns,$period_num,$pulse_wns,$pulse_num,$not_annotated_num)
}
