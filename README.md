runcl - A common interface for command line CL
==============================================
Runcl is a shell wrapper around Common Lisp implementations that provides a 
common interface to running via the command line. The goal is to provide one
syntax to load/run lisp across platforms/implementations.

It's currently supported on windows via cygwin (since it's a bash script).

Use cl-launch
=============
So apparently someone else has already done what I'm doing and done it way
better. Please use [cl-launch](http://www.cliki.net/CL-Launch) instead of runcl.

Oops.

Interface
---------
Output from `--help`:

```bash
runcl (0.0.1)

Usage:
  cl [options] [lispfile]

Options:
  -h, --help         : Print this help
  -v, --version      : Print runcl version
  --clversion        : Run --version against the default CL
  -n, --norc         : Skip loading of user rc file
  -r, --rc <file>    : Load a specific RC file. Not portable
  -b, --batch        : Run in batch mode (quit after processing)
  -i, --image <file> : Load a lisp image file
  --heap <bytes>     : Set lisp heap size
  --stack <bytes>    : Set lisp stack size
  -e, --eval <form>  : Eval a form (can be called multiple times)
  -c, --impl <lisp>  : Specify a desired lisp type to load.

    Allowed implementations (ever-growing):
      sbcl ccl ccl64 clisp ecl

~/.runcl variables:
  preferred  : Preferred lisp(s). Loaded in the given order.
      Can be on or more of: sbcl ccl ccl64 clisp ecl
  search     : Paths (":" delimited) to search for lisp implementations.
  CFG_RC     : If "0", will skip loading the rc file. Otherwise
               it will be loaded by default.
  CFG_BATCH  : Default cl to batch mode (quit after running, no repl).
  CFG_IMAGE  : Image file to load by default.
  CFG_HEAP   : Default heap size (bytes).
  CFG_STACK  : Default stack size (bytes).

example ~/.runcl

  # 64-bit CCL is preferred, but if not available use SBCL
  preferred=ccl64 sbcl

  # search for lisps in /opt/lisp/ccl and /opt/lisp/sbcl
  search=/opt/lisp/ccl:/opt/lisp/sbcl

  # always run in batch mode (quit instead of returning to REPL)
  CFG_BATCH=1


Notes:
 - any parameters after [lispfile] will be ignored (but printed out
   for your viewing/debugging pleasure)
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
    search     : Paths (":" delimited) to search for lisp implementations.
    CFG_RC     : If "0", will skip loading the rc file. Otherwise it will be loaded by default.
    CFG_BATCH  : Default cl to batch mode (quit after running, no repl).
    CFG_IMAGE  : Image file to load by default.
    CFG_HEAP   : Default heap size (bytes).
    CFG_STACK  : Default stack size (bytes).

This is really just a simple bash script, so variables are set just like in
bash:

    preferred=ccl64 sbcl

This says "my preferred implementation is CCL 64-bit, if tht isn't available,
use SBCL."

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
