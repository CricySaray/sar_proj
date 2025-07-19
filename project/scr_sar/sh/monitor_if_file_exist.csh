#!/usr/bin/csh
# -----------------------
# arg $1 is file that you need monitor
while (! -e $1)
	setenv date `date +%m%d_%H:%M`
	echo "$date - sleep 60s : finding $1"
	sleep 60
end
echo "find file : $1"
