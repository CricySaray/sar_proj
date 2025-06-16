#!/usr/bin/csh
# -----------------------
# arg $1 is file that you need monitor
while (! -e $1)
	echo "sleep 60 : finding $1"
	sleep 60
end
echo "find file : $1"
