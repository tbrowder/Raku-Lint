unit module Raku::Lint;

# Some delimited pod blocks can be parents, and some not.

my %types = set <pod heredoc perl-heredoc foreach open close>;
class LType is export {
    has     $.type    is required; # one of: pod, heredoc, foreach, perl-heredoc
    has Int $.linenum is required;

    has $.label;

    # delimited pod block begin/end
    # also heredoc begin/end
    has $.begin;
    has $.end;
    # delimited pod block begin
    has $.is-parent;

    # delimited pod block begin/end
    has $.indent is rw = 0;
    has $.indent-str;

    submethod TWEAK {
        unless %types{$!type}:exists {
            die "FATAL: Unknown type '$!type'"
        }
        my $err = 0;
        my $err-str = '';
        # if pod
        #   must have label (typename)
        #   must have indent-str
        #   must be begin or end
        #   if begin must be a parent or not
        if $!type eq 'pod' {

            if $!begin.defined and $!end.defined {
                die "FATAL: Both 'begin' AND 'end' are defined"
            }
            elsif $!begin.defined {
                die "FATAL: A 'begin' must have 'is-parent' defined" if not $!is-parent.defined
            }
            elsif $!end.defined {
                ; # ok for now
            }
        }

        # if heredoc
        #   must have label (terminator)
        elsif $!type ~~ /heredoc/ {
            ; # ok for now
        }

    }

    method show(:$runaway, :$pod) {
        if $runaway {
            # used for runaway heredocs
            $*OUT.say: "    type:          '$!type'";
            $*OUT.say: "    starting line: $!linenum" if $!linenum;
            $*OUT.say: "    terminator:    '$!label'"  if $!label;
        }
        elsif $pod {
            # used for runaway =begin blocks
            $*OUT.say: "    type:          '$!type'";
            $*OUT.say: "    starting line: $!linenum" if $!linenum;
            $*OUT.say: "    typename:      '$!label'"  if $!label;
        }
        else {
            $*OUT.say: "    type:     '$!type'";
            $*OUT.say: "      line:   $!linenum" if $!linenum;
            if $!type ~~ /heredoc/ {
                $*OUT.say: "      terminator:  '$!label'"  if $!label;
            }
            elsif $!type ~~ /begin/ {
                $*OUT.say: "      typename:    '$!label'"  if $!label;
                $*OUT.say: "      indent:      $!indent"  if $!indent;
            }
            else {
                $*OUT.say: "      label:  '$!label'"  if $!label;
                $*OUT.say: "      indent: $!indent"  if $!indent;
            }
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

    has %.types           is rw; # count by types
    has @.misc-stack      is rw; # track matching begin/end pairs
    # All delimited pod blocks (except comment) can be parents
    has @.pod-stack      is rw; # track matching begin/end pairs
    # A heredoc cannot be a parent, but we can define a list of
    # heredocs in one statement
    has $.open-heredoc   is rw; # track unclosed heredocs

    # All delimited pod blocks (except comment) can be parents
    has @.open-pod-block is rw; # track unclosed pod blocks

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

        unless @!misc-stack.elems or
               @!pod-stack.elems or
               $!open-heredoc or
               @!open-pod-block.elems {
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
	    $*OUT.say: "  Pod typename match problems:";
            for @!pod-stack -> $LT {
                $LT.show;
            }
        }
        if $!open-heredoc {
	    $*OUT.say: "  Runaway heredoc with no terminator:";
            $!open-heredoc.show(:runaway);
        }
        if @!open-pod-block {
            for @!open-pod-block -> $p {
	        $*OUT.say: "  Runaway pod block with no matching '{$p.indent-str}=end {$p.label}'";
            }
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

        # for heredocs (note the compiler warns of indentation
        # problems so we don't worry about it, at least not yet)
        my $in-heredoc;
        my $heredoc-label;      # terminator
        my $heredoc-indent;     # num spaces, determined at termination
        my $heredoc-min-indent = Inf; # check on every line before termination

        # for pod =begin/=end blocks
        my $pod-parent = 0;
        my $pod-label;      # typename
        my $pod-indent;     # num spaces, critical, end must have same indentation and typename
        my $pod-indent-str; # string of indent spaces

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

            # we may be either in a heredoc OR a pod block
            if $in-heredoc {
                note "DEBUG: \$in-heredoc is True on line $linenum" if $debug;
                # the only word on the line should be the ending label (terminator), but we
                # need to save the line data and its identation for analyis
                my $indent = indent $line;
                if $line !~~ /$heredoc-label/ {
                    if $indent < $heredoc-min-indent { 
                        # check on every line before termination:
                        $heredoc-min-indent = $indent;
                    }
                    next LINE;
                }

                # we must have found the ending label, so...
                $heredoc-indent = $indent;
                # compare with what was seen
                if $heredoc-min-indent < $heredoc-indent {
                    # TODO fix reporting
                }

                if $debug {
                    note qq:to/HERE/;
                    DEBUG: Line $linenum: found heredoc terminator '$heredoc-label'
                      for heredoc type '{$L.open-heredoc.type}', indent: $heredoc-indent.
                    HERE
                }

		my $type  = "heredoc";

                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);
                        $heredoc-min-indent = $indent;
                my $LT = LType.new: :$type, :$linenum;
                $LL.types.push($LT);

                # Check the heredoc var and remove the found match
                # if all is well.
                die "FATAL: Unexpected empty \$open-heredoc" if not $L.open-heredoc;

                my $opener = $L.open-heredoc;
                my $err = 0;
                ++$err if $opener.label ne $heredoc-label;
                ++$err if $opener.type !~~ /heredoc/;
                die "FATAL: Unexpected \$open-heredoc errors" if $err;

                # reset
                $in-heredoc = 0;
                $heredoc-min-indent = Inf;
                $L.open-heredoc = 0;

                next LINE;
            }
            #elsif $in-pod-block {
            elsif $pod-parent {

# TODO Need to use a more complex approach since some pod
#      blocks can contain others and some not. For
#      example, =begin/=end pod can contain other
#      pod blocks, but =begin/=end comments mask
#      pod blocks inside.
#
#      But indentation is critical for all such blocks
#      even though parent blocks may have more indentation
#      than child blocks.

                note "DEBUG: \$pod-parent is True on line $linenum" if $debug;
                # the only text on the line should be: '{$indent-spaces}=end \h+ {$typename} \h*'
                if $line !~~ /^ $pod-indent-str '=' end \h+ $pod-label / {
                    next LINE;
                }

                # we must have found the ending label, so...
                if $debug {
                    note qq:to/HERE/;
                    DEBUG: Line $linenum: found ending pod block typename '$pod-label'
                      for pod block type '{$L.open-pod-block.tail.type}'
                    HERE
                }

                #$in-pod-block = 0;
		my $type  = "End-pod-block";

                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);
                my $LT = LType.new: :$type, :$linenum;
                $LL.types.push($LT);

                # Check the pod block var and remove the found match
                # if all is well.
                die "FATAL: Unexpected empty \$open-pod" if not $L.open-pod-block;

                my $opener = $L.open-pod-block.tail;
                my $err = 0;
                ++$err if $opener.label ne $pod-label;
                ++$err if $opener.type !~~ /'Pod-begin'/;
                die "FATAL: Unexpected \$open-pod-block errors" if $err;
                $L.open-pod-block.pop; # = 0;

                next LINE;
            }

            # check pod begin/end
            if $line ~~ /^ (\h*) '=' (begin|end) \h+ (<alpha><alnum>+) \h*/ {
                $LL = set-get-LLine $LL, :$linenum, :$line, :linter($L);

	        my $type  = "pod";
                $pod-indent-str = ~$0;
                my $typ         = ~$1;
                $pod-label      = ~$2;
                $pod-indent     = $pod-indent-str.chars;

                my $begin = $typ eq 'begin' ?? True !! False;

                # is this a pod parent?
                # TODO handle this properly
                my $is-parent = False;

                my $LT = LType.new:
                :$type,
                :$begin,
                :$is-parent,
                :label($pod-label),
                :$linenum,
                :indent-str($pod-indent-str),
                ;

                $LL.types.push($LT);

                # reportable
                $L.misc-stack.push($LT);

                #die "FATAL: Unexpected value for \$open-pod-block" if $L.open-pod-block;
                $L.open-pod-block.push: $LT;

                next LINE;
            }

            # check heredocs
            if $line ~~ / '=' \h* '<<' <['"]> (<alpha><alnum>+) <['"]> / {

	        my $type = "perl-heredoc";
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
                my $type = "heredoc";
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
} # sub paste

sub indent(Str:D $s) {
    # determine length of leading spaces in string $s
    my $indent = '';
    if $s ~~ /^ (\h*) / {
        $indent = ~$0;
    }
    $indent.chars
} # sub indent
