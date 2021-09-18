unit module Raku::Lint;

# a hash to keep info, key on line number
#  line number => type = 'value' # where value is name, or indentation, or '' if nothing of note
#    type is almost generic, list so far
#      begin, end, open, close
# analysis is done after parsing (????)

sub lint(@ifils, :$ifil, :$verbose, :$debug --> Str) is export {
    # local vars
    my %ifils;
    if @ifils.elems {
        for @ifils { %ifils{$_} = 1 };
    }
    my %h;
    my $nopen  = 0; # number of types: open
    my $nclose = 0; # number of types: close
    my %begin;      # number of types: begin
    my %end;        # number of types: end

    my Str $s = '';
    if $ifil and $ifil.IO.r {
        # get the files out of the input file
        for $ifil.IO.lines -> $line {
            for $line.words -> $fil {
                next if !$fil.IO.f;
                %ifils{$fil}++;
            }
        }
    }

    for %ifils.keys -> $f {
        unless $f.IO.f {
            die "FATAL: \%ifils.keys->\$f '$f' is NOT a file";
        }
	$s ~= "== Linting file '$f'...\n" if $verbose;
	for $f.IO.lines.kv -> $linenum is copy, $line is copy {
	    ++$linenum;
            when $line ~~ /:i ^ \s* '=' (begin|end) \s+ (<alpha><alnum>+) / {
		my $typ = ~$0;
		my $nam = ~$1;
		if $verbose {
		    $s ~= "line $linenum: =$typ $nam\n";
		    $s ~= "  a 'begin' type\n" if $typ ~~ /begin/;
		    $s ~= "  an 'end' type\n" if $typ ~~ /end/;
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
		elsif $typ ~~ /end/ {
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
		if $verbose {
		    $s ~= "line $linenum: $typ\n";
		    $s ~= "  an 'open' type\n";
		}
		# an 'open' type
		++$nopen;
            }

            when $line ~~ /:i (<<close>> | ':close' ) / {
		my $typ = ~$0;
		if $verbose {
		    $s ~= "line $linenum: $typ\n";
		    $s ~= "  a 'close' type\n";
		}
		# a 'close' type
		++$nclose;
            }
	}
    }

    for %begin.keys.sort -> $k {
	my $v = %begin{$k};
	$s ~= "  begin $k: $v\n";
    }
    for %end.keys.sort -> $k {
	my $v = %end{$k};
	$s ~= "  end $k: $v\n";
    }

    $s ~= qq:to/HERE/;
    open:  $nopen
    close: $nclose
    HERE

    $s
} # sub lint
