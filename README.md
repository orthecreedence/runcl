runcl - A common interface for command line CL
==============================================
Runcl is a shell wrapper around Common Lisp implementations that provides a 
common interface to running via the command line. The goal is to provide one
syntax to load/run lisp across platforms/implementations.

It's currently supported on windows via cygwin (since it's a bash script).

Interface
---------
I'm way too lazy to type this all up again since I just finished the `--help`
option, so it's going to stay blank until I'm motivated to finish it.

```bash
# print out all options
cl --help
```

Examples
--------

```bash
# start your default lisp implementation
cl

# start SBCL (if it exists, otherwise load next implementation) with no RC file loaded
cl -cl sbcl -n

# start your default implementation, load "app.lisp", quit once done processing (batch mode)
cl -b app.lisp
```

.runcl
------
The `~/.runcl` file is a simple configuration file that is sourced by runcl. It
can tell runcl some useful things, such as what implementation to run, whether
or not to load the rc file by default, etc:

    preferred  : Preferred lisp(s). Loaded in the given order.
	    Can be one or more of: sbcl ccl ccl64 clisp ecl
    CFG_RC     : If "0", will skip loading the rc file. Otherwise it will be loaded by default.
    CFG_BATCH  : Default cl to batch mode (quit after running, no repl).
    CFG_IMAGE  : Image file to load by default.
    CFG_HEAP   : Default heap size (bytes).
    CFG_STACK  : Default stack size (bytes).
    CFG_RLWRAP : If 1, will load rlwrap (if it exists), otherwise will start normally.

This is really just a simple bash script, so variables are set just like in
bash:

    preferred=ccl64
	CFG_RLWRAP=

This says "my preferred implementation is CCL 64-bit, and don't use the `rlwrap`
command when starting.

Implementations
---------------
Supported:

* SBCL
* Clozure (x86 and x86_64)
* ECL
* clisp

Unsupported:

* Allegro
* Lispworks
* ABCL
* Others

__Please__ help me add support for the above (if you care about them) by
[opening an issue](https://github.com/orthecreedence/runcl/issues/new) and
posting the following information:

* common executable names (for instance, Clozure has lx86cl, lx86cl64, wx86cl,
etc)
* The complete output of `--help` (or whatever command lists the usage for the
lisp's executable).

Thanks!

Broken
------
* Some implementations take megabytes for heap sizes, some take bytes. I have
_not_ standardized this yet. This is probably next on my list.
* Many implementations are not taken into account, yet.
