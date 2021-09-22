#!/usr/bin/env raku
use lib <../lib>;
use Raku::Lint;

if !@*ARGS {
    say qq:to/HERE/;
    Usage: {$*PROGRAM.basename} [options...] <files to check...>

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
    HERE
    exit;
}

my $verbose = 0;
my %ifils   = [];
my $debug   = 0;
my $ifil    = 0;
my $idir    = 0;
my $strip   = 0;
my $last    = 0;
ARG: for @*ARGS -> $arg {
    if !$arg.IO.f  {
        if $arg ~~ /^ '-'? '-v' [erbose]? $/ {
            ++$verbose;
        }
        elsif $arg ~~ /^ '--dir=' (\S+) / {
            $idir = ~$0;
        }
        elsif $arg ~~ /^ '-'? '-d' [ebug]? $/ {
            ++$debug;
        }
        elsif $arg ~~ /^ '--file=' (\S+) / {
            $ifil = ~$0;
        }
        elsif $arg eq '--strip' {
            $strip = 1;
        }
        elsif $arg eq '--strip-last' {
            $strip = 1;
            $last  = 1;
        }
        else {
            say "FATAL:  Unknown arg '$arg'.";
            exit;
        }
        next ARG;
    }

    # must be a file
    unless $arg and $arg.IO.f {
        say "FATAL: Arg '$arg' is not a file.";
        exit;
    }
    %ifils{$arg.IO.absolute} = 1;
}

die "FATAL: No files entered.\n" if !%ifils && !$ifil && !$idir;

my @ifils = %ifils.keys;
my @linters = lint(@ifils, :$ifil, :$idir, :$strip, :$last, :$verbose, :$debug);
$_.show(:$verbose, :$debug) for @linters;
