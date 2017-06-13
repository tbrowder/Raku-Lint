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
# a hash to keep info, key on line number
#  line number => type = 'value' # where value is name, or indentation, or '' if nothing of note
#    type is almost generic, list so far
#      begin, end, open, close
# analysis is done after parsing (????)
my %h;
my $nopen;  # number of types: open
my $nclose; # number of types: close
my %nbegin; # number of types: begin
my %nend;   # number of types: end

for @ifils -> $f {
    say "DEBUG:  Linting file '$f'..." if $debug;
    for $f.IO.lines.kv -> $linenum is copy, $line is copy {
	++$linenum;
        when $line ~~ /:i ^ \s* '=' (begin|end) \s+ (<alpha><alnum>+) / {
	    my $typ = ~$0;
            if $debug {
		say "line $linenum: =$typ {~$1}";
		say "  a 'begin' type" if $typ ~~ /begin/;
		say "  an 'end' type" if $typ ~~ /end/;
	    }
	    # a 'begin' or 'end' type
            # get the indentation amount
            my $indent = index $line, '=';
        }

        when $line ~~ /:i (<<open>> | ':err' | ':out' ) / {
	    my $typ = ~$0;
            if $debug {
		say "line $linenum: $typ";
		say "  an 'open' type";
	    }
	    # an 'open' type
        }

        when $line ~~ /:i (<<close>> | ':close' ) / {
	    my $typ = ~$0;
            if $debug {
		say "line $linenum: $typ";
		say "  a 'close' type";
	    }
	    # a 'close' type
        }
    }
}
