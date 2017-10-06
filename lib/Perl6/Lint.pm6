unit module Perl6::Lint;

# a hash to keep info, key on line number
#  line number => type = 'value' # where value is name, or indentation, or '' if nothing of note
#    type is almost generic, list so far
#      begin, end, open, close
# analysis is done after parsing (????)
my %h;
my $nopen  = 0; # number of types: open
my $nclose = 0; # number of types: close
my %begin;      # number of types: begin
my %end;        # number of types: end

sub Lint(%ifils, :$ifil, :$debug, :$verbose) is export {

    if $ifil {
        # get the files out of the input file
        for $ifil.IO.lines -> $line {
            for $line.words -> $fil {
                next if !$fil.IO.f;
                %ifils{$fil}++;
            }
        }
    }

    for %ifils.keys -> $f {
	say "DEBUG:  Linting file '$f'..." if $debug;
	for $f.IO.lines.kv -> $linenum is copy, $line is copy {
	    ++$linenum;
            when $line ~~ /:i ^ \s* '=' (begin|end) \s+ (<alpha><alnum>+) / {
		my $typ = ~$0;
		my $nam = ~$1;
		if $debug {
		    say "line $linenum: =$typ $nam";
		    say "  a 'begin' type" if $typ ~~ /begin/;
		    say "  an 'end' type" if $typ ~~ /end/;
		}
		# a 'begin' or 'end' type
		# get the indentation amount
		my $indent = index $line, '=';
		%h{$linenum}<type>{$typ}<indent> = $indent;
		%h{$linenum}<type>{$typ}<name>   = $nam;
		if $typ ~~ /begin/ {
                    if %begin{$nam}:exists {
			++%begin{$nam};
                    }
                    else {
			%begin{$nam} = 1;
                    }
		}
		else {
                    if %end{$nam}:exists {
			++%end{$nam};
                    }
                    else {
			%end{$nam} = 1;
                    }
		}
            }

            when $line ~~ /:i (<<open>> | ':err' | ':out' ) / {
		my $typ = ~$0;
		if $debug {
		    say "line $linenum: $typ";
		    say "  an 'open' type";
		}
		# an 'open' type
		++$nopen;
            }

            when $line ~~ /:i (<<close>> | ':close' ) / {
		my $typ = ~$0;
		if $debug {
		    say "line $linenum: $typ";
		    say "  a 'close' type";
		}
		# a 'close' type
		++$nclose;
            }
	}
    }

    say "Normal end.";
    for %begin.keys.sort -> $k {
	my $v = %begin{$k};
	say "  begin $k: $v";
    }
    for %end.keys.sort -> $k {
	my $v = %end{$k};
	say "  end $k: $v";
    }
    say qq:to/HERE/;
    open:  $nopen
    close: $nclose
    HERE
}
