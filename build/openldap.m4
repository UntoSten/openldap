dnl Copyright 1998 The OpenLDAP Foundation,  All Rights Reserved.
dnl COPYING RESTRICTIONS APPLY, See COPYRIGHT file
dnl
dnl OpenLDAP Autoconf Macros
dnl
dnl builtin(include, build/libtool.m4)dnl
dnl --------------------------------------------------------------------
dnl Restricted form of AC_ARG_ENABLE that limits user options
dnl
dnl $1 = option name
dnl $2 = help-string
dnl $3 = default value	(auto)
dnl $4 = allowed values (auto yes no)
AC_DEFUN([OL_ARG_ENABLE], [# OpenLDAP --enable-$1
	AC_ARG_ENABLE($1,[$2 (]ifelse($3,,auto,$3)[)],[
	ol_arg=invalid
	for ol_val in ifelse($4,,[auto yes no],[$4]) ; do
		if test "$enableval" = "$ol_val" ; then
			ol_arg="$ol_val"
		fi
	done
	if test "$ol_arg" = "invalid" ; then
		AC_MSG_ERROR(bad value $enableval for --enable-$1)
	fi
	ol_enable_$1="$ol_arg"
],
[	ol_enable_$1=ifelse($3,,"auto","$3")])dnl
dnl AC_VERBOSE(OpenLDAP -enable-$1 $ol_enable_$1)
# end --enable-$1
])dnl
dnl
dnl --------------------------------------------------------------------
dnl Restricted form of AC_ARG_WITH that limits user options
dnl
dnl $1 = option name
dnl $2 = help-string
dnl $3 = default value (no)
dnl $4 = allowed values (yes or no)
AC_DEFUN([OL_ARG_WITH], [# OpenLDAP --with-$1
	AC_ARG_WITH($1,[$2 (]ifelse($3,,yes,$3)[)],[
	ol_arg=invalid
	for ol_val in ifelse($4,,[yes no],[$4]) ; do
		if test "$withval" = "$ol_val" ; then
			ol_arg="$ol_val"
		fi
	done
	if test "$ol_arg" = "invalid" ; then
		AC_MSG_ERROR(bad value $withval for --with-$1)
	fi
	ol_with_$1="$ol_arg"
],
[	ol_with_$1=ifelse($3,,"no","$3")])dnl
dnl AC_VERBOSE(OpenLDAP --with-$1 $ol_with_$1)
# end --with-$1
])dnl
dnl
dnl ====================================================================
dnl check if hard links are supported.
dnl
AC_DEFUN([OL_PROG_LN_H], [# test for ln hardlink support
AC_MSG_CHECKING(whether ln works)
AC_CACHE_VAL(ol_cv_prog_LN_H,
[rm -f conftest.src conftest.dst
echo "conftest" > conftest.src
if ln conftest.src conftest.dst 2>/dev/null
then
  ol_cv_prog_LN_H="ln"
else
  ol_cv_prog_LN_H="cp"
fi
rm -f conftest.src conftest.dst
])dnl
LN_H="$ol_cv_prog_LN_H"
if test "$ol_cv_prog_LN_H" = "ln"; then
	AC_MSG_RESULT(yes)
else
	AC_MSG_RESULT(no)
fi
AC_SUBST(LN_H)dnl
])dnl
dnl
dnl ====================================================================
dnl Check if system uses EBCDIC instead of ASCII
AC_DEFUN([OL_CPP_EBCDIC], [# test for EBCDIC
AC_MSG_CHECKING([for EBCDIC])
AC_CACHE_VAL(ol_cv_cpp_ebcdic,[
	AC_TRY_CPP([
#if !('M' == 0xd4)
#include <__ASCII__/generate_error.h>
#endif
],
	[ol_cv_cpp_ebcdic=yes],
	[ol_cv_cpp_ebcdic=no])])
AC_MSG_RESULT($ol_cv_cpp_ebcdic)
if test $ol_cv_cpp_ebcdic != no ; then
	AC_DEFINE(HAVE_EBCDIC,1, [define if system uses EBCDIC instead of ASCII])
fi
])
dnl
dnl --------------------------------------------------------------------
dnl OpenLDAP version of STDC header check w/ EBCDIC support
AC_DEFUN(OL_HEADER_STDC,
[AC_REQUIRE_CPP()dnl
AC_REQUIRE([OL_CPP_EBCDIC])
AC_CACHE_CHECK([for ANSI C header files], ol_cv_header_stdc,
[AC_TRY_CPP([#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <float.h>], ol_cv_header_stdc=yes, ol_cv_header_stdc=no)

if test $ol_cv_header_stdc = yes; then
  # SunOS 4.x string.h does not declare mem*, contrary to ANSI.
AC_EGREP_HEADER(memchr, string.h, , ol_cv_header_stdc=no)
fi

if test $ol_cv_header_stdc = yes; then
  # ISC 2.0.2 stdlib.h does not declare free, contrary to ANSI.
AC_EGREP_HEADER(free, stdlib.h, , ol_cv_header_stdc=no)
fi

if test $ol_cv_header_stdc = yes; then
  # /bin/cc in Irix-4.0.5 gets non-ANSI ctype macros unless using -ansi.
AC_TRY_RUN([#include <ctype.h>
#ifndef HAVE_EBCDIC
#	define ISLOWER(c) ('a' <= (c) && (c) <= 'z')
#	define TOUPPER(c) (ISLOWER(c) ? 'A' + ((c) - 'a') : (c))
#else
#	define ISLOWER(c) (('a' <= (c) && (c) <= 'i') \
		|| ('j' <= (c) && (c) <= 'r') \
		|| ('s' <= (c) && (c) <= 'z'))
#	define TOUPPER(c)	(ISLOWER(c) ? ((c) | 0x40) : (c))
#endif
#define XOR(e, f) (((e) && !(f)) || (!(e) && (f)))
int main () { int i; for (i = 0; i < 256; i++)
if (XOR (islower (i), ISLOWER (i)) || toupper (i) != TOUPPER (i)) exit(2);
exit (0); }
], , ol_cv_header_stdc=no, :)
fi])
if test $ol_cv_header_stdc = yes; then
  AC_DEFINE(STDC_HEADERS)
fi
ac_cv_header_stdc=disable
])
dnl
dnl ====================================================================
dnl Check if db.h is Berkeley DB2
dnl
dnl defines ol_cv_header_db2 to 'yes' or 'no'
dnl
dnl uses:
dnl		AC_CHECK_HEADERS(db.h)
dnl
AC_DEFUN([OL_HEADER_BERKELEY_DB2],
[AC_CHECK_HEADERS(db.h)
if test $ac_cv_header_db_h = yes ; then
	AC_CACHE_CHECK([if db.h is DB2], [ol_cv_header_db2],[
		AC_EGREP_CPP(__db_version_2,[
#			include <db.h>
			/* this check could be improved */
#			ifdef DB_VERSION_MAJOR
#				if DB_VERSION_MAJOR == 2
					__db_version_2
#				endif
#			endif
		], ol_cv_header_db2=yes, ol_cv_header_db2=no)])
else
	ol_cv_header_db2=no
fi
])dnl
dnl --------------------------------------------------------------------
dnl Check if Berkeley DB2 library exists
dnl Check for dbopen in standard libraries or -ldb
dnl
dnl defines ol_cv_lib_db2 to '-ldb' or 'no'
dnl
dnl uses:
dnl		AC_CHECK_LIB(db,db_open)
dnl
AC_DEFUN([OL_LIB_BERKELEY_DB2],
[AC_CACHE_CHECK([for DB2 library], [ol_cv_lib_db2],
[	ol_LIBS="$LIBS"
	AC_CHECK_LIB(db,db_open,[ol_cv_lib_db2=-ldb],[ol_cv_lib_db2=no])
	LIBS="$ol_LIBS"
])
])dnl
dnl
dnl --------------------------------------------------------------------
dnl Check if Berkeley db2 exists
dnl
dnl defines ol_cv_berkeley_db2 to 'yes' or 'no'
dnl 
dnl uses:
dnl		OL_LIB_BERKELEY_DB2
dnl		OL_HEADER_BERKELEY_DB2
dnl
AC_DEFUN([OL_BERKELEY_DB2],
[AC_REQUIRE([OL_LIB_BERKELEY_DB2])
 AC_REQUIRE([OL_HEADER_BERKELEY_DB2])
 AC_CACHE_CHECK([for Berkeley DB2], [ol_cv_berkeley_db2], [
	if test "$ol_cv_lib_db2" = no -o "$ol_cv_header_db2" = no ; then
		ol_cv_berkeley_db2=no
	else
		ol_cv_berkeley_db2=yes
	fi
])
 if test $ol_cv_berkeley_db2 = yes ; then
	AC_DEFINE(HAVE_BERKELEY_DB2,1, [define if Berkeley DBv2 is available])
 fi
])dnl
dnl
dnl ====================================================================
dnl Check for db.h/db_185.h is Berkeley DB
dnl
dnl defines ol_cv_header_db to 'yes' or 'no'
dnl
dnl uses:
dnl		OL_HEADER_BERKELEY_DB2
dnl		AC_CHECK_HEADERS(db_185.h)
dnl
AC_DEFUN([OL_HEADER_BERKELEY_DB],
[AC_REQUIRE([OL_HEADER_BERKELEY_DB2])
AC_CHECK_HEADERS(db_185.h)
if test "$ol_cv_header_db2" = yes ; then
	dnl db.h is db2! 

	ol_cv_header_db=$ac_cv_header_db_185_h
else
	ol_cv_header_db=$ac_cv_header_db_h
fi
])dnl
dnl
dnl --------------------------------------------------------------------
dnl Check if Berkeley DB library exists
dnl Check for dbopen in standard libraries or -ldb
dnl
dnl defines ol_cv_lib_db to 'yes' or '-ldb' or 'no'
dnl		'yes' implies dbopen is in $LIBS
dnl
dnl uses:
dnl		AC_CHECK_FUNC(dbopen)
dnl		AC_CHECK_LIB(db,dbopen)
dnl
AC_DEFUN([OL_LIB_BERKELEY_DB],
[AC_CACHE_CHECK([for Berkeley DB library], [ol_cv_lib_db],
[	ol_LIBS="$LIBS"
	AC_CHECK_FUNC(dbopen,[ol_cv_lib_db=yes], [
		AC_CHECK_LIB(db,dbopen,[ol_cv_lib_db=-ldb],[ol_cv_lib_db=no])
	])
	LIBS="$ol_LIBS"
])
])dnl
dnl
dnl --------------------------------------------------------------------
dnl Check if Berkeley DB exists
dnl
dnl defines ol_cv_berkeley_db to 'yes' or 'no'
dnl 
dnl uses:
dnl		OL_LIB_BERKELEY_DB
dnl		OL_HEADER_BERKELEY_DB
dnl
AC_DEFUN([OL_BERKELEY_DB],
[AC_REQUIRE([OL_LIB_BERKELEY_DB])
 AC_REQUIRE([OL_HEADER_BERKELEY_DB])
 AC_CACHE_CHECK([for Berkeley DB], [ol_cv_berkeley_db], [
	if test "$ol_cv_lib_db" = no -o "$ol_cv_header_db" = no ; then
		ol_cv_berkeley_db=no
	else
		ol_cv_berkeley_db=yes
	fi
])
 if test $ol_cv_berkeley_db = yes ; then
	AC_DEFINE(HAVE_BERKELEY_DB,1, [define if Berkeley DB is available])
 fi
])dnl
dnl
dnl ====================================================================
dnl Check if GDBM library exists
dnl Check for gdbm_open in standard libraries or -lgdbm
dnl
dnl defines ol_cv_lib_gdbm to 'yes' or '-lgdbm' or 'no'
dnl		'yes' implies gdbm_open is in $LIBS
dnl
dnl uses:
dnl		AC_CHECK_FUNC(gdbm_open)
dnl		AC_CHECK_LIB(gdbm,gdbm_open)
dnl
AC_DEFUN([OL_LIB_GDBM],
[AC_CACHE_CHECK(for GDBM library, [ol_cv_lib_gdbm],
[	ol_LIBS="$LIBS"
	AC_CHECK_FUNC(gdbm_open,[ol_cv_lib_gdbm=yes], [
		AC_CHECK_LIB(gdbm,gdbm_open,[ol_cv_lib_gdbm=-lgdbm],[ol_cv_lib_gdbm=no])
	])
	LIBS="$ol_LIBS"
])
])dnl
dnl
dnl --------------------------------------------------------------------
dnl Check if GDBM exists
dnl
dnl defines ol_cv_gdbm to 'yes' or 'no'
dnl 
dnl uses:
dnl		OL_LIB_GDBM
dnl		AC_CHECK_HEADERS(gdbm.h)
dnl
AC_DEFUN([OL_GDBM],
[AC_REQUIRE([OL_LIB_GDBM])
 AC_CHECK_HEADERS(gdbm.h)
 AC_CACHE_CHECK(for db, [ol_cv_gdbm], [
	if test $ol_cv_lib_gdbm = no -o $ac_cv_header_gdbm_h = no ; then
		ol_cv_gdbm=no
	else
		ol_cv_gdbm=yes
	fi
])
 if test $ol_cv_gdbm = yes ; then
	AC_DEFINE(HAVE_GDBM,1, [define if GNU DBM is available])
 fi
])dnl
dnl
dnl ====================================================================
dnl Check if NDBM library exists
dnl Check for dbm_open in standard libraries or -lndbm or -ldbm
dnl
dnl defines ol_cv_lib_ndbm to 'yes' or '-lndbm' or -ldbm or 'no'
dnl		'yes' implies ndbm_open is in $LIBS
dnl
dnl uses:
dnl		AC_CHECK_FUNC(dbm_open)
dnl		AC_CHECK_LIB(ndbm,dbm_open)
dnl		AC_CHECK_LIB(dbm,dbm_open)
dnl
dnl restrictions:
dnl		should also check SVR4 case: dbm_open() in -lucb but that
dnl		would requiring dealing with -L/usr/ucblib
dnl
AC_DEFUN([OL_LIB_NDBM],
[AC_CACHE_CHECK(for NDBM library, [ol_cv_lib_ndbm],
[	ol_LIBS="$LIBS"
	AC_CHECK_FUNC(dbm_open,[ol_cv_lib_ndbm=yes], [
		AC_CHECK_LIB(ndbm,dbm_open,[ol_cv_lib_ndbm=-lndbm], [
			AC_CHECK_LIB(dbm,dbm_open,[ol_cv_lib_ndbm=-ldbm],
				[ol_cv_lib_ndbm=no])dnl
		])
	])
	LIBS="$ol_LIBS"
])
])dnl
dnl
dnl --------------------------------------------------------------------
dnl Check if NDBM exists
dnl
dnl defines ol_cv_ndbm to 'yes' or 'no'
dnl 
dnl uses:
dnl		OL_LIB_NDBM
dnl		AC_CHECK_HEADERS(ndbm.h)
dnl
dnl restrictions:
dnl		Doesn't handle SVR4 case (see above)
dnl
AC_DEFUN([OL_NDBM],
[AC_REQUIRE([OL_LIB_NDBM])
 AC_CHECK_HEADERS(ndbm.h)
 AC_CACHE_CHECK(for db, [ol_cv_ndbm], [
	if test $ol_cv_lib_ndbm = no -o $ac_cv_header_ndbm_h = no ; then
		ol_cv_ndbm=no
	else
		ol_cv_ndbm=yes
	fi
])
 if test $ol_cv_ndbm = yes ; then
	AC_DEFINE(HAVE_NDBM,1, [define if NDBM is available])
 fi
])dnl
dnl
dnl ====================================================================
dnl Check POSIX Thread version 
dnl
dnl defines ol_cv_posix_version to 'final' or 'draft' or 'unknown'
dnl 	'unknown' implies that the version could not be detected
dnl		or that pthreads.h does exist.  Existance of pthreads.h
dnl		should be tested separately.
dnl
AC_DEFUN([OL_POSIX_THREAD_VERSION],
[AC_CACHE_CHECK([POSIX thread version],[ol_cv_pthread_version],[
	AC_EGREP_CPP(pthread_version_final,[
#		include <pthread.h>
		/* this check could be improved */
#		ifdef PTHREAD_ONCE_INIT
			pthread_version_final
#		endif
	], ol_pthread_final=yes, ol_pthread_final=no)

	AC_EGREP_CPP(pthread_version_draft4,[
#		include <pthread.h>
		/* this check could be improved */
#		ifdef pthread_once_init
			pthread_version_draft4
#		endif
	], ol_pthread_draft4=yes, ol_pthread_draft4=no)

	if test $ol_pthread_final = yes -a $ol_pthread_draft4 = no; then
		ol_cv_pthread_version=final
	elif test $ol_pthread_final = no -a $ol_pthread_draft4 = yes; then
		ol_cv_pthread_version=draft4
	else
		ol_cv_pthread_version=unknown
	fi
])
])dnl
dnl
dnl --------------------------------------------------------------------
dnl Check LinuxThread
dnl
dnl defines ol_cv_linux_threads to 'yes' or 'no'
dnl		'no' implies pthreads.h is not LinuxThreads or pthreads.h
dnl		doesn't exists.  Existance of pthread.h should separately
dnl		checked.
dnl 
AC_DEFUN([OL_LINUX_THREADS],
[
AC_CACHE_CHECK([for LinuxThreads], [ol_cv_linux_threads], [
	res=`grep Linuxthreads /usr/include/pthread.h 2>/dev/null | wc -l`
	if test "$res" -gt 0 ; then
		ol_cv_linux_threads=yes
	else
		ol_cv_linux_threads=no
	fi
])
])dnl
dnl
dnl ====================================================================
dnl Check if toupper() requires islower() to be called first
AC_DEFUN([OL_C_UPPER_LOWER],
[
AC_MSG_CHECKING([if toupper() requires islower()])
AC_CACHE_VAL(ol_cv_c_upper_lower,[
	AC_TRY_RUN([
#include <ctype.h>
main()
{
	if ('C' == toupper('C'))
		exit(0);
	else
		exit(1);
}],
	[ol_cv_c_upper_lower=no],
	[ol_cv_c_upper_lower=yes],
	[ol_cv_c_upper_lower=safe])])
AC_MSG_RESULT($ol_cv_c_upper_lower)
if test $ol_cv_c_upper_lower != no ; then
	AC_DEFINE(C_UPPER_LOWER,1, [define if toupper() requires islower()])
fi
])
dnl
dnl ====================================================================
dnl Check for declaration of sys_errlist in one of stdio.h and errno.h.
dnl Declaration of sys_errlist on BSD4.4 interferes with our declaration.
dnl Reported by Keith Bostic.
AC_DEFUN([OL_SYS_ERRLIST],
[
AC_MSG_CHECKING([declaration of sys_errlist])
AC_CACHE_VAL(ol_cv_dcl_sys_errlist,[
	AC_TRY_COMPILE([
#include <stdio.h>
#include <sys/types.h>
#include <errno.h> ],
	[char *c = (char *) *sys_errlist],
	[ol_cv_dcl_sys_errlist=yes],
	[ol_cv_dcl_sys_errlist=no])])
AC_MSG_RESULT($ol_cv_dcl_sys_errlist)
# It's possible (for near-UNIX clones) that sys_errlist doesn't exist
if test $ol_cv_dcl_sys_errlist = no ; then
	AC_DEFINE(DECL_SYS_ERRLIST,1,
		[define if sys_errlist is not declared in stdio.h or errno.h])
	AC_MSG_CHECKING([existence of sys_errlist])
	AC_CACHE_VAL(ol_cv_have_sys_errlist,[
		AC_TRY_LINK([#include <errno.h>],
			[char *c = (char *) *sys_errlist],
			[ol_cv_have_sys_errlist=yes],
			[ol_cv_have_sys_errlist=no])])
	AC_MSG_RESULT($ol_cv_have_sys_errlist)
	if test $ol_cv_have_sys_errlist = yes ; then
		AC_DEFINE(HAVE_SYS_ERRLIST,1,
			[define if you actually have sys_errlist in your libs])
	fi
fi
])dnl
dnl
dnl ====================================================================
dnl Check to see if we should not declare strdup if we have it
dnl
AC_DEFUN([OL_DECL_STRDUP],
[
AC_MSG_CHECKING([strdup declaration])
AC_CACHE_VAL(ol_cv_dcl_strdup,[
	AC_TRY_COMPILE([
#include <string.h> ],
	[extern char *strdup();],
	[ol_cv_dcl_strdup=yes],
	[ol_cv_dcl_strdup=no])])
AC_MSG_RESULT($ol_cv_dcl_strdup)
if test $ol_cv_dcl_strdup = yes ; then
	AC_DEFINE(DECL_STRDUP,1,
		[define if you have strdup() but it's not declared])
fi
])dnl

dnl ====================================================================
dnl Early MIPS compilers (used in Ultrix 4.2) don't like
dnl "int x; int *volatile a = &x; *a = 0;"
dnl 	-- borrowed from PDKSH
AC_DEFUN(OL_C_VOLATILE,
 [AC_CACHE_CHECK(if compiler understands volatile, ol_cv_c_volatile,
    [AC_TRY_COMPILE([int x, y, z;],
      [volatile int a; int * volatile b = x ? &y : &z;
      /* Older MIPS compilers (eg., in Ultrix 4.2) don't like *b = 0 */
      *b = 0;], ol_cv_c_volatile=yes, ol_cv_c_volatile=no)])
  if test $ol_cv_c_volatile = yes; then
    : 
  else
    AC_DEFINE(volatile,)
  fi
 ])dnl
dnl
dnl ====================================================================
dnl Define sig_atomic_t if not defined in signal.h
AC_DEFUN(OL_TYPE_SIG_ATOMIC_T,
 [AC_CACHE_CHECK(for sig_atomic_t, ol_cv_type_sig_atomic_t,
    [AC_TRY_COMPILE([#include <signal.h>], [sig_atomic_t atomic;],
		ol_cv_type_sig_atomic_t=yes, ol_cv_type_sig_atomic_t=no)])
  if test $ol_cv_type_sig_atomic_t = no; then
    AC_DEFINE(sig_atomic_t, int)
  fi
 ])dnl
dnl
dnl ====================================================================
dnl check no of arguments for ctime_r
AC_DEFUN(OL_FUNC_CTIME_R_NARGS,
 [AC_CACHE_CHECK(number of arguments of ctime_r, ol_cv_func_ctime_r_nargs,
   [AC_TRY_COMPILE([#include <time.h>],
		[time_t ti; char *buffer; ctime_r(&ti,buffer,32);],
			ol_cv_func_ctime_r_nargs=3,
			[AC_TRY_COMPILE([#include <time.h>],
				[time_t ti; char *buffer; ctime_r(&ti,buffer);],
					ol_cv_func_ctime_r_nargs=2,
					ol_cv_func_ctime_r_nargs=0)])])
  if test $ol_cv_func_ctime_r_nargs -gt 1 ; then
    AC_DEFINE_UNQUOTED(CTIME_R_NARGS, $ol_cv_func_ctime_r_nargs,
		[set to the number of arguments ctime_r() expects])
  fi
])dnl
dnl
dnl --------------------------------------------------------------------
dnl check return type of ctime_r()
AC_DEFUN(OL_FUNC_CTIME_R_TYPE,
 [AC_CACHE_CHECK(return type of ctime_r, ol_cv_func_ctime_r_type,
   [AC_TRY_COMPILE([#include <time.h>],
		[int ctime_r();],
			ol_cv_func_ctime_r_type="int", ol_cv_func_ctime_r_type="charp")
	])
  if test $ol_cv_func_ctime_r_type = "int" ; then
	AC_DEFINE(CTIME_R_RETURNS_INT,1, [define if ctime_r() returns int])
  fi
])dnl
dnl ====================================================================
dnl check no of arguments for gethostbyname_r
AC_DEFUN(OL_FUNC_GETHOSTBYNAME_R_NARGS,
 [AC_CACHE_CHECK(number of arguments of gethostbyname_r,
	ol_cv_func_gethostbyname_r_nargs,
	[AC_TRY_COMPILE([#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#define BUFSIZE (sizeof(struct hostent)+10)],
		[struct hostent hent; char buffer[BUFSIZE];
		int bufsize=BUFSIZE;int h_errno;
		(void)gethostbyname_r("segovia.cs.purdue.edu", &hent,
			buffer, bufsize, &h_errno);],
		ol_cv_func_gethostbyname_r_nargs=5, 
 		[AC_TRY_COMPILE([#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#define BUFSIZE (sizeof(struct hostent)+10)],
			[struct hostent hent;struct hostent *rhent;
			char buffer[BUFSIZE];
			int bufsize=BUFSIZE;int h_errno;
			(void)gethostbyname_r("localhost", &hent, buffer, bufsize,
				&rhent, &h_errno);],
			ol_cv_func_gethostbyname_r_nargs=6,
			ol_cv_func_gethostbyname_r_nargs=0)])])
  if test $ol_cv_func_gethostbyname_r_nargs -gt 1 ; then
	AC_DEFINE_UNQUOTED(GETHOSTBYNAME_R_NARGS,
		$ol_cv_func_gethostbyname_r_nargs,
		[set to the number of arguments gethostbyname_r() expects])
  fi
])dnl
dnl
dnl check no of arguments for gethostbyaddr_r
AC_DEFUN(OL_FUNC_GETHOSTBYADDR_R_NARGS,
 [AC_CACHE_CHECK(number of arguments of gethostbyaddr_r,
	[ol_cv_func_gethostbyaddr_r_nargs],
	[AC_TRY_COMPILE([#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#define BUFSIZE (sizeof(struct hostent)+10)],
	   [struct hostent hent; char buffer[BUFSIZE]; 
	    struct in_addr add;
	    size_t alen=sizeof(struct in_addr);
	    int bufsize=BUFSIZE;int h_errno;
		(void)gethostbyaddr_r( (void *)&(add.s_addr),
			alen, AF_INET, &hent, buffer, bufsize, &h_errno);],
		ol_cv_func_gethostbyaddr_r_nargs=7,
		[AC_TRY_COMPILE([#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#define BUFSIZE (sizeof(struct hostent)+10)],
			[struct hostent hent;
			struct hostent *rhent; char buffer[BUFSIZE]; 
			struct in_addr add;
			size_t alen=sizeof(struct in_addr);
			int bufsize=BUFSIZE;int h_errno;
			(void)gethostbyaddr_r( (void *)&(add.s_addr),
				alen, AF_INET, &hent, buffer, bufsize, 
				&rhent, &h_errno);],
			ol_cv_func_gethostbyaddr_r_nargs=8,
			ol_cv_func_gethostbyaddr_r_nargs=0)])])
  if test $ol_cv_func_gethostbyaddr_r_nargs -gt 1 ; then
    AC_DEFINE_UNQUOTED(GETHOSTBYADDR_R_NARGS,
		$ol_cv_func_gethostbyaddr_r_nargs,
		[set to the number of arguments gethostbyaddr_r() expects])
  fi
])dnl
dnl
