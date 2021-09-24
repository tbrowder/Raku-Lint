[![Actions Status](https://github.com/tbrowder/Raku-Lint/workflows/test/badge.svg)](https://github.com/tbrowder/Raku-Lint/actions)

NAME
====

**Raku::Lint** [**THIS IS A WORK IN PROGRESS**]

A simple linter for Raku code

SYNOPSIS
========

```raku
$ ./raku-lint [options...] <file names...>
```

DESCRIPTION
===========

This module is a simple checker of Raku source code to detect common coding errors (file scope only at present). Its advantage over the compiler is that it checks every line rather than bailing out after finding the first error. It can be very useful in porting Perl code to Raku, and it may eventually use some code from **Larry Wall**'s and **Bruce Gray**'s old conversion programs as well as the late **Jeff Goff**'s **Perl6::Parser**.

The module includes the executable Raku program `raku-lint`. Its use is shown by executing it with no arguments, e.g.,

```raku
$ ./raku-lint
Usage: lint.raku [options...] <files to check...>

Checks files for some syntax and other errors.

Options:

  --dir=X       Raku files listed in directory X are added to the
                  list of files to check.
  --file=X      Files listed in file X are added to the list of files
                  to check.
  --strip       Strips normal comments (at and following first '#'
                  character on a line).
  --strip-last  Strips normal comments (at and following last '#'
                  character on a line).
  --verbose     Reports findings in detail to stdout.
```

Currently checks for:

  * Pod blocks

    Matching pod `=begin/=end` statements (checks for same indentation)

    Runaway pod blocks (improperly closed blocks).

  * Matching file `open/close` statements

  * Heredocs

    Matching terminators

    Runaway heredocs (missing ending terminator)

    Lines with less indentation than the terminator

It also detects some Perl constructs that are lurking during a port of Perl code to Raku such as:

  * foreach

  * heredocs using '=<<'

AUTHOR
======

Tom Browder <tbrowder@cpan.org>

COPYRIGHT and LICENSE
=====================

Copyright © 2021 Tom Browder

This library is free software; you may redistribute or modify it under the Artistic License 2.0.

