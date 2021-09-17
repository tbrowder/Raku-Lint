[![Actions Status](https://github.com/tbrowder/Raku-Lint/workflows/test/badge.svg)](https://github.com/tbrowder/Raku-Lint/actions)

NAME
====

**THIS IS A WORK IN PROGRESS**

**Raku::Lint**

Checks for some mistakes in Raku files and modules. Currently checks for:

  * matching pod `=begin/=end` statements

  * matching file `open/close` statements

  * matching heredoc labels

It also detects some Perl constructs that are lurking during a port of Perl code to Raku such as:

  * foreach

  * heredocs using '<<'

SYNOPSIS
========

```raku
    raku-lint [options...] <file names...>
```

or

```raku
    raku-lint [options...] --files=<file with list of files to check>
```

DESCRIPTION
===========

This module is a simple checker of Raku source code to detect common coding errors (file scope only at present). Its advantage over the compiler is that it checks every line rather than bailing out after finding the first error. It can be very useful in porting Perl code to Raku, and it may eventually be using some code from **Larry Wall**'s and **Bruce Gray**'s old conversion programs.

The module includes the executable Raku program `raku-lint`. Its use is shown by executing it with no arguments, e.g.,

```raku
$ ./raku-lint
Usage: raku-lint [options...] <one or more files to check...>

Checks files for errors:

  matching =begin/=end blocks
  file opens without a close

Options:

  --file=X   Files listed in file X are added to the list of files
               to check.
  --verbose  Reports more details to stdout.
```

AUTHOR
======

Tom Browder <tbrowder@cpan.org>

COPYRIGHT and LICENSE
=====================

Copyright © 2021 Tom Browder

This library is free software; you may redistribute or modify it under the Artistic License 2.0.

