#!/usr/bin/perl -w

use strict;
use Cwd;
##use Find::Find;
use Getopt::Long;

my $help = 0;
my $pop_flag = 0;
my $push_flag = 0;
my $msg = "";
my $id;
my $popid = "x";
my $line_limit = 20;

GetOptions(
	"push=s" => \$msg,
	"pop=s" => \$popid,
);

#if ($help) {$hel; exit}
if ($popid ne "x" && $msg ne "") {
print "Error: -push and -pop are mutually exclusive\n",
###&help;
}

# must write abs path!!!
my $dir = "/home/cricy/.teamshare";

#push
my $id_flag = 0;
if (length($msg)) {
	for (my $i=0; $i<100; $i++) {
		$id = (sprintf "%03d", (rand(999)));
		if (!-e "$dir/$id") {
			$id_flag = 1;
			last
		}
	}
	if ($id_flag) {
		open FID, "> $dir/$id" or die "Error: Can not open $dir/$id for write\n";
		print FID "$msg";
		close FID;
		`chmod 777 $dir/$id`;
		print "$msg\n";
		print "teamshare -pop $id\n";
	} else {
		print "Error: No ids avilable! Delete old content of id($id) and push new content.\n";
    `rm -rf $dir/$id`;
		open FID, "> $dir/$id" or die "Error: Can not open $dir/$id for write\n";
		print FID "$msg";
		close FID;
		`chmod 777 $dir/$id`;
		print "$msg\n";
		print "teamshare -pop $id\n";
	}
}

#pop
if ($popid ne "x") {
	#print "In pop mode:\n";
	if (!-e "$dir/$popid") {
		print "Error: id number $popid not exists!\n";
		exit
	}
	my @tmp = split/\s+/, `wc -l $dir/$popid`;
	my $tline = $tmp[0];
	my $line = 0;
	
	open FID, "< $dir/$popid" or die "$!";
	
	while (<FID>) {
		if ($line > $line_limit) {
			print "warning: id number $popid has $tline lines, exceeds limit(20) of display";
			last
		}
		chomp($_);
		print "$_\n";
		$line++;
	}
	close FID;
}
