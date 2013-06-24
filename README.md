runcl - A common interface for command line CL
==============================================
Runcl is a shell wrapper around Common Lisp implementations that provides a 
common interface to running via the command line. The goal is to provide one
syntax to load/run lisp across platforms/implementations.

It's currently supported on windows via cygwin (since it's a bash script).

I'm aware that [cl-launch](http://cliki.net/cl-launch) has some similar goals.
runcl aims to be a very simple wrapper to instantiate your CL implementation.
It does not handle script generation or saving of images or executables. It
tries to do one thing well. If you need more options, use cl-launch.

Interface
---------
Output from `--help`:

```bash
runcl (0.0.3)

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
  -e, --eval <form>  : Eval a lisp form (can be called multiple times)
  -cl, --impl <lisp> : Specify a desired lisp type to load, space delim
  -nw, --no-rlwrap   : Specify NOT to use rlwrap if it exists in the $PATH

    Allowed implementations (ever-growing):
      sbcl ccl ccl64 clisp ecl

Command line example:

  # load Clozure CL 64bit (but SBCL if CCL isn't available), don't load the RC
  # file, and run a format command in batch mode
  cl -cl 'ccl64 sbcl' -n -b -e '(format t hello~%)'

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
  CFG_RLWRAP : Whether or not to use rlwrap when running lisp (1 by default).

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

```
preferred  : Preferred lisp(s). Loaded in the given order.
    Can be one or more of: sbcl ccl ccl64 clisp ecl
search     : Paths (":" delimited) to search for lisp implementations.
CFG_RC     : If "0", will skip loading the rc file. Otherwise it will be loaded by default.
CFG_BATCH  : Default cl to batch mode (quit after running, no repl).
CFG_IMAGE  : Image file to load by default.
CFG_HEAP   : Default heap size (bytes).
CFG_STACK  : Default stack size (bytes).
CFG_RLWRAP : Whether or not to use rlwrap when running lisp (1 by default).
```

Note that `CFG_RLWRAP` is on by default, but will not try to load rlwrap *unless
it exists in `$PATH`*.

This is really just a simple bash script, so variables are set just like in
bash. Here's a short example:

```bash
# if Clozure CL 64-bit is not available, use SBCL
preferred=ccl64 sbcl

# turn off rlwrap (even if it's in $PATH)
CFG_RLWRAP=0

# batch all operations (quit after running file/code)
CFG_BATCH=1
```

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
