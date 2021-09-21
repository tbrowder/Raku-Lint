unit module Raku::Lint;

class LType is export {
    has $.type   is rw = '';
    # pod begin/end
    has $.label  is rw = '';
    has $.indent is rw = 0;
    
    method show {
        $*OUT.say: "    type:    '$!type'";
        $*OUT.say( "      label: '$!label'") if $!label;
        $*OUT.say( "      indent: $!indent") if $!indent;
    }
}

class LLine is export {
    has $.linenum;
    has $.line;
    has LType @.types;

    method show {
        $*OUT.say: "  line $!linenum: |$!line|";
        .show for @.types;
    }
}

# A class to keep track of problems in a single
# file
class Linter is export {
    has $.fname    is rw;

    =begin comment
    my $nopen  = 0; # number of types: open
    my $nclose = 0; # number of types: close
    my %begin;      # number of types: begin
    my %end;        # number of types: end
    =end comment

    has %.types is rw; # count by types

    # prob format example:
    #   %.probs{$line-num} = [];
    #      = "problem...
    has LLine %.lines    is rw; # key: line number, indexed from 1

    method record-pod-type($LT) {
        my ($t, $l) = $LT.type, $LT.label;
        if %!types{$t}{$l}:exists {
            ++%!types{$t}{$l}
        }
        else {
            %!types{$t}{$l} = 1;
        }
    }

    method record-io-type($LT) {
        my $t = $LT.type;
        if %!types<io>{$t}:exists {
            ++%!types<io>{$t}
        }
        else {
            %!types<io>{$t} = 1;
        }
    }

    method show {
	$*OUT.say: "== Linting file '$!fname'...";
        my @n = %!lines.keys.sort({$^a <=> $^b});
        for @n -> $n {
            %!lines{$n}.show; 
        }
    }

}

sub find-raku-files($dir) {
    use File::Find;
    find :$dir, :name(/'.' [p6|pl6|pm6|raku|rakumod] $/);
} # sub find-raku-files

sub set-get-LLine($LL where LLine|Int, :$linenum!, :$line!, Linter:D :$linter!) {
    my $ll = $LL;
    if not $ll {
        $ll = LLine.new: :$linenum, :$line;
        $linter.lines{$linenum} = $ll;
    }
    $ll
}

sub lint(
    @ifils, 
    :$ifil, 
    :$idir, 
    :$strip = 0, 
    :$last = 0, 
    :$verbose, 
    :$debug 
    --> List
) is export {
    use Text::Utils :strip-comment;

    # local vars
    my %ifils;
    if @ifils.elems {
        for @ifils { %ifils{$_} = 1 };
    }

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

    my $s = '';
    if $ifil and $ifil.IO.r {
        # get the files out of the input file
        for $ifil.IO.lines -> $line {
            for $line.words -> $fil {
                next if !$fil.IO.f;
                %ifils{$fil}++;
            }
        }
    }

    if $idir and $idir.IO.d {
        # get the files out of the input dir
        my @fils = find-raku-files $idir;
        for @fils -> $fil {
            next if !$fil.IO.f;
            %ifils{$fil}++;
        }
    }

    my @linters; # one Linter object per file
    for %ifils.keys.sort -> $fname {
        unless $fname.IO.f {
            die "FATAL: \%ifils.keys->\$fname '$fname' is NOT a file";
        }

        my $L = Linter.new: :$fname;
        @linters.push: $L;

        my $in-heredoc;
        my $heredoc-label;
	LINE: for $fname.IO.lines.kv -> $linenum is copy, $line is copy {
            ++$linenum; # make line numbers indexed from one
            # ignore normal comments?
            if $strip and $last {
                $line = strip-comment $line, :$last;
            }
            elsif $strip {
                $line = strip-comment $line;
            }

            # skip blank lines
            next LINE if $line !~~ /\S/;

            # We only have LLine objects for lines that are triggered
            # by some policy problem.
            my $LL = 0; # LLine.new: :$linenum, :$line;

            if $in-heredoc {
                # the only word on the line should be the ending label
                next LINE if $line !~~ /$heredoc-label/;

                $in-heredoc = 0;
		my $type  = "End-heredoc";
               
                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);
                my $LT = LType.new: :$type, :label($heredoc-label);
                $LL.types.push($LT);
                
                next LINE;
            }

            if $line ~~ /^ \s* '=' (begin|end) \s+ (<alpha><alnum>+) / {
		my $type  = ~$0;
		my $label = ~$1;
                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);

                my $LT = LType.new: :$type;
                $LL.types.push($LT);
		# a 'begin' or 'end' type
                $LT.label = $label;
		# get the indentation amount
		$LT.indent = index $line, '=';

                $L.record-pod-type: $LT;
                # should only be one per line
                next LINE;
            }

            if $line ~~ / <<open>> / {
		my $type = 'open';
                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);

                my $LT = LType.new: :$type;
                $LL.types.push($LT);
                $L.record-io-type: $LT;
            }

            if $line ~~ / ':err' / {
		my $type = 'open';
                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);

                my $LT = LType.new: :$type;
                $LL.types.push($LT);
                $L.record-io-type: $LT;

                # possible other open type on the same line
                $line = $/.prematch ~ " " ~ $/.postmatch;
            }

            if $line ~~ / ':out' / {
		my $type = 'open';
                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);

                my $LT = LType.new: :$type;
                $LL.types.push($LT);
                $L.record-io-type: $LT;

                # possible other open type on the same line
                $line = $/.prematch ~ " " ~ $/.postmatch;
            }

            if $line ~~ / <<close>> / {
		my $type = 'close';
                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);

                my $LT = LType.new: :$type;
                $LL.types.push($LT);
                $L.record-io-type: $LT;
            }

            if $line ~~ / ':close' / {
		my $type = 'close';
                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);

                my $LT = LType.new: :$type;
                $LL.types.push($LT);
                $L.record-io-type: $LT;
            }

            if $line ~~ /  (foreach) / {
		my $type = ~$0;
                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);

                my $LT = LType.new: :$type;
                $LL.types.push($LT);
            }

            if $line ~~ /  '=' \h* '<<' / {
		my $type = "Perl-heredoc";
                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);

                my $LT = LType.new: :$type;
                $LL.types.push($LT);
            }

            if $line ~~ / [q|qq] ':' [to|heredoc] '/' (<alpha><alnum>+) '/'  / {
		my $type = "Raku-heredoc";
                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);
                $heredoc-label = ~$0;
                $in-heredoc    = 1;

                my $LT = LType.new: :$type, :label($heredoc-label);
                $LL.types.push($LT);

                # read lines until finding matching label
                # handled above
                next LINE;
            }
            
	}
    }

    @linters;
    
} # sub lint
