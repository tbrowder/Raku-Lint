#!/usr/bin/env perl6

use lib <./lib>;

use Perl6::Linter::Lite;

if !@*ARGS {
    say "Usage: $*PROGRAM-NAME [options...] <files...>";
    exit;
}

my $debug = 0;
my @ifils;

for @*ARGS -> $arg {
    if !$arg.IO.f  {
        if $arg ~~ /:i ^ d / {
            $debug = 1;
        }
        else {
            say "FATAL:  Unknown arg '$arg'.";
            exit;
        }
        next;
    }

    # must be a file
    @ifils.append: $arg;

}

my $tifil = 't/data/p6-lint-test-script.p6';
if $debug {
    @ifils.append: $tifil;
}

die "FATAL: No files entered.\n" if !@ifils;

my %h;
for @ifils -> $f {
    say "DEBUG:  Linting file '$f'..." if $debug;
    for $f.IO.lines.kv -> $linenum is copy, $line is copy {
	++$linenum;
        when $line ~~ /:i ^ \s* '=' (begin|end) \s+ (<alpha><alnum>+) / {
            if $debug {
		say "line $linenum: ={~$0} {~$1}";
	    }
        }
        when $line ~~ /:i (<<open>>) / {
            if $debug {
		say "line $linenum: {~$0}";
	    }
        }
        when $line ~~ /:i (':err')  / {
            if $debug {
		say "line $linenum: {~$0}";
	    }
        }
        when $line ~~ /:i (':out')  / {
            if $debug {
		say "line $linenum: {~$0}";
	    }
        }
    }
}
