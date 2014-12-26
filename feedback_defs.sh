#
# quit -- Display a message and terminate abnormally.
#
# Calling Sintax:
#	quit <pformat> [ <parg> ... ]
#
# Where:
#	<pformat>	Feedback message. It can contain printf() conversion
#			specifications.
#
#	<parg>		Argument operand printed under the control of the
#			<pformat> operand.
quit ()
{
	quitparms=
	if [ $# -gt 1 ]; then
		quitparm=2
		while test $quitparm -le $#; do
			quitparms="$quitparms \"\$$quitparm\""
			quitparm=`expr $quitparm + 1`
		done
	fi
	eval "printf \"$1\n\" $quitparms"
	exit 1
}



#
# fbck -- Display a feedback message.
#
# Calling Sintax:
#	fbck <pformat> [ <parg> ... ]
#
# Where:
#	<pformat>	Feedback message. It can contain printf() conversion
#			specifications.
#
#	<parg>		Argument operand printed under the control of the
#			<pformat> operand.
#
# Remarks:
#	The message is displayed only if the environment variable 'verbose' has
# the 'yes' value.
#
fbck ()
{
	fbckparms=
	if [ $# -gt 1 ]; then
		fbckparm=2
		while test $fbckparm -le $#; do
			fbckparms="$fbckparms \"\$$fbckparm\""
			fbckparm=`expr $fbckparm + 1`
		done
	fi
	test "$verbose" = "yes" && eval "printf \"$1\n\" $fbckparms"
}



#
# prompt - Ask the user for the value to assign to an environment variable.
#
# Calling Sintax:
#	prompt <varnam> <pformat> [ <parg> ... ]
#
# Where:
#	<varnam>	Name of the environment variable which is going to
#			receive the user introduced value.
#
#	<pformat>	Prompt to display to the user. It can contain printf()
#			conversion specifications.
#
#	<parg>		Argument operand printed under the control of the
#			<pformat> operand.
#
# Remarks:
#	The <varname> variable is not exported.
#
prompt ()
{
	promptparms=
	if [ $# -gt 2 ]; then
		promptparm=3
		while test $promptparm -le $#; do
			promptparms="$promptparms \"\$$promptparm\""
			promptparm=`expr $promptparm + 1`
		done
	fi
	eval "printf \"$2\" $promptparms"
	read promptresponse
	eval $1="$promptresponse"
}
