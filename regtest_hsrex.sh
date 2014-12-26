#!/bin/sh
#
# Copyright (c) 2002, Stooges & Cueless CO., All rights reserved.
#
# Module:
#	@(#)regtest_hsrex.sh	1.0	(Stooges & Clueless)	04/xx/02
# Purpose:
#	@(#)Perform regression test to Henry Spencer's RE libary.
# Author:
#	Walter Waldo
# History:
#	04/xx/02 (ww)		Version 1.0
#
H=$HOME
me=`basename $0`
rgsrc=regtest_hsrex.c
rgbin=regtest_hsrex
datsrc=regtest_data.c
datbin=regtest_data
CC=gcc


cleanup_and_exit()
{
	rm -f $rgsrc $rgbin $datsrc $datbin
	exit 1
}


usage ()
{
test X$1 != X && printf "$me: $1\n"
cat << EOF

$me: Perform regression test to Henry Spencer's RE libary.
Usage: $me	[-h]

Options:

-h		This stuff.

EOF
test X$1 != X && exit 1 || exit 0
}

. feedback_defs.sh

while getopts h FLAG; do
	case $FLAG in
	h)	usage
		;;
	?)	quit "Unknown option"
		;;
	esac
done


. regtest_util.sh
trap "trap '' 0; cleanup_and_exit 1" HUP INT QUIT PIPE TERM
trap "cleanup_and_exit $?" 0


printf "\nTesting Henry Spencer's REs\n\n"
#-----------------------------------
# Invocation:
#	$rgbin  <number_of_groups>  <RE>  <string2scan>
#
cat<<-EOF>$rgsrc
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include "regalone.h"
	#include "regex.h"
	#ifdef REGEX_WCHAR
	#	define chr	wchar_t
	#	define re_comp	re_wcomp
	#	define re_exec	re_wexec
	#else
	#	define chr	char
	#endif
	size_t hexescapes2bin(chr *t, char *src, size_t mxlen)
	{
		char	*s, *xs;
		size_t	len;
		s = xs = src;
		len = 0;
		while ( s = strstr(s, "\\\x") )
		{
			int	cbin;
			sscanf(&s[2], "%2x", &cbin);
	#		ifdef REGEX_WCHAR
				*s = '\0';
				len += mbstowcs(&t[len], xs, mxlen-len);
	#		else
				memcpy(&t[len], xs, (size_t ) (s-xs));
				len += (size_t ) (s-xs);
	#		endif
			t[len++] = cbin;
			s += 4;
			xs = s;
		}
	#	ifdef REGEX_WCHAR
			len += mbstowcs(&t[len], xs, mxlen-len);
	#	else
			strcpy(&t[len], xs);
			len += strlen(xs);
	#	endif
		return len;
	}
	main(int argc, char *argv[])
	{
		chr		re[1024*4], dat[1024*8];
		size_t		relen, datlen;
		regex_t		cre;
		regmatch_t	pmatch[100];
		int		cflags, nmatch, rc;
		char		buf[1024*2];

		//memset(&cre, '\0', sizeof(cre));
		nmatch = atoi(argv[1]);
		relen = hexescapes2bin(re, argv[2], sizeof(re)/sizeof(chr));
		datlen = hexescapes2bin(dat, argv[3], sizeof(dat)/sizeof(chr));
		cflags = REG_ADVANCED | (nmatch ? 0 : REG_NOSUB);
		rc = re_comp(&cre, re, relen, cflags);
		if ( rc != REG_OKAY )
		{
			regerror(rc, &cre, buf, sizeof(buf));
			fprintf(stderr, "Compile error. %s\n", buf);
			exit(1);
		}
		if ( nmatch >= 0 && cre.re_nsub != nmatch )
		{
			fprintf(stderr,
				"Mismatch on number of group patterns. ",
				"Expected %d, compiled %d\n",
				nmatch, cre.re_nsub);
			exit(1);
		}
		rc = re_exec(&cre, dat, datlen, NULL, 100, pmatch, 0);
		if ( rc != REG_OKAY )
		{
			regerror(rc, &cre, buf, sizeof(buf));
			fprintf(stderr, "Execution error. %s\n", buf);
			exit(1);
		}
		if ( cre.re_nsub )
		{
			int	i;

			buf[0] = '\0';
			for ( i=1; i<cre.re_nsub+1 && pmatch[i].rm_so>=0; i++ )
				sprintf(&buf[strlen(buf)], "%s%.*s",
					i>1 ? ":" : "",
					pmatch[i].rm_eo-pmatch[i].rm_so,
					argv[3]+pmatch[i].rm_so);
			printf("%s\n", buf);
		}
		regfree(&cre);
		exit(0);
	}
EOF
PATH=.:$PATH
LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH
export PATH LD_LIBRARY_PATH
# Either this one
$CC -I. -I$H/inc -L. -lhsrex -o $rgbin $rgsrc			# Test ascii ch
# Or this one
#$CC -I. -I$H/inc -L. -lhswrex -DREGEX_WCHAR -o $rgbin $rgsrc	# Test wide ch
#-----------------------------------
resp=`$rgbin 0 "clavo" "Pablito clavo un clavito" 2>&1`
msg="Simple match"
test -z "$resp" && f_ok "$msg" || f_no "$msg" "$resp"
#-----------------------------------
resp=`$rgbin 0 \
	"(19|20)\d\d[- /.](0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[01])" \
	"1960-10-12" 2>&1`
msg="yyyy-mm-dd between 1900-01-01 and 2099-12-31"
test -z "$resp" && f_ok "$msg" || f_no "$msg" "$resp"
#-----------------------------------
resp=`$rgbin 0 \
	"(19|20)\d\d[- /.](0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[01])" \
	"El arzobispo 1960-14-12 de Constantinopla" 2>&1`
msg="yyyy-mm-dd out of 1900-01-01 and 2099-12-31"
if echo "$resp"|grep "failed to match">/dev/null;
then f_ok "$msg"; else f_no "$msg" "$resp"; fi
#-----------------------------------
resp=`$rgbin 0 "^([1-9]|[1-9][0-9]|[1-9][0-9][0-9])$" "432" 2>&1`
msg="1..999"
test -z "$resp" && f_ok "$msg" || f_no "$msg" "$resp"
#-----------------------------------
resp=`$rgbin 0 "^([1-9]|[1-9][0-9]|[1-9][0-9][0-9])$" " 4321" 2>&1`
msg="Bad 1..999"
if echo "$resp"|grep "failed to match">/dev/null;
then f_ok "$msg"; else f_no "$msg" "$resp"; fi
#-----------------------------------
resp=`$rgbin 0 "word1\W+(?:\w+\W+){1,3}?word2" \
		"word1 clavo un clavito word2" 2>&1`
msg="Quantifier: One to three words between 'word1' and 'word2'"
test -z "$resp" && f_ok "$msg" || f_no "$msg" "$resp"
#-----------------------------------
resp=`$rgbin 0 "a?a?a?a?a?aaaaaaaaaaaaaaa" \
		"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" 2>&1`
msg="Pathological: a?^6a^15 against aaaaaaaaaaaaaaaaaa..."
test -z "$resp" && f_ok "$msg" || f_no "$msg" "$resp"
#-----------------------------------
resp=`$rgbin 0 "(a|aa)*b" \
		"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab" 2>&1`
msg="Pathological: (a|aa)*b against aaaaaaaaaaaaaaaaaa...b"
test -z "$resp" && f_ok "$msg" || f_no "$msg" "$resp"
#-----------------------------------
cat<<-EOF>$datsrc
	#include <stdio.h>
	#include <stdlib.h>
	#include <ctype.h>
	#ifdef WIN32
	#	include <process.h>
	#	define getpid	_getpid
	#elif defined(unix) || defined(__unix__)
	#	include <unistd.h>
	#else
	#	error unknown platform
	#endif
	char	nums[] = "0123456789";
	char	alph[] = "abcdefghijklmnopqrstuvwxyz";
	main(int argc, char *argv[])
	{
		char	dat[16], *arr;
		int	arrsz, datsz, i;

		if ( isdigit(argv[1][0]) )
			{ arr = nums; arrsz = sizeof(nums)-1; }
		else if ( isalpha(argv[1][0]) )
			{ arr = alph; arrsz = sizeof(alph)-1; }
		srand(getpid());
		datsz = rand()%13+1;
		for ( i=0; i<datsz; i++ ) dat[i] = arr[ rand()%arrsz ];
		dat[datsz] = '\0';
		printf("%s\n", dat);
	}
EOF
$CC -o $datbin $datsrc
#-----------------------------------
i=0
totre="[a-zA-Z]+"
totdat=`$datbin a`
while test $i -lt 5; do
	num=`$datbin 0`
	alph=`$datbin a`
	totre=$totre"([0-9]+)[a-zA-Z]+"
	totdat=$totdat$num$alph
	test $i -eq 0 && expectedresp=$num || expectedresp=$expectedresp:$num
	i=`expr $i + 1`
done
resp=`$rgbin 5 "$totre" "$totdat" 2>&1`
msg="5 group patterns taken with bracket ranges"
test "$resp" = "$expectedresp" && f_ok "$msg" || f_no "$msg" "$resp"
#-----------------------------------
i=0
totre="[a-zA-Z]+"
totdat=`$datbin a`
while test $i -lt 10; do
	num=`$datbin 0`
	alph=`$datbin a`
	totre=$totre"([0-9]+)[a-zA-Z]+"
	totdat=$totdat$num$alph
	test $i -eq 0 && expectedresp=$num || expectedresp=$expectedresp:$num
	i=`expr $i + 1`
done
resp=`$rgbin 10 "$totre" "$totdat" 2>&1`
msg="10 group patterns taken with bracket ranges"
test "$resp" = "$expectedresp" && f_ok "$msg" || f_no "$msg" "$resp"
#-----------------------------------
i=0
totre="[a-zA-Z]+"
totdat=`$datbin a`
while test $i -lt 99; do
	num=`$datbin 0`
	alph=`$datbin a`
	totre=$totre"([0-9]+)[a-zA-Z]+"
	totdat=$totdat$num$alph
	test $i -eq 0 && expectedresp=$num || expectedresp=$expectedresp:$num
	i=`expr $i + 1`
done
resp=`$rgbin 99 "$totre" "$totdat" 2>&1`
msg="99 group patterns taken with bracket ranges"
test "$resp" = "$expectedresp" && f_ok "$msg" || f_no "$msg" "$resp"
#-----------------------------------
i=0
totre="[[:alpha:]]+"
totdat=`$datbin a`
while test $i -lt 99; do
	num=`$datbin 0`
	alph=`$datbin a`
	totre=$totre"([[:digit:]]+)[[:alpha:]]+"
	totdat=$totdat$num$alph
	test $i -eq 0 && expectedresp=$num || expectedresp=$expectedresp:$num
	i=`expr $i + 1`
done
resp=`$rgbin 99 "$totre" "$totdat" 2>&1`
msg="99 group patterns taken with character classes"
test "$resp" = "$expectedresp" && f_ok "$msg" || f_no "$msg" "$resp"
#-----------------------------------
resp=`$rgbin 0 "clavo" "Pablito\00clavo un clavito" 2>&1`
msg="Binary data"
test -z "$resp" && f_ok "$msg" || f_no "$msg" "$resp"
#-----------------------------------
resp=`$rgbin 0 "cl\xFFavo" "Pablito\x00cl\xFFavo un clavito" 2>&1`
msg="Binary RE and data"
test -z "$resp" && f_ok "$msg" || f_no "$msg" "$resp"
#-----------------------------------
resp=`$rgbin 1 "(?i)(clavo)" "Pablito ClAvO un clavito" 2>&1`
msg="One group pattern with case-insensitive matching"
test "$resp" = "ClAvO" && f_ok "$msg" || f_no "$msg" "$resp"
#-----------------------------------
