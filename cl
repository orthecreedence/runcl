#!/bin/bash

# runcl
# 
# This is a script that attempts to provide a common interface for different
# lisp implementations on the command line. The idea is that no matter what
# lisp(s) you have installed, you have one script that provides a common
# interface to starting/running them.
# 
# It also support user-defined configuration via the ~/.runcl file.
# 
# Homepage: https://github.com/orthecreedence/runcl
# Author:   Andrew Lyon
# License:  MIT

version=0.0.1

default_locations="/bin:/usr/bin:/usr/local/bin:/opt/bin"

# TODO: allegro, lispworks, abcl
allowed_implementations="sbcl ccl ccl64 clisp ecl"

sbcl_locations="/usr/local/sbcl:/opt/sbcl"
sbcl_exec="run-sbcl.sh sbcl"

ccl_locations="/c/lisp/ccl:/usr/local/ccl:/opt/ccl"
ccl_exec="wx86cl lx86cl ccl"

ccl64_locations="/c/lisp/ccl:/usr/local/ccl:/opt/ccl"
ccl64_exec="wx86cl64 lx86cl64 ccl"

clisp_locations="/usr/local/clisp:/opt/clisp"
clisp_exec="clisp"

ecl_locations="/usr/local/ecl:/opt/ecl"
ecl_exec="ecl"

if [ "`uname -m`" == "x86_64" ]; then
	is_64bit=1
else
	is_64bit=0
fi

# define our command-line options, the defaults of which can be overridden by
# the .runcl file
RLWRAP=`which rlwrapzzz 2> /dev/null`
CFG_RC=
CFG_BATCH=
CFG_IMAGE=
CFG_HEAP=
CFG_STACK=
CFG_RLWRAP=1
# load the local config file
if [ -f "$HOME/.runcl" ]; then
	source $HOME/.runcl
fi
# don't let the config overwrite these values
CFG_LOAD=
CFG_EVAL=()
CFG_VERSION=

print_version() {
	echo
	echo "runcl ($version)"
}

print_help() {
	print_version

	echo
	echo "Usage:"
	echo "  cl [options] [lispfile]"
	echo
	echo "Options:"
	echo "  -h, --help         : Print this help"
	echo "  -v, --version      : Print runcl version"
	echo "  --clversion        : Run --version against the default CL"
	echo "  -n, --norc         : Skip loading of user rc file"
	echo "  -r, --rc <file>    : Load a specific RC file. Not portable"
	echo "  -b, --batch        : Run in batch mode (quit after processing)" 
	echo "  -i, --image <file> : Load a lisp image file"
	echo "  --heap <bytes>     : Set lisp heap size"
	echo "  --stack <bytes>    : Set lisp stack size"
	echo "  -e, --eval <form>  : Eval a form (can be called multiple times)"
	echo "  --no-rlwrap        : Turn off readline wrapper (on by default)"
	echo "  -c, --impl <lisp>  : Specify a desired lisp type to load."
	echo
	echo "    Allowed implementations (ever-growing):"
	echo "      $allowed_implementations"
	echo
	echo "~/.runcl variables:"
	echo "  preferred  : Preferred lisp to load. Can be one of:"
	echo "               $allowed_implementations"
	echo "  CFG_RC     : If \"0\", will skip loading the rc file. Otherwise"
	echo "               it will be loaded by default."
	echo "  CFG_BATCH  : Default cl to batch mode (quit after running, no repl)."
	echo "  CFG_IMAGE  : Image file to load by default."
	echo "  CFG_HEAP   : Default heap size (bytes)."
	echo "  CFG_STACK  : Default stack size (bytes)."
	echo "  CFG_RLWRAP : If 1, will load rlwrap (if it exists), otherwise will"
	echo "               start normally."
	echo
	echo "example ~/.runcl"
	echo
	echo "  preferred=ccl64"
	echo "  CFG_RLWRAP="
	echo 
	echo
	echo "Notes:"
	echo " - any parameters after [lispfile] will be ignored (but printed out"
	echo "   for your viewing/debugging pleasure)"
	echo " - if the \"rlwrap\" program exists in your path, it will be used to"
	echo "   load the lisp unless --no-rlwrap is given"
}

build_option() {
	directive=$1
	bare_directive=$(echo $directive | sed 's/-//g')
	value=$2
	ignore_force=$3

	if [ "$value" == "" ] && [ "$ignore_force" != "force" ]; then
		echo ""
		return;
	fi
	OPT="$directive "
	if [ "$ignore_force" != "ignore" ]; then
		if [ "$bare_directive" == "eval" ] || [ "$bare_directive" == "x" ]; then
			value="'$value'"
		fi
		OPT="$OPT $value"
	fi

	echo "$OPT "
}

sbcl_options() {
	if [ "$CFG_RC" == "0" ]; then
		OPTIONS="$OPTIONS --no-userinit "
	else
		OPTIONS="$OPTIONS `build_option --userinit $CFG_RC`"
	fi
	OPTIONS="$OPTIONS `build_option --version \"$CFG_VERSION\" ignore`"
	OPTIONS="$OPTIONS `build_option --load $CFG_LOAD`"
	for EVAL in "${CFG_EVAL[@]}"; do
		OPTIONS="$OPTIONS `build_option --eval \"$EVAL\"`"
	done
	OPTIONS="$OPTIONS `build_option --non-interactive \"$CFG_BATCH\" ignore`"
	OPTIONS="$OPTIONS `build_option --core $CFG_IMAGE`"
	OPTIONS="$OPTIONS `build_option --dynamic-space-size $CFG_HEAP`"
	OPTIONS="$OPTIONS `build_option --control-stack-size $CFG_STACK`"

	OPTIONS="$OPTIONS $sbcl_extra_options"
	echo $OPTIONS
}

ccl_options() {
	if [ "$CFG_RC" == "0" ]; then
		OPTIONS="$OPTIONS --no-init "
	fi
	OPTIONS="$OPTIONS `build_option --version \"$CFG_VERSION\" ignore`"
	OPTIONS="$OPTIONS `build_option --load $CFG_LOAD`"
	if [ "$CFG_BATCH" == "1" ]; then
		CFG_EVAL[${#CFG_EVAL[@]}]='(quit)'
	fi
	for EVAL in "${CFG_EVAL[@]}"; do
		OPTIONS="$OPTIONS `build_option --eval \"$EVAL\"`"
	done
	OPTIONS="$OPTIONS `build_option --image-name $CFG_IMAGE`"
	OPTIONS="$OPTIONS `build_option --heap-reserve $CFG_HEAP`"
	OPTIONS="$OPTIONS `build_option --stack-size $CFG_STACK`"

	OPTIONS="$OPTIONS $ccl_extra_options"
	echo $OPTIONS
}

ccl64_options() {
	ccl_options
}

clisp_options() {
	if [ "$CFG_RC" == "0" ]; then
		OPTIONS="$OPTIONS -norc "
	fi
	OPTIONS="$OPTIONS `build_option --version \"$CFG_VERSION\" ignore`"
	if [ "$CFG_BATCH" == "1" ]; then
		CFG_EVAL[${#CFG_EVAL[@]}]='(quit)'
	fi
	for EVAL in "${CFG_EVAL[@]}"; do
		OPTIONS="$OPTIONS `build_option -x \"$EVAL\"`"
	done
	OPTIONS="$OPTIONS `build_option -M $CFG_IMAGE`"
	OPTIONS="$OPTIONS `build_option -m $CFG_HEAP`"
	#OPTIONS="$OPTIONS `build_option --stack-size $CFG_STACK`"
	if [ "$CFG_RLWRAP" == "0" ]; then
		OPTIONS="$OPTIONS -disable-readline "
	fi

	OPTIONS="$OPTIONS $clisp_extra_options"
	if [ "$CFG_LOAD" != "" ]; then
		OPTIONS="$OPTIONS $CFG_LOAD"
	fi
	echo $OPTIONS
}

ecl_options() {
	if [ "$CFG_RC" == "0" ]; then
		OPTIONS="$OPTIONS --norc "
	fi
	OPTIONS="$OPTIONS `build_option --version \"$CFG_VERSION\" ignore`"
	OPTIONS="$OPTIONS `build_option -load $CFG_LOAD`"
	for EVAL in "${CFG_EVAL[@]}"; do
		OPTIONS="$OPTIONS `build_option -eval \"$EVAL\"`"
	done
	#OPTIONS="$OPTIONS `build_option --batch \"$CFG_BATCH\" ignore`"
	#OPTIONS="$OPTIONS `build_option --image-name $CFG_IMAGE`"
	OPTIONS="$OPTIONS `build_option --heap-size $CFG_HEAP`"
	OPTIONS="$OPTIONS `build_option --lisp-stack $CFG_STACK`"

	OPTIONS="$OPTIONS $ecl_extra_options"
	echo $OPTIONS
}

search_implementations="$preferred sbcl"
if [ "$is_64bit" == "1" ]; then
	search_implementations="$search_implementations ccl64"
else
	search_implementations="$search_implementations ccl"
fi
search_implementations="$search_implementations ecl clisp"

allowed_implementation() {
	IMPL=$1
	ALLOWED=no
	for imp in $(echo $allowed_implementations | tr " " "\n"); do
		if [ "$imp" == "$IMPL" ]; then
			ALLOWED=yes
			break;
		fi
	done
	echo $ALLOWED
}

while test -n "$1"; do
    case "$1" in
        --help|-h)
            print_help
			exit 0
            ;;
        --version|-v)
			print_version
			exit 0
            ;;
		--clversion)
			CFG_VERSION=1
			;;
		--norc|-n)
			CFG_RC=0
			;;
		--rc|-r)
			CFG_RC=$2
			shift
			;;
		--batch|-b)
			CFG_BATCH=1
			;;
		--image|-i)
			CFG_IMAGE=$2
			shift
			;;
		--heap)
			CFG_HEAP=$2
			shift
			;;
		--stack)
			CFG_STACK=$2
			shift
			;;
		--eval|-e)
			CFG_EVAL[${#CFG_EVAL[@]}]=$2
			shift
			;;
		--no-rlwrap)
			CFG_RLWRAP=0
			;;
		--impl|-cl)
			if [ "`allowed_implementation $2`" != "yes" ]; then
				echo "Bad implementation given. Must be one of:"
				echo "  $allowed_implementations"
				exit 1
			fi

			search_implementations="$2 $search_implementations"
			shift
			;;
        *)
			CFG_LOAD=$1
			shift
			if [ "$*" != "" ]; then
				echo 
				echo "  Note: ignoring args: \"$@\""
				echo "    (they appear after the file \"$CFG_LOAD\")"
				echo
			fi
			break;
            ;;
    esac
    shift
done


find_implementation() {
	OLDPATH=$PATH
	impls=$(echo $search_implementations | tr " " "\n")
	for impl in $impls; do
		if [ "$impl" == "" ]; then
			continue;
		fi
		impl_locations=$(eval "echo \$${impl}_locations")
		impl_exec=$(eval "echo \$${impl}_exec | tr \" \" \"\\\n\"")
		search_paths="$default_locations:${impl_locations}"
		export PATH=$OLDPATH
		export PATH="$search_paths:$PATH"
		for exe in $impl_exec; do
			CL_EXE=`which $exe 2> /dev/null`
			if [ "$CL_EXE" != "" ]; then
				break;
			fi
		done
		if [ "$CL_EXE" != "" ]; then
			break;
		fi
	done
	export PATH=$OLDPATH

	echo "$CL_EXE $impl"
}

IMPL=`find_implementation`
CL_PATH=$(echo $IMPL | sed 's/ .*//')
CL_NAME=$(echo $IMPL | sed 's/.* //')
CL_OPTIONS=`${CL_NAME}_options`

CMD="$CL_PATH"
if [ "$CFG_RLWRAP" == "1" ] && [ "$RLWRAP" != "" ]; then
	CMD="rlwrap $CMD"
fi

echo
echo "Running: $CMD $CL_OPTIONS"
echo
eval "$CMD" $CL_OPTIONS
