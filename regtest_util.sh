
f_ok ()
{
	printf "%-60s[ok]\n" "$1"
}

f_no ()
{
	printf "%-60s[error]\n" "$1"
	test -n "$2" && printf "\t%s\n" "$2"
}

f_abort ()
{
	printf "%-60s[fatal] aborting...\n" "$1"
	exit 1
}

check_start ()
{
	ntries=0
	while	test $ntries -lt 20 &&
		{ test ! -p $ppin ||
		test "`ps -p \"\`fuser $ppout 2>/dev/null\`\" -ocomm= \
					2>/dev/null`" != "$locrthub";}; do
		ntries=`expr $ntries + 1`
		sleep 2;
	done;
	msg="Regression Test switch started"
	test $ntries -ge 20 && f_abort "$msg" || f_ok "$msg"
	rtpid=`fuser $ppout 2>/dev/null`
}

start ()
{
	$locrthub -f$H/etc/$1.conf 2>$H/log/$1 1>&2
	check_start
}

restart ()
{
	$locrthub -f$H/etc/$1.conf 2>>$H/log/$1 1>&2
	check_start
}

stop()
{
	msg="Regression Test switch signaled to terminate"
	if kill $rtpid; then f_ok "$msg"; else f_abort "$msg"; fi
	#-----------------------------------
	ntries=0
	while	test $ntries -lt 20 &&
		test "`ps -p \"\`fuser $ppout 2>/dev/null\`\" -ocomm= \
					2>/dev/null`" = "$locrthub"; do
		ntries=`expr $ntries + 1`
		sleep 2;
	done;
	msg="Regression Test switch terminated"
	test $ntries -ge 20 && f_no "$msg" && exit 1 || f_ok "$msg"
}
