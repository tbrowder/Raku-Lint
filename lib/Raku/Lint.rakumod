unit module Raku::Lint;

class LType is export {
    has $.type is required  is rw = '';
    # pod begin/end
    has $.label  is rw = '';
    has $.indent is rw = 0;
    has $.linenum is required is rw = 0;

    method show(:$runaway) {
        if $runaway {
            # used for runaway heredocs
            $*OUT.say: "    type:           '$!type'";
            $*OUT.say: "    starting line:  $!linenum" if $!linenum;
            $*OUT.say: "    label:          '$!label'"  if $!label;
        }
        else {
            $*OUT.say: "    type:     '$!type'";
            $*OUT.say: "      line:   $!linenum" if $!linenum;
            $*OUT.say: "      label:  '$!label'"  if $!label;
            $*OUT.say: "      indent: $!indent"  if $!indent;
        }
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

    has %.types         is rw; # count by types
    has @.pod-stack     is rw; # track matching begin/end pairs
    has $.open-heredoc  is rw; # track unclosed heredocs
    has @.misc-stack    is rw; # foreach, etc.

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

    method show(:$verbose = 0, :$debug) {
	$*OUT.say: "== Linting file '$!fname'...";
        if $verbose {
            my @n = %!lines.keys.sort({$^a <=> $^b});
            for @n -> $n {
                %!lines{$n}.show;
            }
        }

        unless @!misc-stack.elems or @!pod-stack.elems or $!open-heredoc {
	    $*OUT.say: "  No problems found.";
            return;
        }

        if @!misc-stack.elems {
	    $*OUT.say: "  Miscellaneous problems:";
            for @!misc-stack -> $LT {
                $LT.show;
            }
        }
        if @!pod-stack.elems {
	    $*OUT.say: "  Pod label match problems:";
            for @!pod-stack -> $LT {
                $LT.show;
            }
        }
        if $!open-heredoc {
	    $*OUT.say: "  Runaway heredoc with no closing label:";
            $!open-heredoc.show(:runaway);
        }
    }

}

sub find-raku-files($dir) {
    use File::Find;
    find :$dir, :name(/'.' [p6|pl6|pm6|raku|rakumod] $/), :type('file');;
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
                note "DEBUG: \$in-heredoc is True on line $linenum" if $debug;
                # the only word on the line should be the ending label
                next LINE if $line !~~ /$heredoc-label/;

                # we must have found the ending label, so...
                note "DEBUG: Line $linenum: found ending heredoc label '$heredoc-label' for heredoc type '{$L.open-heredoc.type}'" if $debug;
                $in-heredoc = 0;
		my $type  = "End-heredoc";

                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);
                my $LT = LType.new: :$type, :$linenum;
                $LL.types.push($LT);

                # check the heredoc stack and remove the found match
                # if all is well
                die "FATAL: Unexpected empty \$open-heredoc" if not $L.open-heredoc;
                my $opener = $L.open-heredoc;
                my $err = 0;
                ++$err if $opener.label ne $heredoc-label;
                ++$err if $opener.type !~~ /heredoc/;
                die "FATAL: Unexpected \$open-heredoc errors" if $err;
                $L.open-heredoc = 0;

                next LINE;
            }

            # check heredoc beginners
            if $line ~~ / '=' \h* '<<' <['"]> (<alpha><alnum>+) <['"]> / {
	        my $type = "Perl-heredoc";
                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);
                $heredoc-label = ~$0;
                $in-heredoc    = 1;

                my $LT = LType.new: :$type, :label($heredoc-label), :$linenum;
                $LL.types.push($LT);

                # reportable
                $L.misc-stack.push($LT);

                die "FATAL: Unexpected value for \$open-heredoc" if $L.open-heredoc;
                $L.open-heredoc = $LT;

                # read lines until finding matching label
                # handled above

                next LINE;
            }

            if $line ~~ / [q|qq] ':' [to|heredoc] '/' (<alpha><alnum>+) '/'  / {
                my $type = "Raku-heredoc";
                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);
                $heredoc-label = ~$0;
                $in-heredoc    = 1;

                my $LT = LType.new: :$type, :label($heredoc-label), :$linenum;
                $LL.types.push($LT);

                # reportable
                die "FATAL: Unexpected value for \$open-heredoc" if $L.open-heredoc;
                $L.open-heredoc = $LT;

                # read lines until finding matching label
                # handled above

                next LINE;
            }


            # This loop allows visiting the line multiple times
            # to pick out interesting pieces by pasting prematch
            # and postmatch parts into a new line.
            loop {
                my $x = 0;

                if $line ~~ /^ \s* '=' (begin|end) \s+ (<alpha><alnum>+) / {
	       	    my $type  = ~$0;
		    my $label = ~$1;
                    $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);

                    my $LT = LType.new: :$type, :$linenum;
                    $LL.types.push($LT);
                    $LT.label = $label;
		    # get the indentation amount
		    $LT.indent = index $line, '=';

                    $L.record-pod-type: $LT;
                    # should only be one per line

                    $line = paste $/;
                    ++$x;
                }

                if $line ~~ / <<open>> / {
		    my $type = 'open';
                    $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);

                    my $LT = LType.new: :$type, :$linenum;
                    $LL.types.push($LT);
                    $L.record-io-type: $LT;

                    $line = paste $/;
                    ++$x;
                }

                if $line ~~ / ':err' / {
		    my $type = 'open';
                    $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);

                    my $LT = LType.new: :$type, :$linenum;
                    $LL.types.push($LT);
                    $L.record-io-type: $LT;

                    # possible other open type on the same line
                    $line = paste $/;
                    ++$x;
                }

                if $line ~~ / ':out' / {
		    my $type = 'open';
                    $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);

                    my $LT = LType.new: :$type, :$linenum;
                    $LL.types.push($LT);
                    $L.record-io-type: $LT;

                    # possible other open type on the same line
                    $line = paste $/;
                    ++$x;
                }

                if $line ~~ / <<close>> / {
		    my $type = 'close';
                    $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);

                    my $LT = LType.new: :$type, :$linenum;
                    $LL.types.push($LT);
                    $L.record-io-type: $LT;

                    $line = paste $/;
                    ++$x;
                }

                if $line ~~ / ':close' / {
		    my $type = 'close';
                    $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);

                    my $LT = LType.new: :$type, :$linenum;
                    $LL.types.push($LT);
                    $L.record-io-type: $LT;

                    $line = paste $/;
                    ++$x;
                }

                if $line ~~ / (foreach) / {
		    my $type = ~$0;
                    $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);
                    my $LT = LType.new: :$type, :$linenum;
                    $LL.types.push($LT);

                    # reportable
                    $L.misc-stack.push($LT);

                    $line = paste $/;
                    ++$x;
                }


                redo if $x > 0;
                last;
            }
	}
    }

    @linters;

} # sub lint

sub paste(Match $m) {
    $m.prematch ~ " " ~ $m.postmatch
}
