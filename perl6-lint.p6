#!/usr/bin/env perl6

if !@*ARGS {
    say "Usage: $*PROGRAM-NAME [options...] <files...>";
    exit;
}


my $debug = 0;
my %h;
for @*ARGS.kv -> $i, $arg {
    if !$arg.IO.f  {
        if 
    }
 
    # must be a file
    say "DEBUG:  Linting file '$f'..." if $debug;
    for $arg.IO.lines.kv $j, $line is copy {
        once next;
    }
}


